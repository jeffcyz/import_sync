#!/usr/bin/env python3
"""Import a pair of Claude artifacts using automatic naming detection.

Supported pairs in Downloads:
  - out_1.jsonl + out_2.json
  - SPEC_R006.jsonl + QA_R006.json (for --id 6)

Always remove the LAST NON-EMPTY TEXT LINE from EACH input (including the
already named files). Validate both cleaned files and then copy to the
canonical project destinations. On any failure, retain the original inputs.
If both pairs exist, require an explicit --source-mode to avoid stale imports.

Usage:
  py tools/import_claude_artifacts.py --id 6
  py tools/import_claude_artifacts.py --id 6 --source-mode named
  py tools/import_claude_artifacts.py --id 6 --source-mode generic
  py tools/import_claude_artifacts.py --id 6 --keep-downloads
  py tools/import_claude_artifacts.py --id 6 --replace
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def trim_final_nonempty_line(path: Path) -> tuple[str, str]:
    """Remove exactly one last nonblank logical line, plus any trailing blank lines.

    Unicode BOM is tolerated on read. The caller validates the result before
    modifying any original or published file.
    """
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines(keepends=True)
    while lines and not lines[-1].strip():
        lines.pop()
    if len(lines) < 2:
        raise ValueError(
            f"{path.name}: fewer than two nontrivial physical lines; "
            "forced last-line deletion would erase the entire artifact. "
            "No files changed."
        )
    removed = lines.pop()
    cleaned = "".join(lines).rstrip("\r\n") + "\n"
    if not cleaned.strip():
        raise ValueError(f"{path.name}: no content remains after deleting last line")
    return cleaned, removed


def read_jsonl_text(text: str, filename: str) -> list[dict]:
    records = []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{filename}: cleaned JSONL line {n} invalid: {exc}") from exc
        if not isinstance(item, dict):
            raise ValueError(f"{filename}: JSONL line {n} must be an object")
        records.append(item)
    if not records:
        raise ValueError(f"{filename}: cleaned JSONL has no records")
    return records


def check_qa(text: str, rid: int) -> None:
    try:
        obj = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError(
            "QA input is not valid JSON AFTER forced last-line removal; "
            "it may have ended with an essential closing brace. "
            "No files changed. " + str(exc)
        ) from exc
    if not isinstance(obj, dict):
        raise ValueError("QA input must be a JSON object")
    if "target_record_id" in obj and int(obj["target_record_id"]) != rid:
        raise ValueError(f"QA target_record_id does not match --id {rid}")
    if "expected_row_keys" in obj and f"R{rid:03d}" not in obj["expected_row_keys"]:
        raise ValueError(f"QA expected_row_keys does not include R{rid:03d}")


def discover_download_pair(downloads: Path, rid: int, source_mode: str) -> tuple[Path, Path, str]:
    """Choose a complete pair, never combine one stale file with another pair."""
    pairs = {
        "named": (
            downloads / f"SPEC_R{rid:03d}.jsonl",
            downloads / f"QA_R{rid:03d}.json",
        ),
        "generic": (downloads / "out_1.jsonl", downloads / "out_2.json"),
    }

    if not downloads.is_dir():
        raise FileNotFoundError(f"Downloads folder does not exist: {downloads}")

    if source_mode != "auto":
        patch, qa = pairs[source_mode]
        missing = [str(p) for p in (patch, qa) if not p.is_file()]
        if missing:
            raise FileNotFoundError(
                f"Missing {source_mode} artifact(s): {', '.join(missing)}"
            )
        return patch, qa, source_mode

    complete = [
        mode for mode, files in pairs.items()
        if all(p.is_file() for p in files)
    ]
    if len(complete) == 1:
        mode = complete[0]
        return *pairs[mode], mode
    if len(complete) > 1:
        raise ValueError(
            "Both named and generic artifact pairs are present in Downloads. "
            "Use --source-mode named or --source-mode generic to select explicitly."
        )

    found = {mode: [p.name for p in files if p.is_file()] for mode, files in pairs.items()}
    raise FileNotFoundError(
        f"No complete artifact pair for record {rid}. Found: {found}. "
        "Expected matching pair of named or generic files; do not mix formats."
    )


def atomic_write(path: Path, data: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="wb", dir=path.parent,
                                     prefix=path.name + ".", suffix=".tmp",
                                     delete=False) as f:
        tmp = Path(f.name)
        f.write(data.encode("utf-8"))
    try:
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--id", type=int, required=True, help="Numbered validation ID, e.g. 3")
    parser.add_argument("--downloads", type=Path, default=Path.home() / "Downloads")
    parser.add_argument(
        "--source-mode", choices=("auto", "named", "generic"), default="auto",
        help="Auto-detect pair, or explicitly choose when Downloads has both kinds",
    )
    parser.add_argument("--keep-downloads", action="store_true", help="Preserve input downloads after import")
    parser.add_argument("--replace", action="store_true", help="Back up and replace existing destination artifacts")
    parser.add_argument("--skip-project-validation", action="store_true",
                        help="Only JSON syntax checks; NOT recommended for production")
    args = parser.parse_args()
    if args.id <= 0:
        parser.error("--id must be positive")

    incoming_patch, incoming_qa, detected_mode = discover_download_pair(
        args.downloads, args.id, args.source_mode
    )
    print(f"Detected Claude download naming: {detected_mode}")
    print(f"Input patch: {incoming_patch}")
    print(f"Input QA:    {incoming_qa}")

    dest_patch = ROOT / "patches" / "by_record" / f"SPEC_R{args.id:03d}.jsonl"
    dest_qa = ROOT / "qa" / "by_record" / f"QA_R{args.id:03d}.json"
    for incoming, dest in ((incoming_patch, dest_patch), (incoming_qa, dest_qa)):
        if incoming.resolve() == dest.resolve():
            raise ValueError(
                f"Input is already at destination ({dest}); do not trim in-place. "
                "Place fresh Claude downloads in Downloads first."
            )
    for p in (dest_patch, dest_qa):
        if p.exists() and not args.replace:
            raise FileExistsError(f"Destination exists: {p}. Use --replace to create a backup and overwrite.")

    cleaned_patch, deleted_patch_line = trim_final_nonempty_line(incoming_patch)
    cleaned_qa, deleted_qa_line = trim_final_nonempty_line(incoming_qa)
    parsed_patch = read_jsonl_text(cleaned_patch, incoming_patch.name)
    check_qa(cleaned_qa, args.id)

    # Validate the actual cleaned patch with the existing project's schema,
    # source fingerprint, and continuation-row coverage rules BEFORE publication.
    if not args.skip_project_validation:
        validator = ROOT / "tools" / "single_validation.py"
        if not validator.exists():
            raise FileNotFoundError(f"Missing project validator: {validator}")
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_patch = Path(tmpdir) / "candidate.jsonl"
            temp_patch.write_bytes(cleaned_patch.encode("utf-8"))
            cmd = [sys.executable, str(validator), "validate", "--id",
                   str(args.id), "--patch", str(temp_patch)]
            print("Running Single Validation source/schema/fingerprint checks...")
            subprocess.run(cmd, cwd=ROOT, check=True)

    # Only commit after both cleaned artifacts and source registry are checked.
    backups = {}
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    for path in (dest_patch, dest_qa):
        if path.exists():
            backup = path.with_name(f"{path.stem}.{stamp}.bak{path.suffix}")
            shutil.copy2(path, backup)
            backups[path] = backup

    published = []
    try:
        atomic_write(dest_patch, cleaned_patch)
        published.append(dest_patch)
        atomic_write(dest_qa, cleaned_qa)
        published.append(dest_qa)
    except Exception:
        for path in published:
            if path in backups:
                shutil.copy2(backups[path], path)
            else:
                path.unlink(missing_ok=True)
        raise

    # Remove Downloads files only after successful validation and publication.
    if not args.keep_downloads:
        incoming_patch.unlink()
        incoming_qa.unlink()

    print(f"\nSUCCESS — R{args.id:03d}: imported {len(parsed_patch)} JSONL row(s)")
    print(f"Removed 1 last non-empty line from {incoming_patch.name} (length {len(deleted_patch_line.strip())} chars)")
    print(f"Removed 1 last non-empty line from {incoming_qa.name} (length {len(deleted_qa_line.strip())} chars)")
    print("Patch:", dest_patch)
    print("QA:   ", dest_qa)
    print("Downloads:", "kept" if args.keep_downloads else "removed after success")
    print(f"Next: py tools/single_validation.py merge --id {args.id}")


if __name__ == "__main__":
    main()

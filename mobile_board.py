
#!/usr/bin/env python3
"""
ASAP Validation Enrichment — Single Validation Tool

Commands:
    prepare  --id N
    validate --id N
    merge    --id N

Manual modes:
    shared   (default)
    full
    selected

The tool preserves the original Validation Master JSON.
It updates only implementation_spec in the merged output.
"""

import argparse
import hashlib
import json
import re
import shutil

from datetime import datetime
from pathlib import Path


# ============================================================
# Paths and configuration
# ============================================================

ROOT = Path(__file__).resolve().parents[1]

DEFAULT_SOURCE = ROOT / "source" / "validation_master_flat.json"

DEFAULT_REGISTRY = ROOT / "control" / "ROW_REGISTRY.jsonl"

DEFAULT_SCHEMA = ROOT / "control" / "SPEC_SCHEMA.json"

SHARED_CONTEXT = (
    ROOT
    / "context_packs"
    / "shared"
    / "ASAP_KNOWLEDGE_CONTEXT.md"
)

CONTEXT_DIR = ROOT / "context_packs" / "by_record"

PATCH_DIR = ROOT / "patches" / "by_record"

DEFAULT_OUTPUT = (
    ROOT
    / "final"
    / "validation_master_enriched.json"
)

MANUALS = {
    "ASAP_SCRIPTING_MANUAL": "merged_scripting_manual.md",
    "ASAP_USER_MANUAL": "merged_user_manual.md",
    "ASAP_RELEASE_NOTES": "Releases-be4181818e.md",
    "ASAP_SCHEMA_CATALOG": "schema_catalog.md",
}


# ============================================================
# File utilities
# ============================================================

def read_text(path):
    return Path(path).read_text(encoding="utf-8-sig")


def read_json(path):
    return json.loads(read_text(path))


def read_jsonl(path):
    records = []

    for line_number, line in enumerate(
        read_text(path).splitlines(),
        start=1,
    ):
        if not line.strip():
            continue

        try:
            item = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(
                f"Invalid JSONL at {path}, "
                f"line {line_number}: {exc}"
            ) from exc

        if not isinstance(item, dict):
            raise ValueError(
                f"Expected JSON object at "
                f"{path}:{line_number}"
            )

        records.append(item)

    return records


def write_text(path, content):
    path = Path(path)

    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    # Avoid Windows newline conversion.
    path.write_bytes(content.encode("utf-8"))


def write_json(path, data):
    content = json.dumps(
        data,
        ensure_ascii=False,
        indent=2,
        allow_nan=False,
    ) + "\n"

    write_text(path, content)

    if read_json(path) != data:
        raise ValueError(
            f"JSON round-trip verification failed: {path}"
        )


def source_fingerprint(record):
    serialized = json.dumps(
        record,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )

    return hashlib.sha256(
        serialized.encode("utf-8")
    ).hexdigest()


def normalize_id(value):
    if value is None:
        return None

    if isinstance(value, bool):
        raise ValueError("Boolean record ID is invalid")

    number = float(value)

    if not number.is_integer():
        raise ValueError(f"Invalid record ID: {value}")

    return int(number)


# ============================================================
# Source registry
# ============================================================

def load_source_registry(source_path, registry_path):
    source_records = read_json(source_path)
    registry_records = read_jsonl(registry_path)

    if not isinstance(source_records, list):
        raise ValueError(
            "Validation Master must be a JSON array"
        )

    if len(source_records) != len(registry_records):
        raise ValueError(
            "Source and registry row counts differ"
        )

    index = {}
    continuation_counts = {}

    for position, (record, registry) in enumerate(
        zip(source_records, registry_records)
    ):
        record_id = normalize_id(
            record.get("record_id")
        )

        if record_id is not None:
            row_key = f"R{record_id:03d}"

        else:
            parent_id = normalize_id(
                record.get("parent_record_id")
            )

            if parent_id is None:
                raise ValueError(
                    f"Continuation at index {position} "
                    "has no parent_record_id"
                )

            continuation_counts[parent_id] = (
                continuation_counts.get(parent_id, 0) + 1
            )

            row_key = (
                f"C{parent_id:03d}-"
                f"{continuation_counts[parent_id]:02d}"
            )

        fingerprint = source_fingerprint(record)

        if registry.get("row_key") != row_key:
            raise ValueError(
                f"Row key mismatch: {row_key}"
            )

        if registry.get("source_index") != position:
            raise ValueError(
                f"Source index mismatch: {row_key}"
            )

        if registry.get("source_row_sha256") != fingerprint:
            raise ValueError(
                f"Source fingerprint mismatch: {row_key}"
            )

        if row_key in index:
            raise ValueError(
                f"Duplicate row key: {row_key}"
            )

        index[row_key] = {
            "position": position,
            "record": record,
            "fingerprint": fingerprint,
        }

    return source_records, index


def get_target_keys(index, record_id):
    main_key = f"R{record_id:03d}"

    if main_key not in index:
        raise ValueError(
            f"Record ID {record_id} not found"
        )

    keys = []

    for key, entry in index.items():
        record = entry["record"]

        rid = normalize_id(record.get("record_id"))
        parent = normalize_id(
            record.get("parent_record_id")
        )

        if rid == record_id:
            keys.append(key)

        elif rid is None and parent == record_id:
            keys.append(key)

    return keys


# ============================================================
# Source block generator
# ============================================================

def make_source_block(
    source_id,
    chunk_id,
    content,
    scope="FULL_DOCUMENT",
):
    return (
        "===== BEGIN SOURCE =====\n"
        f"SOURCE_ID: {source_id}\n"
        f"CHUNK_ID: {chunk_id}\n"
        f"SOURCE_SCOPE: {scope}\n"
        "CONTENT_START\n"
        f"{content.rstrip()}\n"
        "CONTENT_END\n"
        "===== END SOURCE =====\n"
    )


# ============================================================
# Shared Knowledge Context
# ============================================================

def validate_shared_context():
    if not SHARED_CONTEXT.is_file():
        raise FileNotFoundError(
            f"Shared Context not found:\n"
            f"{SHARED_CONTEXT}\n\n"
            "Run:\n"
            "py tools/build_asap_context.py"
        )

    content = read_text(SHARED_CONTEXT)

    for source_id in MANUALS:
        pattern = (
            rf"(?m)^SOURCE_ID:\s*"
            rf"{re.escape(source_id)}\s*$"
        )

        matches = re.findall(pattern, content)

        if len(matches) != 1:
            raise ValueError(
                f"Expected exactly one source block for "
                f"{source_id}, found {len(matches)}"
            )

    if content.count("===== BEGIN SOURCE =====") != 4:
        raise ValueError(
            "Shared Context must contain four source blocks"
        )

    if content.count("===== END SOURCE =====") != 4:
        raise ValueError(
            "Shared Context source boundaries are incomplete"
        )

    print(
        f"[OK] Shared Context: "
        f"{SHARED_CONTEXT.stat().st_size:,} bytes"
    )

    return content


# ============================================================
# Prepare Claude Context
# ============================================================

def prepare(args, index):
    record_id = args.id

    keys = get_target_keys(index, record_id)

    target_records = [
        index[key]["record"]
        for key in keys
    ]

    registry_subset = [
        {
            "row_key": key,
            "source_index": index[key]["position"],
            "source_row_sha256": index[key]["fingerprint"],
        }
        for key in keys
    ]

    blocks = []

    # Validation source
    blocks.append(
        make_source_block(
            "VALIDATION_RECORD",
            f"R{record_id:03d}",
            json.dumps(
                target_records,
                ensure_ascii=False,
                indent=2,
            ),
            "TARGET_AND_CONTINUATIONS",
        )
    )

    # Registry
    blocks.append(
        make_source_block(
            "ROW_REGISTRY",
            f"R{record_id:03d}",
            "\n".join(
                json.dumps(item, ensure_ascii=False)
                for item in registry_subset
            ),
            "TARGET_AND_CONTINUATIONS",
        )
    )

    # Schema
    blocks.append(
        make_source_block(
            "SPEC_SCHEMA",
            "CANONICAL",
            read_text(args.schema),
        )
    )

    # --------------------------------------------------------
    # Knowledge source modes
    # --------------------------------------------------------

    if args.manual_mode == "shared":
        shared_content = validate_shared_context()

        if args.embed_shared:
            # Embed the four existing source blocks as-is.
            # Do not wrap them in another SOURCE block.
            blocks.append(shared_content)

    elif args.manual_mode == "full":
        for source_id, filename in MANUALS.items():
            path = ROOT / "source" / filename

            if not path.is_file():
                raise FileNotFoundError(path)

            blocks.append(
                make_source_block(
                    source_id,
                    filename,
                    read_text(path),
                    "FULL_DOCUMENT",
                )
            )

    elif args.manual_mode == "selected":
        if not args.include:
            raise ValueError(
                "Selected mode requires --include"
            )

    # Optional selected manual chunks
    for item in args.include:
        source_id, separator, relative_path = (
            item.partition(":")
        )

        if not separator or source_id not in MANUALS:
            raise ValueError(
                "Expected --include "
                "SOURCE_ID:relative/path.md"
            )

        path = (ROOT / relative_path).resolve()

        if ROOT not in path.parents or not path.is_file():
            raise ValueError(
                f"Invalid or missing source chunk: {path}"
            )

        blocks.append(
            make_source_block(
                source_id,
                path.stem,
                read_text(path),
                "SELECTED_SECTIONS",
            )
        )

    # --------------------------------------------------------
    # Generate three output files
    # --------------------------------------------------------

    CONTEXT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    prefix = f"R{record_id:03d}"

    header_path = (
        CONTEXT_DIR / f"{prefix}_HEADER.txt"
    )

    context_path = (
        CONTEXT_DIR / f"{prefix}_CONTEXT.txt"
    )

    execute_path = (
        CONTEXT_DIR / f"{prefix}_EXECUTE.txt"
    )

    # Header, with automatic Record ID substitution
    header_template = read_text(
        ROOT / "prompts" / "SINGLE_VALIDATION_HEADER.md"
    )

    header = (
        header_template
        .replace(
            "[REPLACE_WITH_INTEGER]",
            str(record_id),
        )
        .replace(
            "[R###]",
            prefix,
        )
    )

    write_text(header_path, header)

    # Record context
    write_text(
        context_path,
        "\n\n".join(blocks),
    )

    # Final execute prompt
    execute_template = read_text(
        ROOT / "prompts" / "SINGLE_VALIDATION_EXECUTE.md"
    )

    execute = (
        f"TARGET_RECORD_ID: {record_id}\n"
        f"TARGET_ROW_KEY: {prefix}\n\n"
        + execute_template
    )

    write_text(execute_path, execute)

    # --------------------------------------------------------
    # Console summary
    # --------------------------------------------------------

    print()
    print("=" * 60)
    print(f"Prepared {prefix}: {len(keys)} source rows")
    print("=" * 60)

    print(f"Header:  {header_path}")
    print(f"Context: {context_path}")
    print(f"Execute: {execute_path}")

    if args.manual_mode == "shared":
        if args.embed_shared:
            print(
                "\nShared Knowledge was embedded "
                "inside the Record Context."
            )
        else:
            print(
                "\nPaste Shared Knowledge separately:"
            )
            print(SHARED_CONTEXT)

    print("\nClaude input order:")
    print("1. HEADER")
    print("2. CONTEXT")
    if (
        args.manual_mode == "shared"
        and not args.embed_shared
    ):
        print("3. SHARED KNOWLEDGE")
        print("4. EXECUTE")
    else:
        print("3. EXECUTE")

    print()


# ============================================================
# Schema validation
# ============================================================

JSON_TYPES = {
    "null": type(None),
    "string": str,
    "array": list,
    "object": dict,
    "integer": int,
    "number": (int, float),
    "boolean": bool,
}


def validate_schema(value, schema, location="$"):
    if "enum" in schema:
        if value not in schema["enum"]:
            raise ValueError(
                f"{location}: invalid enum value"
            )

    expected_type = schema.get("type")

    if expected_type:
        allowed = (
            [expected_type]
            if isinstance(expected_type, str)
            else expected_type
        )

        def matches(type_name):
            cls = JSON_TYPES[type_name]

            if type_name in ("integer", "number"):
                if isinstance(value, bool):
                    return False

            return isinstance(value, cls)

        if not any(matches(t) for t in allowed):
            raise ValueError(
                f"{location}: wrong data type; "
                f"expected {allowed}"
            )

    if isinstance(value, dict):
        required = schema.get("required", [])

        for field in required:
            if field not in value:
                raise ValueError(
                    f"{location}: missing {field}"
                )

        properties = schema.get("properties", {})

        if schema.get("additionalProperties") is False:
            unexpected = set(value) - set(properties)

            if unexpected:
                raise ValueError(
                    f"{location}: unexpected fields "
                    f"{sorted(unexpected)}"
                )

        for name, item in value.items():
            if name in properties:
                validate_schema(
                    item,
                    properties[name],
                    f"{location}.{name}",
                )

    if isinstance(value, list):
        item_schema = schema.get("items")

        if isinstance(item_schema, dict):
            for position, item in enumerate(value):
                validate_schema(
                    item,
                    item_schema,
                    f"{location}[{position}]",
                )


# ============================================================
# Validate one Claude Patch
# ============================================================

def validate_patch(record_id, index, patch_path, schema_path):
    patches = read_jsonl(patch_path)

    expected_keys = get_target_keys(
        index,
        record_id,
    )

    actual_keys = [
        item.get("row_key")
        for item in patches
    ]

    if (
        len(actual_keys) != len(set(actual_keys))
        or set(actual_keys) != set(expected_keys)
    ):
        raise ValueError(
            "Patch row coverage mismatch.\n"
            f"Expected: {expected_keys}\n"
            f"Received: {actual_keys}"
        )

    schema = read_json(schema_path)

    expected_fields = {
        "row_key",
        "source_row_sha256",
        "implementation_spec",
    }

    for patch in patches:
        if set(patch) != expected_fields:
            raise ValueError(
                f"Unexpected Patch fields: "
                f"{patch.get('row_key')}"
            )

        row_key = patch["row_key"]

        if (
            patch["source_row_sha256"]
            != index[row_key]["fingerprint"]
        ):
            raise ValueError(
                f"Patch fingerprint mismatch: {row_key}"
            )

        validate_schema(
            patch["implementation_spec"],
            schema,
            f"{row_key}.implementation_spec",
        )

    return patches


# ============================================================
# Incremental JSON merge
# ============================================================

def merge(args, original_records, index, patches):
    output_path = args.output

    if output_path.resolve() == args.source.resolve():
        raise ValueError(
            "Output cannot overwrite original source JSON"
        )

    if output_path.exists():
        merged = read_json(output_path)
    else:
        merged = [
            dict(row)
            for row in original_records
        ]

    if (
        not isinstance(merged, list)
        or len(merged) != len(original_records)
    ):
        raise ValueError(
            "Existing enriched JSON has invalid row count"
        )

    # Verify no original fields have been altered.
    for position, (original, current) in enumerate(
        zip(original_records, merged)
    ):
        original_fields = {
            key: value
            for key, value in current.items()
            if key != "implementation_spec"
        }

        if original_fields != original:
            raise ValueError(
                f"Original data changed at row {position}"
            )

    # Apply ONLY target record patches.
    changed_keys = []

    for patch in patches:
        row_key = patch["row_key"]

        position = index[row_key]["position"]

        if (
            "implementation_spec" in merged[position]
            and not args.replace
        ):
            raise ValueError(
                f"{row_key} already enriched. "
                "Use --replace to update it."
            )

        merged[position]["implementation_spec"] = (
            patch["implementation_spec"]
        )

        changed_keys.append(row_key)

    # Serialize and verify before changing output.
    serialized = json.dumps(
        merged,
        ensure_ascii=False,
        indent=2,
        allow_nan=False,
    ) + "\n"

    if json.loads(serialized) != merged:
        raise ValueError("JSON serialization check failed")

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    temp_path = output_path.with_suffix(".tmp")

    write_text(temp_path, serialized)

    if read_json(temp_path) != merged:
        temp_path.unlink(missing_ok=True)
        raise ValueError("Temporary output verification failed")

    # Back up previous enriched output.
    if output_path.exists():
        timestamp = datetime.now().strftime(
            "%Y%m%d_%H%M%S_%f"
        )

        backup_path = output_path.with_name(
            f"{output_path.stem}_{timestamp}.bak.json"
        )

        shutil.copy2(
            output_path,
            backup_path,
        )

        print(f"Backup created: {backup_path}")

    # Publish new output.
    temp_path.replace(output_path)

    print()
    print("=" * 60)
    print("MERGE SUCCESSFUL")
    print("=" * 60)

    print("Updated Row Keys:", ", ".join(changed_keys))
    print("Total source rows:", len(original_records))
    print("Output:", output_path)
    print("Original business fields: preserved")
    print("Development statuses: preserved")
    print()


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description=(
            "ASAP Single Validation Enrichment "
            "— prepare, validate, merge"
        )
    )

    commands = parser.add_subparsers(
        dest="command",
        required=True,
    )

    for command_name in (
        "prepare",
        "validate",
        "merge",
    ):
        command = commands.add_parser(command_name)

        command.add_argument(
            "--id",
            type=int,
            required=True,
            help="Numbered Validation Record ID",
        )

        command.add_argument(
            "--source",
            type=Path,
            default=DEFAULT_SOURCE,
        )

        command.add_argument(
            "--registry",
            type=Path,
            default=DEFAULT_REGISTRY,
        )

        command.add_argument(
            "--schema",
            type=Path,
            default=DEFAULT_SCHEMA,
        )

        if command_name == "prepare":
            command.add_argument(
                "--manual-mode",
                choices=("shared", "full", "selected"),
                default="shared",
            )

            command.add_argument(
                "--embed-shared",
                action="store_true",
                help=(
                    "Embed shared Markdown inside "
                    "the Record Context"
                ),
            )

            command.add_argument(
                "--include",
                action="append",
                default=[],
                help="SOURCE_ID:relative/path.md",
            )

        else:
            command.add_argument(
                "--patch",
                type=Path,
                default=None,
            )

        if command_name == "merge":
            command.add_argument(
                "--output",
                type=Path,
                default=DEFAULT_OUTPUT,
            )

            command.add_argument(
                "--replace",
                action="store_true",
            )

    args = parser.parse_args()

    original_records, index = load_source_registry(
        args.source,
        args.registry,
    )

    if args.command == "prepare":
        prepare(args, index)
        return

    patch_path = (
        args.patch
        if args.patch is not None
        else PATCH_DIR / f"SPEC_R{args.id:03d}.jsonl"
    )

    patches = validate_patch(
        args.id,
        index,
        patch_path,
        args.schema,
    )

    print()
    print("[PASS] Patch validation")
    print("Record ID:", args.id)
    print("Validated source rows:", len(patches))
    print("Row coverage: complete")
    print("Source fingerprints: matched")
    print("Schema basic validation: passed")

    if args.command == "merge":
        merge(
            args,
            original_records,
            index,
            patches,
        )


if __name__ == "__main__":
    main()

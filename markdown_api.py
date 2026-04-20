from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path
from typing import Iterable

BASE_DIR = Path(__file__).resolve().parent
MARKITDOWN_SRC = BASE_DIR / "markitdown" / "packages" / "markitdown" / "src"

MODULE_TO_PACKAGE = {
    "requests": "requests",
    "magika": "magika",
    "charset_normalizer": "charset-normalizer",
    "bs4": "beautifulsoup4",
    "markdownify": "markdownify",
    "defusedxml": "defusedxml",
    "mammoth": "mammoth",
    "pdfminer": "pdfminer.six",
    "pdfplumber": "pdfplumber",
    "openpyxl": "openpyxl",
    "xlrd": "xlrd",
    "olefile": "olefile",
    "pptx": "python-pptx",
    "pydub": "pydub",
    "speech_recognition": "SpeechRecognition",
}

CORE_MODULES = [
    "requests",
    "magika",
    "charset_normalizer",
    "bs4",
    "markdownify",
    "defusedxml",
]

EXTENSION_MODULES = {
    ".docx": ["mammoth"],
    ".pdf": ["pdfminer", "pdfplumber"],
    ".pptx": ["pptx"],
    ".xlsx": ["openpyxl"],
    ".xls": ["xlrd"],
    ".msg": ["olefile"],
    ".mp3": ["pydub", "speech_recognition"],
    ".wav": ["pydub", "speech_recognition"],
    ".m4a": ["pydub", "speech_recognition"],
}


def ensure_local_markitdown_on_path() -> None:
    src_path = str(MARKITDOWN_SRC)
    if src_path not in sys.path:
        sys.path.insert(0, src_path)


def _missing_packages(modules: Iterable[str]) -> list[str]:
    missing: list[str] = []
    for module_name in modules:
        if importlib.util.find_spec(module_name) is None:
            missing.append(MODULE_TO_PACKAGE.get(module_name, module_name))
    return sorted(set(missing))


def _required_modules_for(file_path: Path) -> list[str]:
    modules = list(CORE_MODULES)
    modules.extend(EXTENSION_MODULES.get(file_path.suffix.lower(), []))
    return modules


def _raise_if_dependencies_missing(file_path: Path) -> None:
    missing = _missing_packages(_required_modules_for(file_path))
    if not missing:
        return

    package_list = ", ".join(missing)
    raise RuntimeError(
        "The local markitdown source directory is configured, but the current Python interpreter is missing runtime dependencies: "
        f"{package_list}\n"
        f"markitdown source path: {MARKITDOWN_SRC}\n"
        "This means you do not need to `pip install markitdown`, but you still need these third-party dependencies "
        "available in the current interpreter, or you need to switch to a Python environment that already has them installed."
    )


def build_markitdown(**kwargs):
    ensure_local_markitdown_on_path()
    from markitdown import MarkItDown

    return MarkItDown(**kwargs)


def convert_file(file_path: str | Path, **kwargs):
    resolved_path = Path(file_path).expanduser().resolve()
    _raise_if_dependencies_missing(resolved_path)
    converter = build_markitdown()
    return converter.convert(str(resolved_path), **kwargs)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Call MarkItDown directly from the local markitdown source tree."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Files to convert. If omitted, the script tries test.pdf and test.docx in the current directory.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    targets = args.files or ["test.pdf", "test.docx"]
    for target in targets:
        abs_path = (BASE_DIR / target).resolve() if not Path(target).is_absolute() else Path(target)
        print(f"=== markitdown {abs_path.name} ===")

        if not abs_path.exists():
            print(f"[error] File not found: {abs_path}")
            continue

        try:
            result = convert_file(abs_path)
        except Exception as exc:
            print(f"[error] {exc}")
            continue

        print(result.markdown)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

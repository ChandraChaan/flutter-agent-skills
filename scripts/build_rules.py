"""Generates the Cursor and Copilot rule files from rules/AGENTS.md.

AGENTS.md is the single source. Edit it, then run:

    python scripts/build_rules.py          # write the generated files
    python scripts/build_rules.py --check  # fail if they are out of date (CI)
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
HEADER = "<!-- Generated from rules/AGENTS.md by scripts/build_rules.py. Edit AGENTS.md instead. -->"

# Cursor rule files: name -> (description, globs or None for always-on, AGENTS.md sections)
CURSOR_RULES = {
    "flutter-core": (
        "Project setup, the checks to run before finishing, architecture and git rules for this Flutter app",
        None,
        ["This project", "Before you finish any change", "Architecture", "Git"],
    ),
    "flutter-ui": (
        "Rules for Flutter widgets, state management, accessibility and performance",
        "lib/**/*.dart",
        ["State management (Riverpod 3)", "Widgets", "Accessibility", "Performance"],
    ),
    "flutter-data": (
        "Rules for async code, errors, networking and security in the data layer",
        "lib/**/data/**/*.dart,lib/core/**/*.dart",
        ["Async, errors and networking", "Security"],
    ),
    "flutter-tests": (
        "Rules for writing Flutter unit, widget and integration tests",
        "test/**/*.dart,integration_test/**/*.dart",
        ["Testing"],
    ),
}


def sections(markdown: str) -> dict[str, str]:
    parts = re.split(r"^## (.+)$", markdown, flags=re.MULTILINE)
    return {parts[i].strip(): parts[i + 1].strip() for i in range(1, len(parts), 2)}


def strip_comments(markdown: str) -> str:
    return re.sub(r"<!--.*?-->\n?", "", markdown, flags=re.S)


def generate() -> dict[Path, str]:
    source = (RULES / "AGENTS.md").read_text(encoding="utf-8")
    by_title = sections(source)
    files = {}

    for name, (description, globs, titles) in CURSOR_RULES.items():
        missing = [t for t in titles if t not in by_title]
        if missing:
            raise SystemExit(f"AGENTS.md has no section(s) {missing} for {name}.mdc")
        front = ["---", f"description: {description}"]
        front.append(f"globs: {globs}" if globs else "globs:")
        front.append(f"alwaysApply: {'false' if globs else 'true'}")
        front.append("---")
        body = "\n\n".join(f"## {t}\n\n{by_title[t]}" for t in titles)
        files[RULES / "cursor" / f"{name}.mdc"] = "\n".join(front) + f"\n{HEADER}\n\n{body}\n"

    body = strip_comments(source).strip()
    body = body.replace("# AGENTS.md: Flutter project rules", "# Copilot instructions: Flutter project rules", 1)
    files[RULES / "copilot-instructions.md"] = f"{HEADER}\n\n{body}\n"
    return files


def main() -> int:
    check = "--check" in sys.argv
    stale = []
    for path, content in generate().items():
        current = path.read_text(encoding="utf-8") if path.exists() else None
        if current != content:
            if check:
                stale.append(path.relative_to(ROOT))
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
                print(f"wrote {path.relative_to(ROOT)}")
    if stale:
        print("Out of date (run python scripts/build_rules.py):")
        for path in stale:
            print(f"  {path}")
        return 1
    if check:
        print("Generated rule files are up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main())

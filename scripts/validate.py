"""Validates the skills, plugin manifests and rule files.

Run from anywhere: python scripts/validate.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "plugins" / "flutter"
SKILLS = PLUGIN / "skills"

NAME = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
LINK = re.compile(r"\]\(([^)#\s]+)(#[^)\s]*)?\)")


def frontmatter(text: str) -> dict[str, str] | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end < 0:
        return None
    fields = {}
    for line in text[4:end].splitlines():
        key, sep, value = line.partition(":")
        if not sep or not key or key.startswith(" "):
            return None
        fields[key.strip()] = value.strip()
    return fields


def check_skill(skill: Path) -> list[str]:
    errors = []
    md = skill / "SKILL.md"
    if not md.exists():
        return [f"{skill.name}: missing SKILL.md"]
    text = md.read_text(encoding="utf-8")
    meta = frontmatter(text)
    if meta is None:
        return [f"{skill.name}: SKILL.md must start with --- frontmatter ---"]

    name = meta.get("name", "")
    description = meta.get("description", "")
    if name != skill.name:
        errors.append(f"{skill.name}: name '{name}' must match the folder name")
    if not NAME.match(name) or len(name) > 64:
        errors.append(f"{skill.name}: name must be lowercase words joined by hyphens, at most 64 characters")
    if not 50 <= len(description) <= 1024:
        errors.append(f"{skill.name}: description must be 50-1024 characters (is {len(description)})")
    if "Use when" not in description and "Use for" not in description and "Use before" not in description:
        errors.append(f"{skill.name}: description should say when to use the skill ('Use when ...')")
    if any(c in description for c in "<>"):
        errors.append(f"{skill.name}: description can't contain < or >")
    unknown = set(meta) - {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
    if unknown:
        errors.append(f"{skill.name}: fields {sorted(unknown)} aren't portable across agents")
    if len(text.splitlines()) > 500:
        errors.append(f"{skill.name}: SKILL.md is over 500 lines; move detail into supporting files")
    if text.count("```") % 2:
        errors.append(f"{skill.name}: unbalanced code fences")
    for target, _ in LINK.findall(text):
        if not re.match(r"^[a-z]+:", target) and not (skill / target).exists():
            errors.append(f"{skill.name}: links to missing file {target}")
    return errors


def check_manifests() -> list[str]:
    errors = []
    marketplace = json.loads((ROOT / ".claude-plugin" / "marketplace.json").read_text())
    plugin = json.loads((PLUGIN / ".claude-plugin" / "plugin.json").read_text())
    entries = {p["name"]: p for p in marketplace.get("plugins", [])}
    if plugin["name"] not in entries:
        errors.append(f"marketplace.json has no entry named '{plugin['name']}' (must match plugin.json)")
    else:
        source = entries[plugin["name"]]["source"]
        if (ROOT / source).resolve() != PLUGIN.resolve():
            errors.append(f"marketplace.json source {source} doesn't point at plugins/flutter")
    if not re.match(r"^\d+\.\d+\.\d+$", plugin.get("version", "")):
        errors.append("plugin.json needs a semantic version")
    return errors


def check_docs(skill_names: list[str]) -> list[str]:
    errors = []
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    claude_md = (ROOT / "rules" / "CLAUDE.md").read_text(encoding="utf-8")
    for name in skill_names:
        if f"/flutter:{name}" not in readme:
            errors.append(f"README.md doesn't list /flutter:{name}")
        if f"/flutter:{name}" not in claude_md:
            errors.append(f"rules/CLAUDE.md doesn't list /flutter:{name}")
    for target, _ in LINK.findall(readme):
        if not re.match(r"^[a-z]+:", target) and not (ROOT / target).exists():
            errors.append(f"README.md links to missing file {target}")

    template = (ROOT / "rules" / "analysis_options.yaml").read_text(encoding="utf-8")
    example = (ROOT / "example_app" / "analysis_options.yaml").read_text(encoding="utf-8")
    if template != example:
        errors.append("example_app/analysis_options.yaml must be identical to rules/analysis_options.yaml")
    return errors


def main() -> int:
    skills = sorted(p for p in SKILLS.iterdir() if p.is_dir())
    errors = []
    for skill in skills:
        errors += check_skill(skill)
    errors += check_manifests()
    errors += check_docs([s.name for s in skills])
    for error in errors:
        print(f"error: {error}")
    print(f"Checked {len(skills)} skills: {'OK' if not errors else f'{len(errors)} errors'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

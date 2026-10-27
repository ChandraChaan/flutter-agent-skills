#!/usr/bin/env bash
# Copies the rules into a Flutter project, or the skills into a skills folder.
#
#   scripts/install.sh rules  <flutter-project>          AGENTS.md, CLAUDE.md, Cursor and Copilot rules
#   scripts/install.sh skills <flutter-project>          skills into <project>/.claude/skills
#   scripts/install.sh skills --user                     skills into ~/.claude/skills
#
# Existing files are never overwritten; pass --force to replace them.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
force=false
args=()
for arg in "$@"; do
  if [[ "$arg" == "--force" ]]; then force=true; else args+=("$arg"); fi
done
what="${args[0]:-}"
target="${args[1]:-}"

copy() {
  local from="$1" to="$2"
  if [[ -e "$to" && "$force" != true ]]; then
    echo "skip   ${to} (exists; use --force to replace)"
    return
  fi
  mkdir -p "$(dirname "$to")"
  cp "$from" "$to"
  echo "added  ${to}"
}

case "$what" in
  rules)
    [[ -f "$target/pubspec.yaml" ]] || { echo "Not a Flutter project: $target" >&2; exit 1; }
    copy "$repo/rules/AGENTS.md" "$target/AGENTS.md"
    copy "$repo/rules/CLAUDE.md" "$target/CLAUDE.md"
    copy "$repo/rules/copilot-instructions.md" "$target/.github/copilot-instructions.md"
    for rule in "$repo"/rules/cursor/*.mdc; do
      copy "$rule" "$target/.cursor/rules/$(basename "$rule")"
    done
    echo
    echo "Next: edit the 'This project' section of $target/AGENTS.md."
    echo "Optional: compare $repo/rules/analysis_options.yaml with your analysis_options.yaml."
    ;;
  skills)
    if [[ "$target" == "--user" ]]; then
      dest="$HOME/.claude/skills"
    elif [[ -n "$target" ]]; then
      dest="$target/.claude/skills"
    else
      echo "Usage: $0 skills <flutter-project> | --user" >&2; exit 1
    fi
    for skill in "$repo"/plugins/flutter/skills/*/; do
      name="flutter-$(basename "$skill")"
      if [[ -e "$dest/$name" && "$force" != true ]]; then
        echo "skip   $dest/$name (exists; use --force to replace)"
        continue
      fi
      rm -rf "${dest:?}/$name"
      mkdir -p "$dest"
      cp -R "$skill" "$dest/$name"
      # Standalone skills get a flutter- prefix so they don't clash with others.
      sed -i.bak "s/^name: .*/name: $name/" "$dest/$name/SKILL.md" && rm "$dest/$name/SKILL.md.bak"
      echo "added  $dest/$name"
    done
    ;;
  *)
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac

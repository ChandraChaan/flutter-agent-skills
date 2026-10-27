# Contributing

Rules and skills here should come from real Flutter projects. The best contributions start with "agents keep doing X in our codebase, and this rule stopped it".

## Changing the rules

1. Edit `rules/AGENTS.md` only. The Cursor and Copilot files are generated from it.
2. Run `python scripts/build_rules.py` to regenerate them.
3. Keep each rule short, specific and checkable. "Write clean code" doesn't help an agent; "check `context.mounted` after `await` before using `context`" does.
4. If a rule changes how code should look, update `example_app/` so it still follows the rules, and make sure its tests pass.

## Adding or changing a skill

A skill is a folder in `plugins/flutter/skills/<name>/` with a `SKILL.md`:

```markdown
---
name: <name, same as the folder>
description: What it does, then "Use when ..." so agents know when to load it.
---

# Steps the agent follows
```

- Lowercase, hyphenated names. Descriptions of 50–1,024 characters that say **when** to use the skill.
- Only portable frontmatter fields: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.
- Keep `SKILL.md` under 500 lines; put long reference material in another file in the same folder and link to it.
- Write steps the agent can act on and verify. End with what to report back to the user.
- Anything irreversible (publishing, uploading, signing, deleting) must stop and hand the command to the user.
- Add the skill to the table in `README.md` and the list in `rules/CLAUDE.md`, and bump `version` in `plugins/flutter/.claude-plugin/plugin.json`.

## Checks

```bash
python scripts/validate.py
python scripts/build_rules.py --check
cd example_app && dart format --set-exit-if-changed . && flutter analyze && flutter test
```

CI runs all of these, plus `claude plugin validate` on the marketplace and the plugin.

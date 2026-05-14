---
name: add-skill
description: Add a new player skill to Arcane Net — creates a SkillData resource, implementation scene, registers it with SkillManager, and runs --headless --import + GUT tests. Use when the user asks "add a skill", "create skill X", or describes a new ability to add to the level-up pool.
---

# add-skill

Follow `.claude/docs/dev-guide.md` → "How to Add a New Skill" exactly. Summary:

1. **Create SkillData** at `resources/skills/<id>.tres`. Required fields: `id` (`StringName`), `display_name`, `rarity`, `max_stacks`, `implementation_scene`. Optional: `evolves_into`, `conflicts_with`, `requires_skills`. Rarity weights live in `SkillManager` — don't invent new ones.
2. **Create implementation scene** at `scenes/skills/<Name>.tscn`. Root `Node` (or `Node3D` if spatial). Attach a script with `class_name`, `@export var data: SkillData`, public-method `##` docs.
3. **Register** the `.tres` in `SkillManager.skill_pool` (Inspector or test code).
4. **Validate**:
   ```bash
   "$GODOT" --path . --headless --import
   "$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/
   ```
5. **Playtest** Main.tscn ≥ 30 s — kill enemies, level up, confirm the skill appears in UI and its effect works.

## Hard rules

- `id` must be a `StringName` (`&"my_skill"`), not a `String`.
- Scene path must live under `scenes/skills/` — no other directory.
- `##` docs on class, signals, public methods (REVIEW.md rule).
- After adding `class_name`: `--headless --import` BEFORE tests, or GUT will report `Could not find type`.
- No commit until `REVIEW.md` checklist passes.

---
name: add-spectator-action
description: Add a new SpectatorAction to EchoCompanion — creates a RefCounted action with can_execute/execute, inserts it in the priority list, extends the context dict if needed. Use when the user asks for a new Echo ability, AI companion behaviour, or extending the spectator-mode action set.
---

# add-spectator-action

Follow `.claude/docs/spectator_mode.md` → "Adding a New SpectatorAction" exactly.

1. **Create action** at `scripts/spectator/actions/<Name>Action.gd`:
   ```gdscript
   ## Brief one-line role. When it fires, what it does.
   class_name MyAction
   extends SpectatorAction

   func _init() -> void:
       action_name = &"my_action"
       mana_cost = 50.0

   func can_execute(ctx: Dictionary) -> bool:
       return ctx.get("some_key", false)

   func execute(ctx: Dictionary) -> void:
       pass
   ```
2. **Insert in priority** in `EchoCompanion._ready()`. Array order = priority — first match wins.
3. **Extend context** in `EchoCompanion._build_context()` ONLY if the action needs a new key. Document the key in `.claude/docs/spectator_mode.md` context table.
4. **Validate**:
   ```bash
   "$GODOT" --path . --headless --import
   "$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/
   ```
5. **Playtest** Main.tscn ≥ 30 s — kill the player, watch Echo, confirm the action fires when its condition holds.

## Hard rules

- `extends SpectatorAction` (`RefCounted`), never `Node`. No scene needed.
- `action_name` is `StringName` (`&"..."`), not `String`.
- `mana_cost` must be set in `_init()`, not at the call site.
- `can_execute()` is pure — read ctx, return bool, no side effects.
- `execute()` is allowed side effects but must not assume mana state — mana is already deducted by `EchoCompanion._perform()`.
- `##` docs on class + public methods.

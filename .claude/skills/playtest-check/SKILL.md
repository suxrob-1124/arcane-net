---
name: playtest-check
description: Run the 30-second Main.tscn playtest ritual required by CLAUDE.md for gameplay changes (combat, AI, UI, scenes, game feel). Reminds the user to run Godot, what to verify, and how to read the debugger output. Use after combat/spectator/UI changes or before opening a PR that touches gameplay.
---

# playtest-check

Unit tests do not cover game feel, camera smoothing, dash timing, or live AutoLoad signal integration. A 30-second playtest of `Main.tscn` is **mandatory** before any PR touching gameplay (per `CLAUDE.md` → Testing Rules).

## Run it

Playtest is interactive — ask the user to run it themselves in their shell:

```
! "$GODOT" --path /Users/sukhrobshukurov/Dev/godot-test-game
```

(The `!` prefix lets the output land back in this session.)

## What to verify in the 30 s

- **Zero ERROR logs** in the debugger output. Warnings are tolerated only from engine / addons (e.g. GUT). Any warning from `res://scripts/**` is a regression.
- **Golden path**: move (WASD), dash (Space), attack (LMB / Enter). If touched, exercise spectator switch (Tab).
- **The specific feature**: trigger it. For combat → kill enemies, level up, check skill effect. For spectator → die, watch Echo.
- **No frame stalls / Hitstop stuck on**.

## Report

After the user pastes output, summarise: "Clean / ERRORs found / warnings from <file>". If unclean, do **not** approve commit — return to the change.

## Hard rule

If the change touches `scripts/combat/`, `scripts/spectator/`, `scripts/ui/`, scenes, or AI, **no PR without playtest**.

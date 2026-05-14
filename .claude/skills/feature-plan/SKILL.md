---
name: feature-plan
description: Draft a feature plan for Arcane Net using the .claude/templates/feature_plan.md template. Fills every section (Context & Goal, Architecture & Node Tree, EventBus Integration, GUT Tests, Implementation Checklist). Use when the user asks to plan a feature, design a new system, or wants a structured implementation outline before coding.
---

# feature-plan

Always base feature plans on `.claude/templates/feature_plan.md`. Required by project memory `feedback_planner_template.md` and enforced by hook `.claude/hooks/validate_plan_file.sh`.

## Pre-flight (mandatory)

Before writing the plan, read in this order:

1. `.claude/templates/feature_plan.md` — the structure you will follow verbatim.
2. `REVIEW.md` — the checklist your plan must allow the executor to satisfy.
3. The relevant `.claude/docs/*.md` files for the subsystems your feature touches:
   - `architecture.md` — AutoLoads, composition, StringName rules, directory map.
   - `combat_and_progression.md` — if touching `scripts/combat/` or `scripts/progression/`.
   - `spectator_mode.md` — if touching `scripts/spectator/` or EchoCompanion.
   - `dev-guide.md` — if adding skills, enemies, or GUT tests.
4. `.claude/memory/MEMORY.md` — project memory index (not auto-loaded by the harness).

Skipping pre-flight is the most common cause of plans that miss REVIEW gates.

## Workflow

1. **Slug** the feature: short kebab-case, e.g. `shield-action`, `boss-architect`.
2. **Write the plan** to `.claude/plans/feat-<slug>.md` (project-level — do NOT write to user-level `/Users/.../.claude/plans/`).
3. **Fill every section** of the template. Mark inapplicable sections `N/A` explicitly — do not delete them, the hook will block the write otherwise.
4. **Hand the user the plan-file path**. Do not start coding until the plan is reviewed.

## Section rules

- **Context & Goal** — problem, motivation, success criteria, out-of-scope. No vague "make it better".
- **Architecture & Node Tree** — every new script/scene/Resource listed under GDD 2.1 directory map (`scripts/{core,combat,progression,dungeon_gen,spectator,network,ui,data}/`, `scenes/{main,hub,dungeon,ui}/`). **Forbidden dirs**: `shaders/`, `entities/`, `systems/`. Mark facade vs components; cross-component calls go through EventBus or facade.
- **AutoLoad changes** — only if globally needed; reason required.
- **EventBus Integration** — fully typed signal signatures. Add new signals to the table even if they live in EventBus.gd. Document who emits, who listens, and when.
- **GUT Tests** — logic only (math, FSM, signal order). Never timers/visuals/AutoLoad-integration — those go under "Not covered (playtest only)".
- **Implementation Checklist** — every new script gets `##` docs (class, signals, public methods). Include explicit items for `--headless --import`, full GUT suite, REVIEW.md walkthrough, and `/playtest-check` if the feature touches gameplay.

## Anti-patterns (will be flagged)

- Writing the plan to `/Users/<user>/.claude/plans/` instead of the project-local `.claude/plans/`.
- Custom section headings instead of the template's headings — hook blocks the write.
- Mixing implementation steps into Context & Goal (those belong in the Implementation Checklist).
- Omitting `## EventBus Integration` because "no new signals" — keep the heading and write `N/A`, listing relevant existing signals if any.

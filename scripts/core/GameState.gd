## Global game-mode state. AutoLoad singleton.
## Holds the current Mode, a reference to the active scene, and the player count.
## Write `current_mode` only from scene-transition code; everything else is read-only consumer.
extends Node

## High-level game mode. Drives input routing, UI visibility, and Echo activity.
enum Mode { HUB, DUNGEON, SPECTATOR }

## Currently active mode. Other systems read this; never write it from gameplay code.
var current_mode: Mode = Mode.HUB
## Reference to the root node of the currently loaded scene (dungeon, hub, etc.).
var current_scene: Node = null
## Number of human players in the run; used by SpectatorState to gate Echo behaviour.
var player_count: int = 1

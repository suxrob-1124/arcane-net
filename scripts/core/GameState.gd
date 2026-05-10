extends Node

enum Mode { HUB, DUNGEON, SPECTATOR }

var current_mode: Mode = Mode.HUB
var current_scene: Node = null
var player_count: int = 1

extends Node

# Persists player state across room scene transitions
var player_health: int = 100
var player_cores: Array = [0, 0, 0]  # CoreType.NONE = 0
var exit_direction: String = ""  # "north" | "south" | "east" | "west"

# Room rotation — Ambush room is always the 2nd room, then every 3rd after
var room_counter: int = 0

const ROOM_ROTATION = [
	"res://scenes/dungeon/AmbushRoom.tscn",  # 2nd room (always)
	"res://scenes/Main.tscn",
	"res://scenes/Main.tscn",
]

func next_room_scene() -> String:
	var scene: String = ROOM_ROTATION[room_counter % ROOM_ROTATION.size()]
	room_counter += 1
	return scene

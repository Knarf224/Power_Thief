extends Node2D

enum RoomState { IDLE, FIGHTING, CORES_ACTIVE, TRANSITION_READY }

const ROOM_W = 1920
const ROOM_H = 1080
const WALL_T = 32
const EXIT_THRESHOLD = 60
const OPENING = 120  # Width/height of doorway openings into each corner room

# 4 corner rooms — bounds match actual walkable area (from outer wall edge)
const ROOMS = {
	"nw": Rect2(0,    0,   760, 360),
	"ne": Rect2(1160, 0,   760, 360),
	"sw": Rect2(0,    720, 760, 360),
	"se": Rect2(1160, 720, 760, 360),
}

# Center corridor trigger zone — small zone at the exact center intersection
const CENTER_TRIGGER = Rect2(880, 460, 160, 160)

# Inner corners of each room (closest to the corridor) — enemies stuck here get teleported
const TELEPORT_ZONES: Array[Rect2] = [
	Rect2(620, 220, 140, 140),  # NW room — SE corner
	Rect2(1160, 220, 140, 140), # NE room — SW corner
	Rect2(620, 720, 140, 140),  # SW room — NE corner
	Rect2(1160, 720, 140, 140), # SE room — NW corner
]

# Ghost / Assassin / BombBeetle appear 3x more than other enemy types
const ENEMY_POOL = [
	"res://scenes/enemies/Ghost.tscn",
	"res://scenes/enemies/Ghost.tscn",
	"res://scenes/enemies/Ghost.tscn",
	"res://scenes/enemies/Assassin.tscn",
	"res://scenes/enemies/Assassin.tscn",
	"res://scenes/enemies/Assassin.tscn",
	"res://scenes/enemies/BombBeetle.tscn",
	"res://scenes/enemies/BombBeetle.tscn",
	"res://scenes/enemies/BombBeetle.tscn",
	"res://scenes/enemies/FireMage.tscn",
	"res://scenes/enemies/Slime.tscn",
	"res://scenes/enemies/IceWitch.tscn",
	"res://scenes/enemies/LightningSprite.tscn",
	"res://scenes/enemies/Necromancer.tscn",
]

const SPAWN_COUNT = 3  # Enemies per room

var _state := RoomState.IDLE
var _triggered: Dictionary = {}
var _any_triggered := false
var _outer_walls: Array = []
var _triggers_armed := false
var _arm_timer := 0.0
const ARM_DELAY = 0.3
var _cores_activated := false  # Ensures one full frame passes before checking for empty cores

@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD

func _ready() -> void:
	_create_floor()
	_create_corner_floors()
	_create_outer_walls()
	_create_inner_walls()
	_setup_triggers()
	player.health_changed.connect(hud.update_health)
	player.cores_changed.connect(hud.update_cores)
	player.died.connect(_on_player_died)
	hud.update_health(player.health, player.MAX_HEALTH)
	hud.update_cores(player.core_slots)
	# Start player in the corridor arm opposite to where they exited
	# Default lands in south arm — safely outside all trigger zones
	match GameState.exit_direction:
		"west":  player.position = Vector2(1780, 540)
		"east":  player.position = Vector2(140,  540)
		"north": player.position = Vector2(960,  980)
		"south": player.position = Vector2(960,  100)
		_:       player.position = Vector2(960,  900)

func _process(delta: float) -> void:
	if not _triggers_armed:
		_arm_timer += delta
		if _arm_timer >= ARM_DELAY:
			_triggers_armed = true

	match _state:
		RoomState.FIGHTING:
			if _any_triggered and get_tree().get_nodes_in_group("enemy").is_empty():
				_state = RoomState.CORES_ACTIVE
		RoomState.CORES_ACTIVE:
			if not _cores_activated:
				_activate_cores()
				_cores_activated = true
			elif get_tree().get_nodes_in_group("core_pickup").is_empty():
				_state = RoomState.TRANSITION_READY
				_open_exits()
		RoomState.TRANSITION_READY:
			var pos := player.global_position
			if pos.x < -EXIT_THRESHOLD:
				_load_next_room("west")
			elif pos.x > ROOM_W + EXIT_THRESHOLD:
				_load_next_room("east")
			elif pos.y < -EXIT_THRESHOLD:
				_load_next_room("north")
			elif pos.y > ROOM_H + EXIT_THRESHOLD:
				_load_next_room("south")

# --- Trigger logic ---

func _on_room_entered(body: Node2D, room_name: String) -> void:
	if not _triggers_armed or body != player:
		return
	if _triggered.get(room_name, false):
		return
	_trigger_room(room_name)
	# Also trigger one random other untriggered room
	var others: Array = []
	for r in ROOMS:
		if r != room_name and not _triggered.get(r, false):
			others.append(r)
	if not others.is_empty():
		others.shuffle()
		_trigger_room(others[0])

func _on_center_entered(body: Node2D) -> void:
	if not _triggers_armed or body != player:
		return
	# Crossing the center triggers ALL remaining rooms at once
	for room_name in ROOMS:
		if not _triggered.get(room_name, false):
			_trigger_room(room_name)

func _trigger_room(room_name: String) -> void:
	_triggered[room_name] = true
	_any_triggered = true
	_state = RoomState.FIGHTING
	_spawn_in_room(room_name)

func _spawn_in_room(room_name: String) -> void:
	var rect: Rect2 = ROOMS[room_name]
	var pool := ENEMY_POOL.duplicate()
	pool.shuffle()
	var padding := 60.0
	for i in SPAWN_COUNT:
		var enemy = load(pool[i % pool.size()]).instantiate()
		add_child(enemy)
		enemy.teleport_when_stuck = true
		enemy.teleport_target = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)
		enemy.teleport_zones = TELEPORT_ZONES
		enemy.global_position = Vector2(
			randf_range(rect.position.x + padding, rect.end.x - padding),
			randf_range(rect.position.y + padding, rect.end.y - padding)
		)

# --- Trigger setup ---

func _setup_triggers() -> void:
	# One trigger zone per corner room
	for room_name in ROOMS:
		var rect: Rect2 = ROOMS[room_name]
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		area.add_child(shape)
		area.position = rect.get_center()
		area.body_entered.connect(_on_room_entered.bind(room_name))
		add_child(area)

	# Center trigger — crossing this spawns all rooms
	var center_area := Area2D.new()
	var center_shape := CollisionShape2D.new()
	var center_box := RectangleShape2D.new()
	center_box.size = CENTER_TRIGGER.size
	center_shape.shape = center_box
	center_area.add_child(center_shape)
	center_area.position = CENTER_TRIGGER.get_center()
	center_area.body_entered.connect(_on_center_entered)
	add_child(center_area)

# --- Room helpers ---

func _activate_cores() -> void:
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		pickup.activate()

func _open_exits() -> void:
	for wall in _outer_walls:
		wall.queue_free()
	_outer_walls.clear()
	hud.show_transition_prompt()

func _load_next_room(direction: String) -> void:
	GameState.player_health = player.health
	GameState.player_cores = player.core_slots.duplicate()
	GameState.exit_direction = direction
	get_tree().change_scene_to_file(GameState.next_room_scene())

func _on_player_died() -> void:
	hud.show_you_died()

# --- Room construction ---

func _create_floor() -> void:
	var floor_vis := Polygon2D.new()
	floor_vis.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(ROOM_W, 0),
		Vector2(ROOM_W, ROOM_H), Vector2(0, ROOM_H)
	])
	floor_vis.color = Color(0.10, 0.10, 0.16)
	add_child(floor_vis)
	move_child(floor_vis, 0)

func _create_corner_floors() -> void:
	for rect in TELEPORT_ZONES:
		var vis := Polygon2D.new()
		vis.polygon = PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		])
		vis.color = Color(0.18, 0.08, 0.12)  # Dark red-purple — teleport zone tint
		add_child(vis)
		move_child(vis, 1)  # Layer above base floor, below walls

func _create_outer_walls() -> void:
	_make_wall(Vector2(ROOM_W / 2.0, -WALL_T / 2.0),         Vector2(ROOM_W + WALL_T * 2, WALL_T), true)
	_make_wall(Vector2(ROOM_W / 2.0, ROOM_H + WALL_T / 2.0), Vector2(ROOM_W + WALL_T * 2, WALL_T), true)
	_make_wall(Vector2(-WALL_T / 2.0, ROOM_H / 2.0),         Vector2(WALL_T, ROOM_H), true)
	_make_wall(Vector2(ROOM_W + WALL_T / 2.0, ROOM_H / 2.0), Vector2(WALL_T, ROOM_H), true)

func _create_inner_walls() -> void:
	# Each corner room has 2 inner walls facing the corridor, each with a 120px doorway.
	# Corner fillers close the junction gap where the two wall segments meet.

	# --- NW room: east wall (x=760, y=0-360) opening y=120-240 ---
	_make_wall_seg(744, 0,   776, 120)
	_make_wall_seg(744, 240, 776, 360)
	# --- NW room: south wall (y=360, x=0-760) opening x=320-440 ---
	_make_wall_seg(0,   344, 320, 376)
	_make_wall_seg(440, 344, 760, 376)
	_make_wall_seg(744, 344, 776, 376)  # corner filler

	# --- NE room: west wall (x=1160, y=0-360) opening y=120-240 ---
	_make_wall_seg(1144, 0,   1176, 120)
	_make_wall_seg(1144, 240, 1176, 360)
	# --- NE room: south wall (y=360, x=1160-1920) opening x=1480-1600 ---
	_make_wall_seg(1160, 344, 1480, 376)
	_make_wall_seg(1600, 344, 1920, 376)
	_make_wall_seg(1144, 344, 1176, 376)  # corner filler

	# --- SW room: east wall (x=760, y=720-1080) opening y=840-960 ---
	_make_wall_seg(744, 720, 776, 840)
	_make_wall_seg(744, 960, 776, 1080)
	# --- SW room: north wall (y=720, x=0-760) opening x=320-440 ---
	_make_wall_seg(0,   704, 320, 736)
	_make_wall_seg(440, 704, 760, 736)
	_make_wall_seg(744, 704, 776, 736)  # corner filler

	# --- SE room: west wall (x=1160, y=720-1080) opening y=840-960 ---
	_make_wall_seg(1144, 720, 1176, 840)
	_make_wall_seg(1144, 960, 1176, 1080)
	# --- SE room: north wall (y=720, x=1160-1920) opening x=1480-1600 ---
	_make_wall_seg(1160, 704, 1480, 736)
	_make_wall_seg(1600, 704, 1920, 736)
	_make_wall_seg(1144, 704, 1176, 736)  # corner filler

func _make_wall_seg(x1: float, y1: float, x2: float, y2: float) -> void:
	_make_wall(Vector2((x1 + x2) / 2.0, (y1 + y2) / 2.0), Vector2(x2 - x1, y2 - y1), false)

func _make_wall(pos: Vector2, size: Vector2, is_outer: bool) -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	var vis := Polygon2D.new()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw,   hh), Vector2(-hw,  hh)
	])
	vis.color = Color(0.28, 0.28, 0.35)
	wall.add_child(vis)
	wall.position = pos
	if is_outer:
		_outer_walls.append(wall)
	add_child(wall)

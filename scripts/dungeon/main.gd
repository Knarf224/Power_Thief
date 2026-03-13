extends Node2D

enum RoomState { FIGHTING, CORES_ACTIVE, TRANSITION_READY }

const ROOM_W = 960
const ROOM_H = 540
const WALL_T = 32
const EXIT_THRESHOLD = 60

const ENEMY_SCENES = [
	"res://scenes/enemies/FireMage.tscn",
	"res://scenes/enemies/Assassin.tscn",
	"res://scenes/enemies/Slime.tscn",
	"res://scenes/enemies/Ghost.tscn",
	"res://scenes/enemies/BombBeetle.tscn",
	"res://scenes/enemies/IceWitch.tscn",
	"res://scenes/enemies/LightningSprite.tscn",
	"res://scenes/enemies/StoneGolem.tscn",
	"res://scenes/enemies/Necromancer.tscn",
	"res://scenes/enemies/PoisonToad.tscn",
]

const SPAWN_POSITIONS = [
	Vector2(150, 120),
	Vector2(800, 410),
]

var _state := RoomState.FIGHTING
var _enemies_spawned := false
var _walls: Array = []

@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD

func _ready() -> void:
	_create_floor()
	_create_walls()
	_spawn_enemies()
	player.health_changed.connect(hud.update_health)
	player.cores_changed.connect(hud.update_cores)
	player.died.connect(_on_player_died)
	hud.update_health(player.health, player.MAX_HEALTH)
	hud.update_cores(player.core_slots)
	# Position player on the opposite side from where they exited last room
	match GameState.exit_direction:
		"west":  player.position = Vector2(ROOM_W - 80, ROOM_H / 2.0)
		"east":  player.position = Vector2(80,          ROOM_H / 2.0)
		"north": player.position = Vector2(ROOM_W / 2.0, ROOM_H - 80)
		"south": player.position = Vector2(ROOM_W / 2.0, 80)
		_:       player.position = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)

func _process(_delta: float) -> void:
	match _state:
		RoomState.FIGHTING:
			if _enemies_spawned and get_tree().get_nodes_in_group("enemy").is_empty():
				_state = RoomState.CORES_ACTIVE
				_activate_cores()

		RoomState.CORES_ACTIVE:
			if get_tree().get_nodes_in_group("core_pickup").is_empty():
				_state = RoomState.TRANSITION_READY
				_open_exits()

		RoomState.TRANSITION_READY:
			var pos: Vector2 = player.global_position
			if pos.x < -EXIT_THRESHOLD:
				_load_next_room("west")
			elif pos.x > ROOM_W + EXIT_THRESHOLD:
				_load_next_room("east")
			elif pos.y < -EXIT_THRESHOLD:
				_load_next_room("north")
			elif pos.y > ROOM_H + EXIT_THRESHOLD:
				_load_next_room("south")

func _spawn_enemies() -> void:
	var types = ENEMY_SCENES.duplicate()
	types.shuffle()
	for i in 2:
		var enemy = load(types[i]).instantiate()
		add_child(enemy)
		enemy.global_position = SPAWN_POSITIONS[i]
	_enemies_spawned = true

func _activate_cores() -> void:
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		pickup.activate()

func _open_exits() -> void:
	for wall in _walls:
		wall.queue_free()
	_walls.clear()
	hud.show_transition_prompt()

func _load_next_room(direction: String) -> void:
	GameState.player_health = player.health
	GameState.player_cores = player.core_slots.duplicate()
	GameState.exit_direction = direction
	get_tree().change_scene_to_file(GameState.next_room_scene())

func _on_player_died() -> void:
	hud.show_you_died()

func _create_floor() -> void:
	var floor_vis = Polygon2D.new()
	floor_vis.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(ROOM_W, 0),
		Vector2(ROOM_W, ROOM_H), Vector2(0, ROOM_H)
	])
	floor_vis.color = Color(0.12, 0.12, 0.18)
	add_child(floor_vis)
	move_child(floor_vis, 0)

func _create_walls() -> void:
	_make_wall(Vector2(ROOM_W / 2.0, -WALL_T / 2.0),         Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(ROOM_W / 2.0, ROOM_H + WALL_T / 2.0), Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(-WALL_T / 2.0, ROOM_H / 2.0),         Vector2(WALL_T, ROOM_H))
	_make_wall(Vector2(ROOM_W + WALL_T / 2.0, ROOM_H / 2.0), Vector2(WALL_T, ROOM_H))

func _make_wall(pos: Vector2, size: Vector2) -> void:
	var wall = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	var vis = Polygon2D.new()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh),   Vector2(-hw, hh)
	])
	vis.color = Color(0.28, 0.28, 0.35)
	wall.add_child(vis)
	wall.position = pos
	_walls.append(wall)
	add_child(wall)

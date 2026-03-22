extends Node2D

enum RoomState { FIGHTING, CORES_ACTIVE, TRANSITION_READY }

const ROOM_W = 1280
const ROOM_H = 720
const WALL_T = 32
const EXIT_THRESHOLD = 60

# How far from the wall enemies spawn along each border edge
const SPAWN_INSET  = 80.0
# Minimum distance from corners along the perpendicular axis
const SPAWN_MARGIN = 100.0

# Wave spawn settings (non-boss rooms only)
const WAVE_GRACE = 1.5   # grace period before first wave
const WAVE_SIZE  = 6     # max enemies per wave
const WAVE_PAUSE = 3.0   # seconds between waves

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


var _state           := RoomState.FIGHTING
var _enemies_spawned := false
var _walls:   Array  = []
var _blackout: Node

# Spawn state
var _spawn_timer    := 0.0
var _spawn_pending  := false
var _spawn_count    := 0
var _spawned_so_far := 0
var _wave_index     := 0
var _spawn_types: Array = []
var _boss_level     := false

# Which border sides are eligible for this room entry (excludes the player's side)
var _eligible_sides: Array = []

@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD


func _ready() -> void:
	_create_floor()
	_create_walls()

	player.health_changed.connect(hud.update_health)
	player.cores_changed.connect(hud.update_cores)
	player.stamina_changed.connect(hud.update_stamina)
	player.died.connect(_on_player_died)
	hud.update_health(player.health, player.MAX_HEALTH)
	hud.update_cores(player.core_slots)
	hud.update_stamina(player.stamina, player.MAX_STAMINA)
	MusicManager.on_room_entered(GameState.room_counter)
	if GameState.room_counter == 0:
		Tracker.on_run_started()

	# Position player on the opposite side from where they exited last room
	match GameState.exit_direction:
		"west":  player.position = Vector2(ROOM_W - 80, ROOM_H / 2.0)
		"east":  player.position = Vector2(80,           ROOM_H / 2.0)
		"north": player.position = Vector2(ROOM_W / 2.0, ROOM_H - 80)
		"south": player.position = Vector2(ROOM_W / 2.0, 80)
		_:       player.position = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)

	# Build eligible spawn sides — all four borders except the one the player entered from
	var player_side := _entry_side(GameState.exit_direction)
	_eligible_sides = ["north", "south", "west", "east"]
	if player_side != "":
		_eligible_sides.erase(player_side)

	# Prepare delayed spawn
	var types := ENEMY_SCENES.duplicate()
	types.shuffle()
	_spawn_types  = types
	_spawn_pending = true

	_boss_level = GameState.is_boss_level()
	if _boss_level:
		_spawn_count = GameState.get_boss_companion_count()
		_spawn_boss()
	else:
		_spawn_count = GameState.get_enemy_count(2)

	var BlackoutClass = load("res://scripts/dungeon/blackout_overlay.gd")
	if BlackoutClass:
		_blackout = BlackoutClass.new()
		add_child(_blackout)


func _process(delta: float) -> void:
	if _spawn_pending:
		_spawn_timer += delta
		if _boss_level:
			# Boss rooms: spawn all companions at once after grace period
			if _spawn_timer >= WAVE_GRACE:
				_spawn_pending = false
				_do_spawn_all()
		else:
			# Normal rooms: wave system — first wave after grace, then every WAVE_PAUSE
			var threshold := WAVE_GRACE if _wave_index == 0 else WAVE_PAUSE
			if _spawn_timer >= threshold:
				_spawn_timer = 0.0
				_do_spawn_wave()

	match _state:
		RoomState.FIGHTING:
			if _enemies_spawned and get_tree().get_nodes_in_group("enemy").is_empty():
				if _blackout:
				_blackout.deactivate()
				if GameState.boss_defeated_this_level and GameState.is_boss_level():
					_open_exits()
					GameState.open_pending_perk_select()
					_state = RoomState.TRANSITION_READY
				else:
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


# Returns which side of the new room the player enters from
# (opposite of the direction they exited the previous room)
func _entry_side(exit_dir: String) -> String:
	match exit_dir:
		"west":  return "east"   # exited west → enters from east side
		"east":  return "west"
		"north": return "south"
		"south": return "north"
	return ""  # default / center start — no side to exclude


func _border_position(side: String) -> Vector2:
	match side:
		"north": return Vector2(randf_range(SPAWN_MARGIN, ROOM_W - SPAWN_MARGIN), SPAWN_INSET)
		"south": return Vector2(randf_range(SPAWN_MARGIN, ROOM_W - SPAWN_MARGIN), ROOM_H - SPAWN_INSET)
		"west":  return Vector2(SPAWN_INSET, randf_range(SPAWN_MARGIN, ROOM_H - SPAWN_MARGIN))
		"east":  return Vector2(ROOM_W - SPAWN_INSET, randf_range(SPAWN_MARGIN, ROOM_H - SPAWN_MARGIN))
	# Fallback: random interior position (should never reach here)
	return Vector2(randf_range(100, ROOM_W - 100), randf_range(100, ROOM_H - 100))


# Boss rooms: spawn all companions at once (no waves)
func _do_spawn_all() -> void:
	var companion_scene := ""
	var boss_node = get_tree().get_first_node_in_group("boss")
	if boss_node and "companion_scene" in boss_node:
		companion_scene = boss_node.companion_scene
	for i in _spawn_count:
		var scene_path := companion_scene if companion_scene != "" else _spawn_types[i % _spawn_types.size()]
		var enemy = load(scene_path).instantiate()
		add_child(enemy)
		enemy.global_position = _border_position(_eligible_sides[randi() % _eligible_sides.size()])
	_enemies_spawned = true


# Normal rooms: spawn one wave of up to WAVE_SIZE enemies
func _do_spawn_wave() -> void:
	var end := mini(_spawned_so_far + WAVE_SIZE, _spawn_count)
	for i in range(_spawned_so_far, end):
		var enemy = load(_spawn_types[i % _spawn_types.size()]).instantiate()
		add_child(enemy)
		enemy.global_position = _border_position(_eligible_sides[randi() % _eligible_sides.size()])
	_spawned_so_far = end
	_wave_index += 1
	if _spawned_so_far >= _spawn_count:
		_spawn_pending = false
		_enemies_spawned = true

func _spawn_boss() -> void:
	var boss = load(GameState.get_boss_scene()).instantiate()
	add_child(boss)
	# Place boss on the far side of the room from the player's entry point
	match GameState.exit_direction:
		"west":  boss.global_position = Vector2(120,           ROOM_H / 2.0)
		"east":  boss.global_position = Vector2(ROOM_W - 120,  ROOM_H / 2.0)
		"north": boss.global_position = Vector2(ROOM_W / 2.0,  120)
		"south": boss.global_position = Vector2(ROOM_W / 2.0,  ROOM_H - 120)
		_:       boss.global_position = Vector2(ROOM_W / 2.0,  ROOM_H / 2.0)


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
	GameState.player_cores  = player.core_slots.duplicate()
	GameState.exit_direction = direction
	get_tree().change_scene_to_file(GameState.next_room_scene())


func _on_player_died() -> void:
	Tracker.on_player_died()
	hud.show_you_died()


func _create_floor() -> void:
	var floor_vis := Polygon2D.new()
	floor_vis.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(ROOM_W, 0),
		Vector2(ROOM_W, ROOM_H), Vector2(0, ROOM_H)
	])
	floor_vis.color = Color(0.20, 0.20, 0.30)
	add_child(floor_vis)
	move_child(floor_vis, 0)


func _create_walls() -> void:
	_make_wall(Vector2(ROOM_W / 2.0, -WALL_T / 2.0),         Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(ROOM_W / 2.0, ROOM_H + WALL_T / 2.0), Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(-WALL_T / 2.0, ROOM_H / 2.0),         Vector2(WALL_T, ROOM_H))
	_make_wall(Vector2(ROOM_W + WALL_T / 2.0, ROOM_H / 2.0), Vector2(WALL_T, ROOM_H))


func _make_wall(pos: Vector2, size: Vector2) -> void:
	var wall  := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size  = size
	shape.shape = rect
	wall.add_child(shape)
	var vis := Polygon2D.new()
	var hw  := size.x / 2.0
	var hh  := size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw,   hh), Vector2(-hw,  hh)
	])
	vis.color = Color(0.28, 0.28, 0.35)
	wall.add_child(vis)
	wall.position = pos
	_walls.append(wall)
	add_child(wall)

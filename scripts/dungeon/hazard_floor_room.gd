extends Node2D

enum RoomState { FIGHTING, CORES_ACTIVE, TRANSITION_READY }
enum TileState { SAFE, WARNING, DANGER, COOLDOWN }

const ROOM_W = 1536
const ROOM_H = 864
const WALL_T = 32
const EXIT_THRESHOLD = 60

# 16x9 grid — each tile is 120x120px
const GRID_COLS = 16
const GRID_ROWS = 9
const TILE_W: float = ROOM_W / float(GRID_COLS)  # 120
const TILE_H: float = ROOM_H / float(GRID_ROWS)  # 120

# Tile visuals
const GROUT_COLOR    := Color(0.05, 0.05, 0.08)   # gap between tiles
const SAFE_COLOR     := Color(0.10, 0.10, 0.16)   # normal dark floor
const WARNING_COLOR  := Color(0.55, 0.08, 0.08)   # deep crimson — "move now"
const DANGER_COLOR   := Color(0.90, 0.40, 0.05)   # bright orange — dealing damage
const COOLDOWN_COLOR := Color(0.25, 0.10, 0.10)   # dim reddish — brief safe window

# Timing constants
const DANGER_DURATION   := 2.5   # seconds a tile stays hot (was 1.5)
const COOLDOWN_DURATION := 0.3   # seconds before tile returns to safe
const DAMAGE_TICK       := 0.25  # how often damage is dealt while on a danger tile
const DAMAGE_PER_TICK   := 2     # HP lost per tick (= 8 DPS)

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

# Spread spawn positions across the 1920x1080 arena

var _state := RoomState.FIGHTING
var _enemies_spawned := false
var _outer_walls: Array = []
var _blackout: Node

# Tile state grid [col][row]
var _tiles: Array = []
var _tile_timers: Array = []

# Hazard timing — scaled in _ready() from GameState.room_counter
var _warning_duration  := 1.2  # how long WARNING phase lasts (shrinks over time)
var _tiles_per_wave    := 6    # tiles entering WARNING each interval (grows over time)
var _spawn_interval    := 0.4  # seconds between waves of new warning tiles
var _spawn_timer       := 0.0

# Damage tracking
var _damage_timer := 0.0

@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD


func _ready() -> void:
	_init_grid()
	_create_walls()
	_spawn_enemies()
	player.health_changed.connect(hud.update_health)
	player.cores_changed.connect(hud.update_cores)
	player.stamina_changed.connect(hud.update_stamina)
	player.died.connect(_on_player_died)
	hud.update_health(player.health, player.MAX_HEALTH)
	hud.update_cores(player.core_slots)
	hud.update_stamina(player.stamina, player.MAX_STAMINA)
	MusicManager.on_room_entered(GameState.room_counter)

	# Scale difficulty: more tiles enter WARNING and faster as rooms_cleared increases
	var rooms := GameState.room_counter
	_tiles_per_wave   = min(6 + rooms / 5, 12)
	_warning_duration = maxf(0.6, 1.2 - rooms * 0.02)

	match GameState.exit_direction:
		"west":  player.position = Vector2(ROOM_W - 120, ROOM_H / 2.0)
		"east":  player.position = Vector2(120,          ROOM_H / 2.0)
		"north": player.position = Vector2(ROOM_W / 2.0, ROOM_H - 120)
		"south": player.position = Vector2(ROOM_W / 2.0, 120)
		_:       player.position = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)
	_blackout = load("res://scripts/dungeon/blackout_overlay.gd").new()
	_blackout.activation_chance = 0.90
	add_child(_blackout)


func _process(delta: float) -> void:
	queue_redraw()  # smooth color lerp every frame

	_update_tiles(delta)

	match _state:
		RoomState.FIGHTING:
			_handle_floor_damage(delta)
			if _enemies_spawned and get_tree().get_nodes_in_group("enemy").is_empty():
				_blackout.deactivate()
				_clear_all_tiles()  # floor hazard stops once room is cleared
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
			var pos := player.global_position
			if pos.x < -EXIT_THRESHOLD:
				_load_next_room("west")
			elif pos.x > ROOM_W + EXIT_THRESHOLD:
				_load_next_room("east")
			elif pos.y < -EXIT_THRESHOLD:
				_load_next_room("north")
			elif pos.y > ROOM_H + EXIT_THRESHOLD:
				_load_next_room("south")


# --- Tile grid logic ---

func _init_grid() -> void:
	_tiles.resize(GRID_COLS)
	_tile_timers.resize(GRID_COLS)
	for col in GRID_COLS:
		_tiles[col] = []
		_tile_timers[col] = []
		_tiles[col].resize(GRID_ROWS)
		_tile_timers[col].resize(GRID_ROWS)
		for row in GRID_ROWS:
			_tiles[col][row] = TileState.SAFE
			_tile_timers[col][row] = 0.0


func _update_tiles(delta: float) -> void:
	# Advance each tile through its state machine
	for col in GRID_COLS:
		for row in GRID_ROWS:
			_tile_timers[col][row] += delta
			match _tiles[col][row]:
				TileState.WARNING:
					if _tile_timers[col][row] >= _warning_duration:
						_tiles[col][row] = TileState.DANGER
						_tile_timers[col][row] = 0.0
				TileState.DANGER:
					if _tile_timers[col][row] >= DANGER_DURATION:
						_tiles[col][row] = TileState.COOLDOWN
						_tile_timers[col][row] = 0.0
				TileState.COOLDOWN:
					if _tile_timers[col][row] >= COOLDOWN_DURATION:
						_tiles[col][row] = TileState.SAFE
						_tile_timers[col][row] = 0.0

	# Spawn new warning tiles on interval (only while fighting)
	if _state == RoomState.FIGHTING:
		_spawn_timer += delta
		if _spawn_timer >= _spawn_interval:
			_spawn_timer = 0.0
			_spawn_warning_tiles()


func _spawn_warning_tiles() -> void:
	var safe_tiles: Array = []
	for col in GRID_COLS:
		for row in GRID_ROWS:
			if _tiles[col][row] == TileState.SAFE:
				safe_tiles.append(Vector2i(col, row))
	safe_tiles.shuffle()
	var count := mini(_tiles_per_wave, safe_tiles.size())
	for i in count:
		var cell: Vector2i = safe_tiles[i]
		_tiles[cell.x][cell.y] = TileState.WARNING
		_tile_timers[cell.x][cell.y] = 0.0


func _clear_all_tiles() -> void:
	for col in GRID_COLS:
		for row in GRID_ROWS:
			_tiles[col][row] = TileState.SAFE
			_tile_timers[col][row] = 0.0


func _handle_floor_damage(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer < DAMAGE_TICK:
		return
	_damage_timer = 0.0
	var col := clampi(int(player.global_position.x / TILE_W), 0, GRID_COLS - 1)
	var row := clampi(int(player.global_position.y / TILE_H), 0, GRID_ROWS - 1)
	if _tiles[col][row] == TileState.DANGER:
		player.take_damage(DAMAGE_PER_TICK)


# --- Drawing ---

func _draw() -> void:
	# Dark grout between tiles
	draw_rect(Rect2(0, 0, ROOM_W, ROOM_H), GROUT_COLOR)

	for col in GRID_COLS:
		for row in GRID_ROWS:
			var color := _get_tile_color(col, row)
			# 1px gap on each edge creates visible grout lines
			var rect := Rect2(
				col * TILE_W + 1,
				row * TILE_H + 1,
				TILE_W - 2,
				TILE_H - 2
			)
			draw_rect(rect, color)


func _get_tile_color(col: int, row: int) -> Color:
	var t: float = _tile_timers[col][row]
	match _tiles[col][row]:
		TileState.WARNING:
			# Gradually shift from safe floor to crimson as the timer advances
			var progress := clampf(t / _warning_duration, 0.0, 1.0)
			return SAFE_COLOR.lerp(WARNING_COLOR, progress)
		TileState.DANGER:
			# Pulse between crimson and orange to draw the eye
			var pulse := (sin(t * 10.0) + 1.0) * 0.5
			return WARNING_COLOR.lerp(DANGER_COLOR, 0.5 + pulse * 0.5)
		TileState.COOLDOWN:
			# Fade back down to safe
			var progress := clampf(t / COOLDOWN_DURATION, 0.0, 1.0)
			return DANGER_COLOR.lerp(SAFE_COLOR, progress)
		_:  # SAFE
			return SAFE_COLOR


# --- Room helpers ---

func _spawn_enemies() -> void:
	if GameState.is_boss_level():
		_spawn_boss()

	var types  := ENEMY_SCENES.duplicate()
	types.shuffle()
	var count  := GameState.get_boss_companion_count() if GameState.is_boss_level() else GameState.get_enemy_count(2)
	for i in count:
		var enemy = load(types[i % types.size()]).instantiate()
		add_child(enemy)
		enemy.global_position = Vector2(
			randf_range(100, ROOM_W - 100),
			randf_range(100, ROOM_H - 100)
		)
	_enemies_spawned = true

func _spawn_boss() -> void:
	var boss = load(GameState.get_boss_scene()).instantiate()
	add_child(boss)
	match GameState.exit_direction:
		"west":  boss.global_position = Vector2(160,           ROOM_H / 2.0)
		"east":  boss.global_position = Vector2(ROOM_W - 160,  ROOM_H / 2.0)
		"north": boss.global_position = Vector2(ROOM_W / 2.0,  160)
		"south": boss.global_position = Vector2(ROOM_W / 2.0,  ROOM_H - 160)
		_:       boss.global_position = Vector2(ROOM_W / 2.0,  ROOM_H / 2.0)


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


# --- Wall construction ---

func _create_walls() -> void:
	_make_wall(Vector2(ROOM_W / 2.0, -WALL_T / 2.0),         Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(ROOM_W / 2.0, ROOM_H + WALL_T / 2.0), Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(-WALL_T / 2.0, ROOM_H / 2.0),         Vector2(WALL_T, ROOM_H))
	_make_wall(Vector2(ROOM_W + WALL_T / 2.0, ROOM_H / 2.0), Vector2(WALL_T, ROOM_H))


func _make_wall(pos: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	# Walls are invisible — the player just can't walk through them.
	# The floor tiles visually define the room boundary.
	wall.position = pos
	_outer_walls.append(wall)
	add_child(wall)

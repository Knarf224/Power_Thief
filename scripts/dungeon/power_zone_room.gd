extends Node2D

enum RoomState { FIGHTING, CORES_ACTIVE, TRANSITION_READY }

const ROOM_W = 1280
const ROOM_H = 1280
const CX = ROOM_W / 2.0   # 640 — room centre x
const CY = ROOM_H / 2.0   # 640 — room centre y
const WALL_T = 32
const EXIT_THRESHOLD = 60

# Zone colours — tinted lighter version of the base floor rather than a contrast colour.
# Active zone looks "lit from below" rather than jarring.
const INACTIVE_COLOR := Color(0.10, 0.10, 0.16)   # standard dark dungeon floor
const ACTIVE_COLOR   := Color(0.24, 0.22, 0.35)   # lighter purple-blue glow
const WARNING_COLOR  := Color(0.52, 0.48, 0.72)   # bright pulse — "zone switching"
const DIVIDER_COLOR  := Color(0.04, 0.04, 0.06)   # diagonal dividers (subtle)
const PILLAR_COLOR   := Color(0.20, 0.20, 0.28)   # decorative centre node

# Zone timing
const ZONE_DURATION_BASE := 5.0
const ZONE_DURATION_MIN  := 2.5
const ZONE_WARNING_DUR   := 0.6

# Wave system
const WAVE_COUNT_BASE  := 3
const WAVE_INTERVAL    := 8.0   # seconds between waves (was 12)

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

# Zones 0=North  1=East  2=South  3=West
# Four triangles formed by the two room diagonals, meeting at the centre.
# Built in _ready() since PackedVector2Array can't live in a const.
var _zone_polys: Array[PackedVector2Array] = []

# Spread spawn candidates per zone — points clearly inside each triangle
const ZONE_SPAWNS: Array = [
	# North triangle (top)
	[Vector2(640, 160), Vector2(360, 300), Vector2(920, 300)],
	# East triangle (right)
	[Vector2(1120, 640), Vector2(960, 360), Vector2(960, 920)],
	# South triangle (bottom)
	[Vector2(640, 1120), Vector2(360, 980), Vector2(920, 980)],
	# West triangle (left)
	[Vector2(160, 640), Vector2(320, 360), Vector2(320, 920)],
]

var _state       := RoomState.FIGHTING
var _outer_walls : Array = []
var _blackout    : Node

# Active zone state
var _active_zone   := 0
var _zone_timer    := 0.0
var _zone_duration := ZONE_DURATION_BASE
var _in_warning    := false
var _warn_timer    := 0.0

# Wave state
var _wave_count       := WAVE_COUNT_BASE
var _enemies_per_wave := 2   # computed in _ready() from global scale / wave count
var _waves_spawned    := 0
var _wave_timer       := 0.0
var _all_waves_done   := false
var _arm_timer        := 0.0
const ARM_DELAY       := 0.5

@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD


func _ready() -> void:
	_build_zone_polys()
	_create_walls()
	player.health_changed.connect(hud.update_health)
	player.cores_changed.connect(hud.update_cores)
	player.stamina_changed.connect(hud.update_stamina)
	player.died.connect(_on_player_died)
	hud.update_health(player.health, player.MAX_HEALTH)
	hud.update_cores(player.core_slots)
	hud.update_stamina(player.stamina, player.MAX_STAMINA)
	MusicManager.on_room_entered(GameState.room_counter)

	var rooms       := GameState.room_counter
	_zone_duration   = maxf(ZONE_DURATION_MIN, ZONE_DURATION_BASE - rooms * 0.08)
	_wave_count      = WAVE_COUNT_BASE + rooms / 6
	var total        := GameState.get_boss_companion_count() if GameState.is_boss_level() else GameState.get_enemy_count(2)
	_enemies_per_wave = maxi(1, total / _wave_count)
	_active_zone     = randi() % 4

	if GameState.is_boss_level():
		_spawn_boss()

	_blackout = load("res://scripts/dungeon/blackout_overlay.gd").new()
	_blackout.activation_chance = 0.90
	add_child(_blackout)

	match GameState.exit_direction:
		"west":  player.position = Vector2(ROOM_W - 120, CY)
		"east":  player.position = Vector2(120,          CY)
		"north": player.position = Vector2(CX,           ROOM_H - 120)
		"south": player.position = Vector2(CX,           120)
		_:       player.position = Vector2(CX,           CY)


func _build_zone_polys() -> void:
	var tl := Vector2(0,      0)
	var tr := Vector2(ROOM_W, 0)
	var bl := Vector2(0,      ROOM_H)
	var br := Vector2(ROOM_W, ROOM_H)
	var c  := Vector2(CX,     CY)
	# North — top edge to centre
	_zone_polys.append(PackedVector2Array([tl, tr, c]))
	# East  — right edge to centre
	_zone_polys.append(PackedVector2Array([tr, br, c]))
	# South — bottom edge to centre
	_zone_polys.append(PackedVector2Array([br, bl, c]))
	# West  — left edge to centre
	_zone_polys.append(PackedVector2Array([bl, tl, c]))


func _process(delta: float) -> void:
	queue_redraw()

	match _state:
		RoomState.FIGHTING:
			_update_arm(delta)
			_update_zone(delta)
			_update_waves(delta)
			player.can_attack = (_get_player_zone() == _active_zone)

			if _all_waves_done and get_tree().get_nodes_in_group("enemy").is_empty():
				player.can_attack = true
				_active_zone = -1
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
			var pos := player.global_position
			if pos.x < -EXIT_THRESHOLD:
				_load_next_room("west")
			elif pos.x > ROOM_W + EXIT_THRESHOLD:
				_load_next_room("east")
			elif pos.y < -EXIT_THRESHOLD:
				_load_next_room("north")
			elif pos.y > ROOM_H + EXIT_THRESHOLD:
				_load_next_room("south")


# --- Zone logic ---

func _update_arm(delta: float) -> void:
	if _arm_timer < ARM_DELAY:
		_arm_timer += delta


func _update_zone(delta: float) -> void:
	if _in_warning:
		_warn_timer += delta
		if _warn_timer >= ZONE_WARNING_DUR:
			_in_warning  = false
			_warn_timer  = 0.0
			_zone_timer  = 0.0
			var next := _active_zone
			while next == _active_zone:
				next = randi() % 4
			_active_zone = next
	else:
		_zone_timer += delta
		if _zone_timer >= _zone_duration:
			_in_warning = true
			_warn_timer = 0.0


func _get_player_zone() -> int:
	# Determine which triangle the player is in using the two room diagonals.
	# Diagonal 1 (TL→BR): above if py < px
	# Diagonal 2 (TR→BL): above if py < ROOM_H - px
	var px := player.global_position.x
	var py := player.global_position.y
	var above_tlbr := py < px
	var above_trbl := py < (ROOM_H - px)
	if above_tlbr and above_trbl:      return 0  # North
	if not above_tlbr and above_trbl:  return 3  # West
	if above_tlbr and not above_trbl:  return 1  # East
	return 2                                      # South


# --- Wave logic ---

func _update_waves(delta: float) -> void:
	if _all_waves_done or _arm_timer < ARM_DELAY:
		return
	if _waves_spawned == 0:
		_spawn_wave()
		return
	_wave_timer += delta
	if _wave_timer >= WAVE_INTERVAL:
		_wave_timer = 0.0
		_spawn_wave()


func _spawn_wave() -> void:
	_waves_spawned += 1
	if _waves_spawned >= _wave_count:
		_all_waves_done = true

	var types := ENEMY_SCENES.duplicate()
	types.shuffle()

	for i in _enemies_per_wave:
		var enemy = load(types[i % types.size()]).instantiate()
		add_child(enemy)
		# Pick a random zone and a random spawn point within it
		var zone    := randi() % 4
		var points  : Array = ZONE_SPAWNS[zone]
		var base    : Vector2 = points[randi() % points.size()]
		enemy.global_position = base + Vector2(
			randf_range(-40.0, 40.0),
			randf_range(-40.0, 40.0)
		)


# --- Drawing ---

func _draw() -> void:
	for z in 4:
		draw_colored_polygon(_zone_polys[z], _zone_color(z))

	# Diagonal dividers — the two lines that form the X
	draw_line(Vector2(0, 0),      Vector2(ROOM_W, ROOM_H), DIVIDER_COLOR, 5.0)
	draw_line(Vector2(ROOM_W, 0), Vector2(0, ROOM_H),      DIVIDER_COLOR, 5.0)

	# Decorative centre node where the diagonals cross
	var pr := 18.0
	draw_circle(Vector2(CX, CY), pr, PILLAR_COLOR)


func _zone_color(zone: int) -> Color:
	if zone != _active_zone:
		return INACTIVE_COLOR
	if _in_warning:
		var pulse := (sin(_warn_timer * 18.0) + 1.0) * 0.5
		return ACTIVE_COLOR.lerp(WARNING_COLOR, pulse)
	return ACTIVE_COLOR


# --- Room helpers ---

func _spawn_boss() -> void:
	var boss = load(GameState.get_boss_scene()).instantiate()
	add_child(boss)
	# Boss starts at room center — the iconic meeting point of all four zones
	boss.global_position = Vector2(CX, CY)

func _activate_cores() -> void:
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		pickup.activate()


func _open_exits() -> void:
	for wall in _outer_walls:
		wall.queue_free()
	_outer_walls.clear()
	hud.show_transition_prompt()


func _load_next_room(direction: String) -> void:
	GameState.player_health  = player.health
	GameState.player_cores   = player.core_slots.duplicate()
	GameState.exit_direction = direction
	player.can_attack = true
	get_tree().change_scene_to_file(GameState.next_room_scene())


func _on_player_died() -> void:
	player.can_attack = true
	hud.show_you_died()


# --- Wall construction ---

func _create_walls() -> void:
	_make_wall(Vector2(ROOM_W / 2.0, -WALL_T / 2.0),         Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(ROOM_W / 2.0, ROOM_H + WALL_T / 2.0), Vector2(ROOM_W + WALL_T * 2, WALL_T))
	_make_wall(Vector2(-WALL_T / 2.0, ROOM_H / 2.0),         Vector2(WALL_T, ROOM_H))
	_make_wall(Vector2(ROOM_W + WALL_T / 2.0, ROOM_H / 2.0), Vector2(WALL_T, ROOM_H))


func _make_wall(pos: Vector2, size: Vector2) -> void:
	var wall     := StaticBody2D.new()
	var shape    := CollisionShape2D.new()
	var rect     := RectangleShape2D.new()
	rect.size     = size
	shape.shape   = rect
	wall.add_child(shape)
	wall.position = pos
	_outer_walls.append(wall)
	add_child(wall)

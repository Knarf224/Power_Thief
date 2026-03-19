extends "res://scripts/enemies/bosses/boss_base.gd"

# The Storm Tyrant — aggressive orbiter firing homing lightning bolts.
# Persistent storm aura punishes standing close. Phase 2 expands aura and
# increases fire rate. Every 6s a chain bolt jumps through multiple enemies.

const MOVE_SPEED    := 110.0
const ORBIT_DIST    := 180.0
const SHOOT_CD_1    := 1.2
const SHOOT_CD_2    := 0.7     # phase 2 (below 40% HP)
const AURA_RADIUS_1 := 100.0
const AURA_RADIUS_2 := 160.0   # phase 2
const AURA_DAMAGE   := 6
const AURA_TICK     := 0.4
const CHAIN_CD      := 6.0
const CHAIN_DAMAGE  := 15
const CHAIN_JUMPS   := 3

@export var homing_bolt_scene: PackedScene

var _shoot_timer  := 0.0
var _aura_tick    := 0.0
var _chain_timer  := CHAIN_CD
var _orbit_angle  := 0.0

func _ready() -> void:
	boss_name       = "The Storm Tyrant"
	boss_perk_pool  = ["rapid_fire", "gravity_push", "death_burst"]
	companion_scene = "res://scenes/enemies/LightningSprite.tscn"
	super()
	max_health = 280
	health     = 280

func _ai_update(delta: float) -> void:
	# Orbit around the player at ORBIT_DIST
	_orbit_angle += delta * 1.2
	var orbit_pos := player.global_position + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * ORBIT_DIST
	var to_orbit  := orbit_pos - global_position
	velocity = to_orbit.normalized() * minf(MOVE_SPEED, to_orbit.length() / delta)

	# Storm aura ticking damage
	_aura_tick -= delta
	if _aura_tick <= 0.0:
		_aura_tick = AURA_TICK
		if _dist_to_player() <= _aura_radius():
			player.take_damage(AURA_DAMAGE)

	# Homing bolts
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_fire_bolt(false)
		_shoot_timer = _shoot_cd()

	# Chain bolt special
	_chain_timer -= delta
	if _chain_timer <= 0.0:
		_fire_bolt(true)
		_chain_timer = CHAIN_CD

func _fire_bolt(is_chain: bool) -> void:
	if homing_bolt_scene == null:
		return
	var bolt = homing_bolt_scene.instantiate()
	bolt.is_chain     = is_chain
	bolt.chain_damage = CHAIN_DAMAGE
	bolt.chain_jumps  = CHAIN_JUMPS
	get_parent().add_child(bolt)
	bolt.global_position = global_position
	bolt.direction = _dir_to_player()

func _draw() -> void:
	# Draw storm aura ring, then the health bar on top
	draw_arc(Vector2.ZERO, _aura_radius(), 0.0, TAU, 36,
			Color(1.0, 0.9, 0.1, 0.22), 2.0)
	super()

func _aura_radius() -> float:
	return AURA_RADIUS_2 if health < max_health * 0.4 else AURA_RADIUS_1

func _shoot_cd() -> float:
	return SHOOT_CD_2 if health < max_health * 0.4 else SHOOT_CD_1

extends "res://scripts/enemies/bosses/boss_base.gd"

# The Plague Lord — slow tank that denies floor space with persistent poison pools.
# Over time the room fills with hazardous zones; rewards patience and map awareness.

const MOVE_SPEED     := 40.0
const SHOOT_CD_1     := 1.8
const SHOOT_CD_2     := 1.0    # phase 2 (below 50% HP)
const PROJ_DAMAGE    := 8
const PROJ_SPEED     := 220.0
const CONTACT_DAMAGE := 12
const CONTACT_CD     := 1.0
const POOL_DURATION_1 := 8.0
const POOL_DURATION_2 := 12.0  # phase 2

@export var projectile_scene: PackedScene

var _shoot_timer  := 0.0
var _contact_cd   := 0.0

func _ready() -> void:
	boss_name       = "The Plague Lord"
	boss_perk_pool  = ["life_steal", "thorns", "death_burst", "iron_will"]
	companion_scene = "res://scenes/enemies/PoisonToad.tscn"
	super()
	max_health = 400
	health     = 400

func _ai_update(delta: float) -> void:
	_shoot_timer -= delta
	_contact_cd   = maxf(0.0, _contact_cd - delta)

	velocity = _dir_to_player() * MOVE_SPEED

	if _dist_to_player() < 52.0 and _contact_cd <= 0.0:
		player.take_damage(CONTACT_DAMAGE, self)
		_contact_cd = CONTACT_CD

	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = _shoot_cd()

func _shoot() -> void:
	if projectile_scene == null:
		return
	var p = projectile_scene.instantiate()
	p.damage        = PROJ_DAMAGE
	p.speed         = PROJ_SPEED
	p.pool_duration = POOL_DURATION_2 if health < max_health * 0.5 else POOL_DURATION_1
	get_parent().add_child(p)
	p.global_position = global_position
	p.direction = _dir_to_player()

func _shoot_cd() -> float:
	return SHOOT_CD_2 if health < max_health * 0.5 else SHOOT_CD_1

extends "res://scripts/enemies/base_enemy.gd"

const MOVE_SPEED = 100.0
const PREFERRED_DIST = 160.0
const SHOOT_COOLDOWN = 1.0
const PROJECTILE_DAMAGE = 20
const PROJECTILE_SPEED = 300.0

@export var projectile_scene: PackedScene
var _shoot_timer := 0.0

func _ready() -> void:
	super()
	max_health = 40
	health = 40
	drop_core_type = 2  # FIRE

func _ai_update(delta: float) -> void:
	var dist = _dist_to_player()
	var dir = _dir_to_player()

	if dist > PREFERRED_DIST + 30:
		velocity = dir * MOVE_SPEED
	elif dist < PREFERRED_DIST - 30:
		velocity = -dir * MOVE_SPEED
	else:
		velocity = Vector2.ZERO

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = SHOOT_COOLDOWN

func _shoot() -> void:
	if projectile_scene == null:
		return
	var p = projectile_scene.instantiate()
	p.damage = PROJECTILE_DAMAGE
	p.speed = PROJECTILE_SPEED
	get_parent().add_child(p)
	p.global_position = global_position
	p.direction = _dir_to_player()

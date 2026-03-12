extends "res://scripts/enemies/base_enemy.gd"

const MOVE_SPEED = 150.0
const SHOOT_COOLDOWN = 0.8
const PROJECTILE_DAMAGE = 12
const PROJECTILE_SPEED = 400.0

@export var projectile_scene: PackedScene
var _shoot_timer := 0.0

func _ready() -> void:
	super()
	max_health = 20
	health = 20
	drop_core_type = 7  # LIGHTNING

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * MOVE_SPEED
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

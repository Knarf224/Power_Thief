extends "res://scripts/enemies/base_enemy.gd"

const MOVE_SPEED = 90.0
const PREFERRED_DIST = 180.0
const SHOOT_COOLDOWN = 2.0
const PROJECTILE_DAMAGE = 15
const PROJECTILE_SPEED = 260.0
const SUMMON_COOLDOWN = 4.0
const MAX_SUMMONED = 3

@export var projectile_scene: PackedScene
var _shoot_timer := 0.0
var _summon_timer := 0.0

func _ready() -> void:
	super()
	max_health = 35
	health = 35
	drop_core_type = 9  # SUMMON

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
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_try_summon()
		_summon_timer = SUMMON_COOLDOWN

func _shoot() -> void:
	if projectile_scene == null:
		return
	var p = projectile_scene.instantiate()
	p.damage = PROJECTILE_DAMAGE
	p.speed = PROJECTILE_SPEED
	get_parent().add_child(p)
	p.global_position = global_position
	p.direction = _dir_to_player()

func _try_summon() -> void:
	if get_tree().get_nodes_in_group("summoned_spirit").size() >= MAX_SUMMONED:
		return
	var spirit = load("res://scenes/enemies/SummonedSpirit.tscn").instantiate()
	spirit.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	get_parent().add_child(spirit)

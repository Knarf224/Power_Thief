extends Node2D

const ALLY_SPEED = 150.0
const ATTACK_RANGE = 30.0
const ATTACK_DAMAGE = 8
const ATTACK_RATE = 1.0
const DURATION = 8.0

var _lifetime := 0.0
var _attack_cooldown := 0.0

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= DURATION:
		queue_free()
		return

	_attack_cooldown = max(0.0, _attack_cooldown - delta)
	var target = _find_nearest_enemy()
	if target == null:
		return

	var dir = (target.global_position - global_position).normalized()
	global_position += dir * ALLY_SPEED * delta

	if global_position.distance_to(target.global_position) <= ATTACK_RANGE and _attack_cooldown <= 0.0:
		target.take_damage(ATTACK_DAMAGE)
		_attack_cooldown = ATTACK_RATE

func _find_nearest_enemy() -> Node:
	var nearest: Node = null
	var nearest_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var d = global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest

extends Area2D

const SPEED = 500.0
const LIFETIME = 2.0
const DAMAGE = 10

var direction := Vector2.RIGHT
var _timer := 0.0

var apply_slow := false
var apply_poison := false
var chain_count := 0
var chain_range := 120.0
var chain_damage := 8

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * SPEED * delta
	_timer += delta
	if _timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		if apply_slow and body.has_method("apply_slow"):
			body.apply_slow(0.4, 2.0)
		if apply_poison and body.has_method("apply_poison"):
			body.apply_poison(5, 3.0)
		if chain_count > 0:
			_do_chain(body)
	queue_free()

func _do_chain(hit_body: Node) -> void:
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if hits >= chain_count:
			break
		if enemy == hit_body or not is_instance_valid(enemy):
			continue
		if hit_body.global_position.distance_to(enemy.global_position) <= chain_range:
			enemy.take_damage(chain_damage)
			hits += 1

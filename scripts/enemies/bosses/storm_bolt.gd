extends Area2D

# Homing lightning bolt fired by the Storm Tyrant.
# Gradually turns toward the player. Chain bolts jump to nearby enemies on hit.

const LIFETIME   := 3.0
const TURN_RATE  := PI / 2.0   # 90 degrees per second max turning
const BASE_SPEED := 300.0
const BASE_DAMAGE := 18

var speed        := BASE_SPEED
var damage       := BASE_DAMAGE
var direction    := Vector2.RIGHT
var is_chain     := false
var chain_damage := 15
var chain_jumps  := 3

var _timer  := 0.0
var _player : Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	# Home toward player
	if _player != null and is_instance_valid(_player):
		var target_dir := (_player.global_position - global_position).normalized()
		var turn_amount := clampf(
			direction.angle_to(target_dir),
			-TURN_RATE * delta,
			TURN_RATE * delta
		)
		direction = direction.rotated(turn_amount)

	position += direction * speed * delta
	_timer += delta
	if _timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") or body.is_in_group("boss"):
		return
	if body.is_in_group("player"):
		if is_chain:
			body.take_damage(chain_damage)
			_do_chain()
		else:
			body.take_damage(damage)
	queue_free()

func _do_chain() -> void:
	var remaining := chain_jumps
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if remaining <= 0:
			break
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= 200.0:
			enemy.take_damage(chain_damage)
			remaining -= 1

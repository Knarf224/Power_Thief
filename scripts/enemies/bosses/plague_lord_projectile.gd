extends Area2D

# Poison glob fired by the Plague Lord. Spawns a persistent PoisonPool wherever
# it lands — on a wall, on impact with the player, or when it times out.

const LIFETIME := 2.0

var speed         := 220.0
var damage        := 8
var direction     := Vector2.RIGHT
var pool_duration := 8.0

var _timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta
	if _timer >= LIFETIME:
		_land()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("boss"):
		return
	if body.is_in_group("player"):
		body.call("take_damage", damage)
	_land()

func _land() -> void:
	if is_queued_for_deletion():
		return
	var pool = load("res://scenes/enemies/bosses/PoisonPool.tscn").instantiate()
	pool.pool_duration = pool_duration
	get_parent().add_child(pool)
	pool.global_position = global_position
	queue_free()

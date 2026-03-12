extends Area2D

const LIFETIME = 3.0

var speed := 220.0
var damage := 10
var direction := Vector2.RIGHT
var _timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta
	if _timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		return
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

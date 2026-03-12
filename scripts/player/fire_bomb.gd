extends Node2D

const FUSE_TIME = 1.5
const EXPLOSION_RADIUS = 80.0
const DAMAGE = 40

var _timer := 0.0
var _exploded := false

@onready var visual: Polygon2D = $Visual

func _process(delta: float) -> void:
	if _exploded:
		return
	_timer += delta
	# Pulse while waiting to explode
	var pulse = 1.0 + sin(_timer * 10.0) * 0.15
	visual.scale = Vector2(pulse, pulse)
	if _timer >= FUSE_TIME:
		_explode()

func _explode() -> void:
	_exploded = true
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(enemy.global_position) <= EXPLOSION_RADIUS:
			enemy.take_damage(DAMAGE)
	queue_free()

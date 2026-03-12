extends Node2D

const EXPLOSION_RADIUS = 80.0
const EXPLOSION_DAMAGE = 25
const FLASH_TIME = 0.15

@onready var visual: Polygon2D = $Visual
var _timer := 0.0

func _ready() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(enemy.global_position) <= EXPLOSION_RADIUS:
			enemy.take_damage(EXPLOSION_DAMAGE)

func _process(delta: float) -> void:
	_timer += delta
	visual.modulate.a = 1.0 - (_timer / FLASH_TIME)
	if _timer >= FLASH_TIME:
		queue_free()

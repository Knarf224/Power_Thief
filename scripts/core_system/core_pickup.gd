extends Area2D

const CORE_COLORS = {
	1: Color(0.5, 0.3, 0.9, 1),    # DASH      - purple
	2: Color(1.0, 0.35, 0.05, 1),  # FIRE      - orange
	3: Color(0.2, 0.85, 0.2, 1),   # SPLIT     - green
	4: Color(0.85, 0.85, 0.95, 1), # PHASE     - white
	5: Color(0.6, 0.35, 0.05, 1),  # EXPLOSION - brown
	6: Color(0.1, 0.75, 0.9, 1),   # ICE       - cyan
	7: Color(1.0, 0.9, 0.1, 1),    # LIGHTNING - yellow
	8: Color(0.55, 0.55, 0.55, 1), # SHIELD    - gray
	9: Color(0.3, 0.05, 0.4, 1),   # SUMMON    - dark purple
	10: Color(0.45, 0.8, 0.1, 1),  # POISON    - yellow-green
}

var core_type := 0
var _time := 0.0

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("core_pickup")
	body_entered.connect(_on_body_entered)
	monitoring = false
	if CORE_COLORS.has(core_type):
		visual.color = CORE_COLORS[core_type]
	visual.modulate.a = 0.25

func _process(delta: float) -> void:
	_time += delta
	position.y += sin(_time * 3.0) * 0.4

func activate() -> void:
	monitoring = true
	visual.modulate.a = 1.0

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.equip_core(core_type)
	# Remove all other cores — one per room
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		if pickup != self:
			pickup.queue_free()
	queue_free()

extends Area2D

# Persistent poison pool left by the Plague Lord's projectiles.
# Deals ticking damage to any player standing inside.

const DAMAGE_PER_TICK := 4
const TICK_RATE       := 0.5

var pool_duration := 8.0

var _life_timer := 0.0
var _tick_timer := 0.0

func _ready() -> void:
	_life_timer = pool_duration
	monitoring  = true

func _process(delta: float) -> void:
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_RATE
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.take_damage(DAMAGE_PER_TICK)

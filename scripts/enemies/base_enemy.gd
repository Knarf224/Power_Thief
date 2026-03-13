extends CharacterBody2D

const SPEED = 80.0

var max_health := 30
var health := 30
var drop_core_type := 0
var player: CharacterBody2D = null

var _slow_timer := 0.0
var _slow_amount := 0.0
var _poison_timer := 0.0
var _poison_tick_timer := 0.0
var _poison_damage := 0

# Stuck detection — opt-in per room type via teleport_when_stuck
var teleport_when_stuck := false
var teleport_target := Vector2.ZERO       # Set by spawner; falls back to viewport center if zero
var teleport_zones: Array[Rect2] = []     # If set, only teleport when inside one of these rects
var _prev_position := Vector2.ZERO
var _stuck_timer := 0.0

signal died

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	_prev_position = global_position

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_ai_update(delta)
	_tick_effects(delta)
	if is_queued_for_deletion():
		return
	velocity *= _speed_multiplier()

	move_and_slide()

	# If stuck in a designated corner zone, teleport to the room center (ambush room only)
	if teleport_when_stuck and _in_teleport_zone():
		var moved := global_position.distance_to(_prev_position)
		_prev_position = global_position
		if moved < 3.0 and velocity.length() > 10.0:
			_stuck_timer += delta
			if _stuck_timer >= 1.0:
				global_position = teleport_target if teleport_target != Vector2.ZERO else get_viewport_rect().size / 2.0
				_stuck_timer = 0.0
		else:
			_stuck_timer = 0.0
	else:
		_prev_position = global_position
		_stuck_timer = 0.0

func _tick_effects(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
	if _poison_timer > 0.0:
		_poison_timer -= delta
		_poison_tick_timer -= delta
		if _poison_tick_timer <= 0.0:
			_poison_tick_timer = 0.5
			take_damage(_poison_damage)

func _speed_multiplier() -> float:
	return (1.0 - _slow_amount) if _slow_timer > 0.0 else 1.0

func apply_slow(amount: float, duration: float) -> void:
	_slow_amount = amount
	_slow_timer = duration

func apply_poison(damage_per_tick: int, duration: float) -> void:
	_poison_damage = damage_per_tick
	_poison_timer = duration
	_poison_tick_timer = 0.5

func _ai_update(_delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		_on_death()

func _on_death() -> void:
	if drop_core_type != 0:
		_spawn_core_pickup()
	died.emit()
	queue_free()

func _spawn_core_pickup() -> void:
	var pickup = load("res://scenes/core_system/CorePickup.tscn").instantiate()
	pickup.core_type = drop_core_type
	pickup.global_position = global_position
	get_parent().add_child(pickup)

func _in_teleport_zone() -> bool:
	if teleport_zones.is_empty():
		return true  # No zones defined — apply everywhere (fallback)
	for zone in teleport_zones:
		if zone.has_point(global_position):
			return true
	return false

func _dir_to_player() -> Vector2:
	return (player.global_position - global_position).normalized()

func _dist_to_player() -> float:
	return global_position.distance_to(player.global_position)

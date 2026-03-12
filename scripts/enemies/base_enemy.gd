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

signal died

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_ai_update(delta)
	_tick_effects(delta)
	if is_queued_for_deletion():
		return
	velocity *= _speed_multiplier()
	move_and_slide()

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

func _dir_to_player() -> Vector2:
	return (player.global_position - global_position).normalized()

func _dist_to_player() -> float:
	return global_position.distance_to(player.global_position)

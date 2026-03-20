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
var _stun_timer := 0.0
var _stun_flash_timer := 0.0
const STUN_FLASH_PERIOD := 0.12

# Stuck detection — opt-in per room type via teleport_when_stuck
var teleport_when_stuck := false
var teleport_target := Vector2.ZERO       # Set by spawner; falls back to viewport center if zero
var teleport_zones: Array[Rect2] = []     # If set, only teleport when inside one of these rects
var _prev_position := Vector2.ZERO
var _stuck_timer := 0.0

signal died

var _is_dying := false
var is_boss   := false

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	_prev_position = global_position

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	# Freeze power-up — stop all AI movement and tint icy blue (bosses are immune)
	if not is_boss and GameState.freeze_timer > 0.0:
		velocity = Vector2.ZERO
		modulate = Color(0.55, 0.85, 1.0, 1.0)
		return

	if _stun_timer > 0.0:
		_stun_timer -= delta
		_stun_flash_timer += delta
		var flash := fmod(_stun_flash_timer, STUN_FLASH_PERIOD * 2.0) < STUN_FLASH_PERIOD
		modulate = Color(1.8, 1.6, 0.3, 1.0) if flash else Color(0.5, 0.5, 0.5, 1.0)
		velocity = velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
		move_and_slide()
		_enforce_bounds()
		return
	if modulate != Color.WHITE:
		modulate = Color.WHITE

	_ai_update(delta)
	_tick_effects(delta)
	if is_queued_for_deletion():
		return
	velocity *= _speed_multiplier()

	move_and_slide()
	_enforce_bounds()

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

func apply_knockback(impulse: Vector2, stun_duration: float) -> void:
	velocity = impulse
	_stun_timer = stun_duration
	_stun_flash_timer = 0.0

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
	if _is_dying:
		return
	# Insta-Kill power-up — one hit kills basic enemies (bosses are immune)
	if not is_boss and GameState.insta_kill_timer > 0.0:
		health = 0
	else:
		health = max(0, health - amount)
	if health == 0:
		_on_death()

func nuke() -> void:
	if not _is_dying:
		_on_death()

func _on_death() -> void:
	_is_dying = true
	if drop_core_type != 0:
		_spawn_core_pickup()
	# Power-up drop — basic enemies only, never bosses
	if not is_boss:
		_try_spawn_power_up()
	# Life Steal — restore 2 HP to the player on kill
	if GameState.player_perks.has("life_steal"):
		var p := get_tree().get_first_node_in_group("player")
		if p and is_instance_valid(p):
			p.heal(2)
	# Death Burst — explode for 20 AoE damage to nearby enemies
	if GameState.player_perks.has("death_burst"):
		_spawn_death_burst()
	died.emit()
	queue_free()

func _try_spawn_power_up() -> void:
	GameState.enemies_killed_this_room += 1
	# Level 2 (room_counter == 1): guaranteed drop on the 2nd kill as a tutorial
	var is_tutorial_drop := GameState.room_counter == 1 and GameState.enemies_killed_this_room == 2
	if not is_tutorial_drop and randf() > 0.10:
		return
	var types := ["nuke", "insta_kill", "full_heal", "shield_burst", "speed_boost", "freeze"]
	var picked: String = types[randi() % types.size()]
	var pickup = load("res://scenes/pickups/PowerUpPickup.tscn").instantiate()
	pickup.power_up_type = picked
	pickup.global_position = global_position
	get_parent().add_child(pickup)

func _spawn_death_burst() -> void:
	const BURST_RADIUS := 60.0
	const BURST_DAMAGE := 20
	# Spawn visual effect at this position before damaging neighbours
	var fx := load("res://scenes/fx/DeathBurstFx.tscn") as PackedScene
	if fx:
		var inst := fx.instantiate()
		get_parent().add_child(inst)
		inst.global_position = global_position
	# Damage nearby enemies — skip self and any already dying
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not is_instance_valid(enemy):
			continue
		if enemy.is_queued_for_deletion():
			continue
		if global_position.distance_to(enemy.global_position) <= BURST_RADIUS:
			enemy.call("take_damage", BURST_DAMAGE)

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

func _enforce_bounds() -> void:
	var vp := get_viewport_rect()
	const MARGIN := 80.0
	if global_position.x < -MARGIN or global_position.x > vp.size.x + MARGIN \
			or global_position.y < -MARGIN or global_position.y > vp.size.y + MARGIN:
		global_position = vp.size / 2.0
		velocity = Vector2.ZERO

func _dir_to_player() -> Vector2:
	return (player.global_position - global_position).normalized()

func _dist_to_player() -> float:
	return global_position.distance_to(player.global_position)

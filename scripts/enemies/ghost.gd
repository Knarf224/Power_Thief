extends "res://scripts/enemies/base_enemy.gd"

const GHOST_SPEED = 90.0
const CONTACT_DAMAGE = 12
const CONTACT_COOLDOWN = 0.8
const VULNERABILITY_RANGE = 100.0

var _contact_cooldown := 0.0

func _ready() -> void:
	super()
	max_health = 30
	health = 30
	drop_core_type = 4  # PHASE
	# Ghost sits on layer 2 (not the default layer 1 that the player's collision
	# mask covers). This prevents move_and_slide from treating the Ghost as a
	# solid obstacle and shoving the player out of bounds, while keeping the
	# Ghost detectable by projectiles whose mask includes layer 2.
	collision_layer = 2
	collision_mask  = 0

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	if GameState.freeze_timer > 0.0:
		velocity = Vector2.ZERO
		modulate = Color(0.55, 0.85, 1.0, 1.0)
		return

	if _stun_timer > 0.0:
		_stun_timer -= delta
		_stun_flash_timer += delta
		var flash := fmod(_stun_flash_timer, STUN_FLASH_PERIOD * 2.0) < STUN_FLASH_PERIOD
		modulate = Color(1.8, 1.6, 0.3, 1.0) if flash else Color(0.5, 0.5, 0.5, 1.0)
		velocity = velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
		global_position += velocity * delta
		_enforce_bounds()
		return
	if modulate != Color.WHITE:
		modulate = Color.WHITE

	_ai_update(delta)
	_tick_effects(delta)
	if is_queued_for_deletion():
		return
	# Translate directly — bypasses move_and_slide() so walls are ignored
	global_position += velocity * _speed_multiplier() * delta
	_enforce_bounds()

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * GHOST_SPEED
	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	if _dist_to_player() < 22.0 and _contact_cooldown <= 0.0:
		player.take_damage(CONTACT_DAMAGE, self)
		_contact_cooldown = CONTACT_COOLDOWN

func take_damage(amount: int) -> void:
	if _dist_to_player() > VULNERABILITY_RANGE:
		return  # intangible outside close range
	super(amount)

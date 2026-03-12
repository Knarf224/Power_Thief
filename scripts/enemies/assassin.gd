extends "res://scripts/enemies/base_enemy.gd"

const CHASE_SPEED = 120.0
const DASH_SPEED = 500.0
const DASH_DURATION = 0.18
const DASH_RANGE = 120.0
const DASH_COOLDOWN = 1.5
const CONTACT_DAMAGE = 15
const CONTACT_COOLDOWN = 0.8

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown := 0.0
var _dash_dir := Vector2.ZERO
var _contact_cooldown := 0.0

func _ready() -> void:
	super()
	max_health = 50
	health = 50
	drop_core_type = 1  # DASH

func _ai_update(delta: float) -> void:
	_dash_cooldown = max(0.0, _dash_cooldown - delta)
	_contact_cooldown = max(0.0, _contact_cooldown - delta)

	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_timer <= 0.0:
			_is_dashing = false
		_try_contact_damage()
		return

	velocity = _dir_to_player() * CHASE_SPEED

	if _dist_to_player() < DASH_RANGE and _dash_cooldown <= 0.0:
		_start_dash()

	_try_contact_damage()

func _start_dash() -> void:
	_dash_dir = _dir_to_player()
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN

func _try_contact_damage() -> void:
	if _contact_cooldown > 0.0 or _dist_to_player() > 30.0:
		return
	player.take_damage(CONTACT_DAMAGE)
	_contact_cooldown = CONTACT_COOLDOWN

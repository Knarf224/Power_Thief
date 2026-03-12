extends "res://scripts/enemies/base_enemy.gd"

const GOLEM_SPEED = 50.0
const CONTACT_DAMAGE = 25
const CONTACT_COOLDOWN = 1.2
const SHIELD_RECHARGE = 8.0

var _has_shield := true
var _shield_recharge_timer := 0.0
var _contact_cooldown := 0.0

func _ready() -> void:
	super()
	max_health = 80
	health = 80
	drop_core_type = 8  # SHIELD

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * GOLEM_SPEED
	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	if not _has_shield:
		_shield_recharge_timer -= delta
		if _shield_recharge_timer <= 0.0:
			_has_shield = true
	if _dist_to_player() < 28.0 and _contact_cooldown <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cooldown = CONTACT_COOLDOWN

func take_damage(amount: int) -> void:
	if _has_shield:
		_has_shield = false
		_shield_recharge_timer = SHIELD_RECHARGE
		return  # absorb the hit
	super(amount)

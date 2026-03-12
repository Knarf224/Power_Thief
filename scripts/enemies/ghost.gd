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

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * GHOST_SPEED
	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	if _dist_to_player() < 22.0 and _contact_cooldown <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cooldown = CONTACT_COOLDOWN

func take_damage(amount: int) -> void:
	if _dist_to_player() > VULNERABILITY_RANGE:
		return  # intangible outside close range
	super(amount)

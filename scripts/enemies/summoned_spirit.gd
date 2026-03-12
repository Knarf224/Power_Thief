extends "res://scripts/enemies/base_enemy.gd"

const SPIRIT_SPEED = 110.0
const CONTACT_DAMAGE = 15
const CONTACT_COOLDOWN = 0.8

var _contact_cooldown := 0.0

func _ready() -> void:
	super()
	max_health = 10
	health = 10
	drop_core_type = 0  # no drop
	add_to_group("summoned_spirit")

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * SPIRIT_SPEED
	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	if _dist_to_player() < 22.0 and _contact_cooldown <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cooldown = CONTACT_COOLDOWN

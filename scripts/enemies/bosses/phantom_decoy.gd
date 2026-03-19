extends "res://scripts/enemies/base_enemy.gd"

# Phantom decoy — looks identical to the real Phantom. Dies in one hit.
# Deals contact damage and moves toward the player to cause confusion.

const MOVE_SPEED     := 130.0
const CONTACT_DAMAGE := 18
const CONTACT_CD     := 0.8

var _contact_cd := 0.0

func _ready() -> void:
	super()
	max_health     = 1
	health         = 1
	drop_core_type = 0

func _ai_update(delta: float) -> void:
	velocity    = _dir_to_player() * MOVE_SPEED
	_contact_cd = maxf(0.0, _contact_cd - delta)
	if _dist_to_player() < 28.0 and _contact_cd <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cd = CONTACT_CD

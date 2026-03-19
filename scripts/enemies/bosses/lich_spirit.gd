extends "res://scripts/enemies/base_enemy.gd"

# Spirit summoned by the Lich. In "boss_spirit" group so the Lich can track
# how many are alive. Also in "enemy" group (inherited) so player shots can hit it.

const MOVE_SPEED     := 120.0
const CONTACT_DAMAGE := 15
const CONTACT_CD     := 0.8

var _contact_cd := 0.0

func _ready() -> void:
	super()
	add_to_group("boss_spirit")
	max_health     = 10
	health         = 10
	drop_core_type = 0

func _ai_update(delta: float) -> void:
	velocity    = _dir_to_player() * MOVE_SPEED
	_contact_cd = maxf(0.0, _contact_cd - delta)
	if _dist_to_player() < 22.0 and _contact_cd <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cd = CONTACT_CD

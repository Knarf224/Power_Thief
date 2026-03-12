extends "res://scripts/enemies/base_enemy.gd"

const BEETLE_SPEED = 70.0
const CONTACT_DAMAGE = 10
const CONTACT_COOLDOWN = 0.8
const EXPLOSION_RADIUS = 80.0
const EXPLOSION_DAMAGE = 70

var _contact_cooldown := 0.0

func _ready() -> void:
	super()
	max_health = 45
	health = 45
	drop_core_type = 5  # EXPLOSION

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * BEETLE_SPEED
	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	if _dist_to_player() < 22.0 and _contact_cooldown <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cooldown = CONTACT_COOLDOWN

func _on_death() -> void:
	_explode()
	super()

func _explode() -> void:
	if player == null or not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) <= EXPLOSION_RADIUS:
		player.take_damage(EXPLOSION_DAMAGE)

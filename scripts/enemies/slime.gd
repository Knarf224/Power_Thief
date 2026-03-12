extends "res://scripts/enemies/base_enemy.gd"

const SLIME_SPEED = 55.0
const CONTACT_DAMAGE = 8
const CONTACT_COOLDOWN = 0.6

var is_mini := false
var _contact_cooldown := 0.0

func _ready() -> void:
	super()
	if is_mini:
		max_health = 30
		health = 30
		drop_core_type = 0
		add_to_group("slime_mini")
	else:
		max_health = 60
		health = 60
		drop_core_type = 0  # core drops from last mini, not the full slime

func _ai_update(delta: float) -> void:
	velocity = _dir_to_player() * SLIME_SPEED
	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	if _dist_to_player() < 22.0 and _contact_cooldown <= 0.0:
		player.take_damage(CONTACT_DAMAGE)
		_contact_cooldown = CONTACT_COOLDOWN

func _on_death() -> void:
	if is_mini:
		# size() == 1 means this is the last mini still in the scene
		if get_tree().get_nodes_in_group("slime_mini").size() <= 1:
			_spawn_split_core()
	else:
		_spawn_minis()
	super()

func _spawn_minis() -> void:
	var scene = load("res://scenes/enemies/Slime.tscn")
	for i in 2:
		var mini = scene.instantiate()
		mini.is_mini = true
		mini.global_position = global_position + Vector2(randf_range(-24, 24), randf_range(-24, 24))
		get_parent().add_child(mini)

func _spawn_split_core() -> void:
	var pickup = load("res://scenes/core_system/CorePickup.tscn").instantiate()
	pickup.core_type = 3  # SPLIT
	pickup.global_position = global_position
	get_parent().add_child(pickup)

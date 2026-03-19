extends "res://scripts/enemies/bosses/boss_base.gd"

# The Lich — frail spellcaster protected by undead spirits.
# Completely invulnerable while any boss_spirit is alive. Kill the spirits first.

const MOVE_SPEED       := 80.0
const PREFERRED_DIST   := 200.0
const SHOOT_CD_1       := 1.5
const SHOOT_CD_2       := 0.8    # phase 2 (below 40% HP)
const PROJ_DAMAGE      := 20
const PROJ_SPEED       := 280.0
const SUMMON_CD        := 5.0
const SPIRITS_WAVE_1   := 3
const SPIRITS_WAVE_2   := 5      # phase 2
const MAX_SPIRITS      := 6

@export var projectile_scene: PackedScene

var _shoot_timer  := 0.0
var _summon_timer := 0.0

func _ready() -> void:
	boss_name       = "The Lich"
	boss_perk_pool  = ["rapid_fire", "piercing_shot", "auto_fire"]
	companion_scene = "res://scenes/enemies/Necromancer.tscn"
	super()
	max_health = 220
	health     = 220

func _ai_update(delta: float) -> void:
	var dist := _dist_to_player()
	var dir  := _dir_to_player()

	if dist > PREFERRED_DIST + 30:
		velocity = dir * MOVE_SPEED
	elif dist < PREFERRED_DIST - 30:
		velocity = -dir * MOVE_SPEED
	else:
		velocity = Vector2.ZERO

	_shoot_timer  -= delta
	_summon_timer -= delta

	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = _shoot_cd()

	if _summon_timer <= 0.0:
		_try_summon()
		_summon_timer = SUMMON_CD

func _shoot() -> void:
	if projectile_scene == null:
		return
	var p = projectile_scene.instantiate()
	p.damage    = PROJ_DAMAGE
	p.speed     = PROJ_SPEED
	get_parent().add_child(p)
	p.global_position = global_position
	p.direction = _dir_to_player()

func _try_summon() -> void:
	var active := get_tree().get_nodes_in_group("boss_spirit").size()
	if active >= MAX_SPIRITS:
		return
	var count := SPIRITS_WAVE_2 if health < max_health * 0.4 else SPIRITS_WAVE_1
	for i in count:
		if get_tree().get_nodes_in_group("boss_spirit").size() >= MAX_SPIRITS:
			break
		var spirit = load("res://scenes/enemies/bosses/LichSpirit.tscn").instantiate()
		spirit.global_position = global_position + Vector2(
			randf_range(-40.0, 40.0), randf_range(-40.0, 40.0)
		)
		get_parent().add_child(spirit)

func take_damage(amount: int) -> void:
	# Invulnerable while any spirit is alive
	if not get_tree().get_nodes_in_group("boss_spirit").is_empty():
		return
	super(amount)

func _shoot_cd() -> float:
	return SHOOT_CD_2 if health < max_health * 0.4 else SHOOT_CD_1

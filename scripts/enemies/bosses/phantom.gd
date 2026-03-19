extends "res://scripts/enemies/bosses/boss_base.gd"

# The Phantom — teleporting hunter that spawns decoys and is only vulnerable
# for a brief window after each teleport.

const MOVE_SPEED      := 130.0
const TELEPORT_CD_1   := 3.5
const TELEPORT_CD_2   := 2.0    # phase 2 (below 50% HP)
const VULN_WINDOW     := 1.5    # seconds of vulnerability after teleporting
const CONTACT_DAMAGE  := 18
const CONTACT_CD      := 0.8
const SHOOT_CD        := 2.0
const PROJ_DAMAGE     := 12
const PROJ_SPEED      := 200.0
const DECOYS_1        := 2
const DECOYS_2        := 3      # phase 2

@export var projectile_scene: PackedScene

var _teleport_timer := 1.0   # short delay before first teleport
var _vuln_timer     := VULN_WINDOW
var _vulnerable     := true  # starts visible and vulnerable
var _contact_cd     := 0.0
var _shoot_timer    := SHOOT_CD

func _ready() -> void:
	boss_name       = "The Phantom"
	boss_perk_pool  = ["piercing_shot", "auto_fire", "life_steal"]
	companion_scene = "res://scenes/enemies/Ghost.tscn"
	super()
	max_health = 180
	health     = 180

func _ai_update(delta: float) -> void:
	_contact_cd    = maxf(0.0, _contact_cd - delta)
	_teleport_timer -= delta
	_shoot_timer   -= delta

	# Tick down vulnerability window
	if _vulnerable:
		_vuln_timer -= delta
		if _vuln_timer <= 0.0:
			_vulnerable = false

	velocity = _dir_to_player() * MOVE_SPEED

	# Contact damage (whether visible or not — decoys also do this)
	if _dist_to_player() < 46.0 and _contact_cd <= 0.0:
		player.take_damage(CONTACT_DAMAGE, self)
		_contact_cd = CONTACT_CD

	# Shoot a 3-projectile spread
	if _shoot_timer <= 0.0:
		_fire_spread()
		_shoot_timer = SHOOT_CD

	# Teleport
	if _teleport_timer <= 0.0:
		_do_teleport()

func _do_teleport() -> void:
	# Safe random position within approximate room bounds
	global_position = Vector2(
		randf_range(120.0, 1160.0),
		randf_range(120.0, 600.0)
	)
	_vulnerable     = true
	_vuln_timer     = VULN_WINDOW
	_teleport_timer = _teleport_cd()

	# Spawn decoys alongside the real Phantom
	var decoy_count := DECOYS_2 if health < max_health * 0.5 else DECOYS_1
	for i in decoy_count:
		var decoy = load("res://scenes/enemies/bosses/PhantomDecoy.tscn").instantiate()
		decoy.global_position = global_position + Vector2(
			randf_range(-80.0, 80.0), randf_range(-80.0, 80.0)
		)
		get_parent().add_child(decoy)

func _fire_spread() -> void:
	if projectile_scene == null:
		return
	var base_dir := _dir_to_player()
	for offset in [-0.3, 0.0, 0.3]:
		var p = projectile_scene.instantiate()
		p.damage    = PROJ_DAMAGE
		p.speed     = PROJ_SPEED
		get_parent().add_child(p)
		p.global_position = global_position
		p.direction = base_dir.rotated(offset)

func take_damage(amount: int) -> void:
	if not _vulnerable:
		return
	super(amount)

func _teleport_cd() -> float:
	return TELEPORT_CD_2 if health < max_health * 0.5 else TELEPORT_CD_1

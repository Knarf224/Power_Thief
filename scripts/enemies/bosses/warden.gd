extends "res://scripts/enemies/bosses/boss_base.gd"

# The Warden — armoured melee brute that charges across the room.
# Player must bait the charge, dodge, then punish the stun window.

enum State { WALKING, WINDING_UP, CHARGING, STUNNED }

const WALK_SPEED      := 45.0
const CHARGE_SPEED_1  := 700.0
const CHARGE_SPEED_2  := 900.0   # phase 2 (below 50% HP)
const CHARGE_WINDUP   := 0.8     # seconds of telegraph before launch
const CHARGE_CD_1     := 4.0
const CHARGE_CD_2     := 2.5     # phase 2
const STUN_DURATION   := 1.2     # seconds stunned after hitting a wall
const CONTACT_DAMAGE  := 20
const CONTACT_COOLDOWN := 1.0
const SHIELD_HITS     := 2       # absorbs this many hits before HP is touched

var _state           := State.WALKING
var _windup_timer    := 0.0
var _wall_stun_timer := 0.0
var _charge_cooldown := 2.0   # initial delay so Warden walks toward player first
var _contact_cd      := 0.0
var _charge_dir      := Vector2.ZERO
var _shield_left     := SHIELD_HITS

func _ready() -> void:
	boss_name       = "The Warden"
	boss_perk_pool  = ["stopping_power", "gravity_push", "thorns", "berserker"]
	companion_scene = "res://scenes/enemies/StoneGolem.tscn"
	super()
	max_health = 350
	health     = 350

func _ai_update(delta: float) -> void:
	_charge_cooldown = maxf(0.0, _charge_cooldown - delta)
	_contact_cd      = maxf(0.0, _contact_cd - delta)

	match _state:
		State.WALKING:
			velocity = _dir_to_player() * WALK_SPEED
			_try_contact_damage()
			if _charge_cooldown <= 0.0:
				_state        = State.WINDING_UP
				_windup_timer = CHARGE_WINDUP
				velocity      = Vector2.ZERO

		State.WINDING_UP:
			velocity       = Vector2.ZERO
			_windup_timer -= delta
			if _windup_timer <= 0.0:
				_charge_dir = _dir_to_player()
				_state      = State.CHARGING

		State.CHARGING:
			# Wall detection — is_on_wall() reflects the previous frame's move_and_slide
			if is_on_wall():
				_state           = State.STUNNED
				_wall_stun_timer = STUN_DURATION
				velocity     = Vector2.ZERO
				return
			velocity = _charge_dir * _charge_speed()
			# Heavy impact if we run into the player while charging
			if _dist_to_player() < 48.0 and _contact_cd <= 0.0:
				player.take_damage(40, self)
				_contact_cd = CONTACT_COOLDOWN

		State.STUNNED:
			velocity         = Vector2.ZERO
			_wall_stun_timer -= delta
			if _wall_stun_timer <= 0.0:
				_state           = State.WALKING
				_charge_cooldown = _charge_cd()

func _try_contact_damage() -> void:
	if _contact_cd > 0.0 or _dist_to_player() > 48.0:
		return
	player.take_damage(CONTACT_DAMAGE, self)
	_contact_cd = CONTACT_COOLDOWN

func take_damage(amount: int) -> void:
	if _shield_left > 0:
		_shield_left -= 1
		return   # hit absorbed — no HP lost
	super(amount)

func _charge_speed() -> float:
	return CHARGE_SPEED_2 if health < max_health * 0.5 else CHARGE_SPEED_1

func _charge_cd() -> float:
	return CHARGE_CD_2 if health < max_health * 0.5 else CHARGE_CD_1

extends CharacterBody2D

# CoreType: 0=NONE, 1=DASH, 2=FIRE, 3=SPLIT, 4=PHASE, 5=EXPLOSION, 6=ICE, 7=LIGHTNING, 8=SHIELD, 9=SUMMON, 10=POISON
enum CoreType { NONE, DASH, FIRE, SPLIT, PHASE, EXPLOSION, ICE, LIGHTNING, SHIELD, SUMMON, POISON }

const SPEED = 200.0
const DASH_SPEED = 500.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.8
const FIRE_BOMB_COOLDOWN = 3.0
const PHASE_DURATION = 1.5
const PHASE_COOLDOWN = 8.0
const SHIELD_RECHARGE = 10.0
const SUMMON_COOLDOWN = 15.0
const MAX_HEALTH = 100

var health := MAX_HEALTH
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var fire_bomb_cooldown_timer := 0.0
var _is_phasing := false
var _phase_timer := 0.0
var _phase_cooldown := 0.0
var _shield_active := false
var _shield_recharge_timer := 0.0
var _summon_cooldown := 0.0
var _dash_start_pos := Vector2.ZERO

var core_slots: Array = [CoreType.NONE, CoreType.NONE, CoreType.NONE]

signal health_changed(current: int, maximum: int)
signal died
signal cores_changed(slots: Array)

@export var projectile_scene: PackedScene
@export var fire_bomb_scene: PackedScene
@export var dash_explosion_scene: PackedScene
@export var summon_ally_scene: PackedScene

@onready var _visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * _dash_speed()
		if dash_timer <= 0.0:
			is_dashing = false
			if _has_core(CoreType.EXPLOSION):
				_spawn_dash_explosion()
	else:
		velocity = _get_move_direction() * SPEED

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if fire_bomb_cooldown_timer > 0.0:
		fire_bomb_cooldown_timer -= delta

	if _is_phasing:
		_phase_timer -= delta
		if _phase_timer <= 0.0:
			_is_phasing = false
			_visual.modulate.a = 1.0
	if _phase_cooldown > 0.0:
		_phase_cooldown -= delta

	if not _shield_active and _shield_recharge_timer > 0.0:
		_shield_recharge_timer -= delta
		if _shield_recharge_timer <= 0.0:
			_shield_active = true

	if _summon_cooldown > 0.0:
		_summon_cooldown -= delta

	move_and_slide()

func _get_move_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	return dir.normalized()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_shoot()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_dash()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_use_slot(0)
		elif event.keycode == KEY_2:
			_use_slot(1)
		elif event.keycode == KEY_3:
			_use_slot(2)

# --- Shooting ---

func _shoot() -> void:
	if projectile_scene == null:
		return
	var base_dir := (get_global_mouse_position() - global_position).normalized()
	if _has_core(CoreType.SPLIT):
		_spawn_projectile(base_dir.rotated(-0.26))
		_spawn_projectile(base_dir.rotated(0.26))
	else:
		_spawn_projectile(base_dir)

func _spawn_projectile(dir: Vector2) -> void:
	var p = projectile_scene.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.direction = dir
	if _has_core(CoreType.ICE):
		p.apply_slow = true
	if _has_core(CoreType.LIGHTNING):
		p.chain_count = 2
	if _has_core(CoreType.POISON):
		p.apply_poison = true

# --- Dash ---

func _try_dash() -> void:
	if is_dashing or dash_cooldown_timer > 0.0:
		return
	_dash_start_pos = global_position
	dash_direction = (get_global_mouse_position() - global_position).normalized()
	is_dashing = true
	dash_timer = _dash_duration()
	dash_cooldown_timer = DASH_COOLDOWN

func _dash_speed() -> float:
	return DASH_SPEED * (2.0 if _has_core(CoreType.DASH) else 1.0)

func _dash_duration() -> float:
	return DASH_DURATION * (2.0 if _has_core(CoreType.DASH) else 1.0)

func _spawn_dash_explosion() -> void:
	if dash_explosion_scene == null:
		return
	var expl = dash_explosion_scene.instantiate()
	get_parent().add_child(expl)
	expl.global_position = _dash_start_pos

# --- Active Abilities (1 / 2 / 3 per slot) ---

func _use_slot(slot_index: int) -> void:
	match core_slots[slot_index]:
		CoreType.FIRE:
			_drop_fire_bomb()
		CoreType.PHASE:
			_activate_phase()
		CoreType.SUMMON:
			_summon_ally()

func _drop_fire_bomb() -> void:
	if fire_bomb_scene == null or fire_bomb_cooldown_timer > 0.0:
		return
	var bomb = fire_bomb_scene.instantiate()
	get_parent().add_child(bomb)
	bomb.global_position = global_position
	fire_bomb_cooldown_timer = FIRE_BOMB_COOLDOWN

func _activate_phase() -> void:
	if _is_phasing or _phase_cooldown > 0.0:
		return
	_is_phasing = true
	_phase_timer = PHASE_DURATION
	_phase_cooldown = PHASE_COOLDOWN
	_visual.modulate.a = 0.35

func _summon_ally() -> void:
	if _summon_cooldown > 0.0 or summon_ally_scene == null:
		return
	var ally = summon_ally_scene.instantiate()
	get_parent().add_child(ally)
	ally.global_position = global_position
	_summon_cooldown = SUMMON_COOLDOWN

# --- Core System ---

func equip_core(type: int) -> void:
	for i in 3:
		if core_slots[i] == CoreType.NONE:
			core_slots[i] = type
			cores_changed.emit(core_slots)
			if type == CoreType.SHIELD:
				_shield_active = true
			return
	# All slots full — replace slot 0
	core_slots[0] = type
	cores_changed.emit(core_slots)
	if type == CoreType.SHIELD:
		_shield_active = true

func _has_core(type: int) -> bool:
	return core_slots.has(type)

# --- Health ---

func take_damage(amount: int) -> void:
	if _is_phasing:
		return
	if _has_core(CoreType.SHIELD) and _shield_active:
		_shield_active = false
		_shield_recharge_timer = SHIELD_RECHARGE
		return
	health = max(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		died.emit()

func heal(amount: int) -> void:
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

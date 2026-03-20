extends CharacterBody2D

# CoreType: 0=NONE, 1=DASH, 2=FIRE, 3=SPLIT, 4=PHASE, 5=EXPLOSION, 6=ICE, 7=LIGHTNING, 8=SHIELD, 9=SUMMON, 10=POISON
enum CoreType { NONE, DASH, FIRE, SPLIT, PHASE, EXPLOSION, ICE, LIGHTNING, SHIELD, SUMMON, POISON }

const SPEED = 200.0
const DASH_SPEED_BASE  = 500.0
const DASH_SPEED_CORE  = 750.0
const FIRE_BOMB_COOLDOWN = 3.0
const MAX_STAMINA          := 100.0
const STAMINA_DRAIN_BASE   := 80.0   # per second while dashing (no DASH core)
const STAMINA_DRAIN_CORE   := 55.0   # per second while dashing (DASH core)
const STAMINA_REGEN_BASE   := 40.0   # per second while not dashing
const STAMINA_REGEN_CORE   := 60.0   # per second while not dashing (DASH core)
const MIN_STAMINA_TO_START := 20.0   # minimum stamina required to begin a dash
const PHASE_DURATION = 1.5
const PHASE_COOLDOWN = 8.0
const SHIELD_RECHARGE = 10.0
const SUMMON_COOLDOWN = 15.0
const MAX_HEALTH = 100
const BASE_SHOOT_COOLDOWN := 0.20  # seconds between auto-fire shots

var health := MAX_HEALTH
var stamina: float = MAX_STAMINA
var is_dashing := false
var dash_direction := Vector2.ZERO
var fire_bomb_cooldown_timer := 0.0
var _is_phasing := false
var _phase_timer := 0.0
var _phase_cooldown := 0.0
var _shield_active := false
var _shield_recharge_timer := 0.0
var _summon_cooldown := 0.0
var _gravity_push_cooldown := 0.0
var _dash_start_pos := Vector2.ZERO

const CORE_INTERACT_RANGE := 100.0

var core_slots: Array = [CoreType.NONE, CoreType.NONE, CoreType.NONE]
var can_attack := true  # rooms can gate this (e.g. PowerZoneRoom)
var _shoot_timer := 0.0
var _iron_will_available := true
var _core_hint: Label = null
var _shield_aura: Polygon2D = null
var _shield_aura_timer := 0.0
var _speed_particles: CPUParticles2D = null

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal died
signal cores_changed(slots: Array)

@export var projectile_scene: PackedScene
@export var fire_bomb_scene: PackedScene
@export var dash_explosion_scene: PackedScene
@export var summon_ally_scene: PackedScene

@onready var _visual: Sprite2D = $Visual

func _ready() -> void:
	add_to_group("player")
	health = GameState.player_health
	core_slots = GameState.player_cores.duplicate()
	_setup_core_hint()
	_setup_shield_aura()
	_setup_speed_particles()

func _setup_speed_particles() -> void:
	_speed_particles = CPUParticles2D.new()
	_speed_particles.emitting              = false
	_speed_particles.amount               = 24
	_speed_particles.lifetime             = 0.3
	_speed_particles.one_shot             = false
	_speed_particles.explosiveness        = 0.0
	_speed_particles.randomness           = 0.5
	_speed_particles.emission_shape       = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_speed_particles.emission_sphere_radius = 6.0
	_speed_particles.direction            = Vector2(0.0, 1.0)
	_speed_particles.spread               = 20.0
	_speed_particles.gravity              = Vector2.ZERO
	_speed_particles.initial_velocity_min = 55.0
	_speed_particles.initial_velocity_max = 95.0
	_speed_particles.scale_amount_min     = 1.5
	_speed_particles.scale_amount_max     = 3.5
	_speed_particles.color                = Color(0.0, 0.88, 1.0, 0.85)
	add_child(_speed_particles)


func _setup_shield_aura() -> void:
	_shield_aura = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 32:
		var a := i * TAU / 32.0
		pts.append(Vector2(cos(a), sin(a)) * 22.0)
	_shield_aura.polygon = pts
	_shield_aura.color   = Color(0.3, 0.6, 1.0, 0.0)
	add_child(_shield_aura)

func _setup_core_hint() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 4
	add_child(cl)
	_core_hint = Label.new()
	_core_hint.text = "[E]  Pick Up Core"
	_core_hint.anchor_left   = 0.5
	_core_hint.anchor_right  = 0.5
	_core_hint.anchor_top    = 1.0
	_core_hint.anchor_bottom = 1.0
	_core_hint.offset_left   = -120
	_core_hint.offset_right  = 120
	_core_hint.offset_top    = -295
	_core_hint.offset_bottom = -265
	_core_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_core_hint.add_theme_font_size_override("font_size", 16)
	_core_hint.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	_core_hint.visible = false
	cl.add_child(_core_hint)

func _physics_process(delta: float) -> void:
	# --- Stamina-based dash ---
	if is_dashing:
		stamina -= _stamina_drain() * delta
		if stamina <= 0.0:
			stamina = 0.0
			_stop_dash()
		else:
			velocity = dash_direction * _dash_speed()
			stamina_changed.emit(stamina, MAX_STAMINA)
	else:
		velocity = _get_move_direction() * _move_speed()
		# Regen stamina while not dashing
		if stamina < MAX_STAMINA:
			stamina = minf(MAX_STAMINA, stamina + _stamina_regen() * delta)
			stamina_changed.emit(stamina, MAX_STAMINA)

	if _shoot_timer > 0.0:
		_shoot_timer -= delta
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
	if _gravity_push_cooldown > 0.0:
		_gravity_push_cooldown -= delta

	# Auto-Fire / Rapid-Fire: hold left mouse to shoot at cooldown rate
	if (_has_perk("auto_fire") or _has_perk("rapid_fire")) \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and can_attack and _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = _current_shoot_cd()

	move_and_slide()
	_update_core_hint()
	_update_shield_aura(delta)
	_update_speed_particles()

func _update_speed_particles() -> void:
	if _speed_particles == null:
		return
	if GameState.speed_boost_timer > 0.0:
		_speed_particles.emitting = true
		if velocity.length() > 10.0:
			_speed_particles.direction = -velocity.normalized()
	else:
		_speed_particles.emitting = false


func spawn_heal_hearts() -> void:
	for i in 7:
		var lbl := Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 12 + randi() % 7)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.1 + randf() * 0.2, 0.2))
		get_parent().add_child(lbl)
		lbl.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var target_y  := lbl.position.y - randf_range(35, 60)
		var target_x  := lbl.position.x + randf_range(-14, 14)
		var tween := lbl.create_tween().set_parallel(true)
		tween.tween_property(lbl, "position:y", target_y, 0.9)
		tween.tween_property(lbl, "position:x", target_x, 0.9)
		tween.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.3)
		tween.chain().tween_callback(lbl.queue_free)


func _update_shield_aura(delta: float) -> void:
	if GameState.shield_burst_timer > 0.0:
		_shield_aura_timer += delta * 3.0
		var pulse := 0.25 + 0.12 * sin(_shield_aura_timer)
		_shield_aura.color = Color(0.3, 0.6, 1.0, pulse)
	else:
		_shield_aura.color = Color(0.3, 0.6, 1.0, 0.0)

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

func _has_perk(id: String) -> bool:
	return GameState.player_perks.has(id)

func _move_speed() -> float:
	if GameState.speed_boost_timer > 0.0:
		return SPEED * 2.0
	if _has_perk("berserker") and health <= 30:
		return SPEED * 1.5
	return SPEED

func _current_shoot_cd() -> float:
	var cd := BASE_SHOOT_COOLDOWN
	if _has_perk("rapid_fire"):
		cd *= 0.6
	if _has_perk("berserker") and health <= 30:
		cd *= 0.5
	return cd

func _active_cooldown(base: float) -> float:
	return base * 0.7 if _has_perk("overclock") else base

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_shoot()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_try_dash()
			else:
				if is_dashing:
					_stop_dash()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_use_slot(0)
		elif event.keycode == KEY_2:
			_use_slot(1)
		elif event.keycode == KEY_3:
			_use_slot(2)
		elif event.keycode == KEY_E:
			_try_interact_core()
		elif event.keycode == KEY_SPACE:
			_use_gravity_push()

# --- Shooting ---

func _shoot() -> void:
	if projectile_scene == null or not can_attack:
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
	if _has_perk("stopping_power"):
		p.damage = int(p.damage * 1.3)
	if _has_perk("piercing_shot"):
		p.piercing = true
	if _has_core(CoreType.ICE):
		p.apply_slow = true
	if _has_core(CoreType.LIGHTNING):
		p.chain_count = 2
	if _has_core(CoreType.POISON):
		p.apply_poison = true

# --- Dash ---

func _try_dash() -> void:
	if is_dashing or stamina < MIN_STAMINA_TO_START:
		return
	_dash_start_pos = global_position
	dash_direction = (get_global_mouse_position() - global_position).normalized()
	is_dashing = true

func _use_gravity_push() -> void:
	if not _has_perk("gravity_push") or _gravity_push_cooldown > 0.0:
		return
	_gravity_push_cooldown = 4.0
	var fx := load("res://scenes/fx/GravityPushFx.tscn") as PackedScene
	if fx:
		var inst := fx.instantiate()
		get_parent().add_child(inst)
		inst.global_position = global_position
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var push_dir: Vector2 = enemy.global_position - global_position
		if push_dir.length() <= 250.0:
			enemy.apply_knockback(push_dir.normalized() * 800.0, 1.0)

func _stop_dash() -> void:
	is_dashing = false
	if _has_core(CoreType.EXPLOSION):
		_spawn_dash_explosion()
	stamina_changed.emit(stamina, MAX_STAMINA)

func _dash_speed() -> float:
	return DASH_SPEED_CORE if _has_core(CoreType.DASH) else DASH_SPEED_BASE

func _stamina_drain() -> float:
	return STAMINA_DRAIN_CORE if _has_core(CoreType.DASH) else STAMINA_DRAIN_BASE

func _stamina_regen() -> float:
	return STAMINA_REGEN_CORE if _has_core(CoreType.DASH) else STAMINA_REGEN_BASE

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
	fire_bomb_cooldown_timer = _active_cooldown(FIRE_BOMB_COOLDOWN)

func _activate_phase() -> void:
	if _is_phasing or _phase_cooldown > 0.0:
		return
	_is_phasing = true
	_phase_timer = PHASE_DURATION
	_phase_cooldown = _active_cooldown(PHASE_COOLDOWN)
	_visual.modulate.a = 0.35

func _summon_ally() -> void:
	if _summon_cooldown > 0.0 or summon_ally_scene == null:
		return
	var ally = summon_ally_scene.instantiate()
	get_parent().add_child(ally)
	ally.global_position = global_position
	_summon_cooldown = _active_cooldown(SUMMON_COOLDOWN)

# --- Core Interaction ---

func _update_core_hint() -> void:
	if _core_hint == null:
		return
	# Hide while the swap UI is already open
	if get_tree().get_first_node_in_group("core_swap_ui") != null:
		_core_hint.visible = false
		return
	var has_nearby := false
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		if pickup.is_player_in_range(global_position):
			has_nearby = true
			break
	_core_hint.visible = has_nearby

func _try_interact_core() -> void:
	# Only one swap UI open at a time
	if get_tree().get_first_node_in_group("core_swap_ui") != null:
		return
	var nearby := _get_nearby_cores()
	if nearby.is_empty():
		return
	var packed := load("res://scenes/ui/CoreSwapUI.tscn") as PackedScene
	var ui := packed.instantiate()
	ui.add_to_group("core_swap_ui")
	ui.setup(nearby, self)
	get_parent().add_child(ui)

func _get_nearby_cores() -> Array:
	var result := []
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		if pickup.is_player_in_range(global_position):
			result.append(pickup)
	return result

func equip_core_to_slot(type: int, slot_index: int) -> void:
	core_slots[slot_index] = type
	cores_changed.emit(core_slots)
	if type == CoreType.SHIELD:
		_shield_active = true

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

func take_damage(amount: int, source: Node = null) -> void:
	if _is_phasing:
		return
	if GameState.shield_burst_timer > 0.0:
		return
	if _has_core(CoreType.SHIELD) and _shield_active:
		_shield_active = false
		_shield_recharge_timer = SHIELD_RECHARGE
		return
	# Iron Will: survive one killing blow per room at 1 HP
	if _has_perk("iron_will") and _iron_will_available and health - amount <= 0:
		health = 1
		_iron_will_available = false
		health_changed.emit(health, MAX_HEALTH)
		return
	var min_health := 1 if GameState.god_mode else 0
	health = max(min_health, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	# Thorns: reflect 50% of contact damage back to the attacker
	if source != null and is_instance_valid(source) and source.has_method("take_damage") and _has_perk("thorns"):
		source.take_damage(maxi(1, amount / 2))
	if health == 0:
		died.emit()

func heal(amount: int) -> void:
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

extends "res://scripts/enemies/base_enemy.gd"

const BEETLE_SPEED     = 70.0
const DETONATE_RANGE   = 30.0   # self-destructs when this close to the player
const EXPLOSION_RADIUS = 80.0   # blast radius for player damage
const EXPLOSION_DAMAGE = 70

@onready var _visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	super()
	max_health = 45
	health     = 45
	drop_core_type = 5  # EXPLOSION

func _ai_update(_delta: float) -> void:
	velocity = _dir_to_player() * BEETLE_SPEED

	# Self-destruct when close enough — triggers _on_death() -> _explode()
	if _dist_to_player() < DETONATE_RANGE:
		take_damage(max_health)
		return

	# Rotate sprite to face movement direction. Sprite faces up at rotation 0.
	if _visual != null and velocity.length_squared() > 0.0:
		var dir := velocity.normalized()
		if abs(dir.x) >= abs(dir.y):
			_visual.rotation = PI * 0.5 if dir.x > 0.0 else -PI * 0.5
		else:
			_visual.rotation = 0.0 if dir.y < 0.0 else PI

func _on_death() -> void:
	_explode()
	super()

func _explode() -> void:
	var spawn_parent := get_parent()
	var origin      := global_position

	# --- Expanding ring (reuse DeathBurstFx, scaled up) ---
	var ring_scene := load("res://scenes/fx/DeathBurstFx.tscn") as PackedScene
	if ring_scene:
		var ring := ring_scene.instantiate()
		spawn_parent.add_child(ring)
		ring.global_position = origin
		ring.scale           = Vector2(2.2, 2.2)

	# --- Particle burst ---
	var sparks := CPUParticles2D.new()
	sparks.emitting                = true
	sparks.one_shot                = true
	sparks.explosiveness           = 1.0
	sparks.amount                  = 40
	sparks.lifetime                = 0.55
	sparks.emission_shape          = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius  = 6.0
	sparks.direction               = Vector2(0.0, -1.0)
	sparks.spread                  = 180.0
	sparks.gravity                 = Vector2.ZERO
	sparks.initial_velocity_min    = 90.0
	sparks.initial_velocity_max    = 220.0
	sparks.scale_amount_min        = 2.0
	sparks.scale_amount_max        = 5.0
	sparks.color                   = Color(1.0, 0.55, 0.05, 1.0)
	spawn_parent.add_child(sparks)
	sparks.global_position = origin
	sparks.finished.connect(sparks.queue_free)

	# --- Damage player if within blast radius ---
	if player == null or not is_instance_valid(player):
		return
	if origin.distance_to(player.global_position) <= EXPLOSION_RADIUS:
		player.take_damage(EXPLOSION_DAMAGE)

extends Node2D

# Expanding shockwave rings drawn around the player on Gravity Push dash.

const PUSH_RADIUS := 250.0   # matches the push range in player.gd
const DURATION    := 0.45

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p      := _t / DURATION               # 0 → 1
	var ease_p := 1.0 - pow(1.0 - p, 2.5)    # ease-out power curve

	# Three staggered rings — each offset in time so they ripple outward
	_draw_ring(ease_p,          1.00)   # leading ring — fully visible
	_draw_ring(maxf(0.0, ease_p - 0.18), 0.60)   # mid ring
	_draw_ring(maxf(0.0, ease_p - 0.36), 0.35)   # trailing ring

	# 12 radial spikes pointing outward
	var spike_radius := PUSH_RADIUS * ease_p
	var alpha_spikes := (1.0 - p) * 0.85
	for i in 12:
		var angle   := TAU * i / 12.0
		var dir     := Vector2(cos(angle), sin(angle))
		var inner   := dir * spike_radius * 0.72
		var outer   := dir * (spike_radius + 18.0 * (1.0 - p))
		draw_line(inner, outer, Color(0.65, 0.85, 1.0, alpha_spikes), 2.0)

func _draw_ring(progress: float, opacity_scale: float) -> void:
	if progress <= 0.0:
		return
	var radius := PUSH_RADIUS * progress
	var alpha  := (1.0 - progress) * opacity_scale

	# Outer bright rim
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64,
		Color(0.75, 0.92, 1.0, alpha), 3.5)
	# Inner soft glow ring
	draw_arc(Vector2.ZERO, radius * 0.88, 0.0, TAU, 64,
		Color(0.45, 0.65, 1.0, alpha * 0.5), 1.5)

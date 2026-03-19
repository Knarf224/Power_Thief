extends Node2D

# Expanding ring + glow drawn procedurally — no child nodes required.

const BURST_RADIUS := 60.0
const DURATION     := 0.40

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p := _t / DURATION          # 0.0 → 1.0
	var ease_p := 1.0 - pow(1.0 - p, 2.0)   # ease-out quad

	var radius      := BURST_RADIUS * ease_p
	var alpha_outer := 1.0 - p               # fades as it expands
	var alpha_inner := (1.0 - p) * 0.4      # softer inner glow

	# Inner filled glow — orange-red core
	draw_circle(Vector2.ZERO, radius * 0.55,
		Color(1.0, 0.35, 0.05, alpha_inner))

	# Mid ring — bright orange
	draw_arc(Vector2.ZERO, radius * 0.75, 0.0, TAU, 48,
		Color(1.0, 0.65, 0.1, alpha_outer * 0.7), 2.5)

	# Outer ring — sharp bright edge
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48,
		Color(1.0, 0.88, 0.4, alpha_outer), 3.5)

	# Small radiating spikes at 8 evenly spaced angles
	var spike_count := 8
	for i in spike_count:
		var angle := TAU * i / spike_count
		var inner_pt := Vector2(cos(angle), sin(angle)) * radius * 0.85
		var outer_pt := Vector2(cos(angle), sin(angle)) * (radius + 10.0 * alpha_outer)
		draw_line(inner_pt, outer_pt,
			Color(1.0, 0.95, 0.6, alpha_outer * 0.9), 2.0)

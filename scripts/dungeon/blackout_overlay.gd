extends Node2D
# BlackoutOverlay — drop into any room as a child node.
# Rolls activation_chance on ready. If it activates, runs the full blackout
# cycle independently. The room only needs to call deactivate() when combat ends.
#
# Usage in a room's _ready():
#   _blackout = preload("res://scripts/dungeon/blackout_overlay.gd").new()
#   _blackout.activation_chance = 0.35   # optional override
#   add_child(_blackout)
#
# Usage when room is cleared:
#   _blackout.deactivate()

const OVERLAY_COLOR  := Color(0.00, 0.00, 0.02, 0.97)
const CIRCLE_POINTS  := 56

const LIT_DURATION_BASE  := 6.0
const LIT_DURATION_MIN   := 3.0
const DARK_DURATION_BASE := 3.5
const DARK_DURATION_MAX  := 7.0
const FADE_SPEED         := 2.2

const LIGHT_RADIUS_START := 180.0
const LIGHT_RADIUS_MIN   := 80.0
const LIGHT_RADIUS_STEP  := 15.0

# Base chance used only as a floor — overridden at runtime by depth scaling.
# Room scripts can still set this; it becomes the minimum, not the final value.
var activation_chance := 0.50

var _active        := false
var _is_dark       := false
var _phase_timer   := 0.0
var _lit_duration  := LIT_DURATION_BASE
var _dark_duration := DARK_DURATION_BASE
var _overlay_alpha := 0.0
var _light_radius  := LIGHT_RADIUS_START
var _overlay       : Polygon2D
var _player        : Node2D


func _ready() -> void:
	if GameState.room_counter < 3:
		return  # blackout never triggers in the first 3 rooms

	# Scale chance with depth: +5% per room beyond room 4, capped at 100%.
	# room 4  (counter=3):  50%
	# room 6  (counter=5):  60%
	# room 10 (counter=9):  80%
	# room 14 (counter=13): 100% — guaranteed from here on
	var depth_chance := clampf(0.50 + (GameState.room_counter - 3) * 0.05, activation_chance, 1.00)
	if randf() > depth_chance:
		return  # room stays fully lit — overlay never created

	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var rooms      := GameState.room_counter
	_lit_duration   = maxf(LIT_DURATION_MIN,  LIT_DURATION_BASE  - rooms * 0.08)
	_dark_duration  = minf(DARK_DURATION_MAX, DARK_DURATION_BASE + rooms * 0.07)
	_light_radius   = maxf(LIGHT_RADIUS_MIN,  LIGHT_RADIUS_START - rooms * 4.0)

	_overlay                = Polygon2D.new()
	_overlay.color          = Color(OVERLAY_COLOR.r, OVERLAY_COLOR.g, OVERLAY_COLOR.b, 0.0)
	_overlay.invert_enabled = true
	_overlay.invert_border  = 6000.0
	_overlay.z_index        = 100
	_overlay.polygon        = _make_circle(_player.global_position, _light_radius)
	_overlay.visible        = false
	add_child(_overlay)

	_active = true


func _process(delta: float) -> void:
	if not _active or not is_instance_valid(_player):
		return

	_phase_timer += delta

	if not _is_dark:
		_overlay_alpha = move_toward(_overlay_alpha, 0.0, delta * FADE_SPEED)
		if _phase_timer >= _lit_duration:
			_is_dark     = true
			_phase_timer = 0.0
	else:
		_overlay_alpha = move_toward(_overlay_alpha, OVERLAY_COLOR.a, delta * FADE_SPEED)
		if _phase_timer >= _dark_duration:
			_is_dark      = false
			_phase_timer  = 0.0
			_light_radius = maxf(LIGHT_RADIUS_MIN, _light_radius - LIGHT_RADIUS_STEP)

	if _overlay_alpha <= 0.005:
		_overlay.visible = false
	else:
		_overlay.visible = true
		_overlay.color   = Color(OVERLAY_COLOR.r, OVERLAY_COLOR.g, OVERLAY_COLOR.b, _overlay_alpha)
		_overlay.polygon = _make_circle(_player.global_position, _light_radius)


func deactivate() -> void:
	_active = false
	if _overlay != null:
		_overlay.visible = false


func _make_circle(center: Vector2, radius: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in CIRCLE_POINTS:
		var angle := (TAU / CIRCLE_POINTS) * i
		verts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return verts

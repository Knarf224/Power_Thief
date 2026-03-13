extends CanvasLayer

const BAR_MAX_WIDTH = 200.0

const CORE_COLORS = {
	0: Color(0.2, 0.2, 0.2, 1),    # empty
	1: Color(0.5, 0.3, 0.9, 1),    # DASH      - purple
	2: Color(1.0, 0.35, 0.05, 1),  # FIRE      - orange
	3: Color(0.2, 0.85, 0.2, 1),   # SPLIT     - green
	4: Color(0.85, 0.85, 0.95, 1), # PHASE     - white
	5: Color(0.6, 0.35, 0.05, 1),  # EXPLOSION - brown
	6: Color(0.1, 0.75, 0.9, 1),   # ICE       - cyan
	7: Color(1.0, 0.9, 0.1, 1),    # LIGHTNING - yellow
	8: Color(0.55, 0.55, 0.55, 1), # SHIELD    - gray
	9: Color(0.3, 0.05, 0.4, 1),   # SUMMON    - dark purple
	10: Color(0.45, 0.8, 0.1, 1),  # POISON    - yellow-green
}

@onready var fill: ColorRect = $HealthBarFill
@onready var slot_star_1: Polygon2D = $SlotStar1
@onready var slot_star_2: Polygon2D = $SlotStar2
@onready var slot_star_3: Polygon2D = $SlotStar3
@onready var transition_prompt: Label = $TransitionPrompt
@onready var you_died_overlay: ColorRect = $YouDiedOverlay
@onready var you_died_title: Label = $YouDiedTitle
@onready var you_died_prompt: Label = $YouDiedPrompt

var _player_dead := false

func update_health(current: int, maximum: int) -> void:
	fill.size.x = BAR_MAX_WIDTH * (float(current) / float(maximum))

func update_cores(slots: Array) -> void:
	slot_star_1.color = CORE_COLORS.get(slots[0], CORE_COLORS[0])
	slot_star_2.color = CORE_COLORS.get(slots[1], CORE_COLORS[0])
	slot_star_3.color = CORE_COLORS.get(slots[2], CORE_COLORS[0])

func show_transition_prompt() -> void:
	transition_prompt.visible = true

func hide_transition_prompt() -> void:
	transition_prompt.visible = false

func show_you_died() -> void:
	_player_dead = true
	you_died_overlay.visible = true
	you_died_title.visible = true
	you_died_prompt.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_dead:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		GameState.player_health = 100
		GameState.player_cores = [0, 0, 0]
		GameState.exit_direction = ""
		GameState.room_counter = 0
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

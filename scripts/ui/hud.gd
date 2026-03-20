extends CanvasLayer

const BAR_MAX_WIDTH = 200.0

const PERK_SYMBOLS: Dictionary = {
	"auto_fire":      "∞",
	"rapid_fire":     "≫",
	"stopping_power": "✦",
	"piercing_shot":  "⇒",
	"thorns":         "※",
	"life_steal":     "♥",
	"death_burst":    "✸",
	"berserker":      "⚡",
	"iron_will":      "◆",
	"overclock":      "⊙",
	"gravity_push":   "⊕",
}

const PERK_NAMES: Dictionary = {
	"auto_fire":      "Auto-Fire",
	"stopping_power": "Stopping Power",
	"gravity_push":   "Gravity Push",
	"life_steal":     "Life Steal",
	"piercing_shot":  "Piercing Shot",
	"rapid_fire":     "Rapid Fire",
	"thorns":         "Thorns",
	"death_burst":    "Death Burst",
	"berserker":      "Berserker",
	"iron_will":      "Iron Will",
	"overclock":      "Overclock",
}

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
var _insta_kill_label: Label
@onready var stamina_fill: ColorRect = $StaminaBarFill
@onready var slot_star_1: Polygon2D = $SlotStar1
@onready var slot_star_2: Polygon2D = $SlotStar2
@onready var slot_star_3: Polygon2D = $SlotStar3
@onready var transition_prompt: Label = $TransitionPrompt
@onready var you_died_overlay: ColorRect = $YouDiedOverlay
@onready var you_died_title: Label = $YouDiedTitle
@onready var you_died_prompt: Label = $YouDiedPrompt
@onready var level_label: Label = $LevelLabel
@onready var perks_label: Label = $PerksLabel

var _player_dead := false
var _paused      := false
var _pause_panel: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_level_label()
	GameState.perks_changed.connect(_refresh_perks)
	_refresh_perks()
	_pause_panel = _build_pause_panel()
	add_child(_pause_panel)
	_insta_kill_label = _build_insta_kill_label()
	add_child(_insta_kill_label)

func _process(_delta: float) -> void:
	_insta_kill_label.visible = GameState.insta_kill_timer > 0.0
	if _insta_kill_label.visible:
		_insta_kill_label.text = "☠  INSTA KILL  %ds" % ceili(GameState.insta_kill_timer)

func _build_insta_kill_label() -> Label:
	var lbl := Label.new()
	lbl.anchor_left   = 0.5
	lbl.anchor_right  = 0.5
	lbl.anchor_top    = 0.0
	lbl.anchor_bottom = 0.0
	lbl.offset_left   = -120
	lbl.offset_right  = 120
	lbl.offset_top    = 8
	lbl.offset_bottom = 40
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	lbl.visible = false
	return lbl

func _refresh_level_label() -> void:
	if GameState.endless_mode:
		level_label.text = "ENDLESS: %d" % (GameState.room_counter + 1)
		level_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.55))
	else:
		level_label.text = "LEVEL: %d" % (GameState.room_counter + 1)

func _refresh_perks() -> void:
	var lines: PackedStringArray = []
	for perk_id: String in GameState.player_perks:
		var sym: String = PERK_SYMBOLS[perk_id] if PERK_SYMBOLS.has(perk_id) else "?"
		var name: String = PERK_NAMES[perk_id] if PERK_NAMES.has(perk_id) else perk_id
		lines.append(sym + "  " + name)
	perks_label.text = "\n".join(lines)

func update_health(current: int, maximum: int) -> void:
	fill.size.x = BAR_MAX_WIDTH * (float(current) / float(maximum))

func update_stamina(current: float, maximum: float) -> void:
	stamina_fill.size.x = BAR_MAX_WIDTH * (current / maximum)

func update_cores(slots: Array) -> void:
	slot_star_1.color = CORE_COLORS[slots[0]] if CORE_COLORS.has(slots[0]) else CORE_COLORS[0]
	slot_star_2.color = CORE_COLORS[slots[1]] if CORE_COLORS.has(slots[1]) else CORE_COLORS[0]
	slot_star_3.color = CORE_COLORS[slots[2]] if CORE_COLORS.has(slots[2]) else CORE_COLORS[0]

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
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_ESCAPE and not _player_dead:
		if _paused:
			_resume()
		elif not get_tree().paused:
			_pause()
		get_viewport().set_input_as_handled()

	elif event.keycode == KEY_R and _player_dead:
		_do_restart()


func _pause() -> void:
	_paused = true
	_pause_panel.visible = true
	get_tree().paused = true


func _resume() -> void:
	_paused = false
	_pause_panel.visible = false
	get_tree().paused = false


func _do_restart() -> void:
	get_tree().paused = false
	GameState.player_health            = 100
	GameState.player_cores             = [0, 0, 0]
	GameState.player_perks             = []
	GameState.exit_direction           = ""
	GameState.room_counter             = 0
	GameState.hardcore_mode            = false
	GameState.endless_mode             = false
	GameState.pending_win_screen       = false
	GameState.boss_defeated_this_level = false
	GameState.reset_boss_pool()
	get_tree().change_scene_to_file("res://scenes/ui/HomeScreen.tscn")


func _build_pause_panel() -> Control:
	var root := Control.new()
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.anchor_right  = 1.0
	root.anchor_bottom = 1.0
	root.visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)

	var center := CenterContainer.new()
	center.anchor_right  = 1.0
	center.anchor_bottom = 1.0
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(420, 0)
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.88, 0.82, 1.00))
	vbox.add_child(title)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(gap)

	vbox.add_child(_make_pause_volume_row())
	vbox.add_child(_make_pause_btn("RESUME",  func(): _resume()))
	vbox.add_child(_make_pause_btn("RESTART", func(): _do_restart()))

	return root


func _make_pause_btn(label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.text = label
	btn.custom_minimum_size = Vector2(420, 58)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color",         Color(0.78, 0.74, 0.95))
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.10, 0.16)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.16, 0.28)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	btn.pressed.connect(callback)
	return btn


func _make_pause_volume_row() -> Control:
	var row := HBoxContainer.new()
	row.process_mode = Node.PROCESS_MODE_ALWAYS
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.process_mode = Node.PROCESS_MODE_ALWAYS
	lbl.text = "MUSIC VOLUME"
	lbl.custom_minimum_size = Vector2(180, 0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.95))
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.process_mode          = Node.PROCESS_MODE_ALWAYS
	slider.min_value             = 0.0
	slider.max_value             = 100.0
	slider.step                  = 1.0
	slider.value                 = MusicManager.volume * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, 20)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.process_mode          = Node.PROCESS_MODE_ALWAYS
	val_lbl.custom_minimum_size   = Vector2(52, 0)
	val_lbl.text                  = "%d%%" % int(MusicManager.volume * 100.0)
	val_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.95))
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float):
		MusicManager.set_volume(v / 100.0)
		val_lbl.text = "%d%%" % int(v)
	)

	return row

extends Control

const BG_COLOR     := Color(0.04, 0.04, 0.07)
const TITLE_COLOR  := Color(0.88, 0.82, 1.00)
const BTN_NORMAL   := Color(0.10, 0.10, 0.16)
const BTN_HOVER    := Color(0.18, 0.16, 0.28)
const BTN_TEXT     := Color(0.78, 0.74, 0.95)
const HC_NORMAL    := Color(0.45, 0.06, 0.06)
const HC_HOVER     := Color(0.60, 0.10, 0.10)

var _hardcore_btn: Button
var _settings_panel: Control
var _account_btn: Button


func _ready() -> void:
	PlayerAuth.auth_changed.connect(_on_auth_changed)
	MusicManager.play_home_screen()
	# Fill the entire window
	anchor_right  = 1.0
	anchor_bottom = 1.0

	# Background
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Main layout — centered column
	var center := CenterContainer.new()
	center.anchor_right  = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(420, 0)
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "POWER THIEF"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "steal their power. survive."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.50, 0.46, 0.62))
	vbox.add_child(sub)

	# Gap
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(gap)

	# Start Game
	var start_btn := _make_button("START GAME", BTN_NORMAL, BTN_HOVER)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	# Account / Log In
	_account_btn = _make_button(_account_label(), BTN_NORMAL, BTN_HOVER)
	_account_btn.pressed.connect(_on_account_pressed)
	_refresh_account_btn()
	vbox.add_child(_account_btn)

	# Almanac
	var almanac_btn := _make_button("TRACKER", BTN_NORMAL, BTN_HOVER)
	almanac_btn.pressed.connect(_on_almanac_pressed)
	vbox.add_child(almanac_btn)

	# Leaderboard
	var leaderboard_btn := _make_button("LEADERBOARD", BTN_NORMAL, BTN_HOVER)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)
	vbox.add_child(leaderboard_btn)

	# Settings
	var settings_btn := _make_button("SETTINGS", BTN_NORMAL, BTN_HOVER)
	settings_btn.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_btn)

	# Hardcore Mode toggle
	_hardcore_btn = _make_button(_hardcore_label(), BTN_NORMAL, BTN_HOVER)
	_hardcore_btn.pressed.connect(_on_hardcore_pressed)
	_refresh_hardcore_btn()
	vbox.add_child(_hardcore_btn)

	# Settings overlay (hidden until Settings is pressed)
	_settings_panel = _build_settings_panel()
	add_child(_settings_panel)
	_settings_panel.visible = false


# --- Button factory ---

func _make_button(label: String, normal_color: Color, hover_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(420, 58)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	_apply_btn_style(btn, normal_color, hover_color)
	return btn


func _apply_btn_style(btn: Button, normal_color: Color, hover_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)

	# Remove focus box so there's no ugly dotted border
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


# --- Settings panel ---

func _build_settings_panel() -> Control:
	var root := Control.new()
	root.anchor_right  = 1.0
	root.anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.09, 0.97)
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
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	vbox.add_child(_make_volume_row())

	var back_btn := _make_button("BACK", BTN_NORMAL, BTN_HOVER)
	back_btn.pressed.connect(func(): root.visible = false)
	vbox.add_child(back_btn)

	return root


# --- Volume row (shared by settings panel) ---

func _make_volume_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = "MUSIC VOLUME"
	lbl.custom_minimum_size = Vector2(180, 0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", BTN_TEXT)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step      = 1.0
	slider.value     = MusicManager.volume * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, 20)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size    = Vector2(52, 0)
	val_lbl.text                   = "%d%%" % int(MusicManager.volume * 100.0)
	val_lbl.horizontal_alignment   = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_color_override("font_color", BTN_TEXT)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float):
		MusicManager.set_volume(v / 100.0)
		val_lbl.text = "%d%%" % int(v)
	)

	return row


# --- Hardcore helpers ---

func _hardcore_label() -> String:
	return "HARDCORE MODE:  ON" if GameState.hardcore_mode else "HARDCORE MODE:  OFF"


func _refresh_hardcore_btn() -> void:
	_hardcore_btn.text = _hardcore_label()
	if GameState.hardcore_mode:
		_apply_btn_style(_hardcore_btn, HC_NORMAL, HC_HOVER)
		_hardcore_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	else:
		_apply_btn_style(_hardcore_btn, BTN_NORMAL, BTN_HOVER)
		_hardcore_btn.add_theme_color_override("font_color", BTN_TEXT)


# --- Button callbacks ---

func _on_start_pressed() -> void:
	GameState.player_health            = 1 if GameState.hardcore_mode else 100
	GameState.player_cores             = [0, 0, 0]
	GameState.player_perks             = []
	GameState.exit_direction           = ""
	GameState.room_counter             = 0
	GameState.endless_mode             = false
	GameState.pending_win_screen       = false
	GameState.boss_defeated_this_level = false
	GameState.reset_boss_pool()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_settings_pressed() -> void:
	_settings_panel.visible = true


func _on_hardcore_pressed() -> void:
	GameState.hardcore_mode = not GameState.hardcore_mode
	_refresh_hardcore_btn()


# --- Account helpers ---

func _account_label() -> String:
	if PlayerAuth.is_logged_in():
		return "ACCOUNT:  " + PlayerAuth.username.to_upper()
	return "LOG IN / REGISTER"


func _refresh_account_btn() -> void:
	_account_btn.text = _account_label()
	if PlayerAuth.is_logged_in():
		_apply_btn_style(_account_btn, Color(0.07, 0.14, 0.24), Color(0.11, 0.21, 0.35))
		_account_btn.add_theme_color_override("font_color", Color(0.55, 0.85, 1.00))
	else:
		_apply_btn_style(_account_btn, BTN_NORMAL, BTN_HOVER)
		_account_btn.add_theme_color_override("font_color", BTN_TEXT)


func _on_auth_changed(_logged_in: bool) -> void:
	_refresh_account_btn()


func _on_account_pressed() -> void:
	var screen: Node = load("res://scripts/ui/login_screen.gd").new()
	get_tree().root.add_child(screen)


func _on_almanac_pressed() -> void:
	var screen: Node = load("res://scripts/ui/almanac_screen.gd").new()
	get_tree().root.add_child(screen)


func _on_leaderboard_pressed() -> void:
	var screen: Node = load("res://scripts/ui/leaderboard_screen.gd").new()
	get_tree().root.add_child(screen)

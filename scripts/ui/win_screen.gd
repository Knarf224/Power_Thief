extends CanvasLayer

const BG_COLOR       := Color(0.04, 0.04, 0.07, 0.96)
const GOLD           := Color(1.0, 0.88, 0.25)
const BTN_NORMAL     := Color(0.10, 0.10, 0.16)
const BTN_HOVER      := Color(0.18, 0.16, 0.28)
const BTN_TEXT       := Color(0.78, 0.74, 0.95)
const ENDLESS_NORMAL := Color(0.08, 0.26, 0.10)
const ENDLESS_HOVER  := Color(0.12, 0.40, 0.15)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	get_tree().paused = true
	Tracker.on_win()
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(480, 0)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "YOU WON!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", GOLD)
	vbox.add_child(title)

	# Flavour subtitle
	var sub := Label.new()
	sub.text = "All 5 bosses defeated.\nThe power is yours."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	# Spacer
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(gap)

	# Endless Mode button
	var endless_btn := _make_button("ENDLESS MODE", ENDLESS_NORMAL, ENDLESS_HOVER)
	endless_btn.add_theme_color_override("font_color", Color(0.55, 1.0, 0.60))
	endless_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	endless_btn.pressed.connect(_on_endless_pressed)
	vbox.add_child(endless_btn)

	var endless_note := Label.new()
	endless_note.text = "Keep fighting — only the enemy count grows."
	endless_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_note.add_theme_font_size_override("font_size", 13)
	endless_note.add_theme_color_override("font_color", Color(0.42, 0.65, 0.44))
	vbox.add_child(endless_note)

	# Main Menu button
	var menu_btn := _make_button("MAIN MENU", BTN_NORMAL, BTN_HOVER)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)


func _make_button(label: String, normal_color: Color, hover_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(480, 64)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	return btn


func _on_endless_pressed() -> void:
	GameState.endless_mode = true
	get_tree().paused = false
	queue_free()


func _on_menu_pressed() -> void:
	Tracker.on_menu_from_win()
	get_tree().paused = false
	GameState.player_health      = 100
	GameState.player_cores       = [0, 0, 0]
	GameState.player_perks       = []
	GameState.exit_direction     = ""
	GameState.room_counter       = 0
	GameState.hardcore_mode      = false
	GameState.endless_mode       = false
	GameState.pending_win_screen = false
	GameState.reset_boss_pool()
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/HomeScreen.tscn")

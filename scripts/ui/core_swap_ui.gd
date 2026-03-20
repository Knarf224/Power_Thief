extends CanvasLayer

const CORE_COLORS = {
	0:  Color(0.25, 0.25, 0.30, 1),
	1:  Color(0.5,  0.3,  0.9,  1),   # DASH      - purple
	2:  Color(1.0,  0.35, 0.05, 1),   # FIRE      - orange
	3:  Color(0.2,  0.85, 0.2,  1),   # SPLIT     - green
	4:  Color(0.85, 0.85, 0.95, 1),   # PHASE     - white
	5:  Color(0.6,  0.35, 0.05, 1),   # EXPLOSION - brown
	6:  Color(0.1,  0.75, 0.9,  1),   # ICE       - cyan
	7:  Color(1.0,  0.9,  0.1,  1),   # LIGHTNING - yellow
	8:  Color(0.55, 0.55, 0.55, 1),   # SHIELD    - gray
	9:  Color(0.3,  0.05, 0.4,  1),   # SUMMON    - dark purple
	10: Color(0.45, 0.8,  0.1,  1),   # POISON    - yellow-green
}

const CORE_NAMES = {
	0:  "Empty",
	1:  "Dash",
	2:  "Fire",
	3:  "Split",
	4:  "Phase",
	5:  "Explosion",
	6:  "Ice",
	7:  "Lightning",
	8:  "Shield",
	9:  "Summon",
	10: "Poison",
}

var _nearby_cores: Array = []
var _player = null
var _selected_core_type := -1
var _from_multi_step    := false   # true if we came from the core-picker step
var _content: VBoxContainer


func setup(nearby_cores: Array, player_node) -> void:
	_nearby_cores = nearby_cores
	_player       = player_node


func _ready() -> void:
	layer = 5
	_build_panel()
	if _nearby_cores.size() == 1:
		_show_slot_step(_nearby_cores[0].core_type, false)
	else:
		_show_core_step()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()


func _build_panel() -> void:
	# Anchored to bottom-centre of the viewport
	var panel := PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -310
	panel.offset_right  = 310
	panel.offset_top    = -275
	panel.offset_bottom = -20

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.10, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	panel.add_child(_content)


# ---------------------------------------------------------------------------
# Step 1 — pick which core (only shown when 2+ cores are nearby)
# ---------------------------------------------------------------------------
func _show_core_step() -> void:
	_clear_content()
	_selected_core_type = -1

	_add_title("PICK UP CORE", Color(1.0, 0.88, 0.25))
	_add_subtitle("Choose which core to take")

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	_content.add_child(hbox)

	for pickup in _nearby_cores:
		var ctype: int = pickup.core_type
		var btn := _make_core_btn(ctype)
		btn.pressed.connect(func(): _show_slot_step(ctype, true))
		hbox.add_child(btn)

	var cancel := _make_cancel_btn("CANCEL")
	cancel.pressed.connect(func(): queue_free())
	_content.add_child(cancel)


# ---------------------------------------------------------------------------
# Step 2 — pick which slot to place the chosen core into
# ---------------------------------------------------------------------------
func _show_slot_step(core_type: int, from_multi: bool) -> void:
	_selected_core_type = core_type
	_from_multi_step    = from_multi
	_clear_content()

	var col: Color = CORE_COLORS[core_type] if CORE_COLORS.has(core_type) else Color.WHITE
	var col_name: String = CORE_NAMES[core_type] if CORE_NAMES.has(core_type) else "?"
	_add_title("PLACE  %s CORE" % col_name, col)
	_add_subtitle("Choose a slot to replace  (1 / 2 / 3)")

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	_content.add_child(hbox)

	var slots: Array = _player.core_slots
	for i in 3:
		var btn := _make_slot_btn(i, slots[i], core_type)
		var idx := i
		btn.pressed.connect(func(): _confirm_slot(idx))
		hbox.add_child(btn)

	# Cancel goes back to core picker if we came from there, else closes
	var cancel_label := "← BACK" if _from_multi_step else "CANCEL"
	var cancel := _make_cancel_btn(cancel_label)
	if _from_multi_step:
		cancel.pressed.connect(func(): _show_core_step())
	else:
		cancel.pressed.connect(func(): queue_free())
	_content.add_child(cancel)


# ---------------------------------------------------------------------------
# Confirm — equip the core, free all pickups, close UI
# ---------------------------------------------------------------------------
func _confirm_slot(slot_index: int) -> void:
	_player.equip_core_to_slot(_selected_core_type, slot_index)
	# Free every core in the room (one-per-room rule)
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		pickup.queue_free()
	queue_free()


# ---------------------------------------------------------------------------
# Widget helpers
# ---------------------------------------------------------------------------
func _clear_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()  # deferred — never free a node mid-signal dispatch


func _add_title(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	_content.add_child(lbl)


func _add_subtitle(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	_content.add_child(lbl)


func _make_core_btn(core_type: int) -> Button:
	var color: Color = CORE_COLORS[core_type] if CORE_COLORS.has(core_type) else Color.WHITE
	var name_text: String = CORE_NAMES[core_type] if CORE_NAMES.has(core_type) else "?"

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 80)
	btn.text = "●\n%s" % name_text
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color",        color)
	btn.add_theme_color_override("font_hover_color",  Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r * 0.12, color.g * 0.12, color.b * 0.12, 1.0)
	normal.border_color = color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(color.r * 0.28, color.g * 0.28, color.b * 0.28, 1.0)
	hover.border_color = color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	return btn


func _make_slot_btn(slot_index: int, current_type: int, incoming_type: int) -> Button:
	var inc_color: Color = CORE_COLORS[incoming_type] if CORE_COLORS.has(incoming_type) else Color.WHITE
	var cur_name: String = CORE_NAMES[current_type] if CORE_NAMES.has(current_type) else "Empty"
	var inc_name: String = CORE_NAMES[incoming_type] if CORE_NAMES.has(incoming_type) else "?"

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(158, 100)
	btn.text = "SLOT %d\n%s\n→  %s" % [slot_index + 1, cur_name, inc_name]
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color",        Color(0.85, 0.85, 0.85))
	btn.add_theme_color_override("font_hover_color",  Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color     = Color(0.10, 0.10, 0.16, 1.0)
	normal.border_color = inc_color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(
		inc_color.r * 0.22, inc_color.g * 0.22, inc_color.b * 0.22, 1.0)
	hover.border_color = inc_color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	return btn


func _make_cancel_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(110, 38)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color",       Color(0.55, 0.55, 0.55))
	btn.add_theme_color_override("font_hover_color", Color(0.85, 0.85, 0.85))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.08, 0.12)
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.14, 0.14, 0.20)
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	return btn

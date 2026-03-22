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
var _from_multi_step    := false
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
	var panel := PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -320
	panel.offset_right  = 320
	panel.offset_top    = -290
	panel.offset_bottom = -20

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.10, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
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
	_add_title("EQUIP  %s  CORE" % col_name.to_upper(), col)
	_add_subtitle("Choose a slot to place it in")

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
	for pickup in get_tree().get_nodes_in_group("core_pickup"):
		pickup.queue_free()
	queue_free()


# ---------------------------------------------------------------------------
# Widget helpers
# ---------------------------------------------------------------------------
func _clear_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


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
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_content.add_child(lbl)


func _make_star_control(size: float, color: Color) -> Control:
	var lbl := Label.new()
	lbl.text = "★"
	lbl.add_theme_font_size_override("font_size", int(size * 1.1))
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size  = Vector2(size, size)
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


# ---------------------------------------------------------------------------
# Step 1 button — shows one available core to pick up
# ---------------------------------------------------------------------------
func _make_core_btn(core_type: int) -> Button:
	var color: Color = CORE_COLORS[core_type] if CORE_COLORS.has(core_type) else Color.WHITE
	var name_text: String = CORE_NAMES[core_type] if CORE_NAMES.has(core_type) else "?"

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 90)
	btn.text = ""

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

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var star := _make_star_control(32.0, color)
	vbox.add_child(star)

	var lbl := Label.new()
	lbl.text = name_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)

	return btn


# ---------------------------------------------------------------------------
# Step 2 button — shows one equipment slot with current vs incoming core
# ---------------------------------------------------------------------------
func _make_slot_btn(slot_index: int, current_type: int, incoming_type: int) -> Button:
	var inc_color: Color = CORE_COLORS[incoming_type] if CORE_COLORS.has(incoming_type) else Color.WHITE
	var cur_color: Color = CORE_COLORS[current_type]  if CORE_COLORS.has(current_type)  else CORE_COLORS[0]
	var cur_name: String = CORE_NAMES[current_type]   if CORE_NAMES.has(current_type)   else "Empty"

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 130)
	btn.text = ""

	var normal := StyleBoxFlat.new()
	normal.bg_color     = Color(inc_color.r * 0.08, inc_color.g * 0.08, inc_color.b * 0.08, 1.0)
	normal.border_color = inc_color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(inc_color.r * 0.24, inc_color.g * 0.24, inc_color.b * 0.24, 1.0)
	hover.border_color = inc_color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Slot number
	var slot_lbl := Label.new()
	slot_lbl.text = "SLOT  %d" % (slot_index + 1)
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_size_override("font_size", 11)
	slot_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	slot_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(slot_lbl)

	# ── Currently equipped (muted, top section) ──────────────────────────────
	var cur_row := HBoxContainer.new()
	cur_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cur_row.add_theme_constant_override("separation", 5)
	cur_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cur_row)

	var cur_star := _make_star_control(16.0, Color(cur_color.r * 0.55, cur_color.g * 0.55, cur_color.b * 0.55))
	cur_row.add_child(cur_star)

	var cur_lbl := Label.new()
	cur_lbl.text = cur_name
	cur_lbl.add_theme_font_size_override("font_size", 12)
	cur_lbl.add_theme_color_override("font_color", Color(cur_color.r * 0.55, cur_color.g * 0.55, cur_color.b * 0.55))
	cur_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cur_row.add_child(cur_lbl)

	# Arrow
	var arrow := Label.new()
	arrow.text = "v"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 11)
	arrow.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(arrow)

	# ── Incoming core (bright, prominent) ────────────────────────────────────
	var inc_star := _make_star_control(36.0, inc_color)
	vbox.add_child(inc_star)

	var inc_lbl := Label.new()
	inc_lbl.text = CORE_NAMES[incoming_type] if CORE_NAMES.has(incoming_type) else "?"
	inc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inc_lbl.add_theme_font_size_override("font_size", 14)
	inc_lbl.add_theme_color_override("font_color", inc_color)
	inc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(inc_lbl)

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

extends CanvasLayer

# Fetches and displays the global top-20 high scores.

const BG_COLOR    := Color(0.04, 0.04, 0.08, 0.97)
const TITLE_COLOR := Color(0.88, 0.82, 1.00)
const BTN_NORMAL  := Color(0.10, 0.10, 0.16)
const BTN_HOVER   := Color(0.18, 0.16, 0.28)
const BTN_TEXT    := Color(0.78, 0.74, 0.95)
const GOLD        := Color(1.00, 0.88, 0.25)
const SILVER      := Color(0.78, 0.78, 0.82)
const BRONZE      := Color(0.80, 0.55, 0.28)
const ROW_A       := Color(0.08, 0.08, 0.13)
const ROW_B       := Color(0.06, 0.06, 0.10)

# Core name → element color (matches almanac)
const CORE_COLORS := {
	"None":      Color(0.30, 0.28, 0.40),
	"Fire":      Color(0.95, 0.35, 0.10),
	"Dash":      Color(0.50, 0.15, 0.65),
	"Clone":     Color(0.30, 0.80, 0.30),
	"Phase":     Color(0.70, 0.85, 1.00),
	"Explosion": Color(0.90, 0.55, 0.10),
	"Ice":       Color(0.30, 0.72, 0.95),
	"Lightning": Color(0.95, 0.90, 0.20),
	"Shield":    Color(0.62, 0.58, 0.48),
	"Summon":    Color(0.52, 0.20, 0.72),
	"Poison":    Color(0.40, 0.88, 0.35),
}

var _content_vbox: VBoxContainer


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_shell()
	_show_message("Loading…")

	PlayerAuth.rest_get(
		"high_scores?select=display_name,highest_room,cores,achieved_at" +
		"&order=highest_room.desc,achieved_at.asc&limit=20",
		_on_data_received
	)


# ── SHELL ──────────────────────────────────────────────────────────────────

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)

	# Title bar
	var title_bar := CenterContainer.new()
	title_bar.custom_minimum_size = Vector2(0, 72)
	outer.add_child(title_bar)

	var title := Label.new()
	title.text = "LEADERBOARD"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title_bar.add_child(title)

	# Column headers
	var header_bg := ColorRect.new()
	header_bg.color = Color(0.10, 0.09, 0.16)
	header_bg.custom_minimum_size = Vector2(0, 36)
	outer.add_child(header_bg)

	var header_row := _make_header_row()
	header_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_bg.add_child(header_row)

	# Scrollable content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(_content_vbox)

	# Back button
	var back_bar := CenterContainer.new()
	back_bar.custom_minimum_size = Vector2(0, 80)
	outer.add_child(back_bar)

	var back_btn := _make_btn("BACK", BTN_NORMAL, BTN_HOVER)
	back_btn.custom_minimum_size = Vector2(420, 56)
	back_btn.pressed.connect(queue_free)
	back_bar.add_child(back_btn)


func _make_header_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)

	var cols := [["#",              52,  HORIZONTAL_ALIGNMENT_CENTER],
				 ["PLAYER",       200,  HORIZONTAL_ALIGNMENT_LEFT],
				 ["CORES EQUIPPED", 0,  HORIZONTAL_ALIGNMENT_LEFT]]   # 0 = expand

	for col in cols:
		var lbl := Label.new()
		lbl.text = col[0]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.75))
		lbl.horizontal_alignment = col[2]
		if col[1] == 0:
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			lbl.custom_minimum_size = Vector2(col[1], 0)
		row.add_child(lbl)

	return row


# ── DATA HANDLING ──────────────────────────────────────────────────────────

func _on_data_received(result: int, code: int, body_bytes: PackedByteArray) -> void:
	_clear_content()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_show_message("Could not load leaderboard — check your connection.")
		return

	var parsed: Variant = JSON.parse_string(body_bytes.get_string_from_utf8())
	if not parsed is Array or (parsed as Array).is_empty():
		_show_message("No scores yet — be the first to make the board!")
		return

	var rows: Array = parsed
	for i in rows.size():
		_build_row(i + 1, rows[i], i % 2 == 0)


func _build_row(rank: int, data: Dictionary, alt: bool) -> void:
	var bg := ColorRect.new()
	bg.color = ROW_A if alt else ROW_B
	bg.custom_minimum_size = Vector2(0, 68)
	_content_vbox.add_child(bg)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	bg.add_child(row)

	# Rank
	var rank_color := Color(0.65, 0.62, 0.78)
	if rank == 1:   rank_color = GOLD
	elif rank == 2: rank_color = SILVER
	elif rank == 3: rank_color = BRONZE

	var rank_lbl := Label.new()
	rank_lbl.text = str(rank)
	rank_lbl.custom_minimum_size  = Vector2(52, 0)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 20)
	rank_lbl.add_theme_color_override("font_color", rank_color)
	row.add_child(rank_lbl)

	# Player name + room — stacked vertically
	var info_vbox := VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(200, 0)
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info_vbox)

	var name_str: String = data.get("display_name", "???")
	var is_me := PlayerAuth.is_logged_in() and \
			name_str.to_lower() == PlayerAuth.username.to_lower()

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", GOLD if is_me else Color(0.88, 0.86, 1.00))
	info_vbox.add_child(name_lbl)

	var room_lbl := Label.new()
	room_lbl.text = "Room " + str(data.get("highest_room", 0))
	room_lbl.add_theme_font_size_override("font_size", 13)
	room_lbl.add_theme_color_override("font_color", Color(0.55, 0.80, 1.00))
	info_vbox.add_child(room_lbl)

	# Cores — star icon + name stacked, one per slot
	var cores_raw: Variant = data.get("cores", [])
	var cores_hbox := HBoxContainer.new()
	cores_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cores_hbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	cores_hbox.add_theme_constant_override("separation", 14)
	row.add_child(cores_hbox)

	# Spacer so cores don't flush to the left
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	cores_hbox.add_child(spacer)

	if cores_raw is Array:
		for core_name_raw in (cores_raw as Array):
			var core_name: String = str(core_name_raw)
			if core_name == "None" or core_name == "":
				continue
			var col: Color = CORE_COLORS.get(core_name, Color(0.50, 0.48, 0.60))
			var slot_vbox := VBoxContainer.new()
			slot_vbox.add_theme_constant_override("separation", 2)
			slot_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cores_hbox.add_child(slot_vbox)

			var star_ctrl := Control.new()
			star_ctrl.custom_minimum_size = Vector2(22, 22)
			star_ctrl.draw.connect(func():
				var c := Vector2(11.0, 11.0)
				var pts := PackedVector2Array()
				for i in range(10):
					var a := deg_to_rad(-90.0 + i * 36.0)
					var r := 10.0 if i % 2 == 0 else 4.0
					pts.append(c + Vector2(cos(a), sin(a)) * r)
				star_ctrl.draw_polygon(pts, PackedColorArray([col]))
			)
			slot_vbox.add_child(star_ctrl)

			var name_lbl2 := Label.new()
			name_lbl2.text = core_name
			name_lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl2.add_theme_font_size_override("font_size", 11)
			name_lbl2.add_theme_color_override("font_color", col.lightened(0.1))
			slot_vbox.add_child(name_lbl2)


# ── UI HELPERS ─────────────────────────────────────────────────────────────

func _show_message(text: String) -> void:
	_clear_content()
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.52, 0.50, 0.64))
	_content_vbox.add_child(lbl)


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _make_btn(label: String, normal_color: Color, hover_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color",         BTN_TEXT)
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal",  normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	return btn

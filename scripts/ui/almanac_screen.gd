extends CanvasLayer

# ── THEME ──────────────────────────────────────────────────────────────────
const BG           := Color(0.04, 0.04, 0.08, 0.97)
const CARD_BG      := Color(0.08, 0.08, 0.13)
const CARD_LOCKED  := Color(0.06, 0.06, 0.10)
const CARD_BORDER  := Color(0.18, 0.16, 0.28)
const TITLE_CLR    := Color(0.88, 0.82, 1.00)
const DIM          := Color(0.52, 0.50, 0.64)
const VALUE_CLR    := Color(0.90, 0.88, 1.00)
const GOLD         := Color(1.00, 0.88, 0.25)
const BOSS_CLR     := Color(1.00, 0.55, 0.35)
const LOCKED_CLR   := Color(0.25, 0.23, 0.32)
const BTN_NORMAL   := Color(0.10, 0.10, 0.16)
const BTN_HOVER    := Color(0.18, 0.16, 0.28)
const BTN_TEXT     := Color(0.78, 0.74, 0.95)

# ── ENEMY DATA ─────────────────────────────────────────────────────────────
# texture: res:// path to PNG. atlas_rect: Rect2 for first frame (null = full image).
# color: element color for badge/glow. core: dropped core name. key: tracker column.
const ENEMIES := [
	{key="kills_fire_mage",        name="Fire Mage",        core="Fire Core",
	 texture="res://assets/enemies/fire_mage.png",        atlas=null,
	 color=Color(0.95,0.35,0.10),
	 desc="Hurls fireballs from range. Keeps its distance and punishes you for closing in."},
	{key="kills_rogue_assassin",   name="Rogue Assassin",   core="Dash Core",
	 texture="res://assets/enemies/rogue_assassin.png",   atlas=null,
	 color=Color(0.50,0.15,0.65),
	 desc="Blindingly fast. Closes distance in an instant and vanishes before you can retaliate."},
	{key="kills_slime",            name="Slime",            core="Clone Core",
	 texture="res://assets/enemies/Slime_sheet.png",      atlas=Rect2(0,0,32,32),
	 color=Color(0.30,0.80,0.30),
	 desc="Splits into smaller slimes on death. The last mini-slime drops a core."},
	{key="kills_ghost",            name="Ghost",            core="Phase Core",
	 texture="res://assets/enemies/Ghost_Sheet.png",      atlas=Rect2(0,0,32,32),
	 color=Color(0.70,0.85,1.00),
	 desc="Phases through walls to track you. Cannot be outrun — only outfought."},
	{key="kills_bomb_beetle",      name="Bomb Beetle",      core="Explosion Core",
	 texture="res://assets/enemies/bug_sheet.png",        atlas=Rect2(0,0,62,64),
	 color=Color(0.90,0.55,0.10),
	 desc="Charges directly at you and explodes on contact. Devastating at close range."},
	{key="kills_ice_witch",        name="Ice Witch",        core="Ice Core",
	 texture="res://assets/enemies/frost_mage.png",       atlas=null,
	 color=Color(0.30,0.72,0.95),
	 desc="Casts ice magic that slows your movement, leaving you vulnerable to other enemies."},
	{key="kills_lightning_sprite", name="Lightning Sprite", core="Lightning Core",
	 texture="",                                          atlas=null,
	 color=Color(0.95,0.90,0.20),
	 desc="An erratic flier that fires chain lightning. Hard to predict, harder to corner."},
	{key="kills_stone_golem",      name="Stone Golem",      core="Shield Core",
	 texture="res://assets/enemies/golem_sheet.png",      atlas=Rect2(0,0,64,64),
	 color=Color(0.62,0.58,0.48),
	 desc="Heavily armoured and slow. One hit can be devastating — keep your distance."},
	{key="kills_necromancer",      name="Necromancer",      core="Summon Core",
	 texture="res://assets/enemies/necro.png",            atlas=Rect2(0,0,32,32),
	 color=Color(0.52,0.20,0.72),
	 desc="Raises slain enemies from the dead. Clear it first or the room never ends."},
	{key="kills_poison_toad",      name="Poison Toad",      core="Poison Core",
	 texture="res://assets/enemies/frog_blue_spritesheet.png", atlas=Rect2(0,0,32,32),
	 color=Color(0.40,0.88,0.35),
	 desc="Spits venom and leaves toxic pools underfoot. Watch where you step."},
]

# ── BOSS DATA ──────────────────────────────────────────────────────────────
const BOSSES := [
	{key="kills_warden",      name="The Warden",    color=Color(0.70,0.52,0.28),
	 desc="A titanic guardian wielding earth and fire. Attacks in elemental bursts that cover the arena."},
	{key="kills_lich",        name="The Lich",       color=Color(0.55,0.20,0.82),
	 desc="An ancient undead sorcerer. Raises every enemy you kill to fight by its side."},
	{key="kills_phantom",     name="The Phantom",    color=Color(0.60,0.88,1.00),
	 desc="Splits into perfect decoys to confuse you. Only one is real — hit the wrong one and pay."},
	{key="kills_plague_lord", name="Plague Lord",    color=Color(0.38,0.80,0.22),
	 desc="Covers the entire arena in toxic pools and infectious clouds. Every inch of ground becomes a hazard."},
	{key="kills_storm_tyrant",name="Storm Tyrant",   color=Color(0.90,0.85,0.20),
	 desc="Commands the storm itself. Chain lightning and orbital bolts rain down without warning."},
]

# ── CORE DATA ──────────────────────────────────────────────────────────────
# unlock_key: the tracker column that must be > 0 to unlock this core entry.
const CORES := [
	{name="Fire Core",      color=Color(0.95,0.35,0.10), unlock_key="kills_fire_mage",
	 desc="Launch a blazing projectile. Deals bonus damage and leaves a brief burn effect on hit."},
	{name="Dash Core",      color=Color(0.50,0.15,0.65), unlock_key="kills_rogue_assassin",
	 desc="Dash in any direction. Passes through enemies and briefly makes you invincible."},
	{name="Clone Core",     color=Color(0.30,0.80,0.30), unlock_key="kills_slime",
	 desc="Summon a decoy clone that draws enemy fire. Disappears after taking enough hits."},
	{name="Phase Core",     color=Color(0.70,0.85,1.00), unlock_key="kills_ghost",
	 desc="Walk through walls and become temporarily intangible. Enemies cannot damage you."},
	{name="Explosion Core", color=Color(0.90,0.55,0.10), unlock_key="kills_bomb_beetle",
	 desc="Detonate a bomb around you dealing heavy area damage. Also destroys projectiles."},
	{name="Ice Core",       color=Color(0.30,0.72,0.95), unlock_key="kills_ice_witch",
	 desc="Launch an ice spike that slows every enemy it passes through."},
	{name="Lightning Core", color=Color(0.95,0.90,0.20), unlock_key="kills_lightning_sprite",
	 desc="Release chain lightning that jumps between nearby enemies, dealing damage to each."},
	{name="Shield Core",    color=Color(0.62,0.58,0.48), unlock_key="kills_stone_golem",
	 desc="Generate a shield aura that absorbs a set amount of incoming damage before breaking."},
	{name="Summon Core",    color=Color(0.52,0.20,0.72), unlock_key="kills_necromancer",
	 desc="Summon a spirit ally that fights alongside you until it is destroyed."},
	{name="Poison Core",    color=Color(0.40,0.88,0.35), unlock_key="kills_poison_toad",
	 desc="Emit a poison aura. Enemies that enter it take damage over time."},
]

# ── STATE ──────────────────────────────────────────────────────────────────
var _scroll_vbox: VBoxContainer


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_shell()

	if not PlayerAuth.is_logged_in():
		_set_content(_make_message("Log in to view your Almanac."))
		return

	_set_content(_make_message("Loading…"))
	PlayerAuth.rest_get(
		"tracker?user_id=eq." + PlayerAuth.user_id + "&select=*",
		_on_data_received
	)


# ── SHELL ──────────────────────────────────────────────────────────────────

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)

	# Title
	var title_bar := CenterContainer.new()
	title_bar.custom_minimum_size = Vector2(0, 68)
	outer.add_child(title_bar)
	var title := Label.new()
	title.text = "TRACKER"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TITLE_CLR)
	title_bar.add_child(title)

	# Scroll area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_scroll_vbox = VBoxContainer.new()
	_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(_scroll_vbox)

	# Back button
	var back_bar := CenterContainer.new()
	back_bar.custom_minimum_size = Vector2(0, 72)
	outer.add_child(back_bar)
	var back_btn := _make_btn("BACK")
	back_btn.custom_minimum_size = Vector2(320, 52)
	back_btn.pressed.connect(queue_free)
	back_bar.add_child(back_btn)


# ── DATA RECEIVED ──────────────────────────────────────────────────────────

func _on_data_received(result: int, code: int, body_bytes: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_set_content(_make_message("Could not load stats — check your connection."))
		return

	var parsed: Variant = JSON.parse_string(body_bytes.get_string_from_utf8())
	if not parsed is Array or (parsed as Array).is_empty():
		_set_content(_make_message("No stats yet.\nComplete a run to start your Almanac!"))
		return

	_build_content((parsed as Array)[0])


# ── CONTENT BUILDER ────────────────────────────────────────────────────────

func _build_content(d: Dictionary) -> void:
	_clear_scroll()

	var pad := _hpad()
	_scroll_vbox.add_child(pad)

	# ── Summary stat cards ──────────────────────────────────────────────
	var summary := HBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation", 12)
	summary.set("theme_override_constants/margin_left",  40)
	summary.set("theme_override_constants/margin_right", 40)
	_scroll_vbox.add_child(summary)

	_stat_card(summary, "RUNS",        str(d.get("runs_attempted", 0)), VALUE_CLR)
	_stat_card(summary, "DEATHS",      str(d.get("deaths",         0)), Color(0.90,0.40,0.40))
	_stat_card(summary, "WINS",        str(d.get("wins",           0)), GOLD)
	_stat_card(summary, "TOTAL KILLS", str(d.get("total_kills",    0)), Color(0.55,0.85,1.00))

	_scroll_vbox.add_child(_hpad(24))

	# ── Enemy cards ─────────────────────────────────────────────────────
	_section_header("ENEMIES")
	var enemy_grid := _make_grid()
	for info in ENEMIES:
		var kills: int = d.get(info["key"], 0)
		enemy_grid.add_child(_make_enemy_card(info, kills))
	_scroll_vbox.add_child(enemy_grid)

	_scroll_vbox.add_child(_hpad(16))

	# ── Boss cards ──────────────────────────────────────────────────────
	_section_header("BOSSES")
	var boss_grid := _make_grid()
	for info in BOSSES:
		var kills: int = d.get(info["key"], 0)
		boss_grid.add_child(_make_boss_card(info, kills))
	_scroll_vbox.add_child(boss_grid)

	_scroll_vbox.add_child(_hpad(16))

	# ── Core cards ──────────────────────────────────────────────────────
	_section_header("POWER CORES")
	var lore_lbl := Label.new()
	lore_lbl.text = "Cores unlock as you defeat the enemies that carry them."
	lore_lbl.add_theme_font_size_override("font_size", 13)
	lore_lbl.add_theme_color_override("font_color", DIM)
	lore_lbl.set("theme_override_constants/margin_left", 44)
	_scroll_vbox.add_child(lore_lbl)
	_scroll_vbox.add_child(_hpad(8))

	var core_grid := _make_grid()
	for info in CORES:
		var unlocked: bool = d.get(info["unlock_key"], 0) > 0
		core_grid.add_child(_make_core_card(info, unlocked))
	_scroll_vbox.add_child(core_grid)

	_scroll_vbox.add_child(_hpad(24))


# ── CARD BUILDERS ──────────────────────────────────────────────────────────

func _make_enemy_card(info: Dictionary, kills: int) -> Control:
	var locked := kills == 0
	var card := _card_container(locked)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Portrait
	hbox.add_child(_make_portrait(info, locked))

	# Right side info
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	# Name row
	var name_row := HBoxContainer.new()
	vbox.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = "???" if locked else info["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color",
		LOCKED_CLR if locked else Color(0.88, 0.86, 1.00))
	name_row.add_child(name_lbl)

	var kills_lbl := Label.new()
	kills_lbl.text = str(kills) + " kills"
	kills_lbl.add_theme_font_size_override("font_size", 16)
	kills_lbl.add_theme_color_override("font_color",
		LOCKED_CLR if locked else (GOLD if kills >= 50 else VALUE_CLR))
	name_row.add_child(kills_lbl)

	# Core badge
	if not locked:
		var core_lbl := Label.new()
		core_lbl.text = "Drops: " + info["core"]
		core_lbl.add_theme_font_size_override("font_size", 12)
		core_lbl.add_theme_color_override("font_color", (info["color"] as Color).lightened(0.1))
		vbox.add_child(core_lbl)

	# Description
	var desc := Label.new()
	desc.text = "Defeat this enemy once to unlock." if locked else info["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", LOCKED_CLR if locked else DIM)
	vbox.add_child(desc)

	return card


func _make_boss_card(info: Dictionary, kills: int) -> Control:
	var locked := kills == 0
	var card := _card_container(locked)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Element badge (bosses have no sprites yet)
	hbox.add_child(_make_color_badge(info["color"] as Color, locked))

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_row := HBoxContainer.new()
	vbox.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = "???" if locked else info["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color",
		LOCKED_CLR if locked else BOSS_CLR)
	name_row.add_child(name_lbl)

	var kills_lbl := Label.new()
	kills_lbl.text = str(kills) + " kills"
	kills_lbl.add_theme_font_size_override("font_size", 16)
	kills_lbl.add_theme_color_override("font_color",
		LOCKED_CLR if locked else (GOLD if kills >= 10 else VALUE_CLR))
	name_row.add_child(kills_lbl)

	var desc := Label.new()
	desc.text = "Defeat this boss once to reveal its secrets." if locked else info["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", LOCKED_CLR if locked else DIM)
	vbox.add_child(desc)

	return card


func _make_core_card(info: Dictionary, unlocked: bool) -> Control:
	var card := _card_container(not unlocked)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Core icon — drawn 5-pointed star (no font needed)
	var star_col: Color = info["color"] if unlocked else LOCKED_CLR
	var star_ctrl := Control.new()
	star_ctrl.custom_minimum_size = Vector2(64, 64)
	star_ctrl.draw.connect(func():
		var c := Vector2(32.0, 32.0)
		var pts := PackedVector2Array()
		for i in range(10):
			var a := deg_to_rad(-90.0 + i * 36.0)
			var r := 28.0 if i % 2 == 0 else 11.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		star_ctrl.draw_polygon(pts, PackedColorArray([star_col]))
	)
	hbox.add_child(star_ctrl)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = "???" if not unlocked else info["name"]
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color",
		LOCKED_CLR if not unlocked else (info["color"] as Color).lightened(0.15))
	vbox.add_child(name_lbl)

	var desc := Label.new()
	desc.text = "Defeat the enemy that carries this core to learn its power." if not unlocked else info["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", LOCKED_CLR if not unlocked else DIM)
	vbox.add_child(desc)

	return card


# ── PORTRAIT HELPERS ───────────────────────────────────────────────────────

func _make_portrait(info: Dictionary, locked: bool) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(64, 64)

	if locked:
		return _make_color_badge(info["color"].darkened(0.65), true)

	var tex_path: String = info["texture"]
	if tex_path == "":
		# No sprite yet — show element color badge
		return _make_color_badge(info["color"], false)

	var base := load(tex_path) as Texture2D
	if base == null:
		return _make_color_badge(info["color"], false)

	var tex: Texture2D = base
	var atlas_rect: Variant = info["atlas"]
	if atlas_rect != null:
		var atlas := AtlasTexture.new()
		atlas.atlas  = base
		atlas.region = atlas_rect as Rect2
		tex = atlas

	var tr := TextureRect.new()
	tr.texture        = tex
	tr.expand_mode    = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(tr)
	return box


func _make_color_badge(color: Color, locked: bool) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(64, 64)

	var bg := ColorRect.new()
	bg.color = color.darkened(0.55) if not locked else Color(0.06, 0.06, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(bg)

	# Coloured accent strip on the left
	if not locked:
		var strip := ColorRect.new()
		strip.color = color.darkened(0.10)
		strip.anchor_left   = 0.0
		strip.anchor_right  = 0.15
		strip.anchor_top    = 0.0
		strip.anchor_bottom = 1.0
		box.add_child(strip)

	var lbl := Label.new()
	lbl.text = "?" if locked else ""
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", LOCKED_CLR)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(lbl)

	return box


# ── LAYOUT HELPERS ─────────────────────────────────────────────────────────

func _section_header(text: String) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top",   16)
	_scroll_vbox.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.78))
	vbox.add_child(lbl)

	var line := ColorRect.new()
	line.color = Color(0.20, 0.18, 0.32)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line)

	_scroll_vbox.add_child(_hpad(8))


func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.set("theme_override_constants/margin_left",  40)
	grid.set("theme_override_constants/margin_right", 40)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_vbox.add_child(grid)
	return grid


func _card_container(locked: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = CARD_LOCKED if locked else CARD_BG
	style.border_color = Color(0.14, 0.13, 0.20) if locked else CARD_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	return panel


func _stat_card(parent: Control, label: String, value: String, val_color: Color) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.09, 0.15)
	style.border_color = CARD_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", DIM)
	vbox.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 28)
	val.add_theme_color_override("font_color", val_color)
	vbox.add_child(val)

	parent.add_child(panel)


func _make_message(text: String) -> Control:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", DIM)
	return lbl


func _set_content(node: Control) -> void:
	_clear_scroll()
	_scroll_vbox.add_child(node)


func _clear_scroll() -> void:
	for child in _scroll_vbox.get_children():
		child.queue_free()


func _hpad(h: int = 12) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s


func _make_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color",         BTN_TEXT)
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var n := StyleBoxFlat.new()
	n.bg_color = BTN_NORMAL
	n.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", n)
	var h := StyleBoxFlat.new()
	h.bg_color = BTN_HOVER
	h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", h)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	return btn

extends CanvasLayer

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

# Set by GameState before add_child — always strings, never Variant
var perk_a: String = ""
var perk_b: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	get_tree().paused = true
	_build_ui()

func _build_ui() -> void:
	# Fullscreen dark overlay
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Root control that fills the screen
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_ctrl)

	# Centre everything vertically and horizontally
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "BOSS DEFEATED"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose a perk"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Side-by-side perk buttons
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	_add_perk_button(hbox, perk_a)
	_add_perk_button(hbox, perk_b)

func _add_perk_button(parent: Control, perk_id: String) -> void:
	var display_name: String = PERK_NAMES[perk_id] if PERK_NAMES.has(perk_id) else perk_id
	var symbol: String = PERK_SYMBOLS[perk_id] if PERK_SYMBOLS.has(perk_id) else "?"
	var owned: bool = GameState.player_perks.has(perk_id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 180)
	btn.text = ""
	if not owned:
		btn.pressed.connect(func(): _pick(perk_id))
	else:
		btn.disabled = true

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	btn.add_child(vbox)

	var sym_lbl := Label.new()
	sym_lbl.text = symbol
	sym_lbl.add_theme_font_size_override("font_size", 52)
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_lbl.add_theme_color_override("font_color",
		Color(0.55, 0.55, 0.55) if owned else Color(1.0, 0.88, 0.3))
	vbox.add_child(sym_lbl)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color",
		Color(0.55, 0.55, 0.55) if owned else Color(1.0, 1.0, 1.0))
	vbox.add_child(name_lbl)

	var action_lbl := Label.new()
	action_lbl.text = "(Already Owned)" if owned else "— Take It —"
	action_lbl.add_theme_font_size_override("font_size", 14)
	action_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_lbl.add_theme_color_override("font_color",
		Color(0.45, 0.45, 0.45) if owned else Color(0.65, 0.95, 0.65))
	vbox.add_child(action_lbl)

	parent.add_child(btn)

func _pick(perk_id: String) -> void:
	if not GameState.player_perks.has(perk_id):
		GameState.player_perks.append(perk_id)
		GameState.perks_changed.emit()
	get_tree().paused = false
	queue_free()

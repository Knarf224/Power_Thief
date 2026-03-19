extends CanvasLayer

# Perk display names — subscript access (PERK_NAMES[id]) is used everywhere
# so GDScript never needs to infer a Variant return from Dictionary.get().
const PERK_NAMES: Dictionary = {
	"auto_fire":      "Auto-Fire",
	"stopping_power": "Stopping Power",
	"gravity_push":   "Gravity Push",
	"life_steal":     "Life Steal",
	"piercing_shot":  "Piercing Shot",
	"rapid_fire":     "Rapid Fire",
	"thorns":         "Thorns",
	"death_burst":    "Death Burst",
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
	# Resolve the display name — use direct subscript with a fallback,
	# both paths produce a String so GDScript never infers Variant.
	var display_name: String
	if PERK_NAMES.has(perk_id):
		display_name = PERK_NAMES[perk_id]
	else:
		display_name = perk_id

	var owned: bool = GameState.player_perks.has(perk_id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 110)
	btn.add_theme_font_size_override("font_size", 22)

	if owned:
		btn.text = display_name + "\n(Already Owned)"
		btn.disabled = true
	else:
		btn.text = display_name + "\nTake It"
		btn.pressed.connect(func(): _pick(perk_id))

	parent.add_child(btn)

func _pick(perk_id: String) -> void:
	if not GameState.player_perks.has(perk_id):
		GameState.player_perks.append(perk_id)
	get_tree().paused = false
	queue_free()

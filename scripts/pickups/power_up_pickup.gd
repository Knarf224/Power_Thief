extends Area2D

const DESPAWN_TIME := 10.0
const FLASH_START  := 5.0    # seconds remaining when flashing begins

const COLORS: Dictionary = {
	"nuke":         Color(1.00, 0.85, 0.10),  # bright yellow
	"insta_kill":   Color(1.00, 0.15, 0.15),  # red
	"full_heal":    Color(0.20, 0.90, 0.30),  # green
	"shield_burst": Color(0.30, 0.55, 1.00),  # blue
	"speed_boost":  Color(0.00, 0.90, 1.00),  # cyan
	"freeze":       Color(0.60, 0.90, 1.00),  # ice blue
}

const ICONS: Dictionary = {
	"nuke":         "☢",
	"insta_kill":   "☠",
	"full_heal":    "♥",
	"shield_burst": "⬡",
	"speed_boost":  "⚡",
	"freeze":       "❄",
}

const LABELS: Dictionary = {
	"nuke":         "NUKE",
	"insta_kill":   "INSTA KILL",
	"full_heal":    "FULL HEAL",
	"shield_burst": "SHIELD",
	"speed_boost":  "SPEED",
	"freeze":       "FREEZE",
}

var power_up_type: String = ""

var _despawn_timer: float = DESPAWN_TIME
var _spinner: Node2D


func _ready() -> void:
	add_to_group("power_up")
	collision_layer = 0
	collision_mask  = 1   # detect player (layer 1)
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	_despawn_timer -= delta

	if _despawn_timer <= 0.0:
		queue_free()
		return

	# Flash only when about to disappear
	if _despawn_timer <= FLASH_START:
		visible = fmod(_despawn_timer, 0.35) > 0.175
	else:
		visible = true

	# Spin the orb + icon
	_spinner.rotation += delta * 1.8


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_apply(body)
		queue_free()


func _apply(player: Node) -> void:
	match power_up_type:
		"nuke":
			_flash_screen()
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if is_instance_valid(enemy) and enemy.has_method("nuke") and not enemy.get("is_boss"):
					enemy.nuke()
		"insta_kill":
			GameState.insta_kill_timer  = 10.0
		"full_heal":
			player.call("heal", player.MAX_HEALTH)
			player.call("spawn_heal_hearts")
		"shield_burst":
			GameState.shield_burst_timer = 8.0
		"speed_boost":
			GameState.speed_boost_timer  = 10.0
		"freeze":
			GameState.freeze_timer       = 8.0


func _build_visual() -> void:
	var col: Color = COLORS[power_up_type] if COLORS.has(power_up_type) else Color.WHITE

	# Outer glow ring — static, does not spin
	var glow := Polygon2D.new()
	glow.polygon = _circle_points(17)
	glow.color   = Color(col.r, col.g, col.b, 0.28)
	add_child(glow)

	# Spinner container — orb + icon rotate together
	_spinner = Node2D.new()
	add_child(_spinner)

	var orb := Polygon2D.new()
	orb.polygon = _circle_points(12)
	orb.color   = col
	_spinner.add_child(orb)

	var icon_lbl := Label.new()
	icon_lbl.text = ICONS[power_up_type] if ICONS.has(power_up_type) else "?"
	icon_lbl.add_theme_font_size_override("font_size", 15)
	icon_lbl.add_theme_color_override("font_color", Color.WHITE)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.custom_minimum_size  = Vector2(24, 24)
	icon_lbl.position             = Vector2(-12, -12)
	_spinner.add_child(icon_lbl)

	# Name label — static, below the orb, does not spin
	var name_lbl := Label.new()
	name_lbl.text = LABELS[power_up_type] if LABELS.has(power_up_type) else power_up_type
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.custom_minimum_size  = Vector2(64, 12)
	name_lbl.position             = Vector2(-32, 15)
	add_child(name_lbl)

	# Collision
	var shape_node := CollisionShape2D.new()
	var shape      := CircleShape2D.new()
	shape.radius   = 14.0
	shape_node.shape = shape
	add_child(shape_node)


func _flash_screen() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().root.add_child(cl)

	var rect := ColorRect.new()
	rect.color = Color(1.0, 1.0, 1.0, 1.0)
	rect.anchor_right  = 1.0
	rect.anchor_bottom = 1.0
	cl.add_child(rect)

	var tween := cl.create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(cl.queue_free)


func _circle_points(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var angle := i * TAU / 16.0
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

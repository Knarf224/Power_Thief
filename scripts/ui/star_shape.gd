extends Control
# Draws a 5-pointed star polygon. Works on all platforms including web export.
# Use load() to instantiate — do NOT preload() from UI scripts.

var star_color := Color.WHITE
var star_size  := 24.0


func _ready() -> void:
	custom_minimum_size = Vector2(star_size, star_size)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := Vector2(star_size * 0.5, star_size * 0.5)
	var outer  := star_size * 0.5
	var inner  := star_size * 0.2
	var pts    := PackedVector2Array()
	for i in 10:
		var angle := (PI / 5.0) * i - PI / 2.0
		var r := outer if i % 2 == 0 else inner
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_polygon(pts, PackedColorArray([star_color]))

extends "res://scripts/enemies/base_enemy.gd"

# ── Visual health bar constants ─────────────────────────────────────────────
const BAR_WIDTH  := 100.0
const BAR_HEIGHT := 10.0
const BAR_Y      := -58.0   # above the boss sprite

# ── Subclasses set these in their _ready() before calling super() ────────────
var boss_name      := "Boss"
var boss_perk_pool : Array  = []   # list of perk ID strings, e.g. ["rapid_fire", "thorns"]
var companion_scene: String = ""   # path to companion enemy scene
# _is_dying and is_boss are inherited from base_enemy — do not redeclare here

func _ready() -> void:
	is_boss = true        # override base_enemy's is_boss = false
	drop_core_type = 0    # bosses never drop cores
	super()
	add_to_group("boss")

func _process(_delta: float) -> void:
	queue_redraw()   # redraw health bar every frame

func _draw() -> void:
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var bx    := -BAR_WIDTH / 2.0

	# Background bar
	draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.22, 0.04, 0.04))
	# Health fill
	draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH * ratio, BAR_HEIGHT), Color(0.85, 0.12, 0.12))
	# Border outline
	draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.6, 0.6, 0.6), false, 1.0)

	# Boss name above bar
	var font := ThemeDB.fallback_font
	if font:
		var text_x := bx
		draw_string(font, Vector2(text_x, BAR_Y - 6), boss_name,
				HORIZONTAL_ALIGNMENT_LEFT, BAR_WIDTH, 13, Color(0.92, 0.72, 0.72))

func _on_death() -> void:
	if _is_dying:
		return
	_is_dying = true
	Tracker.record_kill(get_script().resource_path)
	_show_perk_choice()
	died.emit()
	queue_free()

func _show_perk_choice() -> void:
	if boss_perk_pool.is_empty():
		return
	var pool := boss_perk_pool.duplicate()
	pool.shuffle()
	var perk_a: String = pool[0]
	var perk_b: String = pool[mini(1, pool.size() - 1)]
	# Delegate to GameState — an autoload that remains valid across frames,
	# so there is no dangling-pointer risk from a locally-created Node.
	GameState.stage_perk_select(perk_a, perk_b)

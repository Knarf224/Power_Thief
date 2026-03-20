extends Node

signal perks_changed

# Persists player state across room scene transitions
var player_health: int = 100
var player_cores: Array = [0, 0, 0]  # CoreType.NONE = 0
var exit_direction: String = ""      # "north" | "south" | "east" | "west"
var room_counter: int = 0

# ---------------------------------------------------------------------------
# Room selection
#
# Rules:
#   - Rooms 1-3 are always Standard Combat (no specials while the player
#     is still learning the controls).
#   - After room 3 a weighted roll decides each room.
#   - Standard Combat starts at STANDARD_WEIGHT_BASE and gains
#     STANDARD_STREAK_BONUS for every consecutive special room just played,
#     so long streaks of specials become increasingly unlikely.
#   - Back-to-back specials are allowed, but the SAME special can never
#     appear twice in a row (it is excluded from the eligible pool).
#   - Landing on Standard Combat resets the streak counter to 0.
# ---------------------------------------------------------------------------

const STANDARD_ROOM := "res://scenes/Main.tscn"

const SPECIAL_ROOMS: Dictionary = {
	"res://scenes/dungeon/AmbushRoom.tscn":      15,
	"res://scenes/dungeon/HazardFloorRoom.tscn": 13,
	"res://scenes/dungeon/PowerZoneRoom.tscn":   12,
}

# Base weight for Standard Combat. Each consecutive special adds STANDARD_STREAK_BONUS.
# At 0 specials in a row: standard≈47%  (45 vs 40 total special weight)
# At 1 special in a row:  standard≈68%  (70 vs ~27 remaining specials)
# At 2 specials in a row: standard≈78%  (95 vs ~27 remaining specials)
const STANDARD_WEIGHT_BASE   := 45
const STANDARD_STREAK_BONUS  := 25

var _consecutive_specials := 0   # how many specials have been played back-to-back
var _last_special_scene   := ""  # prevents the same special appearing twice in a row


func next_room_scene() -> String:
	boss_defeated_this_level = false
	enemies_killed_this_room = 0
	if staging_mode:
		return staging_room
	var scene := _pick_room()
	room_counter += 1
	return scene


func _pick_room() -> String:
	# room_counter is 0-indexed and incremented after this call.
	# The starting scene (room 1) is loaded directly, so picks begin at counter=0.
	#
	#   counter 0 → room 2  (standard, player still learning)
	#   counter 1 → room 3  (standard)
	#   counter 2 → room 4  (FORCED special — guaranteed first taste of variety)
	#   counter 3+ → weighted roll

	if room_counter < 2:
		return STANDARD_ROOM

	if room_counter == 2:
		return _pick_forced_special()

	# Standard weight grows with every consecutive special that was just played
	var standard_weight := STANDARD_WEIGHT_BASE + _consecutive_specials * STANDARD_STREAK_BONUS

	# Eligible specials: all except the one played last (no same-special-twice rule)
	var eligible: Dictionary = {}
	for scene: String in SPECIAL_ROOMS:
		if scene != _last_special_scene:
			eligible[scene] = SPECIAL_ROOMS[scene]

	var total := standard_weight
	for w: int in eligible.values():
		total += w

	var roll := randi() % total

	if roll < standard_weight:
		_consecutive_specials = 0
		_last_special_scene   = ""
		return STANDARD_ROOM

	var cumulative := standard_weight
	for scene: String in eligible:
		cumulative += eligible[scene]
		if roll < cumulative:
			_consecutive_specials += 1
			_last_special_scene    = scene
			return scene

	return STANDARD_ROOM  # fallback — should never reach here


func _pick_forced_special() -> String:
	var scenes := SPECIAL_ROOMS.keys()
	var scene: String = scenes[randi() % scenes.size()]
	_consecutive_specials = 1
	_last_special_scene   = scene
	return scene


# ---------------------------------------------------------------------------
# STAGING — flip staging_mode to true when testing a specific room.
# Set staging_room to whichever scene you are working on.
# Rooms call get_enemy_count(default) so the count automatically drops to 1.
# Use F6 in Godot to run the open scene directly instead of the full game.
# ---------------------------------------------------------------------------
var hardcore_mode  := false   # true = player starts with 1 HP
var player_perks: Array = []  # list of owned perk ID strings, e.g. ["rapid_fire", "thorns"]
var boss_defeated_this_level: bool = false

# ---------------------------------------------------------------------------
# BOSS SYSTEM
# Bosses appear at levels 4, 8, 12, 16… (every 4th level).
# They overlay any room type — the room runs its normal logic while the boss
# spawns alongside a scaled group of thematic companions.
# Boss order cycles through the five bosses in sequence.
# ---------------------------------------------------------------------------

const BOSS_SCENES: Array = [
	"res://scenes/enemies/bosses/Warden.tscn",
	"res://scenes/enemies/bosses/Lich.tscn",
	"res://scenes/enemies/bosses/Phantom.tscn",
	"res://scenes/enemies/bosses/PlagueLord.tscn",
	"res://scenes/enemies/bosses/StormTyrant.tscn",
]

func is_boss_level() -> bool:
	# room_counter is already incremented before the room loads, so
	# room_counter + 1 == the level number being played.
	# Endless mode has no boss levels — only enemy count scales.
	if endless_mode:
		return false
	return (room_counter + 1) % 4 == 0

# ---------------------------------------------------------------------------
# Boss shuffle bag — every boss appears once per cycle, never twice in a row.
# ---------------------------------------------------------------------------
var _boss_pool: Array = []
var _last_boss_scene: String = ""

func reset_boss_pool() -> void:
	_boss_pool = []
	_last_boss_scene = ""

func get_boss_scene() -> String:
	if _boss_pool.is_empty():
		_boss_pool = BOSS_SCENES.duplicate()
		_boss_pool.shuffle()
		# If the top of the fresh deck matches the last boss used, swap it out
		# so the same boss never appears twice in a row across cycles.
		if _last_boss_scene != "" and _boss_pool.size() > 1 and _boss_pool[0] == _last_boss_scene:
			var swap_idx := randi_range(1, _boss_pool.size() - 1)
			var tmp: String = _boss_pool[0]
			_boss_pool[0] = _boss_pool[swap_idx]
			_boss_pool[swap_idx] = tmp
	var scene: String = _boss_pool.pop_front()
	_last_boss_scene = scene
	return scene

func get_boss_companion_count() -> int:
	# Flat +2 companions per boss fought. Always fewer than a normal room.
	# L4→2, L8→4, L12→6, L16→8, L20→10 companions
	if staging_mode or quick_mode:
		return 1
	var boss_index := room_counter / 4
	return 2 + boss_index * 2

# ---------------------------------------------------------------------------
# PERK SELECT — called by boss_base on boss death.
# Spawning happens on GameState (an always-valid autoload) so there is no
# dangling-pointer risk from a local Node variable in a deferred call.
# ---------------------------------------------------------------------------
var _pending_perk_a := ""
var _pending_perk_b := ""

func stage_perk_select(perk_a: String, perk_b: String) -> void:
	_pending_perk_a = perk_a
	_pending_perk_b = perk_b
	boss_defeated_this_level = true
	# Level 20 = all 5 bosses cleared — queue the win screen after perk pick
	if room_counter + 1 == 20:
		pending_win_screen = true

func open_pending_perk_select() -> void:
	call_deferred("_open_perk_select")

func _open_perk_select() -> void:
	var packed := load("res://scenes/ui/PerkSelect.tscn") as PackedScene
	if packed == null:
		push_error("GameState: failed to load PerkSelect.tscn")
		return
	var selector := packed.instantiate()
	selector.set("perk_a", _pending_perk_a)
	selector.set("perk_b", _pending_perk_b)
	get_tree().root.add_child(selector)

func open_win_screen() -> void:
	call_deferred("_open_win_screen")

func _open_win_screen() -> void:
	var packed := load("res://scenes/ui/WinScreen.tscn") as PackedScene
	if packed == null:
		push_error("GameState: failed to load WinScreen.tscn")
		return
	get_tree().root.add_child(packed.instantiate())

var staging_mode := false
var staging_room  := "res://scenes/dungeon/HazardFloorRoom.tscn"
var god_mode     := false
var endless_mode := false          # true after player beats level 20 and picks Endless
var pending_win_screen := false    # set on level-20 boss death; consumed by PerkSelect

# ---------------------------------------------------------------------------
# QUICK MODE — set to true to test the room ORDER algorithm.
# Enemy count is forced to 1 so rooms clear fast, but _pick_room() still runs
# the full weighted selection — you will see the actual rotation play out.
# Use F5 (full game) so the room sequence starts from the beginning.
# ---------------------------------------------------------------------------
var quick_mode := false

# ---------------------------------------------------------------------------
# TIMED POWER-UP BUFFS
# ---------------------------------------------------------------------------
var insta_kill_timer   := 0.0
var shield_burst_timer := 0.0
var speed_boost_timer  := 0.0
var freeze_timer       := 0.0
var enemies_killed_this_room: int = 0

func _process(delta: float) -> void:
	insta_kill_timer   = max(0.0, insta_kill_timer   - delta)
	shield_burst_timer = max(0.0, shield_burst_timer - delta)
	speed_boost_timer  = max(0.0, speed_boost_timer  - delta)
	freeze_timer       = max(0.0, freeze_timer       - delta)

func get_enemy_count(default_count: int) -> int:
	if staging_mode or quick_mode:
		return 1
	# Returns the TOTAL enemy count for the current level. Every room type uses
	# this same number — special rooms distribute it differently but never exceed it.
	#
	#   Standard Combat  → spawns all enemies at once
	#   Hazard Floor     → spawns all enemies at once
	#   Ambush Room      → splits total across 4 corner rooms (total / 4 each)
	#   Power Zone       → splits total across wave count   (total / waves each)
	#
	# Progression (default_count = 2, +2 per level, capped at 24):
	#   L1=2  L2=4  L3=6  L4=boss  L5=10  L6=12  L7=14  L8=boss  L9=18 ...
	# In endless mode the cap is lifted — enemy count keeps climbing
	if endless_mode:
		return default_count + room_counter * 2
	return mini(default_count + room_counter * 2, 24)

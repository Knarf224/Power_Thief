extends Node

# ── ENEMY → TRACKER KEY MAP ────────────────────────────────────────────────
# Maps each enemy's script path to its column name in the tracker table.
# Add new enemies here when they are added to the game.
const ENEMY_KEY_MAP := {
	"res://scripts/enemies/fire_mage.gd":           "kills_fire_mage",
	"res://scripts/enemies/assassin.gd":            "kills_rogue_assassin",
	"res://scripts/enemies/slime.gd":               "kills_slime",
	"res://scripts/enemies/ghost.gd":               "kills_ghost",
	"res://scripts/enemies/bomb_beetle.gd":         "kills_bomb_beetle",
	"res://scripts/enemies/ice_witch.gd":           "kills_ice_witch",
	"res://scripts/enemies/lightning_sprite.gd":    "kills_lightning_sprite",
	"res://scripts/enemies/stone_golem.gd":         "kills_stone_golem",
	"res://scripts/enemies/necromancer.gd":         "kills_necromancer",
	"res://scripts/enemies/poison_toad.gd":         "kills_poison_toad",
	"res://scripts/enemies/bosses/warden.gd":       "kills_warden",
	"res://scripts/enemies/bosses/lich.gd":         "kills_lich",
	"res://scripts/enemies/bosses/phantom.gd":      "kills_phantom",
	"res://scripts/enemies/bosses/plague_lord.gd":  "kills_plague_lord",
	"res://scripts/enemies/bosses/storm_tyrant.gd": "kills_storm_tyrant",
}

# ── CORE INDEX → DISPLAY NAME ──────────────────────────────────────────────
# Used when building the high score entry.
# Index matches drop_core_type values set in each enemy script.
const CORE_NAMES := {
	0: "None",     1: "Dash",      2: "Fire",      3: "Clone",
	4: "Phase",    5: "Explosion", 6: "Ice",       7: "Lightning",
	8: "Shield",   9: "Summon",   10: "Poison",
}

# ── PER-RUN STATE ──────────────────────────────────────────────────────────
# Accumulates during a run and is flushed to Supabase when the run ends.
var _kills:         Dictionary = {}  # e.g. {"kills_fire_mage": 3, "kills_slime": 1}
var _total_kills:   int        = 0
var _deaths:        int        = 0   # 0 or 1 per run
var _wins:          int        = 0   # 0 or 1 per run
var _run_active:    bool       = false


# ── LIFECYCLE ──────────────────────────────────────────────────────────────

func _ready() -> void:
	_reset_run()


# ── PUBLIC API ─────────────────────────────────────────────────────────────

## Called when the player starts a new run (main.gd _ready).
func on_run_started() -> void:
	_reset_run()
	_run_active = true
	# Always ping the global play counter — even guests count.
	PlayerAuth.supabase_rpc("increment_play_count", {}, func(_r, _c, _b): pass)


## Called when an enemy dies. Script path identifies the enemy type.
## Invoked from base_enemy._on_death() and boss_base._on_death().
func record_kill(script_path: String) -> void:
	if not _run_active:
		return
	var key: String = ENEMY_KEY_MAP.get(script_path, "")
	if key.is_empty():
		return  # summoned spirits, decoys, etc. — not tracked
	_kills[key] = _kills.get(key, 0) + 1
	_total_kills += 1


## Called when the player reaches the You Won screen (win_screen.gd _ready).
func on_win() -> void:
	if not _run_active:
		return
	_wins = 1


## Called when the player dies (main.gd _on_player_died).
## Also the submission trigger for the high score.
func on_player_died() -> void:
	if not _run_active:
		return
	_deaths = 1
	_end_run()


## Called when the player returns to the main menu from the win screen.
## Needed so the run is flushed even if the player won and didn't die.
func on_menu_from_win() -> void:
	if not _run_active:
		return
	_end_run()


# ── INTERNALS ──────────────────────────────────────────────────────────────

func _reset_run() -> void:
	_kills       = {}
	_total_kills = 0
	_deaths      = 0
	_wins        = 0
	_run_active  = false


func _end_run() -> void:
	_run_active = false

	if not PlayerAuth.is_logged_in():
		_reset_run()
		return

	_submit_high_score()
	_flush_tracker()
	_reset_run()


func _flush_tracker() -> void:
	var params := {
		"p_user_id":                PlayerAuth.user_id,
		"p_runs_delta":             1,
		"p_deaths_delta":           _deaths,
		"p_wins_delta":             _wins,
		"p_kills_fire_mage":        _kills.get("kills_fire_mage",        0),
		"p_kills_rogue_assassin":   _kills.get("kills_rogue_assassin",   0),
		"p_kills_slime":            _kills.get("kills_slime",            0),
		"p_kills_ghost":            _kills.get("kills_ghost",            0),
		"p_kills_bomb_beetle":      _kills.get("kills_bomb_beetle",      0),
		"p_kills_ice_witch":        _kills.get("kills_ice_witch",        0),
		"p_kills_lightning_sprite": _kills.get("kills_lightning_sprite", 0),
		"p_kills_stone_golem":      _kills.get("kills_stone_golem",      0),
		"p_kills_necromancer":      _kills.get("kills_necromancer",      0),
		"p_kills_poison_toad":      _kills.get("kills_poison_toad",      0),
		"p_kills_warden":           _kills.get("kills_warden",           0),
		"p_kills_lich":             _kills.get("kills_lich",             0),
		"p_kills_phantom":          _kills.get("kills_phantom",          0),
		"p_kills_plague_lord":      _kills.get("kills_plague_lord",      0),
		"p_kills_storm_tyrant":     _kills.get("kills_storm_tyrant",     0),
		"p_total_kills":            _total_kills,
	}
	PlayerAuth.supabase_rpc("upsert_tracker", params, func(_r, _c, _b): pass)


func _submit_high_score() -> void:
	var room := GameState.room_counter
	if room < 5:
		return  # only submit scores for runs that cleared at least wave 5

	var core_names: Array[String] = []
	for core_int in GameState.player_cores:
		core_names.append(CORE_NAMES.get(core_int, "Unknown"))

	var body := {
		"user_id":      PlayerAuth.user_id,
		"display_name": PlayerAuth.username,
		"highest_room": room,
		"cores":        core_names,
	}
	PlayerAuth.rest_post("high_scores", body, func(_r, _c, _b): pass)

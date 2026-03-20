extends Node

# ---------------------------------------------------------------------------
# Track list — all 5 files in the audio folder
# ---------------------------------------------------------------------------
const TRACKS: Array[String] = [
	"res://assets/audio/5 Action Chiptunes By Juhani Junkala/Juhani Junkala [Retro Game Music Pack] Ending.wav",
	"res://assets/audio/5 Action Chiptunes By Juhani Junkala/Juhani Junkala [Retro Game Music Pack] Level 1.wav",
	"res://assets/audio/5 Action Chiptunes By Juhani Junkala/Juhani Junkala [Retro Game Music Pack] Level 2.wav",
	"res://assets/audio/5 Action Chiptunes By Juhani Junkala/Juhani Junkala [Retro Game Music Pack] Level 3.wav",
	"res://assets/audio/5 Action Chiptunes By Juhani Junkala/Juhani Junkala [Retro Game Music Pack] Title Screen.wav",
]

var _player: AudioStreamPlayer

# Current volume, 0.0 (silent) – 1.0 (full display / 0.5 actual audio max)
var volume: float = 0.05

# Index into TRACKS that was chosen for the home screen this session
var _home_track_idx: int = -1

# Shuffled pool of the 4 remaining level track indices
var _level_tracks: Array = []
var _level_pool_pos: int = 0

# Which 2-level pair we last started music for (-1 = none yet)
var _current_pair: int = -1


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	# Re-trigger play when a track ends (manual loop)
	_player.finished.connect(func(): _player.play())
	# Apply default volume immediately
	set_volume(volume)


# Call this from the home screen _ready()
func play_home_screen() -> void:
	_home_track_idx = randi() % TRACKS.size()
	_init_level_pool()
	_play(_home_track_idx)


# Call this from sliders whenever the player adjusts volume (0.0 – 1.0)
func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	if volume <= 0.0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		# Map display range 0–1 to actual audio range 0–0.5
		AudioServer.set_bus_volume_db(0, linear_to_db(volume * 0.5))


# Call this from every room script _ready(), passing GameState.room_counter
func on_room_entered(room_counter: int) -> void:
	var pair := room_counter / 2
	if pair == _current_pair:
		return  # still in the same 2-level block — keep current song
	_current_pair = pair
	# Advance through the shuffled pool, wrapping around when exhausted
	var idx: int = _level_tracks[_level_pool_pos % _level_tracks.size()]
	_level_pool_pos += 1
	_play(idx)


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------
func _init_level_pool() -> void:
	_level_tracks = []
	for i in TRACKS.size():
		if i != _home_track_idx:
			_level_tracks.append(i)
	_level_tracks.shuffle()
	_level_pool_pos = 0
	_current_pair   = -1


func _play(track_idx: int) -> void:
	_player.stream = load(TRACKS[track_idx])
	_player.play()

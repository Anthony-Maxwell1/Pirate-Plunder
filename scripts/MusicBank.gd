extends Node

enum Mode { THIRD, HALF, FULL, NONE }
enum Automatic { DISABLED, BGMUSIC }
@export var tracks: Array[AudioStream]
@export_category("Automatic")
@export var automatic: Automatic = Automatic.DISABLED
@export_group("Bgmusic")
@export var repeatMode: Mode = Mode.THIRD

const INVALID_ID := -50000

var max_wait: int = 0 # maximum tracks until a track can be replayed again

var last_played: Array[String] = [] # last played tracks

var curr_id: int = INVALID_ID

func _not_in_last_played():
	return tracks.filter(func(a): return not last_played.has(a.get_rid()))

func _automatic_bgmusic_pick_and_play():
	var track = _not_in_last_played().pick_random()
	if last_played.size() > max_wait:
		last_played.pop_front()
	last_played.append(track.get_rid())
	curr_id = MusicManager.play(track)

func play_track(rid: int = INVALID_ID) -> bool:
	if rid != INVALID_ID:
		if curr_id != INVALID_ID:
			MusicManager.remove(curr_id)
			curr_id = INVALID_ID
		curr_id = MusicManager.play(tracks[tracks.find_custom(func(a): return a.get_rid() == rid)])
		return true
	return false

func _ready():
	if automatic == Automatic.BGMUSIC:
		if repeatMode == Mode.THIRD: max_wait = floor(tracks.size() / 3) # these will always be > 0, so nonegative protection is needed
		if repeatMode == Mode.HALF: max_wait = floor(tracks.size() / 2)
		if repeatMode == Mode.FULL: max_wait = max(tracks.size() - 1, 0) # make sure it doesn't go below 0
	_automatic_bgmusic_pick_and_play()

func _process(delta: float):
	if not curr_id or not MusicManager.get_playing(curr_id):
		_automatic_bgmusic_pick_and_play()

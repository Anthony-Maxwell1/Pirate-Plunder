extends Node

enum Mode { THIRD, HALF, FULL, NONE }
enum Automatic { DISABLED, BGMUSIC }

@export var tracks: Array[MusicTrack]

@export_category("Automatic")
@export var automatic: Automatic = Automatic.DISABLED

@export_group("Bgmusic")
@export var repeatMode: Mode = Mode.THIRD


const INVALID_INDEX := MusicManager.INVALID_INDEX

var max_wait: int = 0
var last_played: Array[String] = [] # store track names
var curr_id: int = INVALID_INDEX

var auto_playing: bool = true

enum ListenerType { PLAY_TRACK }

var listeners: Dictionary[ListenerType, Array] = { # nested collection doesn't work in gdscript
	ListenerType.PLAY_TRACK: [],
}

func _get_track_by_name(name: String) -> MusicTrack:
	for t in tracks:
		if t.name == name:
			return t
	return null


func _not_in_last_played() -> Array[MusicTrack]:
	return tracks.filter(func(t): return not last_played.has(t.name))


func _automatic_bgmusic_pick_and_play():
	var available := _not_in_last_played()

	if available.is_empty():
		last_played.clear()
		available = tracks

	var track: MusicTrack = available.pick_random()

	# update history
	if last_played.size() > max_wait:
		last_played.pop_front()

	last_played.append(track.name)

	# play
	if curr_id != INVALID_INDEX:
		MusicManager.remove(curr_id)

	curr_id = MusicManager.play(track.stream)


func play_track(name: String) -> bool:
	var track := _get_track_by_name(name)
	if track == null:
		return false

	if curr_id != INVALID_INDEX:
		MusicManager.remove(curr_id)

	curr_id = MusicManager.play(track.stream)
	for v in listeners[ListenerType.PLAY_TRACK]:
		v.call()
	return true

func fetch_id() -> int:
	if curr_id != INVALID_INDEX:
		return curr_id
	return INVALID_INDEX

func fetch_player() -> AudioStreamPlayer:
	if curr_id == INVALID_INDEX:
		return null
	return MusicManager.get_player(curr_id)

func stop_auto(stop_curr_music: bool = true, del_curr_music: bool = true) -> void:
	auto_playing = false
	if curr_id == INVALID_INDEX:
		return
	if stop_curr_music:
		MusicManager.stop(curr_id)
	if del_curr_music:
		MusicManager.remove(curr_id)

func _ready() -> void:
	if automatic == Automatic.BGMUSIC:
		if repeatMode == Mode.THIRD:
			max_wait = floor(tracks.size() / 3)
		elif repeatMode == Mode.HALF:
			max_wait = floor(tracks.size() / 2)
		elif repeatMode == Mode.FULL:
			max_wait = max(tracks.size() - 1, 0)
		else:
			max_wait = 0

	_automatic_bgmusic_pick_and_play()

func add_listener(listener_type: ListenerType, listener: Callable):
	listeners[listener_type].append(listener)

func _process(delta: float) -> void:
	if curr_id == INVALID_INDEX or not MusicManager.get_playing(curr_id):
		_automatic_bgmusic_pick_and_play()

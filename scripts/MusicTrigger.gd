extends Node

enum Mode { THIRD, HALF, FULL, NONE }

@export var bank: String
@export var tracks: Array
@export var repeatMode: Mode = Mode.THIRD

var last_played: Array = []

var max_last_played: int = 0

func _not_in_last_played(element):
	return not last_played.has(element)

func _pick_track() -> String:
	var filtered_list = tracks.filter(_not_in_last_played)
	var res = filtered_list.pick_random()
	if last_played.size() >= max_last_played:
		last_played.pop_front()
	last_played.append(res)
	return res

func _pick_and_play_track() -> void:
	var track = _pick_track()
	MusicManager.play(bank, track)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if repeatMode == Mode.THIRD:
		max_last_played = floor(tracks.size() / 3)
	if repeatMode == Mode.HALF:
		max_last_played = floor(tracks.size() / 2)
	if repeatMode == Mode.FULL:
		max_last_played = tracks.size()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not MusicManager.is_playing():
		_pick_and_play_track()

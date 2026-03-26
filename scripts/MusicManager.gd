extends Node

var current: Dictionary[int, AudioStreamPlayer]

var idx: int = -40000

const INVALID_INDEX := -40001

func generate(track: AudioStream, autoplay: bool = false) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = track
	player.autoplay = autoplay
	add_child(player)
	return player

func _fix_position(position: float, length: float) -> float:
	if position < 0:
		return position + length
	return position

func play(track: AudioStream = null, id_: int = INVALID_INDEX, position: float = 0.0, autoplay: bool = true) -> int:
	if id_ == INVALID_INDEX:
		var id = idx
		idx += 1
		var player = generate(track)
		current[id] = player
		if autoplay: player.play(_fix_position(position, track.get_length()))
		return id
	else:
		if not current.has(id_):
			return 0
		current[id_].play(_fix_position(position, current[id_].get_length()))
		return 1

func get_player(id: int) -> AudioStreamPlayer:
	if not current.has(id):
		return null
	return current[id]

func get_playing(id: int) -> bool:
	if not current.has(id):
		return false
	return get_player(id).playing

func get_playback_position(id: int) -> int:
	if not current.has(id):
		return -1
	return get_player(id).get_playback_position()

func goto(id: int, position: float = 0.0) -> bool:
	if not current.has(id):
		return false
	current[id].seek(_fix_position(position, current[id].stream.get_length()))
	return true

func seek(id: int, amount: float = 0.0) -> bool:
	if not current.has(id):
		return false
	return goto(id, current[id].get_playback_position() + amount)

func stop(id: int) -> bool:
	if not current.has(id):
		return false
	current[id].stop()
	return true

func remove(id: int) -> bool:
	if not current.has(id):
		return false
	current[id].queue_free()
	current.erase(id)
	return true

func insert(player: AudioStreamPlayer, id: int = INVALID_INDEX) -> bool:
	if id == INVALID_INDEX:
		id = idx
		idx += 1
	if current.has(id):
		return false
	current[id] = player
	return true

func replace(player: AudioStreamPlayer, id: int) -> bool:
	if id == null or not current.has(id):
		return false
	current[id].queue_free()
	current[id] = player
	return true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

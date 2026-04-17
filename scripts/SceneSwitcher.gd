extends Node

@export var LoadingScreen: Control
@export var ProgressBar_: ProgressBar
@export_file("*.tscn") var scene_path: String

var loading := false

func _on_button_pressed() -> void:
	if loading:
		return
	
	loading = true
	LoadingScreen.visible = true

	var progress = []
	ResourceLoader.load_threaded_request(scene_path)

	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)

		if ProgressBar_ and progress.size() > 0:
			ProgressBar_.value = progress[0] * 100.0

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(scene)
			break

		await get_tree().process_frame

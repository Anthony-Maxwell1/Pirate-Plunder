extends Node

const SAVE_PATH := "user://savegame.save"

func save_game():
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	var save_nodes = get_tree().get_nodes_in_group("Persist")

	for node in save_nodes:

		#if node.scene_file_path.is_empty():
			#print("Skipped non-instanced scene: ", node.name)
			#continue

		if !node.has_method("save"):
			print("Skipped missing save(): ", node.name)
			continue

		var data = node.call("save")

		# 🔑 REQUIRED: deterministic ID
		var id = node.get_meta("save_id") if node.has_meta("save_id") else ""

		if id == "":
			print("Skipped node without save_id: ", node.name)
			continue

		data["id"] = id

		var json_string = JSON.stringify(data)
		save_file.store_line(json_string)

# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)

	# 🔑 Build lookup table of existing nodes by ID
	var existing := {}

	for node in get_tree().get_nodes_in_group("Persist"):
		if node.has_meta("save_id"):
			existing[node.get_meta("save_id")] = node

	while save_file.get_position() < save_file.get_length():

		var json_string = save_file.get_line()

		var json = JSON.new()
		if json.parse(json_string) != OK:
			print("JSON error: ", json.get_error_message())
			continue

		var node_data = json.data
		var id = node_data.get("id", "")

		if id == "":
			continue

		var new_object = null

		# 🔑 REUSE if exists
		if existing.has(id):
			new_object = existing[id]
		else:
			# instantiate new if missing
			new_object = load(node_data["filename"]).instantiate()
			get_node(node_data["parent"]).add_child(new_object)

			# register it
			existing[id] = new_object

			# ensure metadata exists
			new_object.set_meta("save_id", id)

		# ─────────────────────────────
		# RESTORE TRANSFORM
		# ─────────────────────────────

		new_object.position = Vector3(
			node_data.get("pos_x", 0),
			node_data.get("pos_y", 0),
			node_data.get("pos_z", 0)
		)

		new_object.rotation = Vector3(
			node_data.get("rot_x", 0),
			node_data.get("rot_y", 0),
			node_data.get("rot_z", 0)
		)

		# ─────────────────────────────
		# RESTORE CUSTOM DATA
		# ─────────────────────────────

		for k in node_data.keys():
			if k in [
				"filename", "parent",
				"pos_x", "pos_y", "pos_z",
				"rot_x", "rot_y", "rot_z",
				"id"
			]:
				continue

			new_object.set(k, node_data[k])


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

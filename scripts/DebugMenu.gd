extends Control

@export var button: Button
@export var label: Label
@export var input: LineEdit

@export_group("MusicBanks")
@export var bgmusic: Node

func bgmusic_stop() -> void:
	MusicManager.stop(bgmusic.call("fetch_id"))

func bgmusic_goto(position_: String) -> void:
	var position = float(position_)
	MusicManager.goto(bgmusic.call("fetch_id"), position)

func bgmusic_seek(position_: String) -> void:
	var position = float(position_)
	MusicManager.seek(bgmusic.call("fetch_id"), position)

var ui_data = [
	#{
		#"type": "input",
		#"name": "MusicBank",
		#"placeholder": "MusicBank..."
	#},
	#{
		#"type": "input",
		#"name": "Track",
		#"placeholder": "Track..."
	#},
	#{
		#"type": "button",
		#"text": "Play Track",
		#"function": "resonate_play_track",
		#"args": ["$MusicBank", "$Track"]
	#},
	{
		"type": "button",
		"text": "Stop/Skip bgmusic",
		"function": "bgmusic_stop",
		"args": []
	},
	{
		"type": "input",
		"name": "seek_length",
		"placeholder": "Seek length..."
	},
	{
		"type": "button",
		"text": "Seek bgmusic",
		"function": "bgmusic_seek",
		"args": ["$seek_length"]
	},
		{
		"type": "input",
		"name": "goto_length",
		"placeholder": "Goto length..."
	},
	{
		"type": "button",
		"text": "Goto bgmusic",
		"function": "bgmusic_goto",
		"args": ["$goto_length"]
	}
]

func _ready():
	button.hide()
	label.hide()
	input.hide()
	
	generate_ui()

func generate_ui():
	var idx = 0
	
	for item in ui_data:
		var node
		
		match item.get("type", "button"):
			"button":
				node = button.duplicate()
				node.text = item.get("text", "Button")
				node.setup(item, self)
			
			"label":
				node = label.duplicate()
				node.text = item.get("text", "")
			
			"input":
				node = input.duplicate()
				node.placeholder_text = item.get("placeholder", "")
				
				# IMPORTANT: give it a name so $NameInput works
				node.name = item.get("name", "Input")
		
		node.show()
		
		# Positioning
		node.position.y += (node.size.y + 5) * idx
		
		add_child(node)
		idx += 1

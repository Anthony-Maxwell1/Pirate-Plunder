extends Control

@export var button: Button
@export var label: Label
@export var input: LineEdit

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
	#{
		#"type": "button",
		#"text": "Stop Track",
		#"function": "resonate_stop",
		#"args": []
	#},
	#{
		#"type": "input",
		#"name": "seek_length",
		#"placeholder": "Seek length..."
	#},
	#{
		#"type": "button",
		#"text": "Seek Track",
		#"function": "resonate_seek_track",
		#"args": ["$seek_length"]
	#}
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

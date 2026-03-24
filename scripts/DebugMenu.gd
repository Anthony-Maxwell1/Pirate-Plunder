extends Control

@export var button: Button
@export var label: Label
@export var input: LineEdit

func print_name(name):
	print("Name:", name)


func add_numbers(a, b):
	# Convert safely to numbers
	var num1 = float(a)
	var num2 = float(b)
	
	print("Result:", num1 + num2)

var ui_data = [
	{
		"type": "label",
		"text": "Enter your name:"
	},
	{
		"type": "input",
		"name": "NameInput",
		"placeholder": "Name here..."
	},
	{
		"type": "button",
		"text": "Print Name",
		"function": "print_name",
		"args": ["$NameInput"]
	},
	{
		"type": "input",
		"name": "Num1",
		"placeholder": "First number"
	},
	{
		"type": "input",
		"name": "Num2",
		"placeholder": "Second number"
	},
	{
		"type": "button",
		"text": "Add Numbers",
		"function": "add_numbers",
		"args": ["$Num1", "$Num2"]
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

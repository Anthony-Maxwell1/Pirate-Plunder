extends Button

var action_data
var parent_ref

func setup(data: Dictionary, parent):
	action_data = data
	parent_ref = parent
	
	text = data.get("text", "Button")
	pressed.connect(_on_pressed)

func _on_pressed():
	var func_name = action_data.get("function", "")
	var args = []

	for arg in action_data.get("args", []):
		if typeof(arg) == TYPE_STRING and arg.begins_with("$"):
			var node = parent_ref.get_node(arg.replace("$", ""))
			
			# If it's a LineEdit, use its text
			if node is LineEdit:
				args.append(node.text)
			else:
				args.append(node)
		else:
			args.append(arg)

	if parent_ref.has_method(func_name):
		parent_ref.callv(func_name, args)
	else:
		push_error("Function not found: " + func_name)

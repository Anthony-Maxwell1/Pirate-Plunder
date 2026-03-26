extends Button

@export var menu: Control

func _button_pressed():
	if menu.visible:
		menu.visible = false
	else:
		menu.visible = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

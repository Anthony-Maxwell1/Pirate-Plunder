extends Button

@export var isSaveButton: bool = false
@export var isLoadButton: bool = false

func _save_game():
	SaveManager.call("save_game")

func _load_game():
	SaveManager.call("load_game")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if isSaveButton:
		pressed.connect(_save_game)
	if isLoadButton:
		pressed.connect(_load_game)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

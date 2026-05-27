extends Button

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.seed = hash("my_awesome_seed")  # todo: randomly generate or take in from user
	print("Seed: " + rng.seed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

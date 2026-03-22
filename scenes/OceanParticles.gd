extends GPUParticles3D

func trigger_splash():
	restart()
	emitting = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	trigger_splash() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

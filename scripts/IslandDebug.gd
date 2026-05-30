extends Node2D

@export var island_source: Node

func _draw():
	if island_source == null:
		return
	
	for island in island_source.islands:
		if island.shape.size() < 3:
			continue

		draw_colored_polygon(island.shape, Color(0.2, 0.6, 1.0, 0.5))
		draw_polyline(island.shape, Color.BLACK, 2.0, true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

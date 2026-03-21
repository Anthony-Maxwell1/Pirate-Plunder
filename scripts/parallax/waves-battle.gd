extends Node2D

@export var speed := 50.0
@export var copies := 3

var chunks: Array[Node2D] = []
var chunk_width := 0.0

func _ready():
	chunk_width = get_width()

	chunks.append(self)

	for i in range(1, copies + 1):
		var clone = duplicate()

		# 🚨 prevent infinite duplication
		clone.set_script(null)
		clone.set_process(false)

		clone.position.x += chunk_width * i
		get_parent().add_child.call_deferred(clone)

		chunks.append(clone)

func _process(delta):
	for chunk in chunks:
		chunk.position.x -= speed * delta
		chunk.position.x = round(chunk.position.x) # pixel-perfect

	for chunk in chunks:
		if chunk.position.x < -chunk_width:
			var rightmost = get_rightmost_x()
			chunk.position.x = rightmost + chunk_width

func get_rightmost_x():
	var max_x = chunks[0].position.x
	for c in chunks:
		if c.position.x > max_x:
			max_x = c.position.x
	return max_x

func get_width():
	for child in get_children():
		if child is Sprite2D and child.name != "Shadow":
			return child.texture.get_width() * child.scale.x
	return 0.0

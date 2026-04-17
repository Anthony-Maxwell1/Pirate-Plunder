extends TextureRect

@export var speed := 100.0

var tiles: Array[TextureRect] = []
var tile_width: float

func _get_rightmost_x() -> float:
	var max_x := -INF
	for t in tiles:
		max_x = max(max_x, t.position.x)
	return max_x

func _ready() -> void:
	tile_width = size.x

	# create 2 clones (so we have 3 total)
	for i in range(2):
		var clone = duplicate() as TextureRect
		get_parent().add_child.call_deferred(clone)

		clone.position = position + Vector2(tile_width * (i + 1), 0)

		clone.set_meta("is_clone", true)
		tiles.append(clone)

	tiles.append(self)

func _process(delta: float) -> void:
	for tile in tiles:
		tile.position.x -= speed * delta

	# recycle tiles that moved off-screen
	for tile in tiles:
		if tile.position.x <= -tile_width:
			var rightmost = _get_rightmost_x()
			tile.position.x = rightmost + tile_width

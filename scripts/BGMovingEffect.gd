extends TextureRect

@export var speed := Vector2(-30.0, -30.0)

var tiles: Array[TextureRect] = []
var tile_size: Vector2

func _ready() -> void:
	if has_meta("is_clone"):
		return

	tile_size = size
	tiles.append(self)

	var directions = []

	if speed.x != 0:
		directions.append(Vector2(1, 0))
	if speed.y != 0:
		directions.append(Vector2(0, 1))
	if speed.x != 0 and speed.y != 0:
		directions.append(Vector2(1, 1))

	# Always ensure at least 2 tiles per axis
	for dir in directions:
		var clone = duplicate() as TextureRect
		clone.set_meta("is_clone", true)

		get_parent().add_child.call_deferred(clone)

		clone.position = position + (tile_size * dir)
		tiles.append(clone)

	# Create clones in BOTH directions if needed

func _process(delta: float) -> void:
	for tile in tiles:
		tile.position += speed * delta

	# recycle tiles
	for tile in tiles:
		if speed.x != 0 and tile.position.x <= -tile_size.x:
			tile.position.x += tile_size.x * 2 # reset to back

		if speed.y != 0 and tile.position.y <= -tile_size.y:
			tile.position.y += tile_size.y * 2 # reset to back

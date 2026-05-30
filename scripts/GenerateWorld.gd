extends Node

@export var DEBUG_EN : bool = false
@export var DEBUG_ISLAND_NODE : Node2D

@export var seed_: String = "my_awesome_seed"

var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()

# CONFIG
const SIZE := 256
const CELL_SIZE := 4.0

# EDGE TABLE (marching squares)
const EDGE_TABLE = {
	1:  [[Vector2(0.0, 0.5), Vector2(0.5, 1.0)]],
	2:  [[Vector2(0.5, 1.0), Vector2(1.0, 0.5)]],
	3:  [[Vector2(0.0, 0.5), Vector2(1.0, 0.5)]],
	4:  [[Vector2(1.0, 0.5), Vector2(0.5, 0.0)]],
	5:  [[Vector2(0.0, 0.5), Vector2(0.5, 0.0)], [Vector2(0.5, 1.0), Vector2(1.0, 0.5)]],
	6:  [[Vector2(0.5, 1.0), Vector2(0.5, 0.0)]],
	7:  [[Vector2(0.0, 0.5), Vector2(0.5, 0.0)]],
	8:  [[Vector2(0.5, 0.0), Vector2(0.0, 0.5)]],
	9:  [[Vector2(0.5, 1.0), Vector2(0.5, 0.0)]],
	10: [[Vector2(0.5, 1.0), Vector2(0.0, 0.5)], [Vector2(1.0, 0.5), Vector2(0.5, 0.0)]],
	11: [[Vector2(1.0, 0.5), Vector2(0.5, 0.0)]],
	12: [[Vector2(0.0, 0.5), Vector2(1.0, 0.5)]],
	13: [[Vector2(0.5, 1.0), Vector2(1.0, 0.5)]],
	14: [[Vector2(0.0, 0.5), Vector2(0.5, 1.0)]]
}

enum IslandType {
	PIRATE_CENTRAL,
	PIRATE_TOWN,
	PIRATE_ISLAND
}

class Island:
	var name: String
	var type: IslandType
	var position: Vector2
	var shape: PackedVector2Array

class DynamicIsland: # islands that can be generated with dynamic positions
	var name: String
	var type: IslandType

var GuaranteedIslands : Array[Island] = [] # Islands that are generated with set positions

@export var DynamicIslandTypes : Array[IslandType] = []
@export var DynamicIslandNames : Array[String] = []

var DynamicIslands : Array[DynamicIsland] = [] # populated from types and names

var islands: Array[Island] = []


func _ready():
	assert(len(DynamicIslandNames) == len(DynamicIslandTypes))
	
	var island = Island.new()
	island.name = "Pirate Starter"
	island.type = IslandType.PIRATE_CENTRAL
	island.position = Vector2.ZERO
	GuaranteedIslands.append(island)
	
	setup_dynislands()

	setup_noise()

	create_islands()
	generate_shapes()
	
	if DEBUG_EN and DEBUG_ISLAND_NODE: DEBUG_ISLAND_NODE.queue_redraw()

func setup_dynislands() -> void:
	for islandIdx in range(DynamicIslandNames.size()):
		var name = DynamicIslandNames[islandIdx]
		var type = DynamicIslandTypes[islandIdx]
		var dyn = DynamicIsland.new()
		dyn.name = name
		dyn.type = type
		DynamicIslands.append(dyn)

func create_islands() -> void:
	islands = GuaranteedIslands
	
	var grid = generate_grid(20, 20, 500)
	
	for dynIsland in DynamicIslands:
		var random_pos = grid.pick_random()
		grid.erase(random_pos)
		var neighbors = [
			Vector2(
				random_pos.x + 1,
				random_pos.y
			),
			Vector2(
				random_pos.x,
				random_pos.y + 1
			),
			Vector2(
				random_pos.x + 1,
				random_pos.y + 1,
			),
			Vector2(
				random_pos.x - 1,
				random_pos.y
			),
			Vector2(
				random_pos.x,
				random_pos.y - 1
			),
			Vector2(
				random_pos.x - 1,
				random_pos.y - 1,
			),
			Vector2(
				random_pos.x + 1,
				random_pos.y - 1
			),
			Vector2(
				random_pos.x - 1,
				random_pos.y + 1
			)
		]
		neighbors = neighbors.filter(func(x): return x in grid)
		var neighbors_to_rem = randi_range(1, len(neighbors)) # number of neighbors to remove
		for i in range(neighbors_to_rem):
			grid.erase(neighbors[randi_range(0, len(neighbors) - 1)])
		var dyn = Island.new()
		dyn.name = dynIsland.name
		dyn.type = dynIsland.type
		dyn.position = random_pos
		islands.append(dyn)

func generate_shape() -> PackedVector2Array:
	var mask = generate_mask()

	fill_holes(mask)

	var poly = mask_to_polygon(mask)
	
	return poly

func generate_shapes() -> void:
	for island in islands:
		island.shape = generate_shape()

func generate_grid(width: int, height: int, spacing: float) -> Array[Vector2]:
	var grid_points: Array[Vector2] = []
	
	for x in range(width):
		for y in range(height):
			grid_points.append(Vector2(x * spacing, y * spacing))
			
	return grid_points


func setup_noise() -> void:
	var world_seed = hash(seed_)
	rng.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 1.0 / 20.0
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.9
	noise.seed = world_seed


func generate_mask() -> Array:
	var data := []

	for y in range(SIZE):
		var row := []
		for x in range(SIZE):

			var uv = Vector2(x, y) / SIZE
			var centered = uv * 2.0 - Vector2.ONE

			var dist = centered.length()

			var n = noise.get_noise_2d(x, y)

			var value = n - dist

			row.append(value > 0.0)

		data.append(row)

	return data


func fill_holes(mask: Array) -> void:
	var visited = []
	for y in range(SIZE):
		visited.append([])
		for x in range(SIZE):
			visited[y].append(false)

	var stack := []

	# flood fill ocean (false) from edges
	for x in range(SIZE):
		if not mask[0][x]:
			stack.append(Vector2i(x, 0))
		if not mask[SIZE-1][x]:
			stack.append(Vector2i(x, SIZE-1))

	for y in range(SIZE):
		if not mask[y][0]:
			stack.append(Vector2i(0, y))
		if not mask[y][SIZE-1]:
			stack.append(Vector2i(SIZE-1, y))

	var dirs = [
		Vector2i(1,0), Vector2i(-1,0),
		Vector2i(0,1), Vector2i(0,-1)
	]

	while not stack.is_empty():
		var p = stack.pop_back()

		if visited[p.y][p.x]:
			continue
		if mask[p.y][p.x]:
			continue

		visited[p.y][p.x] = true

		for d in dirs:
			var nx = p.x + d.x
			var ny = p.y + d.y

			if nx >= 0 and nx < SIZE and ny >= 0 and ny < SIZE:
				stack.append(Vector2i(nx, ny))

	# fill internal holes
	for y in range(SIZE):
		for x in range(SIZE):
			if not mask[y][x] and not visited[y][x]:
				mask[y][x] = true


func mask_to_polygon(mask: Array) -> PackedVector2Array:
	var segments := []

	for y in range(SIZE - 1):
		for x in range(SIZE - 1):

			var a = int(mask[y][x])
			var b = int(mask[y][x + 1])
			var c = int(mask[y + 1][x + 1])
			var d = int(mask[y + 1][x])

			var idx = (a << 3) | (b << 2) | (c << 1) | d

			if not EDGE_TABLE.has(idx):
				continue

			for seg in EDGE_TABLE[idx]:
				var p1 = (Vector2(x, y) + seg[0]) * CELL_SIZE
				var p2 = (Vector2(x, y) + seg[1]) * CELL_SIZE

				segments.append([p1, p2])

	return stitch_segments(segments)


func stitch_segments(segments: Array) -> PackedVector2Array:
	if segments.is_empty():
		return PackedVector2Array()

	var map := {}

	for s in segments:
		var a = s[0]
		var b = s[1]

		var ka = str(a)
		var kb = str(b)

		if not map.has(ka):
			map[ka] = []
		if not map.has(kb):
			map[kb] = []

		map[ka].append(b)
		map[kb].append(a)

	var start_key = map.keys()[0]
	var current = map[start_key][0]

	var polygon := PackedVector2Array()
	polygon.append(current)

	var prev = Vector2(INF, INF)
	var start = current

	for i in range(10000):
		var key = str(current)
		if not map.has(key):
			break

		var next = null
		for n in map[key]:
			if n != prev:
				next = n
				break

		if next == null:
			break

		polygon.append(next)

		prev = current
		current = next

		if current.distance_to(start) < 0.01:
			break

	return polygon

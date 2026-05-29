# perlin noise params
# cell size 20
# size 256x256
# Levels 3
# attenuation 0.9
extends Button

var rng = RandomNumberGenerator.new()

enum IslandType {
	PIRATE_CENTRAL,
	PIRATE_TOWN,
	PIRATE_ISLAND
}

func generate_grid(width: int, height: int, spacing: float) -> Array[Vector2]:
	var grid_points: Array[Vector2] = []
	
	for x in range(width):
		for y in range(height):
			grid_points.append(Vector2(x * spacing, y * spacing))
			
	return grid_points

class Island:
	var name: String
	var type: IslandType
	var position: Vector2
	var shape: PackedVector2Array

var islands : Array[Island] = []

@export var seed_: String = "my_awesome_seed"

var GuaranteedIslands : Array[Island] = [] # Islands that are generated with set positions

class DynamicIsland: # islands that can be generated with dynamic positions
	var name: String
	var type: IslandType

@export var DynamicIslandTypes : Array[IslandType] = []
@export var DynamicIslandNames : Array[String] = []

var DynamicIslands : Array[DynamicIsland]

var size_distribution : Array[int] = []

var noise := FastNoiseLite.new()

func gen_shape(position) -> PackedVector2Array:
	var size := 256 # perlin noise size
	var data := []  # perlin noise
	
	for y in range(size): # rows
		var row := []
		for x in range(size): # columns
			var uv = Vector2(x, y) / size
			var centered = uv * 2.0 - Vector2.ONE
			
			var dist = centered.length() # radial gradient
			
			var n = noise.get_noise_2d(x, y) # generate noise
			
			var value = n - dist
			
			row.append(value)
		data.append(row)
	
	# Perlin noise generated, time to compare land vs water
	var threshold = 0.0 # Sea level / at what level do we consider a point land?
	var mask = []
	
	for y in range(size):
		var row := []
		for x in range(size):
			row.append(data[y][x] > threshold)
		mask.append(row)
	
	return PackedVector2Array() # todo, finish

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(len(DynamicIslandNames) == len(DynamicIslandTypes))
	
	var island = Island.new()
	island.name = "Pirate Starter"
	island.type = IslandType.PIRATE_CENTRAL
	island.position = Vector2.ZERO
	GuaranteedIslands.append(island)
	
	rng.seed = hash(seed_)  # todo: randomly generate or take in from user
	print("Seed: " + seed_)
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 1.0 / 20.0
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.9
	noise.seed = hash(seed_)
	
	for islandIdx in range(DynamicIslandNames.size()):
		var name = DynamicIslandNames[islandIdx]
		var type = DynamicIslandTypes[islandIdx]
		var dyn = DynamicIsland.new()
		dyn.name = name
		dyn.type = type
		DynamicIslands.append(dyn)
	
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
	
	# later we can add procedurally generated islands outside of predefined names and types

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

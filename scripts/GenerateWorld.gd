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

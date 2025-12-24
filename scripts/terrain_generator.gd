extends RefCounted
class_name TerrainGenerator

# Generates procedural terrain using the C++ SandSimulation directly

static func generate_terrain(sim: SandSimulation, seed_val: int = 0) -> void:
	randomize()
	if seed_val > 0:
		seed(seed_val)
	
	var width: int = sim.get_width()
	var height: int = sim.get_height()
	
	# Terrain surface noise
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Cave noise (smaller scale, more frequent)
	var cave_noise := FastNoiseLite.new()
	cave_noise.seed = randi()
	cave_noise.frequency = 0.08
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	var terrain_base: int = 30
	var terrain_variation: int = 15
	var cave_threshold: float = 0.1  # Higher = fewer caves
	
	# Generate layered terrain
	for col in range(width):
		var noise_val: float = noise.get_noise_1d(col)
		var terrain_height: int = int(terrain_base + noise_val * terrain_variation)
		
		# Place grass on surface and freeze it
		if terrain_height < height:
			sim.set_cell(terrain_height, col, 4)  # Grass on top
			sim.freeze_cell(terrain_height, col)
		
		# Fill from just below surface down (no sand for now)
		for row in range(terrain_height + 1, height):
			var depth: int = row - terrain_height
			
			# Cave generation: create empty spaces below certain depth
			if depth > 5:  # Caves only deep down, preserve surface
				var cave_val: float = cave_noise.get_noise_2d(float(col), float(row))
				if cave_val > cave_threshold:
					# Cave space - leave empty
					continue
			
			# Use stone everywhere below grass so terrain stays static
			sim.set_cell(row, col, 2)  # Rock (element ID 2 in C++)
			sim.freeze_cell(row, col)

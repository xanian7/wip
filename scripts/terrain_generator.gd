extends RefCounted
class_name TerrainGenerator

# Generates procedural terrain using the C++ SandSimulation directly

static func generate_terrain(sim: SandSimulation, seed_val: int = 0) -> void:
	randomize()
	if seed_val > 0:
		seed(seed_val)
	
	var width: int = sim.get_width()
	var height: int = sim.get_height()
	
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	var terrain_base: int = 30
	var terrain_variation: int = 15
	
	# Generate layered terrain
	for col in range(width):
		var noise_val: float = noise.get_noise_1d(col)
		var terrain_height: int = int(terrain_base + noise_val * terrain_variation)
		
		# Fill from terrain surface down
		for row in range(terrain_height, height):
			var depth: int = row - terrain_height
			var element_id: int = 0
			
			if depth == 0:
				# Sand layer on top
				element_id = 1
			elif depth < 8:
				# More sand
				element_id = 1
			elif depth < 15:
				# Gravel mixed in
				if randf() > 0.7:
					element_id = 2
				else:
					element_id = 1
			else:
				# Stone at depth
				element_id = 3
			
			sim.set_cell(row, col, element_id)

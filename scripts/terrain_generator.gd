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
		
		# Place grass on surface
		if terrain_height < height:
			sim.set_cell(terrain_height, col, 4)  # Grass on top
		
		# Fill from just below surface down (no sand for now)
		for row in range(terrain_height + 1, height):
			# Use stone everywhere below grass so terrain stays static
			sim.set_cell(row, col, 3)

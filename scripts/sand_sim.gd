extends RefCounted
class_name SandSim

# Optimized simulation grid for falling sand simulation
# Based on sand-slide architecture but pure GDScript with performance optimizations

var width: int = 200
var height: int = 200
var chunk_size: int = 16

# Main data structures - using typed arrays for performance
var cells: PackedInt32Array  # Particle IDs on grid
var chunks: PackedInt32Array  # Active particle count per chunk
var chunk_width: int = 0
var chunk_height: int = 0

# Element properties (simple version)
enum ElementState { EMPTY, POWDER, LIQUID, SOLID, GAS }

# Pre-allocate element property arrays for faster lookup
var element_states: PackedInt32Array
var element_densities: PackedFloat32Array
var element_colors: PackedColorArray

func _init() -> void:
	# Initialize element properties
	element_states = PackedInt32Array()
	element_states.resize(256)  # Support up to 256 element types
	element_densities = PackedFloat32Array()
	element_densities.resize(256)
	element_colors = PackedColorArray()
	element_colors.resize(256)
	
	# Set up default elements
	setup_element(0, ElementState.EMPTY, 0.0, Color(0, 0, 0, 1))
	setup_element(1, ElementState.POWDER, 1.5, Color(0.8, 0.7, 0.3, 1))  # Sand
	setup_element(2, ElementState.LIQUID, 1.0, Color(0.2, 0.4, 0.8, 1))  # Water
	setup_element(3, ElementState.SOLID, 2.0, Color(0.5, 0.5, 0.5, 1))   # Stone
	
	resize(width, height)

func setup_element(id: int, state: int, density: float, color: Color) -> void:
	element_states[id] = state
	element_densities[id] = density
	element_colors[id] = color

func resize(new_width: int, new_height: int) -> void:
	width = new_width
	height = new_height
	chunk_width = ceili(float(width) / float(chunk_size))
	chunk_height = ceili(float(height) / float(chunk_size))
	
	cells = PackedInt32Array()
	cells.resize(width * height)
	cells.fill(0)
	
	chunks = PackedInt32Array()
	chunks.resize(chunk_width * chunk_height)
	chunks.fill(0)

@warning_ignore("integer_division")
func step(iterations: int) -> void:
	for _iter in iterations:
		# Process from bottom to top, left to right
		for chunk_idx in range(chunks.size() - 1, -1, -1):
			if chunks[chunk_idx] == 0:
				continue
			
			var chunk_row: int = int(float(chunk_idx) / float(chunk_width))
			var chunk_col: int = chunk_idx % chunk_width
			
			# Process chunk cells from bottom to top
			for row_offset in range(chunk_size - 1, -1, -1):
				for col_offset in range(chunk_size):
					var row: int = chunk_row * chunk_size + row_offset
					var col: int = chunk_col * chunk_size + col_offset
					
					if row >= height or col >= width:
						continue
					
					var idx: int = row * width + col
					var cell_id: int = cells[idx]
					if cell_id == 0:
						continue
					
					# Process based on element type
					var state: int = element_states[cell_id]
					if state == ElementState.POWDER:
						process_powder(row, col)
					elif state == ElementState.LIQUID:
						process_liquid(row, col)

func process_powder(row: int, col: int) -> void:
	# Try to fall straight down (increased gravity - fall up to 3 cells per step)
	for fall_dist in range(1, 4):
		if try_move(row, col, row + fall_dist, col):
			return
	
	# Try to fall diagonally (random direction first)
	var dir: int = 1 if randf() > 0.5 else -1
	if try_move(row, col, row + 1, col + dir):
		return
	if try_move(row, col, row + 1, col - dir):
		return

func process_liquid(row: int, col: int) -> void:
	# Try to fall straight down (increased gravity - fall up to 2 cells per step)
	for fall_dist in range(1, 3):
		if try_move(row, col, row + fall_dist, col):
			return
	
	# Try to fall diagonally (random direction first)
	var dir: int = 1 if randf() > 0.5 else -1
	if try_move(row, col, row + 1, col + dir):
		return
	if try_move(row, col, row + 1, col - dir):
		return
	
	# Try to move sideways (fluidity - try both directions)
	if try_move(row, col, row, col + dir):
		return
	if try_move(row, col, row, col - dir):
		return

@warning_ignore("integer_division")
func try_move(row: int, col: int, new_row: int, new_col: int) -> bool:
	if not in_bounds(new_row, new_col):
		return false
	
	var idx: int = row * width + col
	var new_idx: int = new_row * width + new_col
	var current_id: int = cells[idx]
	var target_id: int = cells[new_idx]
	
	# Can't move into solid (avoid array lookup if not needed)
	if target_id == 3:  # SOLID element
		return false
	
	# Inline density comparison - avoid repeated array access
	var current_density: float = element_densities[current_id]
	var target_density: float = element_densities[target_id]
	
	if current_density > target_density:
		# Swap cells
		cells[idx] = target_id
		cells[new_idx] = current_id
		
		# Update chunk activity efficiently - inline chunk calculation
		var old_chunk: int = int(float(row) / float(chunk_size)) * chunk_width + int(float(col) / float(chunk_size))
		var new_chunk: int = int(float(new_row) / float(chunk_size)) * chunk_width + int(float(new_col) / float(chunk_size))
		
		if old_chunk != new_chunk:
			if target_id == 0:
				chunks[old_chunk] = max(0, chunks[old_chunk] - 1)
			if current_id != 0:
				chunks[new_chunk] += 1
		
		return true
	
	return false

func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < height and col >= 0 and col < width

func get_cell(row: int, col: int) -> int:
	if not in_bounds(row, col):
		return 0
	return cells[row * width + col]

@warning_ignore("integer_division")
func set_cell(row: int, col: int, value: int) -> void:
	if not in_bounds(row, col):
		return
	
	var idx: int = row * width + col
	var old_value: int = cells[idx]
	cells[idx] = value
	
	# Update chunk activity
	var chunk_idx: int = int(float(row) / float(chunk_size)) * chunk_width + int(float(col) / float(chunk_size))
	if chunk_idx >= 0 and chunk_idx < chunks.size():
		if old_value == 0 and value != 0:
			chunks[chunk_idx] += 1
		elif old_value != 0 and value == 0:
			chunks[chunk_idx] = max(0, chunks[chunk_idx] - 1)

func draw_cell(row: int, col: int, element_id: int) -> void:
	set_cell(row, col, element_id)

func get_width() -> int:
	return width

func get_height() -> int:
	return height

func get_color_data() -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	data.resize(width * height * 3)
	
	var idx: int = 0
	for i in range(width * height):
		var element_id: int = cells[i]
		var color: Color = element_colors[element_id]
		
		data[idx] = int(color.r * 255)
		data[idx + 1] = int(color.g * 255)
		data[idx + 2] = int(color.b * 255)
		idx += 3
	
	return data

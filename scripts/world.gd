extends Node2D

# Main simulation controller using sand-slide architecture
# Manages SandSim, Canvas rendering, and Painter input

@export var simulation_speed: int = 1
@export var canvas_scale: int = 3

var sim
var canvas
var painter
var active: bool = false
var fps_label: Label
var frame_times: PackedFloat32Array = PackedFloat32Array()
var current_frame: int = 0

func _ready() -> void:
	# Create C++ simulation (much faster!)
	sim = SandSimulation.new()
	sim.set_chunk_size(16)
	sim.resize(300, 200)
	
	# Initialize color system (required by C++ extension)
	initialize_colors()
	
	# Setup canvas (TextureRect node)
	canvas = Canvas.new()
	canvas.px_scale = canvas_scale
	canvas.position = Vector2.ZERO
	canvas.size = Vector2(sim.get_width() * canvas_scale, sim.get_height() * canvas_scale)
	add_child(canvas)
	
	# Setup painter
	painter = Painter.new()
	add_child(painter)
	
	# Wait one frame for nodes to initialize
	await get_tree().process_frame
	
	# Now setup simulation connections
	canvas.setup_simulation(sim)
	painter.setup(sim, canvas)
	
	# Setup FPS counter
	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 24)
	add_child(fps_label)
	
	# Generate procedural terrain
	TerrainGenerator.generate_terrain(sim, 12345)
	canvas.repaint()
	
	# Start simulation
	active = true

func initialize_colors() -> void:
	# Initialize color dictionaries required by C++ extension
	var flat_colors: Dictionary = {
		0: Color(0.1, 0.1, 0.1, 1.0).to_rgba32(),  # Empty/background
		15: Color(0.3, 0.3, 0.3, 1.0).to_rgba32()  # Wall
	}
	sim.initialize_flat_color(flat_colors)
	
	# Fluid colors (for powder and liquid elements)
	var fluid_colors: Dictionary = {
		1: [  # Sand
			Color(0.8, 0.7, 0.3, 1.0).to_rgba32(),
			Color(0.7, 0.6, 0.2, 1.0).to_rgba32(),
			Color(0.6, 0.5, 0.1, 1.0).to_rgba32()
		],
		2: [  # Water
			Color(0.2, 0.4, 0.8, 1.0).to_rgba32(),
			Color(0.15, 0.35, 0.7, 1.0).to_rgba32(),
			Color(0.1, 0.2, 0.5, 1.0).to_rgba32()
		],
		3: [  # Stone
			Color(0.5, 0.5, 0.5, 1.0).to_rgba32(),
			Color(0.4, 0.4, 0.4, 1.0).to_rgba32(),
			Color(0.3, 0.3, 0.3, 1.0).to_rgba32()
		],
		4: [  # Grass
			Color(0.2, 0.8, 0.2, 1.0).to_rgba32(),
			Color(0.15, 0.7, 0.15, 1.0).to_rgba32(),
			Color(0.1, 0.5, 0.1, 1.0).to_rgba32()
		]
	}
	sim.initialize_fluid_color(fluid_colors)
	
	# Initialize empty dicts for other color types
	sim.initialize_gradient_color({})
	sim.initialize_metal_color({})

func _process(delta: float) -> void:
	if active:
		sim.step(simulation_speed)
		canvas.repaint()
	
	# Update FPS counter
	frame_times.append(delta)
	current_frame += 1
	if current_frame % 10 == 0:
		var avg_delta: float = 0.0
		for t in frame_times:
			avg_delta += t
		avg_delta /= frame_times.size()
		var fps: int = int(1.0 / avg_delta) if avg_delta > 0 else 0
		fps_label.text = "FPS: %d" % fps
		frame_times.clear()

func generate_initial_terrain() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	var terrain_base: int = 20
	var terrain_variation: int = 10
	
	# Generate terrain from noise
	for col in range(sim.get_width()):
		var noise_val: float = noise.get_noise_1d(col)
		var terrain_height: int = int(terrain_base + noise_val * terrain_variation)
		
		# Fill from terrain surface down
		for row in range(terrain_height, sim.get_height()):
			var depth: int = row - terrain_height
			var element_id: int = 0
			
			if depth == 0:
				element_id = 1  # Sand on top
			elif depth < 5:
				element_id = 1  # More sand
			else:
				element_id = 3  # Stone below
			
			sim.set_cell(row, col, element_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				painter.selected_element = 4  # Grass (disable sand)
				get_tree().root.set_input_as_handled()
			KEY_2:
				painter.selected_element = 2  # Water
				get_tree().root.set_input_as_handled()
			KEY_3:
				painter.selected_element = 3  # Stone
				get_tree().root.set_input_as_handled()
			KEY_4:
				painter.selected_element = 4  # Grass
				get_tree().root.set_input_as_handled()
			KEY_0:
				painter.selected_element = 0  # Eraser
				get_tree().root.set_input_as_handled()
			KEY_C:
				painter.clear()
				get_tree().root.set_input_as_handled()
			KEY_SPACE:
				active = not active
				get_tree().root.set_input_as_handled()

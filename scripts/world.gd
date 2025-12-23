extends Node2D

@export var world_size: Vector2 = Vector2(1000, 100)
@export var pixel_scene: PackedScene
@export var terrain_height: float = 20.0  # Base terrain height
@export var terrain_roughness: float = 10.0  # How much height varies
@export var pixel_size: Vector2 = Vector2(1, 1)

var noise: FastNoiseLite

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_noise()
	generate_world()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi()  # Random seed each time
	noise.frequency = 0.02  # Lower = smoother terrain
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		generate_pixel()

'''
Generates a grid of pixels based on the world_size variable.
Each pixel is represented as a small colored square with physics properties.
On generation, pixels are placed in a grid layout and should not move until interacted with.
'''
func generate_world() -> void:
	for x in range(world_size.x):
		# Get terrain height at this X position using noise
		var height_value = noise.get_noise_1d(x)  # Returns -1 to 1
		var terrain_y = int(terrain_height + (height_value * terrain_roughness))
		
		# Generate pixels from terrain surface down to bottom
		for y in range(terrain_y, world_size.y):
			var depth = y - terrain_y  # Distance from surface
			generate_pixel_at_position(Vector2(int(x*pixel_size.x), int(y*pixel_size.y)), depth)

'''
Generates a pixel at a specific position in the world.
Should not move until interacted with.
@param position: The position where the pixel should be generated.
@param depth: The Y index (depth layer) for color selection.
'''
func generate_pixel_at_position(position: Vector2, depth: int = 0) -> void:
	var pixel = pixel_scene.instantiate()
	# Ensure exact integer positioning
	pixel.position = Vector2(int(position.x), int(position.y))
	pixel.freeze = true  # Freeze before adding to scene
	pixel.pixel_size = pixel_size
	
	# Assign color based on depth layer
	if depth == 0:
		pixel.pixel_color = Color(0.2 + randf() * 0.2, 0.6 + randf() * 0.2, 0.2 + randf() * 0.2)  # Green grass
	elif depth <= 3:
		pixel.pixel_color = Color(0.4 + randf() * 0.2, 0.25 + randf() * 0.15, 0.1 + randf() * 0.1)  # Brown dirt
	else:
		pixel.pixel_color = Color(0.4 + randf() * 0.2, 0.4 + randf() * 0.2, 0.4 + randf() * 0.2)  # Grey stone
	
	add_child(pixel)

func generate_pixel() -> void:
	# Create a RigidBody2D for physics
	var pixel = RigidBody2D.new()
	pixel.position = get_local_mouse_position()
	
	# Create a visual representation (small square)
	var visual = ColorRect.new()
	visual.size = Vector2(4, 4)
	visual.position = -visual.size / 2  # Center the visual
	visual.color = Color(randf(), randf(), randf())  # Random color
	
	# Create a collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(4, 4)
	collision.shape = shape
	collision.position = Vector2.ZERO  # Center the collision
	
	# Add components to the pixel
	pixel.add_child(visual)
	pixel.add_child(collision)
	
	# Add the pixel to the scene
	add_child(pixel)

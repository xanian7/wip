extends Node2D

@export var world_size: Vector2 = Vector2(140, 10)

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_world()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

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
		for y in range(world_size.y):
			generate_pixel_at_position(Vector2(x*4, y*4))

'''
Generates a pixel at a specific position in the world.
Should not move until interacted with.
@param position: The position where the pixel should be generated.
'''
func generate_pixel_at_position(position: Vector2) -> void:
	var pixel = RigidBody2D.new()
	pixel.position = position
	pixel.freeze = true  # Lock in place until interacted with
	
	var visual = ColorRect.new()
	visual.size = Vector2(4, 4)
	visual.position = -visual.size / 2  # Center the visual
	visual.color = Color(randf(), randf(), randf())  # Random color
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(4, 4)
	collision.shape = shape
	collision.position = Vector2.ZERO  # Center the collision
	
	pixel.add_child(visual)
	pixel.add_child(collision)
	
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

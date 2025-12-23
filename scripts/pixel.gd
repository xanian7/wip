extends RigidBody2D

@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $CollisionShape2D/Sprite2D

@export var pixel_color: Color = Color(1, 255, 1, 1)
@export var pixel_size: Vector2 = Vector2(4, 4)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set physics properties FIRST before any other setup
	freeze = true
	lock_rotation = true
	contact_monitor = false
	
	if sprite_2d and collision_shape_2d:
		sprite_2d.modulate = pixel_color
		
		# Ensure collision shape is properly sized and centered
		collision_shape_2d.shape.size = pixel_size
		collision_shape_2d.position = Vector2.ZERO
		
		# Position sprite relative to its parent (CollisionShape2D)
		sprite_2d.position = Vector2.ZERO
		if sprite_2d.texture:
			var texture_size = sprite_2d.texture.get_size()
			sprite_2d.scale = pixel_size / texture_size
		
		sprite_2d.centered = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

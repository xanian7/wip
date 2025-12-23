extends RigidBody2D

@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D

@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var max_speed: float = 300.0

var is_grounded: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(delta):
	if Input.is_action_just_pressed("jump"):
		# Apply a central impulse in the upward direction (-Y axis in 2D)
		apply_central_impulse(Vector2(0, -jump_force))

func _integrate_forces(state):
	# check inputs and move player
	var input_x = 0.0
	
	# Get input direction
	if Input.is_action_pressed("move_right"):
		input_x += 1
	if Input.is_action_pressed("move_left"):
		input_x -= 1
	
	# Set horizontal velocity only, preserve vertical velocity for gravity
	state.linear_velocity.x = input_x * move_speed

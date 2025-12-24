extends TextureRect
class_name Canvas

# Renders the simulation grid as an ImageTexture
# Based on sand-slide's Canvas implementation

@export var px_scale: int = 3

var sim

func _ready() -> void:
	# Initialize with a small texture
	texture = ImageTexture.create_from_image(Image.create(128, 128, false, Image.FORMAT_RGB8))
	
	# Wait for parent to be ready
	await get_tree().process_frame

func setup_simulation(simulation) -> void:
	sim = simulation
	repaint()

func repaint() -> void:
	if sim == null:
		return
	
	var width: int = sim.get_width()
	var height: int = sim.get_height()
	
	if width <= 0 or height <= 0:
		return
	
	var data: PackedByteArray = sim.get_color_image(false)
	var img: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
	texture.set_image(img)

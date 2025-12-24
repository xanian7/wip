extends Node
class_name Painter

# Handles mouse input and draws elements onto the simulation grid
# Based on sand-slide's Painter implementation

var sim
var canvas

var selected_element: int = 1  # Default to sand
var brush_size: int = 5
var press_released: bool = true
var start_draw: Vector2
var end_draw: Vector2

signal mouse_pressed(start: Vector2, end: Vector2)

func _ready() -> void:
	mouse_pressed.connect(_on_mouse_pressed)

func setup(simulation, render_canvas) -> void:
	sim = simulation
	canvas = render_canvas

func _process(_delta: float) -> void:
	if sim == null or canvas == null:
		return
	
	if Input.is_action_just_released("ui_accept") or Input.is_action_just_released("screen_press"):
		press_released = true
	elif Input.is_action_pressed("ui_accept") or Input.is_action_pressed("screen_press"):
		if press_released:
			var local_pos = canvas.get_local_mouse_position()
			start_draw = local_pos / canvas.px_scale
			press_released = false
			mouse_pressed.emit(start_draw, start_draw)
		else:
			var local_pos = canvas.get_local_mouse_position()
			end_draw = local_pos / canvas.px_scale
			mouse_pressed.emit(start_draw, end_draw)
			start_draw = end_draw

func _on_mouse_pressed(start: Vector2, end: Vector2) -> void:
	if start.distance_to(end) > brush_size / 2.0:
		var point: Vector2 = start
		var move_dir: Vector2 = (end - start).normalized()
		var step: float = brush_size / 4.0
		while point.distance_to(end) > step:
			draw_circle(point.x, point.y, int(float(brush_size) / 2.0))
			point += move_dir * step
	
	draw_circle(end.x, end.y, int(float(brush_size) / 2.0))

func draw_circle(x: float, y: float, radius: float) -> void:
	var row_i: int = roundi(y)
	var col_i: int = roundi(x)
	
	if not sim.in_bounds(row_i, col_i):
		return
	
	for row_offset in range(-roundi(radius), roundi(radius) + 1):
		for col_offset in range(-roundi(radius), roundi(radius) + 1):
			if row_offset * row_offset + col_offset * col_offset < radius * radius:
				draw_pixel(row_i + row_offset, col_i + col_offset)

func draw_pixel(row: int, col: int) -> void:
	# Add some randomness for powder elements (element 1 = sand in C++ extension)
	if selected_element == 1 and randf() > 0.1:
		return
	
	if not sim.in_bounds(row, col):
		return
	
	# C++ draw_cell marks visited=false to allow immediate physics interaction
	sim.draw_cell(row, col, selected_element)

func clear() -> void:
	for row in range(sim.get_height()):
		for col in range(sim.get_width()):
			sim.draw_cell(row, col, 0)
	canvas.repaint()

extends Node2D

var start_object = null
var end_object = null
var is_powered = false

@onready var line = $Line2D

func _ready():
	update_wire()

func setup(from_obj, to_obj):
	start_object = from_obj
	end_object = to_obj
	update_wire()

func _process(delta):
	update_wire()

func update_wire():
	if not start_object or not end_object or not line:
		return
	
	var start_pos = start_object.global_position
	var end_pos = end_object.global_position
	
	var points = calculate_rope_points(start_pos, end_pos)
	
	line.clear_points()
	for point in points:
		line.add_point(to_local(point))
	
	if is_powered:
		line.default_color = Color(1.0, 0.3, 0.3, 1.0)
	else:
		line.default_color = Color(0.6, 0.1, 0.1, 0.8)

func calculate_rope_points(start: Vector2, end: Vector2) -> Array:
	var points = []
	var num_segments = 8
	
	var distance = start.distance_to(end)
	var sag_amount = distance * 0.1
	
	for i in range(num_segments + 1):
		var t = float(i) / float(num_segments)
		
		var point = start.lerp(end, t)
		
		var sag = sin(t * PI) * sag_amount
		point.y += sag
		
		points.append(point)
	
	return points

func set_powered(powered: bool):
	is_powered = powered
	update_wire()

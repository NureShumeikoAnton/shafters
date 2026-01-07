extends Area2D

@export var cone_length = 512
@export var cone_width = 320

func _ready():
	add_to_group("light_areas")
	var half_width = cone_width / 2
	var points = [
		Vector2.ZERO,
		Vector2(cone_length, -half_width),
		Vector2(cone_length, half_width)
	]
	$CollisionPolygon2D.polygon = points

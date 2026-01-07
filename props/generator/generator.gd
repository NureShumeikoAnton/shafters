extends StaticBody2D

signal generator_state_changed(is_on: bool)
signal fuel_depleted
signal clicked(generator)

const MAX_FUEL = 100.0
const FUEL_CONSUMPTION_RATE = 1.0

var is_on = false
var fuel = MAX_FUEL
var player_in_range = false
var connected_lamps: Array = []
var mouse_hovering = false

@onready var interaction_area = $InteractionArea
@onready var light = $GeneratorPointLight2D
@onready var fuel_bar = $FuelBar

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	if fuel_bar:
		fuel_bar.visible = false
		fuel_bar.max_value = MAX_FUEL
		fuel_bar.value = fuel

	if ConnectionManager: 
		clicked.connect(ConnectionManager.on_generator_clicked)
	
	update_visual()

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		interact()
	
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	mouse_hovering = distance < 30
	
	if fuel_bar:
		fuel_bar.visible = mouse_hovering
		fuel_bar.value = fuel
	
	if is_on and fuel > 0:
		var total_consumption = FUEL_CONSUMPTION_RATE
		for lamp in connected_lamps:
			if lamp.is_on:
				total_consumption += lamp.FUEL_CONSUMPTION_RATE
		
		fuel -= total_consumption * delta
		fuel = max(0, fuel)
		
		if fuel <= 0:
			turn_off()
			fuel_depleted.emit()

func interact():
	if fuel > 0:
		toggle()
	else:
		print("Generator out of fuel!")

func toggle():
	if is_on:
		turn_off()
	else:
		turn_on()

func turn_on():
	if fuel > 0:
		is_on = true
		update_visual()
		generator_state_changed.emit(true)

func turn_off():
	is_on = false
	update_visual()
	generator_state_changed.emit(false)

func add_fuel(amount: float):
	fuel = min(fuel + amount, MAX_FUEL)

func get_fuel_percentage() -> float:
	return (fuel / MAX_FUEL) * 100.0

func update_visual():
	queue_redraw()
	
	if light:
		if fuel <= 0:
			light.enabled = false
		elif is_on:
			light.enabled = true
			light.color = Color.LIME_GREEN
			light.energy = 1
		else:
			light.enabled = true
			light.color = Color.RED
			light.energy = 1

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Generator clicked at: ", global_position)
		clicked.emit(self)

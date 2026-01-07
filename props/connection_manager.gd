extends Node

var first_clicked_object = null
var connections: Dictionary = {}
var wires: Dictionary = {}

var wire_scene = preload("res://props/wire.tscn")

func _ready():
	print("ConnectionManager initialized")

func on_generator_clicked(generator):
	print("ConnectionManager: Generator clicked")
	
	if first_clicked_object == null:
		first_clicked_object = generator
		highlight_object(generator, true)
		print("Selected generator, click a lamp to connect")
	elif first_clicked_object == generator:
		highlight_object(generator, false)
		first_clicked_object = null
		print("Deselected generator")
	else:
		if first_clicked_object is StaticBody2D and first_clicked_object.has_signal("lamp_toggled"):
			create_connection(generator, first_clicked_object)
			highlight_object(first_clicked_object, false)
			first_clicked_object = null

func on_lamp_clicked(lamp):
	print("ConnectionManager: Lamp clicked")
	
	if first_clicked_object == null:
		first_clicked_object = lamp
		highlight_object(lamp, true)
		print("Selected lamp, click a generator to connect")
	elif first_clicked_object == lamp:
		highlight_object(lamp, false)
		first_clicked_object = null
		print("Deselected lamp")
	else:
		if first_clicked_object is StaticBody2D and first_clicked_object.has_signal("generator_state_changed"):
			create_connection(first_clicked_object, lamp)
			highlight_object(first_clicked_object, false)
			first_clicked_object = null

func create_connection(generator, lamp):
	print("Creating connection: Generator -> Lamp")
	
	if not connections.has(generator):
		connections[generator] = []
	
	if lamp in connections[generator]:
		print("Already connected!")
		return
	
	connections[generator].append(lamp)
	
	lamp.connected_generator = generator
	lamp.is_connected = true
	
	if not generator.generator_state_changed.is_connected(lamp.on_generator_state_changed):
		generator.generator_state_changed.connect(lamp.on_generator_state_changed)
	
	if not generator.generator_state_changed.is_connected(_on_generator_state_changed.bind(generator)):
		generator.generator_state_changed.connect(_on_generator_state_changed.bind(generator))
	
	if not lamp in generator.connected_lamps:
		generator.connected_lamps.append(lamp)
	
	create_wire(generator, lamp)
	
	if generator.is_on:
		lamp.turn_on()
	else:
		lamp.turn_off()
	
	print("Connection created successfully!")

func create_wire(generator, lamp):
	if not wire_scene:
		print("Wire scene not loaded!")
		return
	
	var wire = wire_scene.instantiate()
	
	var level = generator.get_parent()
	level.add_child(wire)
	
	wire.setup(generator, lamp)
	
	var connection_key = str(generator.get_instance_id()) + "_" + str(lamp.get_instance_id())
	wires[connection_key] = wire
	
	wire.set_powered(generator.is_on)
	
	print("Wire visual created!")

func highlight_object(obj, enabled: bool):
	if enabled:
		obj.modulate = Color(1.5, 1.5, 1.5)
	else:
		obj.modulate = Color(1, 1, 1)

func get_total_lamp_consumption(generator) -> float:
	if not connections.has(generator):
		return 0.0
	
	var total = 0.0
	for lamp in connections[generator]:
		if lamp.is_on:
			total += lamp.FUEL_CONSUMPTION_RATE
	
	return total

func disconnect_wire(generator, lamp):
	print("Disconnecting generator from lamp")
	
	if connections.has(generator):
		connections[generator].erase(lamp)
		if connections[generator].is_empty():
			connections.erase(generator)
	
	if lamp in generator.connected_lamps:
		generator.connected_lamps.erase(lamp)
	
	if generator.generator_state_changed.is_connected(lamp.on_generator_state_changed):
		generator.generator_state_changed.disconnect(lamp.on_generator_state_changed)
	
	lamp.connected_generator = null
	lamp.is_connected = false
	lamp.turn_off()
	
	var connection_key = str(generator.get_instance_id()) + "_" + str(lamp.get_instance_id())
	if wires.has(connection_key):
		var wire = wires[connection_key]
		wire.queue_free()
		wires.erase(connection_key)
	
	print("Disconnection complete!")

func _on_generator_state_changed(is_on: bool, generator):
	if not connections.has(generator):
		return
	
	for lamp in connections[generator]:
		var connection_key = str(generator.get_instance_id()) + "_" + str(lamp.get_instance_id())
		if wires.has(connection_key):
			wires[connection_key].set_powered(is_on)

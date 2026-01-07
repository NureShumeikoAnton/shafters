extends CharacterBody2D
signal request_tile_break(target_pos)

var soundCount = 0
var death_label: Label
var footstep_timer = 0.0
var footstep_sounds = preload("res://SFX/Footstep.mp3")
const FOOTSTEP_INTERVAL = 0.4

const GOLD_ITEM_PATH = "res://items/resources/goldOre.tres"
@export var required_gold = 20

const SPEED = 150.0
@export var affliction_ui: AfflictionDisplay
const MAX_FLASHLIGHT_ENERGY = 4.0
const MIN_FLASHLIGHT_ENERGY = 0.5
const POWER_DRAIN_RATE = 5.0

var flashlight_power = 100.0
var flashlight_on = true
var break_range = 64.0

var generator_scene = preload("res://props/generator/generator.tscn")
var lamp_scene = preload("res://props/lamp/lamp.tscn")
var pickup_scene = preload("res://items/pickup/pickup.tscn")

@onready var flashlight_sound: AudioStreamPlayer2D = $Player
@onready var footsteps_parent: Node2D = $Node2D
@onready var sprite := $AnimatedSprite2D
@onready var flashlight = $FlashlightPointLight2D
@onready var flashlight2 = $FlashlightPointLight2D2
@onready var power_bar = $CanvasLayer/MarginContainer/VBoxContainer/ProgressBar
@onready var inventory: Inventory = $Inventory
@onready var inventory_ui = $CanvasLayer/InventoryUI

func _process(delta):
	check_gold_win_condition()

func check_gold_win_condition():
	var total_gold = 0

	for i in range(20):
		var slot_data = inventory.get_slot_data(i)
		if slot_data == null:
			continue
		if slot_data.item_data.resource_path == GOLD_ITEM_PATH:
			total_gold += slot_data.quantity

	if total_gold >= required_gold:
		game_won()


func _ready():
	death_label = Label.new()
	death_label.text = "YOU DIED\nPress R to restart"
	death_label.visible = false
	death_label.modulate = Color.RED
	death_label.global_position = global_position + Vector2(get_viewport().size.x*0.45, get_viewport().size.y*0.05)
	death_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	death_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(death_label)
	get_tree().current_scene.add_child(canvas)
	
	affliction_ui = get_tree().current_scene.get_node("CanvasLayer/AfflictionsUI")
	inventory_ui.set_inventory(inventory)
	inventory_ui.item_triggered.connect(_on_ui_item_triggered)
	inventory_ui.item_dropped.connect(_on_ui_item_dropped)
	queue_redraw()
	update_flashlight()
	var test_gen = load("res://items/resources/generator_item.tres")
	var test_lamp = load("res://items/resources/lamp_item.tres")
	var test_chest = load("res://items/resources/chest_item.tres")
	var test_bandage = load("res://items/resources/bandage.tres")
	var test_battery = load("res://items/resources/battery.tres")
	if test_battery:
		inventory.add_item(test_battery)
		inventory.add_item(test_battery)
		print("Test: test_battery added to inventory.")
	else:
		print("Test: Failed to load test_battery item.")
	
	if test_gen:
		inventory.add_item(test_gen)
		print("Test: Generator added to inventory.")
	else:
		print("Test: Failed to load generator item.")

	if test_lamp:
		inventory.add_item(test_lamp)
		inventory.add_item(test_lamp)
		print("Test: Lamp added to inventory.")
	else:
		print("Test: Failed to load lamp item.")

	if test_chest:
		inventory.add_item(test_chest)
		print("Test: Chest added to inventory.")
	else:
		print("Test: Failed to load chest item.")
		
	if test_bandage:
		inventory.add_item(test_bandage)
		print("Test: Bandage added to inventory.")
	else:
		print("Test: Failed to load Bandage item.")

func _physics_process(delta):
	if flashlight_on and flashlight_power > 0:
		flashlight_power -= POWER_DRAIN_RATE * delta
		flashlight_power = max(0, flashlight_power)
		update_flashlight()
		if flashlight_sound and not flashlight_sound.playing:
			flashlight_sound.play()
	else:
		if flashlight_sound and flashlight_sound.playing:
			flashlight_sound.stop()
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		if sprite.animation != "Walk":
			sprite.play("Walk")
		footstep_timer -= delta
		if footstep_timer <= 0:
			_play_footstep()
			footstep_timer = FOOTSTEP_INTERVAL
	else:
		velocity = Vector2.ZERO
		if sprite.animation != "Default":
			sprite.play("Default")
		

	look_at(get_global_mouse_position())

	move_and_slide()

func update_flashlight():
	power_bar.value = flashlight_power
	
	var flashlight_active = flashlight_power > 0 and flashlight_on
	
	flashlight.enabled = flashlight_active
	flashlight2.enabled = flashlight_active
	
	if $FlashlightPointLight2D/LightArea2D:
		$FlashlightPointLight2D/LightArea2D.monitoring = flashlight_active
		$FlashlightPointLight2D/LightArea2D/CollisionPolygon2D.visible = flashlight_active
	
	if flashlight_active:
		var energy
		if flashlight_power > 10:
			var normalized = (flashlight_power - 10) / 90.0
			energy = lerp(1.5, MAX_FLASHLIGHT_ENERGY, normalized)
		else:
			var normalized = flashlight_power / 10.0
			energy = lerp(MIN_FLASHLIGHT_ENERGY, 1.5, normalized)
		
		flashlight.energy = energy
		flashlight2.energy = energy * 0.05

func spawn_generator():
	var generator = generator_scene.instantiate()
	generator.global_position = global_position + Vector2(0, 50)
	get_parent().add_child(generator)
	generator.clicked.connect(ConnectionManager.on_generator_clicked)
	print("Generator spawned at: ", generator.global_position)

func spawn_lamp():
	var lamp = lamp_scene.instantiate()
	lamp.global_position = global_position + Vector2(0, 50)
	get_parent().add_child(lamp)
	lamp.clicked.connect(ConnectionManager.on_lamp_clicked)
	print("Lamp spawned at: ", lamp.global_position)
	get_parent().add_child(lamp)
	print("Lamp spawned at: ", lamp.global_position)
	
func _input(event: InputEvent):
	if event.is_action_pressed("attack"):
		destroy_tile()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		spawn_generator()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		spawn_lamp()
	
	if event.is_action_pressed("HealthUI"):
		if affliction_ui:
			affliction_ui.toggle_for_player(self)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: use_quick_slot(0)
		elif event.keycode == KEY_2: use_quick_slot(1)
		elif event.keycode == KEY_3: use_quick_slot(2)
		elif event.keycode == KEY_4: use_quick_slot(3)

func use_quick_slot(index: int):
	use_slot(index)

func _on_ui_item_triggered(slot_data: SlotData, index: int):
	use_slot(index)

func _on_ui_item_dropped(index: int):
	drop_item(index)
	

func use_slot(index: int):
	var slot_data = inventory.get_slot_data(index)
	if slot_data == null: return
	
	var item = slot_data.item_data
	
	if item is PlaceableItem:
		_spawn_placeable(item.placeable_scene)
		
		inventory.decrease_item_at(index, 1)
		
	elif item is ConsumableItem:
		item.use(self) 
		
		inventory.decrease_item_at(index, 1)

func _spawn_placeable(scene: PackedScene):
	if scene == null: return
	
	var instance = scene.instantiate()
	instance.global_position = global_position + Vector2(0, 15)
	get_parent().add_child(instance)
	
	print("Построен объект: ", instance.name)

func drop_item(index: int):
	var slot_data = inventory.get_slot_data(index)
	if slot_data == null: return
	
	var pickup = pickup_scene.instantiate()
	pickup.item_data = slot_data.item_data
	
	var random_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
	pickup.global_position = global_position + random_offset
	
	get_parent().add_child(pickup)
	
	pickup.disable_pickup_temporarily(0.7)
	
	inventory.remove_slot_at(index)

func destroy_tile():
	var target_pos = get_global_mouse_position()

	if global_position.distance_to(target_pos) > break_range:
		print("Tile too far to destroy")
		return

	emit_signal("request_tile_break", target_pos)

func die():
	if death_label:
		death_label.visible = true
		
	queue_free()

func game_won():
	death_label.text = "YOU WIN!\nPress R to restart"
	death_label.modulate = Color.GREEN
	death_label.visible = true
	
	queue_free()
	
func _play_footstep():
	var child_count = footsteps_parent.get_child_count()
	var player = footsteps_parent.get_child(soundCount) as AudioStreamPlayer2D

	player.stream = footstep_sounds
	player.play()

	soundCount += 1
	if soundCount >= child_count:
		soundCount = 0

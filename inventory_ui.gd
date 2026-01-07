extends Control

var slot_scene = preload("res://ui/Slot.tscn")

@onready var hotbar_container = $HotbarContainer
@onready var main_panel = $MainInventoryPanel
@onready var main_grid = $MainInventoryPanel/GridContainer
@onready var external_panel = $ExternalInventoryPanel
@onready var external_grid = $ExternalInventoryPanel/ExternalGrid

var inventory_ref: Inventory = null
var external_inventory_ref: Inventory = null

signal item_triggered(slot_data: SlotData, index: int)
signal item_dropped(index: int)

func _ready():
	main_panel.visible = false
	external_panel.visible = false

func set_inventory(inventory: Inventory):
	inventory_ref = inventory
	inventory_ref.inventory_updated.connect(update_ui)
	update_ui()

func _input(event):
	if event.is_action_pressed("inventory_toggle"):
		if main_panel.visible or external_panel.visible:
			close_external_inventory()
		else:
			main_panel.visible = true
			update_ui()

func update_ui():
	if inventory_ref == null:
		return

	_clear_container(hotbar_container)
	for i in range(4):
		var slot_data = inventory_ref.get_slot_data(i)
		_create_slot(hotbar_container, i, slot_data, inventory_ref)

	if main_panel.visible:
		_clear_container(main_grid)
		for i in range(inventory_ref.capacity):
			var slot_data = inventory_ref.get_slot_data(i)
			_create_slot(main_grid, i, slot_data, inventory_ref)

	if external_panel.visible and external_inventory_ref != null:
		_clear_container(external_grid)
		for i in range(external_inventory_ref.capacity):
			var slot_data = external_inventory_ref.get_slot_data(i)
			var slot = _create_slot(external_grid, i, slot_data, external_inventory_ref)
			slot.set_slot_data(external_inventory_ref, i, slot_data)

func _create_slot(container: Node, index: int, slot_data: SlotData, owner_inventory: Inventory) -> Button:
	var slot = slot_scene.instantiate()
	container.add_child(slot)
	
	slot.set_slot_data(owner_inventory, index, slot_data) 
	
	slot.pressed.connect(_on_slot_pressed.bind(index))
	slot.gui_input.connect(_on_slot_gui_input.bind(index))
	
	return slot

func _on_slot_pressed(index: int):
	var slot_data = inventory_ref.get_slot_data(index)
	if slot_data:
		item_triggered.emit(slot_data, index)

func _on_slot_gui_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var slot_data = inventory_ref.get_slot_data(index)
			if slot_data:
				item_dropped.emit(index)
				get_viewport().set_input_as_handled()

func _clear_container(container: Node):
	for child in container.get_children():
		child.queue_free()

func _on_slot_clicked(index: int):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var item = inventory_ref.get_item(index)
		if item:
			item_triggered.emit(item, index)
			
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var item = inventory_ref.get_item(index)
		if item:
			item_dropped.emit(index)

func open_external_inventory(ext_inv: Inventory):
	external_inventory_ref = ext_inv
	if not external_inventory_ref.inventory_updated.is_connected(update_ui):
		external_inventory_ref.inventory_updated.connect(update_ui)
	
	main_panel.visible = true
	external_panel.visible = true
	update_ui()

func close_external_inventory():
	if external_inventory_ref:
		if external_inventory_ref.inventory_updated.is_connected(update_ui):
			external_inventory_ref.inventory_updated.disconnect(update_ui)
		external_inventory_ref = null
	
	external_panel.visible = false
	main_panel.visible = false

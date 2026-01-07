extends Area2D

@export var item_data: ItemData

@onready var sprite = $Sprite

func _ready():
	if item_data != null:
		sprite.texture = item_data.icon
	else:
		print("Внимание: Pickup без ItemData!")
		queue_free()

func disable_pickup_temporarily(duration: float = 1.0):
	set_deferred("monitoring", false)
	
	await get_tree().create_timer(duration).timeout
	
	set_deferred("monitoring", true)

func _on_body_entered(body):
	if body.name == "Player":
		var inventory = body.get_node_or_null("Inventory")
		
		if inventory:
			if inventory.add_item(item_data):
				print("Подобран предмет: ", item_data.name)
				queue_free()
			else:
				print("Инвентарь полон!")

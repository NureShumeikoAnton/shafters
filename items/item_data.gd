extends Resource
class_name ItemData

@export var name: String = "Item"
@export var stackable: bool = false
@export var max_stack_size: int = 1

@export_multiline var description: String = ""

@export var icon: Texture2D

func use(target: Node) -> void:
	pass

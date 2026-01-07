extends ItemData
class_name PlaceableItem

@export var placeable_scene: PackedScene

func use(target: Node) -> void:
	print("Выбран предмет для стройки: ", name)

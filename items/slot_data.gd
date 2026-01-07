extends Resource
class_name SlotData

@export var item_data: ItemData
@export var quantity: int = 1: set = set_quantity

func set_quantity(value: int):
	quantity = value

func can_merge_with(other_item: ItemData) -> bool:
	return item_data == other_item and item_data.stackable and quantity < item_data.max_stack_size

func merge_with(other_item: ItemData, amount: int) -> int:
	var remaining_space = item_data.max_stack_size - quantity
	var amount_to_add = min(amount, remaining_space)
	
	quantity += amount_to_add
	return amount - amount_to_add

extends TabContainer

@export var button_group_order: Array[BaseButton]
@export var button_group: ButtonGroup

func _on_button_group_pressed_changed():
	var result: int = button_group_order.find(button_group.get_pressed_button()) 
	if result > 0:
		current_tab = result

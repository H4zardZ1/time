extends Button

@export var associated_upgrade: Upgrade

func _ready() -> void:
	associated_upgrade.bought_changed.connect(_update_button_pressed)
	associated_upgrade.res_ref.n_changed.connect(_update_disabled)


func _update_disabled() -> void:
	disabled = (not associated_upgrade.upgrade_cost_reachable()) 

func _update_button_pressed() -> void:
	set_pressed_no_signal(
		associated_upgrade.bought
	)


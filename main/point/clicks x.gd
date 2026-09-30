extends ModifierNode

var clicks := BigNumRef.new()
@export var point_node: CanvasItem



func reset():
	clicks.n_replace(BigNumRef.from_float(0))

func _input(event: InputEvent) -> void:
	if active and (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)) and point_node.is_visible_in_tree():
		clicks.n_add(BigNumRef.from_float(1))

func _custom_modifier(n: PackedFloat64Array) -> PackedFloat64Array:
	return BigNumRef.g_add(n, clicks.d)

func save_data():
	PlayerData.data["clicks_x"] = clicks.n_str()

func load_data():
	if PlayerData.data.has("clicks_x"):
		clicks.l_from_str(PlayerData.data["clicks_x"])
	else:
		clicks.l_from_str("0")

extends Camera2D

var holding: bool = false
# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	pass # Replace with function body.
# var camera_speed: float = 20.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_pan_2d_camera"):
		holding = true
	elif event.is_action_released("mouse_pan_2d_camera"):
		holding = false
	elif ((event is InputEventMouseMotion) and holding) or (event is InputEventScreenDrag):
		# get_tree().set_input_as_handled()
		self.position -= event.relative

func reset_position() -> void:
	self.position = Vector2.ZERO
# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass

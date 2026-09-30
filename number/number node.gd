@icon("res://theme/tetration.svg")
extends Node
class_name BigNumNode

@export var direct: bool = false
@export var string_to_convert: String:
	set(value):
		var v := BigNumRef.from_str(value)
		if Engine.is_editor_hint():
			displayed_as = BigNumRef.g_to_str(v)
		string_to_convert = value
	get:
		return string_to_convert

@export var displayed_as: String = "0"
var n: PackedFloat64Array = [0, 0]:
	set(value):
		n = BigNumRef.duplicate_num_only(value)
	get:
		if direct:
			return n
		return BigNumRef.from_str(string_to_convert)

func _init(p_str: String = ""):
	string_to_convert = p_str

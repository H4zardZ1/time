@tool
extends Resource
class_name BigNumResource
## A helper [Resource] to help write down big numbers in the editor.
##
## A helper [Resource] to help write down [BigNumRef] values in the editor.[br]
## [b]Note[/b]: This class is meant to be deleted quickly and is not meant to be edited during runtime. 
## Use a [PackedFloat64Array] or a [BigNumRef] for runtime bignums!

## The string to convert to a number.
@export var string_to_convert: String:
	set(value):
		string_to_convert = value
		_last_updated_is_string = true
		update_n()

## What the number will be displayed as. This property is meant to be a helper to check whether [member string_to_convert] is the correct number that you want to put in.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var displayed_as: String = "0"
## Layer of the number, stores the negative value if its absolute value is 1 or higher.
@export var n_layer: float = 0.0:
	set(value):
		n_layer = value
		if _free_to_edit:
			_last_updated_is_string = false
			update_n()
## Magnitude of the number, stores the negative value if the layer of the number is zero.
## Otherwise, a negative magnitude represents a number that is close to zero. (1e-x)
@export var n_mag: float = 0.0:
	set(value):
		n_mag = value
		if _free_to_edit:
			_last_updated_is_string = false
			update_n()
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE) var _last_updated_is_string: bool = true
var _free_to_edit: bool = true
var n: PackedFloat64Array:
	get:
		return [n_layer, n_mag]

func _init(p_str: String = ""):
	if not p_str.is_empty():
		string_to_convert = p_str
		_last_updated_is_string = true
	if not Engine.is_editor_hint():
		update_n()
func update_n() -> void:
	if _last_updated_is_string and string_to_convert:
		var n0: PackedFloat64Array = BigNumRef.from_str(string_to_convert)
		_free_to_edit = false
		n_layer = n0[0]
		n_mag = n0[1]
		_free_to_edit = true
		update_display()
		return
	# Normalize the components
	var n1: PackedFloat64Array = [n_layer, n_mag]
	BigNumRef.normalize_n(n1)
	_free_to_edit = false
	n_layer = n1[0]
	n_mag = n1[1]
	_free_to_edit = true
	update_display()
func update_display() -> void:
	if Engine.is_editor_hint():
		displayed_as = BigNumRef.g_to_str(n)
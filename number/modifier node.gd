@icon("res://theme/funct.svg")
extends Node
class_name ModifierNode

@export var modifiers: Array[ModifierComponent] = []
@export var active: bool = false

## Applies all modifiers on [param n] (including ones from [ModifierNode] children).
## The order is applied as follows: [br]
## own [member modifiers] -> own [method _custom_modifier] -> children ModifierNode.
func n_apply(n: PackedFloat64Array) -> PackedFloat64Array:
	var result := BigNumRef.duplicate_num_only(n)

	for m in modifiers:
		if m.active:
			result = m.apply(n)

	if active:
		result = _custom_modifier(n)

	for m in get_children():
		if (m is ModifierNode):			
			if m.active:
				result = m.n_apply(n)
	
	return result

## Applies all modifiers on [param ref] (including ones from ModifierNode children).
## The order is applied as follows: [br]
## own [member modifiers] -> own [method _custom_modifier] -> children ModifierNode.
func apply(ref: BigNumRef) -> BigNumRef:
	ref.d = n_apply(ref.d)
	return ref

## Override this function if you want to make a custom modifier.
## Normally, this returns the dictionary reference itself.
func _custom_modifier(n: PackedFloat64Array) -> PackedFloat64Array:
	return n

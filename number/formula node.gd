extends Node
class_name FormulaNode

signal content_changed()

@export var op_type: int = -1
var _change_op_on_ready: bool = true
var op: Dictionary
@export var starting_constant: Array[BigNumResource]
var cached_antiderivatives: Dictionary[BigNumRef, FormulaNode] = {}
var n


enum FOPID {
	ANTIDERIVATIVE_MAX = 42,
	ANTIDERIVATIVE_MIN,
	ANTIDERIVATIVE_MAXABS,
	ANTIDERIVATIVE_MINABS
}

static var _op_leaf: Dictionary[String, Variant] = {
	"evaluate": _f_passthrough,
	"invert": _f_passthrough,

}


static func _f_passthrough(e):
	return e

static func _antiderivated_leaf(variable: BigNumRef) -> FormulaNode:
	return FormulaNode.new(variable).pow_f(2).div(2)

static func _antiderivated_inner_leaf(variable: BigNumRef) -> FormulaNode:
	return FormulaNode.new(variable)

static func _antiderivated_add(variable: BigNumRef, f1: FormulaNode, f2: FormulaNode) -> FormulaNode:
	var result: FormulaNode = FormulaNode.new(FormulaRef.FORMULA_OP_ID.ADD)
	if g_has_variable(f1, variable):
		var ths: FormulaNode = FormulaNode.new(FormulaRef.FORMULA_OP_ID.MUL)
		ths.add_child(variable.duplicate())
		ths.add_child(f1.antiderivated(variable))
		result.add_child(ths)
	else:
		result.add_child(f1)
	if g_has_variable(f2, variable):
		var ths: FormulaNode = FormulaNode.new(FormulaRef.FORMULA_OP_ID.MUL)
		ths.add_child(variable.duplicate())
		ths.add_child(f1.antiderivated(variable))
		result.add_child(ths)
	else:
		result.add_child(f2.antiderivated(variable))
	return result

static func g_has_variable(arg, variable: BigNumRef = null) -> bool:
	if arg is FormulaNode:
		var child_to_check: int = 0
		for item in arg.n.slice(0, arg.op.evaluate.get_argument_count()):
			if is_same(variable, item):
				return true
			if item is FormulaNode:
				if g_has_variable((item as Node).get_child(child_to_check), variable):
					return true
				child_to_check += 1
	return false


func _init(starting_arg = 0.0, starting_op = -1)-> void:
	if starting_op is int and starting_op >= 0:
		op = FormulaRef.operation_definitions[starting_op]
		_change_op_on_ready = false
	elif starting_op is Dictionary:
		op = starting_op
		_change_op_on_ready = false
	elif starting_op < 0 and op_type < 0:
		op = _op_leaf
	op_type = starting_op
	n = []
	n.push_back(_process_element(starting_arg))

func antiderivated(variable: BigNumRef, substitution_stack: Array[FormulaNode] = []) -> FormulaNode:
	if typeof(variable) == TYPE_NIL: # what
		push_warning("Need variable to integrate formula from")
		return self
	if cached_antiderivatives.has(variable):
		return cached_antiderivatives[variable]
	var result: FormulaNode
	if not has_variable(variable):
		# f * variable
		result = self.duplicate()
		cached_antiderivatives[variable] = result
		print("Variable not found in formula {0}, returning f * variable".format(self))
		return result
	
	if substitution_stack.is_empty():
		if not op.has("inner_antiderivated"):
			if not op.has("antiderivated"):
				return FormulaNode.new(NAN)
	return result

func has_variable(variable: BigNumRef = null) -> bool:
	if typeof(variable) != TYPE_NIL:
		return contains_variable(variable)
	for item in n.slice(0, op.evaluate.get_argument_count()):
		if item is BigNumRef:
			return true
		if item is FormulaNode:
			if item.has_variable():
				return true
	return false

func contains_variable(variable: BigNumRef) -> bool:
	for item in n.slice(0, op.evaluate.get_argument_count()):
		if is_same(variable, item):
			return true
		if item is FormulaNode:
			if item.contains_variable(variable):
				return true
	return false

func _process_element(arg):
	match typeof(arg):
		TYPE_PACKED_FLOAT64_ARRAY:
			return arg
		TYPE_FLOAT, TYPE_INT:
			return BigNumRef.from_float(arg)
		TYPE_OBJECT:
			if arg is FormulaNode or arg is BigNumRef:
				return arg
	return

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		cached_antiderivatives.clear()
	if what == NOTIFICATION_PARENTED:
		content_changed.connect(get_parent().content_changed.emit)

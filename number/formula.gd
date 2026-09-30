extends RefCounted
class_name FormulaRef
## A class that stores a mathematical formula.
##
## A [RefCounted] that stores a mathematical formula.
## [br][b]Expected variable type on the constructor:[/b] [String]
## or a valid [Object] with a valid number PackedFloat64Array [code]d[/code] for variables,
## [PackedFloat64Array], [float], [int] for numbers, 
## or [Array] of a valid [member content] or a valid Object with a valid [member content]
## for copying it.
## [br][b]Note:[/b] Please do not mutate the number PackedFloat64Array that the formula holds! Use Strings or Objects for variables instead.
# https://github.com/profectus-engine/Profectus/blob/main/src/game/formulas/formulas.ts

## The lowest number where [code]n + n == n[/code].
## [br][code]1e(2^52)[/code]
const MAX_ADD: PackedFloat64Array = [1.0, 2.0 ** 52]
## The lowest number where [code]n * n == n[/code].
## [br][code]1ee(2^52)[/code]
const MAX_MULT: PackedFloat64Array = [2.0, 2.0 ** 52]
## Two.
const BIGNUM_TWO: PackedFloat64Array = [0, 2]
const FLOAT_MAX_SAFE_INTEGER: int = 2 ** 53 - 1


signal content_changed()

enum FORMULA_OP_ID {
	ADD = 0,
	SUB,
	NEG,
	MUL,
	DIV,
	RECIP,
	POW,
	ROOT,
	LOG,
	LOG10,
	LN,
	ANTIDERIVATIVE_LHSPOW, ## Special operation for antiderivated polynomials.
	ANTIDERIVATIVE_RHSPOW, ## Special operation for antiderivated exponentials.
	ANTIDERIVATIVE_LOG, ## Special operation for antiderivated logarithms.
	ANTIDERIVATIVE_LN, ## Special operation for antiderivated natural logarithms.
	MAX,
	MIN,
	ABS,
	MAX_ABS,
	MIN_ABS,
	FACTORIAL,
	GAMMA,
	LNGAMMA,
	LAMBERTW,
	TETRATE,
	SLOG,
	SROOT,
	LAYERADD,
	LAYERADD10,
	SIN,
	COS,
	TAN,
	ASIN,
	ACOS,
	ATAN,
	ATAN2,
	SINH,
	COSH,
	TANH,
	ASINH,
	ACOSH,
	ATANH,
	IF,
	IF_TOL, ## Special operation for ternary with approx_zero values.
	MULEXP,
	ANTIDERIVATIVE_DIVLN ## Logarithmic integral function.
}

static var operation_names_indices: Dictionary[String, int] = {
	"add": 0,
	"+": 0,
	"sub": 1,
	"-": 1,
	"negate": 2,
}
## Operation Definitions. Each operation has the following properties:
## [br]- [code]"evaluate"[/code] refers to how the operation is evaluated.
## [br]- [code]"invert"[/code] (optional) refers to how to calculate the input given a targetted result.
## [br]- [code]"antiderivated"[/code] (optional) refers to how the operation's antiderivative is built outside an operation with a complex antiderivative.
## [br]- [code]"inner_antiderivated"[/code] (optional) refers to how the simple operation's antiderivative is built inside an operation with a complex antiderivative.
## [br]- [code]"as_str"[/code] refers to how will the function will be written.
## [br]If the existing operations are insufficient for your needs, create a custom operation by implementing your own evaluation, inversion, and integration functions.
## For spending resources, the antiderivated formula must be invertible.
## [br][b]Warning:[/b]
## Operation's evaluate and inverse is expected to return PackedFloat64Array, 
## while the antiderivated and inner_antiderivated is expected to return arrays!
static var operation_definitions: Array[Dictionary] = [
	# Add 0
	{
		"evaluate": BigNumRef.g_add,
		"invert": _invert_add,
		"antiderivated": _antiderivated_add,
		"inner_antiderivated": _inner_antiderivated_add,
		"as_str": "{0}+{1}",
	},
	# Subtract 1
	{
		"evaluate": BigNumRef.g_sub,
		"invert": _invert_sub,
		"antiderivated": _antiderivated_sub,
		"inner_antiderivated": _inner_antiderivated_sub,
		"as_str": "{0}-{1}",
	},
	# Negate 2
	{
		"evaluate": BigNumRef.g_neg,
		"invert": BigNumRef.g_neg,
		"antiderivated": _antiderivated_neg,
		"inner_antiderivated": _inner_antiderivated_neg,
		"as_str": "-{0}",
	},
	# Multiply 3 
	{
		"evaluate": BigNumRef.g_mul,
		"invert": _invert_mul,
		"inner_antiderivated": _inner_antiderivated_mul,
		"antiderivated": _antiderivated_mul,
		"as_str": "{0}*{1}",
	},
	# Divide 4 
	{
		"evaluate": BigNumRef.g_div,
		"invert": _invert_div,
		"inner_antiderivated": _inner_antiderivated_div,
		"antiderivated": _antiderivated_div,
		"as_str": "{0}/{1}",
	},
	# Recipocal 5 
	{
		"evaluate": BigNumRef.g_recip,
		"invert": BigNumRef.g_recip,
		"antiderivated": _antiderivated_recip,
		"as_str": "1/{0}",
	},
	# Pow (Right-Side-Right version) 6
	# Mirrored Pow (aka pow_base) is a Fake
	{
		"evaluate": BigNumRef.g_pow,
		"invert": _invert_pow,
		"antiderivated": _antiderivated_pow,
		"as_str": "{0}**{1}",
	},
	# Exponential Root 7
	{
		"evaluate": BigNumRef.g_root,
		"invert": _invert_root,
		"as_str": "{0}root({1})",
	},
	# Exponential Logarithm 8
	{
		"evaluate": BigNumRef.g_log,
		"invert": _invert_log,
		"antiderivated": _antiderivated_log,
		"as_str": "log{0}({1})",
	},
	# Exponential Log10 9
	{
		"evaluate": BigNumRef.g_log10,
		"invert": BigNumRef.g_pow10,
		"as_str": "log10({1})"
	},
	# Exponential Nat.Log 10
	{
		"evaluate": BigNumRef.g_ln,
		"invert": BigNumRef.g_exp,
		"antiderivated": _antiderivated_ln,
		"as_str": "ln({0})"
	},
	# Special operation: Antiderivated polynom 11
	{
		"evaluate": op_antiderivated_polynom,
		"invert": _invert_antiderivated_polynom,
		"as_str": "IntegralPolynom({0},{1})",
	},
	# Special operation: Antiderivated exponent 12
	{
		"evaluate": op_antiderivated_exponent,
		"invert": _invert_antiderivated_exponent,
		"as_str": "IntegralExponent({0},{1})",
	},
	# Special operation: Antiderivated exponential logarithm 13
	{
		"evaluate": op_antiderivated_log,
		"invert": _invert_antiderivated_log,
		"as_str": "IntegralLog({0},{1})"
	},
	# Special operation: Antiderivated exponential natural logarithm 14
	{
		"evaluate": op_antiderivated_ln,
		"invert": _invert_antiderivated_ln,
		"as_str": "IntegralLn({0})"
	},
	# Max 15
	{
		"evaluate": BigNumRef.g_num_max,
		"invert": _invert_max,
		"as_str": "max({0},{1})"
	},
	# Min 16
	{
		"evaluate": BigNumRef.g_num_min,
		"invert": _invert_min,
		"as_str": "min({0},{1})"
	},
	# Absolute 17
	{
		"evaluate": BigNumRef.g_abs,
		"as_str": "|{0}|"
	},
	# Absolute-Max 18
	{
		"evaluate": BigNumRef.g_num_max_abs,
		"as_str": "abs_max({0}, {1})"
	},
	# Absolute-Min 19
	{
		"evaluate": BigNumRef.g_num_min_abs,
		"as_str": "abs_min({0}, {1})"
	},
	# Factorial 20
	{
		"evaluate": BigNumRef.g_factorial,
		"invert": invert_factorial,
		"as_str": "factorial({0})"
	},
	# Gamma 21
	{
		"evaluate": BigNumRef.g_gamma,
		"invert": invert_gamma,
		"as_str": "gamma({0})"
	},
	# Exponential Nat.log of Gamma 22
	{
		"evaluate": BigNumRef.g_lngamma,
		"invert": invert_lngamma,
		"as_str": "lngamma({0})"
	},
	# Lambert W 23
	{
		"evaluate": BigNumRef.g_lambertw,
		"invert": invert_lambertw,
		"as_str": "lambertw({0})"
	},
	# Tetration 24
	{
		"evaluate": BigNumRef.g_tetrate,
		"invert": _invert_tetrate,
		"as_str": "{0}^^{1}^{2}"
	},
	# Tetrative Logarithm 25
	{
		"evaluate": BigNumRef.g_slog,
		"invert": _invert_slog,
		"as_str": "slog{0}({1})"
	},
	# Tetrative Root 26
	{
		"evaluate": BigNumRef.g_sroot,
		"invert": _invert_sroot,
		"as_str": "{0}sroot({1})"
	},
	# Layer-Adding 27
	{
		"evaluate": op_layer_add,
		"invert": _invert_layer_add,
		"as_str": "layer{2}add({0},{1})"
	},
	# Layer10-Adding 28
	{
		"evaluate": BigNumRef.g_layer_add_10,
		"invert": _invert_layer10_add,
		"as_str": "layer10add({0}, {1})"
	},
	# Sine 29
	{
		"evaluate": BigNumRef.g_sin,
		"invert": BigNumRef.g_asin,
		"antiderivated": _antiderivated_sin,
		"as_str": "sin({0})"
	},
	# Cosine 30
	{
		"evaluate": BigNumRef.g_cos,
		"invert": BigNumRef.g_acos,
		"antiderivated": _antiderivated_cos,
		"as_str": "cos({0})"
	},
	# Tangent 31
	{
		"evaluate": BigNumRef.g_tan,
		"invert": BigNumRef.g_atan,
		"antiderivated": _antiderivated_tan,
		"as_str": "tan({0})"
	},
	# Arcsine 32
	{
		"evaluate": BigNumRef.g_asin,
		"invert": BigNumRef.g_sin,
		"antiderivated": _antiderivated_asin,
		"as_str": "asin({0})"
	},
	# Arccosine 33
	{
		"evaluate": BigNumRef.g_acos,
		"invert": BigNumRef.g_cos,
		"antiderivated": _antiderivated_acos,
		"as_str": "acos({0})"
	},
	# Arctangent 34
	{
		"evaluate": BigNumRef.g_atan,
		"invert": BigNumRef.g_tan,
		"antiderivated": _antiderivated_atan,
		"as_str": "atan({0})"
	},
	# 2-argument arctangent 35
	{
		"evaluate": BigNumRef.g_atan2,
		"as_str": "atan2({0}, {1})"
	},
	# Hyperbolic Sine 36
	{
		"evaluate": BigNumRef.g_sinh,
		"invert": BigNumRef.g_asinh,
		"antiderivated": _antiderivated_sinh,
		"as_str": "sinh({0})"
	},
	# Hyperbolic Cosine 37
	{
		"evaluate": BigNumRef.g_cosh,
		"invert": BigNumRef.g_acosh,
		"antiderivated": _antiderivated_cosh,
		"as_str": "cosh({0})"
	},
	# Hyperbolic Tangent 38
	{
		"evaluate": BigNumRef.g_tanh,
		"invert": BigNumRef.g_atanh,
		"antiderivated": _antiderivated_tanh,
		"as_str": "tanh({0})"
	},
	# Hyperbolic Arcsine 39
	{
		"evaluate": BigNumRef.g_asinh,
		"invert": BigNumRef.g_sinh,
		"antiderivated": _antiderivated_asinh,
		"as_str": "asinh({0})",
	},
	# Hyperbolic Arccosine 40
	{
		"evaluate": BigNumRef.g_acosh,
		"invert": BigNumRef.g_cosh,
		"antiderivated": _antiderivated_acosh,
		"as_str": "acosh({0})",
	},
	# Hyperbolic Arctangent 41
	{
		"evaluate": BigNumRef.g_atanh,
		"invert": BigNumRef.g_tanh,
		"antiderivated": _antiderivated_atanh,
		"as_str": "atanh({0})",
	},
	# Ternary Conditional 42
	{
		"evaluate": op_if,
		"invert": _invert_if,
		#"antiderivated": _antiderivated_if,
		"as_str": "{1} if {0} else {2}"
	},
	# Ternary Conditional with Tolerance 43
	{
		"evaluate": op_if_tol,
		"invert": _invert_if_tol,
		#"antiderivated": _antidervated_if_tol,
		"as_str": "({1}) if ({0}) else ({2})"
	},
	# Product Exponent 44
	{
		"evaluate": invert_lambertw,
		"invert": BigNumRef.g_lambertw,
		"as_str": "{0} * (e ** {0})"
	},
	# Logarithmic Integral 45
	{
		"evaluate": BigNumRef.g_li,
		"as_str": "li({0})"
	}
]

static var default_direct_sum_on_cumulative: int = 7
static var default_direct_sum_on_final: int = 0
static var direct_sum_max_additional_iterations: int = 5

# (x ** 2) / 2
static func _antiderivated_variable(x: String) -> Array:
	return [x, BIGNUM_TWO.duplicate(), FORMULA_OP_ID.POW, BIGNUM_TWO.duplicate(), FORMULA_OP_ID.DIV]

static func _invert_add(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty(): # Right Side (constant+x)
		return BigNumRef.g_sub(target, n1)
	else: # Left Side (x+constant)
		return BigNumRef.g_sub(target, n2)

static var _current_antiderivative_call_variable_name: String = ""
static var _massive_formula: bool

static func _antiderivated_add(variable_index: int, f1, f2) -> Array:
	if variable_index == 0:
		return g_add(f1, g_mul(_current_antiderivative_call_variable_name, f2))
	else:
		return g_add(f2, g_mul(_current_antiderivative_call_variable_name, f1))

static func _inner_antiderivated_add(_variable_index: int, f1, f2) -> Array:
	return g_add(f1, f2)

static func _invert_sub(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty() : # Right Side (constant-x)
		return BigNumRef.g_add(BigNumRef.g_neg(target), n1)
	else: # Left Side (x-constant)
		return BigNumRef.g_add(target, n2)

static func _antiderivated_sub(variable_index: int, f1, f2) -> Array:
	if variable_index == 0:
		return g_sub(f1, g_mul(_current_antiderivative_call_variable_name, f2))
	else:
		return g_sub(g_mul(f1, _current_antiderivative_call_variable_name), f2)

static func _inner_antiderivated_sub(_variable_index: int, f1, f2) -> Array:
	return g_sub(f1, f2)



# static func _invert_neg(target: PackedFloat64Array) -> PackedFloat64Array:
# 	return BigNumRef.g_neg(target)

static func _antiderivated_neg(_variable_index: int, f) -> Array:
	return g_neg(f)

# Hacky way of doing integral substitution rules. 
# I expect this to be permanent.
static var _substitution_stack: Array[Callable] = []
static func _inner_antiderivated_neg(_variable_index: int, f) -> Array:
	_substitution_stack.push_back(g_neg)
	return g_neg(f)

static func _invert_mul(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		return BigNumRef.g_div(target, n1)
	else:
		return BigNumRef.g_div(target, n2)
static func _antiderivated_mul(_variable_index: int, f1, f2) -> Array:
	return g_mul(f1, f2)

static func _inner_antiderivated_mul(variable_index: int, f1, f2) -> Array:
	_substitution_stack.push_back(_antiderivative_substitution_mul.bind(f2 if variable_index == 0 else f1))
	return g_mul(f1, f2)

static func _antiderivative_substitution_mul(outerf, constf) -> Array:
	return g_div(outerf, constf)

static func _invert_div(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		# y = k / x 
		# x = k / y
		return BigNumRef.g_div(n1, target)
	else:
		return BigNumRef.g_mul(target, n2)

static func _antiderivated_div(variable_index: int, f1, f2) -> Array:
	if variable_index == 0:
		return g_div(f1, f2)
	else:

		push_warning("Need fixing: The antiderivative of k/x is a complex operation, but division isn't a completely complex operation!")
		return g_mul(f1, g_log(BigNumRef.BIGNUM_E, f2))

static func _inner_antiderivated_div(variable_index: int, f1, f2) -> Array:
	_substitution_stack.push_back(_antiderivative_substitution_div.bind(f2 if variable_index == 0 else f1))
	if variable_index == 0:
		return g_div(f1, f2)
	else:
		push_error("the antiderivative of k/x in a complex operation is not well defined")
		return []

static func _antiderivative_substitution_div(outerf, constf) -> Array:
	return g_mul(outerf, constf)

# static func _invert_recip(target: PackedFloat64Array) -> PackedFloat64Array:
# 	return BigNumRef.g_recip(target)

static func _antiderivated_recip(_variable_index: int, f) -> Array:
	return g_log(BigNumRef.BIGNUM_E, f)

static func _invert_pow(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		return BigNumRef.g_log(target, n1)
	else:
		return BigNumRef.g_root(target, n2)

static func _antiderivated_pow(variable_index: int, f1, f2) -> Array:
	if variable_index == 0:
		# Search for strings at f2.
		if (f2 is String) or (f2 is Array and f2.any(func(e): return e is String)):
			return g_antiderivated_polynom(f1, f2)
		# We use the elementary functions instead, since f2 will always be a certain value.
		
		var rhs: PackedFloat64Array
		if f2 is PackedFloat64Array:
			rhs = f2
		else:
			rhs = FormulaRef.new(f2).evaluate()
		if BigNumRef.g_eq(BigNumRef.BIGNUM_NEG_ONE, rhs):
			return g_ln(f1)
		elif not BigNumRef.g_is_nan(rhs):
			var e_plus_one: PackedFloat64Array = BigNumRef.g_add(rhs, BigNumRef.BIGNUM_ONE)
			return g_div(g_pow(f1, e_plus_one), e_plus_one)
		else:
			push_error(false, "Failed to evaluate '{0}', returning an empty array".format(var_to_str(f2)))
			return []
	else:
		if (f1 is String) or (f1 is Array and f1.any(func(e): return e is String)):
			return g_antiderivated_exponent(f1, f2)
		var lhs: PackedFloat64Array
		if f1 is PackedFloat64Array:
			lhs = f1
		else:
			lhs = FormulaRef.new(f1).evaluate()
		if BigNumRef.g_lte(BigNumRef. BIGNUM_ZERO, lhs):
			push_error("Cannot antiderivate x**y with x <= 0")
			return []
		elif BigNumRef.g_eq(BigNumRef.BIGNUM_ONE, lhs):
			return [_current_antiderivative_call_variable_name]
		elif not BigNumRef.g_is_nan(lhs):
			return g_div(g_pow(lhs, f2), g_ln(lhs))
		else:
			push_error(false, "Failed to evaluate '{0}', returning an empty array".format(var_to_str(f1)))
			return []

static func _invert_root(target: PackedFloat64Array, n_exp: PackedFloat64Array, to: PackedFloat64Array) -> PackedFloat64Array:
	if to.is_empty():
		return BigNumRef.g_pow(n_exp, target)
	else:
		return BigNumRef.g_log(target, to)

static func _antiderivated_root(variable_index: int, f1, f2) -> Array:
	if variable_index == 0:
		push_error("the antiderivative of x-root k is not well defined")
		return []
	else:
		return _antiderivated_pow(variable_index, f1, g_recip(f2))

static func _invert_log(target: PackedFloat64Array, base: PackedFloat64Array, to: PackedFloat64Array) -> PackedFloat64Array:
	if to.is_empty():
		return BigNumRef.g_pow(base, target)
	else:
		return BigNumRef.g_root(to, target)

static func _antiderivated_log(variable_index: int, f1, f2) -> Array:
	if variable_index == 0:
		# li(x) * ln(k)
		var result: Array = g_mul(g_antiderivated_divln(f1), g_ln(f2))
		for item in _substitution_stack:
			result = item.call(item)
		return result
	else:
		var result: Array = g_antiderivated_log(f1, f2)
		for item in _substitution_stack:
			result = item.call(item)
		return result

static func _antiderivated_log10(_variable_index: int, f) -> Array:
	return g_antiderivated_log(BigNumRef.from_float(10), f)


static func _antiderivated_ln(_variable_index: int, f) -> Array:
	return g_antiderivated_ln(f)

## Special operation for [code]x**k[/code] antiderivatives.
## [codeblock]
## if k == -1: ln(x)
## if k != -1: (x ** (k+1)) / (k+1)
## [/codeblock]
static func op_antiderivated_polynom(base: PackedFloat64Array, n_exp: PackedFloat64Array) -> PackedFloat64Array:
	if BigNumRef.g_eq(n_exp, BigNumRef.BIGNUM_NEG_ONE):
		return BigNumRef.g_log(BigNumRef.BIGNUM_E, base)
	else:
		var e_plus_one: PackedFloat64Array = BigNumRef.g_add(n_exp, BigNumRef.BIGNUM_ONE)
		return BigNumRef.g_div(BigNumRef.g_pow(base, e_plus_one), e_plus_one)


static func _invert_antiderivated_polynom(target: PackedFloat64Array, base: PackedFloat64Array, n_exp: PackedFloat64Array) -> PackedFloat64Array:
	if base.is_empty():
		if BigNumRef.g_eq(n_exp, BigNumRef.BIGNUM_NEG_ONE):
			return BigNumRef.g_exp(target)
		var e_plus_one: PackedFloat64Array = BigNumRef.g_add(n_exp, BigNumRef.BIGNUM_ONE)
		return BigNumRef.g_mul(e_plus_one, BigNumRef.g_log(e_plus_one, target))
	else:
		# y = (k ** (x+1)) / (x+1), real numbers
		# y * (x + 1) = k ** (x+1)
		# 1/y = (x + 1) * (k ** (-(x+1))
		# -1/y = -(x + 1) * (k ** (-(x+1))
		# -1/y * ln(k) = -(x + 1) * ln(k) * (e ** (ln(k) * -(x+1)))

		# lambertw(-ln(k)/y) = ln(k) * -(x + 1)
		# lambertw(-ln(k)/y)/ln(k) = -(x + 1)
		# -lambertw(-ln(k)/y)/ln(k) = x + 1
		# -1-lambertw(-ln(k)/y)/ln(k) = x
		# since this is not a Usual Use, maybe return NAN instead if the number would be branchy?
		var base_log: PackedFloat64Array = BigNumRef.g_ln(base)
		if BigNumRef.g_is_nan(base_log) or\
		BigNumRef.g_sign(base_log) * BigNumRef.g_sign(target) <= 0:
			return BigNumRef.BIGNUM_NAN.duplicate()
		return BigNumRef.g_neg(BigNumRef.g_add(
			BigNumRef.BIGNUM_ONE,
			BigNumRef.g_div(
				BigNumRef.g_lambertw(BigNumRef.g_neg(
					BigNumRef.g_div(
						base_log,
						target
					)
				), #BigNumRef.g_sign(base_log) * BigNumRef.g_sign(target) <= 0),
				),
				base_log
			)
		))


static var _dirty_antiderivated_exponent_warning: bool = false
#static func op_antiderivated_exponent(
	#base: PackedFloat64Array, n_exp: PackedFloat64Array, meta: PackedFloat64Array
#) -> PackedFloat64Array:
## Special operation for [code]k**x[/code] antiderivatives.
## [codeblock]
## if k <= 0: NaN
## if k == 1: x # Warning: this uses an approximation of x (instead of the actual variable x)
## if k > 0 && k != 1: (k ** x) / ln(k)
## [/codeblock]
static func op_antiderivated_exponent(base: PackedFloat64Array, n_exp: PackedFloat64Array) -> PackedFloat64Array:
	if BigNumRef.g_lte(BigNumRef.BIGNUM_ZERO, base):
		push_error("The antiderivative of {0} is not well defined".format(
			["0**x" if BigNumRef.g_eq(BigNumRef.BIGNUM_ZERO, base) else "-k**x"]
		))
		return BigNumRef.BIGNUM_NAN.duplicate()
	elif BigNumRef.g_eq(BigNumRef.BIGNUM_ONE, base) and !_dirty_antiderivated_exponent_warning: 
		# Normally 1^x antiderivated would be x, since you're still multiplying the constant with x anyway 
		# This is NOT equivalent to that if there are operations that x goes through before that point!
		push_warning("Need fixing: Antiderivated exponent doesn't actually know what is the variable!")
		_dirty_antiderivated_exponent_warning = true
		return BigNumRef.duplicate_num_only_no_normalize(n_exp)
	else:
		return BigNumRef.g_div(BigNumRef.g_pow(base, n_exp), BigNumRef.g_log(BigNumRef.BIGNUM_E, base))

static func _invert_antiderivated_exponent(target: PackedFloat64Array, base: PackedFloat64Array, n_exp: PackedFloat64Array) -> PackedFloat64Array:
	if n_exp.is_empty():
		# logarithm should catch all the degenerate values that m can take on (aka return NAN from that point)
		return BigNumRef.g_mul(BigNumRef.g_log(base, target), base)
	else:
		# y = (x ** k) / ln(x)
		# logk(y) = x / ln(x)
		# ln(y) / ln(k) = x / ln(x)
		# oh boy another lambertw solve
		# y / k = e ** x / x
		# y / k * x = e ** x
		# y / k * x * (e ** -x) = 1
		# k / y = x * (e ** -x)
		# -k / y = -x * (e ** -x)
		
		# lambertw(-k/y) = -x
		# -lambertw(-k/y) = x
		
		return BigNumRef.g_neg(BigNumRef.g_lambertw(
			BigNumRef.g_neg(BigNumRef.g_div(
				base, target
			))
		))
	
## Special operation for [code]logk(x)[/code] antiderivatives. 
## [codeblock](x * (ln(x) - 1))/ln(k)[/codeblock]
static func op_antiderivated_log(base: PackedFloat64Array, to: PackedFloat64Array) -> PackedFloat64Array:
	return BigNumRef.g_div(
		BigNumRef.g_mul(BigNumRef.g_sub(BigNumRef.g_log(BigNumRef.BIGNUM_E, to), BigNumRef.BIGNUM_ONE), to),
		BigNumRef.g_log(BigNumRef.BIGNUM_E, base)
	)
# The inversion of x * (ln(x) - 1)/ln(k)
static func _invert_antiderivated_log(target: PackedFloat64Array, base: PackedFloat64Array, to: PackedFloat64Array) -> PackedFloat64Array:
	if base.is_empty():
		# y = k * (ln(k) - 1)/ln(x)
		# y / (k * (ln(k) - 1)) = 1/ln(x)
		# (k * ln(k) - 1) / y = ln(x)
		# e ** ((k * ln(k) - 1) / y) = x
		return BigNumRef.g_exp(
			BigNumRef.g_div(
				BigNumRef.g_mul(to, BigNumRef.g_sub(BigNumRef.g_log(BigNumRef.BIGNUM_E, to), BigNumRef.BIGNUM_ONE)),
				target
			)
		)
	else: # x * (ln(x) - 1)/ln(k)
		# luckily profectus already solved this one
		var numerator: PackedFloat64Array = BigNumRef.g_mul(BigNumRef.g_log(BigNumRef.BIGNUM_E, base), target)
		return BigNumRef.g_div(numerator, BigNumRef.g_lambertw(BigNumRef.g_div(numerator, BigNumRef.BIGNUM_E)))

## Special operation for [code]ln(x)[/code] antiderivatives. 
## [codeblock]x * (ln(x) - 1)[/codeblock]
static func op_antiderivated_ln(to: PackedFloat64Array) -> PackedFloat64Array:
	return BigNumRef.g_mul(BigNumRef.g_sub(BigNumRef.g_log(BigNumRef.BIGNUM_E, to), BigNumRef.BIGNUM_ONE), to)

static func _invert_antiderivated_ln(target: PackedFloat64Array):
	return BigNumRef.g_div(target, BigNumRef.g_lambertw(BigNumRef.g_div(target, BigNumRef.BIGNUM_E)))

static func _invert_max(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		return target if BigNumRef.g_gt(target, n1) else BigNumRef.BIGNUM_NAN.duplicate()
	else:
		return target if BigNumRef.g_gt(target, n2) else BigNumRef.BIGNUM_NAN.duplicate()

static func _invert_min(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		return target if BigNumRef.g_lt(target, n1) else BigNumRef.BIGNUM_NAN.duplicate()
	else:
		return target if BigNumRef.g_lt(target, n2) else BigNumRef.BIGNUM_NAN.duplicate()

## Inverse of [method BigNumRef.g_factorial]. Given [param target], returns the number that would result in [param target] if the result is put into a factorial.
## [br]The result should be above [code]0.4616321449683623[/code].
static func invert_factorial(target: PackedFloat64Array) -> PackedFloat64Array:
	return BigNumRef.g_sub(invert_gamma(target), BigNumRef.BIGNUM_ONE)


# https://math.stackexchange.com/a/2078194/13854
# gamma internally uses stirling function too, so its fine
## Inverse of [method BigNumRef.g_gamma]. Given [param target], returns the number that would result in [param target] if the result is put into the gamma function.
## [br]The result should be above [code]1.4616321449683623[/code], the positive digamma root.
static func invert_gamma(target: PackedFloat64Array) -> PackedFloat64Array:
	# Maybe the ln (or lambertw) just spits out NAN that way anyway
	# if BigNumRef.g_lt(target, BigNumRef.from_float(0.88560351)):
	# 	return BigNumRef.BIGNUM_NAN.duplicate()
	return BigNumRef.g_add(
		BigNumRef.g_pow(
			BigNumRef.BIGNUM_E, 
			BigNumRef.g_lambertw(
				BigNumRef.g_mul(
					BigNumRef.g_recip(BigNumRef.BIGNUM_E), 
					BigNumRef.g_ln(
						BigNumRef.g_div(
							BigNumRef.g_factorial(target),
							BigNumRef.from_float(2.506628274631001) # sqrt(2 * pi)
						)
					)
				)
			)
		),
		BigNumRef.from_components_no_normalize(1, 0.0, 0.5)
	)

static func invert_lngamma(target: PackedFloat64Array) -> PackedFloat64Array:
	return invert_gamma(BigNumRef.g_pow(BigNumRef.BIGNUM_E, target))

## Returns `x * (e ** x)`.
static func invert_lambertw(x: PackedFloat64Array) -> PackedFloat64Array:
	return BigNumRef.g_mul(BigNumRef.g_pow(BigNumRef.BIGNUM_E, x), x)

static func _invert_tetrate(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array, n3: PackedFloat64Array) -> PackedFloat64Array:
	if n3.is_empty():
		# Layer(n1)add(n2) to (n2)**(n3)
		return BigNumRef.g_root(BigNumRef.g_layer_add(target, BigNumRef.g_neg(n2), n1), n2)
	elif n2.is_empty() and BigNumRef.g_eq(n3, BigNumRef.BIGNUM_ONE):
		return BigNumRef.g_slog(target, n1)
	elif  n2.is_empty():
		push_error("Inverting tetration from the exponent side with payload != 1 is not well defined")
		return BigNumRef.BIGNUM_NAN.duplicate()
	elif  n1.is_empty():
		return BigNumRef.g_sroot(target, n2)
	else:
		push_error("Inverting tetration from the base side with payload != 1 is not well defined")
		return BigNumRef.BIGNUM_NAN.duplicate()

static func _invert_slog(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		return BigNumRef.g_tetrate(n1, target)
	else:
		return BigNumRef.g_sroot(n2, target)



static func _invert_sroot(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n2.is_empty():
		return BigNumRef.g_tetrate(target, n1)
	else:
		return BigNumRef.g_slog(n2, target)

## [method BigNumRef.g_layer_add]
static func op_layer_add(from: PackedFloat64Array, diff: PackedFloat64Array, base: PackedFloat64Array)-> PackedFloat64Array:
	return BigNumRef.g_layer_add(from, diff, base)

static func _invert_layer_add(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array, n3: PackedFloat64Array) -> PackedFloat64Array:
	if n1.is_empty():
		return BigNumRef.g_layer_add(target, BigNumRef.g_neg(n2), n3)
	# TODO: correct math on this operation
	elif n2.is_empty():
		# y = k1 ** (k1 ** (k1 ** ...(k1 ** k2))) x times
		push_warning("inverting layer-adding from the adding layer side may be wrong (check)")
		return BigNumRef.g_sub(
			BigNumRef.g_slog(n3, target), 
			BigNumRef.g_slog(n3, n1)
		)
	else:
		# y = x ** (x ** (x ** ...(x ** k1))) k2 times
		push_warning("inverting layer-adding from the layer base side may be wrong (check)")
		return BigNumRef.g_div(BigNumRef.g_sroot(target, n2), BigNumRef.g_sroot(n1, n2))

static func _invert_layer10_add(target: PackedFloat64Array, n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if n1.is_empty():
		return BigNumRef.g_layer_add_10(target, BigNumRef.g_neg(n2))
	# TODO: correct math on this operation
	else:
		
		push_warning("inverting layer-adding from the adding layer side may be wrong (check)")
		return BigNumRef.g_sub(
			BigNumRef.g_slog(BigNumRef.from_float(10), target), 
			BigNumRef.g_slog(BigNumRef.from_float(10), n1)
		)

static func _antiderivated_sin(_variable_index: int, f) -> Array:
	return g_neg(g_cos(f))

static func _antiderivated_cos(_variable_index: int, f) -> Array:
	return g_sin(f)

static func _antiderivated_tan(_variable_index: int, f) -> Array:
	return g_neg(g_ln(g_cos(f)))

# static func _invert_atan2(target: PackedFloat64Array, y: PackedFloat64Array, x: PackedFloat64Array) -> PackedFloat64Array:
# 	var target_copy: PackedFloat64Array = target
# 	if BigNumRef.g_compare_abs(target, BigNumRef.from_float(PI / 2)) > 0: 
# 		#
# 		target_copy = BigNumRef.g_sub(
# 			BigNumRef.g_posmod(
# 				BigNumRef.g_add(
# 					BigNumRef.from_float(PI / 2), target
# 				), 
# 				BigNumRef.from_float(PI)
# 			), 
# 			BigNumRef.from_float(PI / 2)
# 		)
# 	if BigNumRef.g_compare_abs(target, BigNumRef.BIGNUM_ZERO) == 0:
# 		return BigNumRef.BIGNUM_NAN
	
	

static func _antiderivated_asin(_variable_index: int, f) -> Array:
	return g_add(g_mul(g_asin(f), f), g_root(2, g_sub(1, g_pow(f, 2))))

static func _antiderivated_acos(_variable_index: int, f) -> Array:
	return g_sub(g_mul(g_acos(f), f), g_root(2, g_sub(1, g_pow(f, 2))))

static func _antiderivated_atan(_variable_index: int, f) -> Array:
	return g_sub(g_mul(g_atan(f), f), g_div(g_ln(g_add(1, g_pow(f, 2))), 2))

static func _antiderivated_sinh(_variable_index: int, f) -> Array:
	return g_cosh(f)

static func _antiderivated_cosh(_variable_index: int, f) -> Array:
	return g_sinh(f)

static func _antiderivated_tanh(_variable_index: int, f) -> Array:
	return g_ln(g_cosh(f))

static func _antiderivated_asinh(_variable_index: int, f) -> Array:
	return g_sub(g_mul(g_asinh(f), f), g_root(2, g_add(1, g_pow(f, 2))))

static func _antiderivated_acosh(_variable_index: int, f) -> Array:
	return g_sub(g_mul(g_asinh(f), f), g_root(2, g_sub(1, g_root(2, g_add(1, f)))))

static func _antiderivated_atanh(_variable_index: int, f) -> Array:
	return g_sub(g_mul(g_atanh(f), f), g_div(g_ln(g_add(1, g_pow(f, 2))), 2))

## Ternary conditional operator.
## [codeblock]
## if condition == 0: f_branch
## if condition != 0: t_branch
## [/codeblock]
static func op_if(condition: PackedFloat64Array, t_branch: PackedFloat64Array, f_branch: PackedFloat64Array) -> PackedFloat64Array:
	if BigNumRef.g_eq(BigNumRef.BIGNUM_ZERO, condition):
		return f_branch.duplicate()
	return t_branch.duplicate()


static func _invert_if(
	target: PackedFloat64Array, 
	c: PackedFloat64Array, 
	t: PackedFloat64Array, 
	f: PackedFloat64Array
) -> PackedFloat64Array:
	if c.is_empty():
		# the cursed branch. i probably should return NAN here
		if BigNumRef.g_eq(target, f):
			return BigNumRef.BIGNUM_ZERO
		if BigNumRef.g_eq(target, t):
			return BigNumRef.BIGNUM_INF # xdd
		return BigNumRef.BIGNUM_NAN
	if BigNumRef.g_eq(c, BigNumRef.BIGNUM_ZERO) != f.is_empty():
		return BigNumRef.BIGNUM_NAN
	return target

#static func _antiderivated_if(variable_index: int, f1, f2, f3) -> Array:
	#if variable_index == 0:
		#return g_mul(f1, f2)
	#if variable_index == 1:
		#return g_custom_op(

# ##Special operation for antiderivated conditionals.
# ## [codeblock]
# ## If variable branch: branch # already antiderivated
# ## if not variable branch: branch * variable
# ## [/codeblock]
#static func op_antiderivated_if(condtition: PackedFloat64Array, t_branch: PackedFloat64Array, f_branch: PackedFloat64Array, v_branch: PackedFloat64Array, v_value: PackedFloat64Array) -> PackedFloat64Array:
## Ternary conditional operator with tolerance.
## [codeblock]
## if |condition| <= |tol|: f_branch
## if |condition| > |tol|: t_branch
## [/codeblock]
static func op_if_tol(
	condition: PackedFloat64Array, 
	t_branch: PackedFloat64Array, 
	f_branch: PackedFloat64Array,
	tol: PackedFloat64Array
) -> PackedFloat64Array:
	if BigNumRef.g_compare_abs(condition, tol) <= 0:
		return f_branch.duplicate()
	return t_branch.duplicate()

static func _invert_if_tol(
	target: PackedFloat64Array, 
	c: PackedFloat64Array, 
	t: PackedFloat64Array, 
	f: PackedFloat64Array,
	tol: PackedFloat64Array
) -> PackedFloat64Array:
	if c.is_empty() or tol.is_empty():
		# the cursed branches. i probably should return NAN here
		if tol.is_empty() and BigNumRef.g_eq(BigNumRef.BIGNUM_ZERO, c):
			return BigNumRef.BIGNUM_NAN
		if BigNumRef.g_eq(target, f) != tol.is_empty():
			return BigNumRef.BIGNUM_ZERO
		if BigNumRef.g_eq(target, t) != tol.is_empty():
			return BigNumRef.BIGNUM_INF # ddx
		return BigNumRef.BIGNUM_NAN
	if (BigNumRef.g_compare_abs(c, tol) <= 0) != f.is_empty():
		return BigNumRef.BIGNUM_NAN
	return target

## Creates a new formula from the operation [param op_id] with the arguments [param args].[br]
## [b]Expected argument type:[/b] [String], number [PackedFloat64Array]/[float]/[int], [Array] of a valid [member content], or a valid [Object] with a valid [member content]. 
## Array or Object type will represent parts of the formula that will be done first.
static func create_formula_from_op(op_id: int, ...args) -> FormulaRef:
	var o := FormulaRef.new(g_custom_op.bindv(args).call(op_id))
	return o
## Creates a new content array from the operation [param op_id] with the arguments [param args].[br]
## [b]Expected argument type:[/b] [String], number [PackedFloat64Array] [float]/[int], [Array] of a valid [member content], or a valid [Object] with a valid [member content]. 
## Array or Object type will  represent parts of the formula that will be done first.
static func g_custom_op(op_id: int, ...args) -> Array:
	var op: Dictionary = operation_definitions[op_id]
	if args.size() < op.evaluate.get_argument_count():
		assert(false, "Failed to create formula, returning empty array: operation '{0}' needs {1} argument(s), was given {2}".format([op.as_str, op.evaluate.get_argument_count(), args.size()]))
		return []
	var for_content: Array = []
	for i in range(op.evaluate.get_argument_count()):
		match typeof(args[i]):
			TYPE_STRING, TYPE_PACKED_FLOAT64_ARRAY:
				for_content.append(args[i])
			TYPE_FLOAT, TYPE_INT:
				for_content.append(BigNumRef.from_float(args[i]))
			TYPE_ARRAY:
				if _check_if_array_is_valid_content(args[i]):
					for_content.append_array(args[i])
				else:
					push_error(false, "Found invalid content array")
					return []
			TYPE_OBJECT:
				if "content" in args[i] and args[i].content is Array:
					if _check_if_array_is_valid_content(args[i]):
						for_content.append_array(args[i].content)
					else:
						push_error(false, "Found invalid content array")
						return []
				else: 
					push_error(false, "Found object without param 'content'")
					return []
			_:
				assert(false, "Failed to create formula, returning empty array: found argument of unexpected type '{0}'".format([type_string(typeof(args[i]))]))
				return []
	for_content.append(op_id)
	return for_content

# Helper functions to add certain operations in operation definitions
static func g_add(lhs, rhs) -> Array:
	return g_custom_op(0, lhs, rhs)
static func g_sub(lhs, rhs) -> Array:
	return g_custom_op(1, lhs, rhs)
static func g_neg(f) -> Array:
	return g_custom_op(2, f)
static func g_mul(lhs, rhs) -> Array:
	return g_custom_op(3, lhs, rhs)
static func g_div(lhs,rhs) -> Array:
	return g_custom_op(4, lhs, rhs)
static func g_recip(f) -> Array:
	return g_custom_op(5, f)
static func g_pow(base, n_exp) -> Array:
	return g_custom_op(6, base, n_exp)
static func g_pow_base(n_exp, base) -> Array:
	return g_custom_op(6, base, n_exp)
static func g_root(n_exp, to) -> Array:
	return g_custom_op(7, n_exp, to)
static func g_log(base, to) -> Array:
	return g_custom_op(8, base, to)
static func g_ln(f) -> Array:
	return g_custom_op(10, f)
static func g_antiderivated_polynom(base, n_exp) -> Array:
	return g_custom_op(11, base, n_exp)
static func g_antiderivated_exponent(base, n_exp) -> Array:
	return g_custom_op(12, base, n_exp)
static func g_antiderivated_log(base, to) -> Array:
	return g_custom_op(13, base, to)
static func g_antiderivated_ln(to) -> Array:
	return g_custom_op(14, to)
static func g_sin(f) -> Array:
	return g_custom_op(29, f)
static func g_cos(f) -> Array:
	return g_custom_op(30, f)
static func g_tan(f) -> Array:
	return g_custom_op(31, f)
static func g_asin(f) -> Array:
	return g_custom_op(32, f)
static func g_acos(f) -> Array:
	return g_custom_op(33, f)
static func g_atan(f) -> Array:
	return g_custom_op(34, f)
static func g_sinh(f) -> Array:
	return g_custom_op(36, f)
static func g_cosh(f) -> Array:
	return g_custom_op(37, f)
static func g_tanh(f) -> Array:
	return g_custom_op(38, f)
static func g_asinh(f) -> Array:
	return g_custom_op(39, f)
static func g_acosh(f) -> Array:
	return g_custom_op(40, f)
static func g_atanh(f) -> Array:
	return g_custom_op(41, f)
static func g_if(condition, t_branch, f_branch) -> Array:
	return g_custom_op(42, condition, t_branch, f_branch)
static func g_antiderivated_divln(f) -> Array:
	return g_custom_op(FORMULA_OP_ID.ANTIDERIVATIVE_DIVLN, f)

static func _check_if_array_is_valid_content(a: Array) -> bool:
	if a.is_empty():
		return false
	var num_stack : Array = []
	for item in a:
		if item is String or item is PackedFloat64Array: # Operand
			num_stack.push_back(item)
		elif item is int: # Operation
			var op: Dictionary = operation_definitions[item]
			if "evaluate" not in op.keys() or op.evaluate is not Callable:
				assert(false, "Operation ID#{0} is an invalid operation(dictionary content is{1}); {2} cannot be used as a content of a formula".format([item, op, a]))
				return false
			if num_stack.size() < op.evaluate.get_argument_count():
				print("Malformed formula found ({0})".format([var_to_str(a)]))
				return false
			num_stack.resize(num_stack.size() - op.evaluate.get_argument_count() + 1)
		else: # what is this thing doing in the formula stack
			print("Unexpected item of type '{0}' found in formula ({1})".format([type_string(typeof(item)), var_to_str(a)]))
			return false
	return num_stack.size() == 1


## Content of the formula. Can contain 
## [String](for variables), [PackedFloat64Array](for numbers) and [int](for operations).
var content: Array = []:
	get:
		return content
	set(value):
		if value != content: #if (hash(value) != hash(content)) or (value != content):
			content_changed.emit()
		content = value

var string_refs: Dictionary[String, Object]
var cached_antiderivatives: Dictionary[String, FormulaRef] = {}
## Whether or not the formula's content can be used.
var is_content_valid: bool = true
var _cached_invertability_on_strings: Dictionary[String, bool] = {}

## [b]Expected variable type on the constructor:[/b] [String]
## or a valid [Object] with a valid number PackedFloat64Array [code]d[/code] for variables,
## [PackedFloat64Array], [float], [int] for numbers, 
## or [Array] of a valid [member content] or a valid Object with a valid [member content] for copying formulas.
func _init(starting_value = "x") -> void:
	content = _process_arg(starting_value)
	if content.is_empty():
		content = [BigNumRef.BIGNUM_NAN]
	content_changed.connect(_on_content_changed)

func _on_content_changed():
	cached_antiderivatives.clear()
	_cached_invertability_on_strings.clear()
	is_content_valid = _check_if_array_is_valid_content(content)

## Helper function to push an Object [param o] with a valid Bignum [code]o.d[/code] into the formula.
func process_bignumref(o: Object) -> String:
	if o in string_refs.values():
		return string_refs.find_key(o)
	var result: String = "x0"
	var i: int = 0
	while result in string_refs.keys():
		i += 1
		result = "x" + var_to_str(i)
	string_refs[result] = o
	return result

func _process_arg(arg) -> Array:
	match typeof(arg):
		TYPE_STRING, TYPE_PACKED_FLOAT64_ARRAY:
			return [arg]
		TYPE_INT, TYPE_FLOAT:
			return [BigNumRef.from_float(arg)]
		TYPE_ARRAY:
			if _check_if_array_is_valid_content(arg):
				return arg
			else:
				print("Found invalid content array")
				return []
		TYPE_OBJECT:
			if "content" in arg and arg.content is Array:
				if _check_if_array_is_valid_content(arg.content):
					return _process_formularef(arg)
			if "d" in arg:
				if BigNumRef.is_bignum(arg.d):
					return[process_bignumref(arg)]
			else: 
				push_error("Found argument of object that cannot be converted by this script.")
				return []
	push_error("Found argument of unexpected type '{0}' (expected types: String, PackedFloat64Array, int, float, Array, Object)".format([type_string(typeof(arg))]))
	return []

func _process_formularef(o: Object) -> Array:
	if "string_refs" not in o or o.string_refs is not Dictionary:
		return o.content
	
	var replacements: Dictionary[String, String] = {}
	for variable_name in o.string_refs.keys():
		if o.string_refs[variable_name] not in string_refs.values():
			process_bignumref(o.string_refs[variable_name])
		elif o.string_refs[variable_name] != string_refs[variable_name]:
			replacements[variable_name] = string_refs.find_key(o.string_refs[variable_name])
		
	var result: Array = o.content.duplicate()
	result = result.map(_replace_strings_with_other.bind(replacements))
	return result

func _replace_strings_with_other(item, replacements: Dictionary[String, String]):
	if item is String and item in replacements:
		return replacements[item]
	return item

## Creates a new FormulaRef with additional operation id [param op_id] and additional argumentts [param args].
## [br][b]Expected argument type:[/b] [String] or a valid [Object] 
## with a valid number PackedFloat64Array [code]d[/code] for variables, [Dictionary], [float] and [int] for numbers, 
## and [Array] of a valid [member content], or a valid [Object] with a valid [member content]
## for parts of the formula that will be done first.
func custom_op(op_id: int, ...args) -> FormulaRef:
	if op_id > operation_definitions.size():
		assert(false, "Cannot find operation id {0}".format([op_id]))
		return FormulaRef.new([BigNumRef.BIGNUM_NAN.duplicate()])
	var op: Dictionary = operation_definitions[op_id]
	if "evaluate" not in op:
		assert(false, "Invalid operation of id {0} was found. Content: {1}".format([op_id, op]))
		return FormulaRef.new([BigNumRef.BIGNUM_NAN.duplicate()])
	if args.size() < op.evaluate.get_argument_count() - 1:
		assert(false, "Appending operation '{0}' onto a formula needs {1} argument(s), was given {2}".format([op.as_str, op.evaluate.get_argument_count() - 1, args.size()]))
		return FormulaRef.new([BigNumRef.BIGNUM_NAN.duplicate()])
	var to_append: Array = []
	for i in range(op.evaluate.get_argument_count() - 1):
		var arg_result = _process_arg(args[i])
		if arg_result.is_empty():
			return FormulaRef.new(NAN)
		to_append.append_array(arg_result)
	var result: FormulaRef = FormulaRef.new(self)
	result.append_array(to_append)
	result.append(op_id)
	result.content_changed.emit() # it's listening to itself
	return result

## Appends the operation with id [param op_id] with the arguments [param args] to the reference it was called on, then returns it.
## [br][b]Expected argument type:[/b] [String] or a valid [Object] 
## with a valid number PackedFloat64Array [code]d[/code] for variables, [Dictionary], [float] and [int] for numbers, 
## and [Array] of a valid [member content], or a valid [Object] with a valid [member content]
## for parts of the formula that will be done first.[br]
## [b]Note:[/b] Does not mutate on failure.
func custom_op_mutate(op_id: int, ...args) -> FormulaRef:
	if op_id > operation_definitions.size():
		assert(false, "Cannot find operation id {0}".format([op_id]))
		return self
	var op: Dictionary = operation_definitions[op_id]
	if "evaluate" not in op:
		assert(false, "Invalid operation of id {0} was found. Content: {1}".format([op_id, op]))
		return self
	if args.size() < op.evaluate.get_argument_count() - 1:
		assert(false, "Appending operation '{0}' onto a formula needs {1} argument(s), was given {2}".format([op.as_str, op.evaluate.get_argument_count() - 1, args.size()]))
		return self
	var to_append: Array = []
	for i in range(op.evaluate.get_argument_count() - 1):
		var arg_result = _process_arg(args[i])
		if arg_result.is_empty():
			return self
		to_append.append_array(arg_result)
	content.append_array(to_append)
	content.append(op_id)
	content_changed.emit()
	return self


## [code](former formula) + (rhs)[/code]. See [method custom_op]
func add(rhs) -> FormulaRef:
	return custom_op(FORMULA_OP_ID.ADD, rhs)
## [code](former formula) + (rhs)[/code]. See [method custom_op_mutate]
func add_mutate(rhs) -> FormulaRef:
	return custom_op_mutate(FORMULA_OP_ID.ADD, rhs)
## [code](former formula) - (rhs)[/code]. See [method custom_op]
func sub(rhs) -> FormulaRef:
	return custom_op(FORMULA_OP_ID.SUB, rhs)
## [code]-(former formula)[/code]. See [method custom_op]
func neg() -> FormulaRef:
	return custom_op(FORMULA_OP_ID.NEG)
## [code](former formula) * (rhs)[/code]. See [method custom_op]
func mul(rhs) -> FormulaRef:
	return custom_op(FORMULA_OP_ID.MUL, rhs)
## [code](former formula) * (rhs)[/code]. See [method custom_op_mutate]
func mul_mutate(rhs) -> FormulaRef:
	return custom_op_mutate(FORMULA_OP_ID.MUL, rhs)
## [code](former formula) / (rhs)[/code]. See [method custom_op]
func div(rhs) -> FormulaRef:
	return custom_op(FORMULA_OP_ID.DIV, rhs)
## [code](former formula) / (rhs)[/code]. See [method custom_op_mutate]
func div_mutate(rhs) -> FormulaRef:
	return custom_op_mutate(FORMULA_OP_ID.DIV, rhs)
## [code]1 / (former formula)[/code]. See [method custom_op]
func recip() -> FormulaRef:
	return custom_op(FORMULA_OP_ID.RECIP)
## [code](former formula) ** (rhs)[/code]. See [method custom_op]
func pow_f(rhs) -> FormulaRef:
	return custom_op(FORMULA_OP_ID.POW, rhs)
func pow_mutate(rhs) -> FormulaRef:
	return custom_op_mutate(FORMULA_OP_ID.POW, rhs)
## [code](lhs) ** (former formula)[/code]. See [method custom_op]
func pow_base(lhs) -> FormulaRef:
	return FormulaRef.new(lhs).custom_op_mutate(FORMULA_OP_ID.POW, self)
## [code](lhs) ** (former formula)[/code]. See [method custom_op_mutate]
func pow_base_mutate(lhs) -> FormulaRef:
	var result: Array = _process_arg(lhs)
	if result.is_empty():
		return self
	result.append_array(content)
	result.append(FORMULA_OP_ID.POW)
	content = result
	content_changed.emit()
	return self
func root_f(rhs) -> FormulaRef:
	return custom_op(FORMULA_OP_ID.ROOT, rhs)

## Evaluates the formula, substituting all variables that is equal to a key in [param substitutions] to its corresponding value.
func evaluate(substitutions: Dictionary[String, PackedFloat64Array] = {}) -> PackedFloat64Array:
	if not is_content_valid:
		push_error("Formula with malformed content can't be used!")
		return BigNumRef.BIGNUM_NAN.duplicate()
	var num_stack : Array[PackedFloat64Array] = []
	var internal_substitutions: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
	for ref_variable_name in string_refs.keys():
		if ref_variable_name not in internal_substitutions:
			internal_substitutions[ref_variable_name] = ref_variable_name.d
	for item in content:
		if item is String: # Variable
			if item not in substitutions.keys():
				push_error("'{0}': evaluation returning NAN: Unsubstituted variable '\"{1}\"'".format([self, item]))
				return BigNumRef.BIGNUM_NAN.duplicate()
			num_stack.push_back(internal_substitutions[item])
		elif item is PackedFloat64Array: # Number
			num_stack.push_back(item)
		else: # Operation
			var op: Callable = operation_definitions[item].evaluate
			var to_evaluate: Array[PackedFloat64Array] = num_stack.slice(-op.get_argument_count())

			num_stack.resize(num_stack.size() - op.get_argument_count())
			num_stack.push_back(op.callv(to_evaluate))
			if BigNumRef.g_is_nan(num_stack[-1]):

				return num_stack[-1]
	return num_stack[-1]

## Calculates what value the variable inside the formula would have to be for it to be equal to [param target]. Only works if there's a single variable and if the formula is invertible.
## Additionally you can substitute other variables so that there is one variable left.
## Returns [code]NAN[/code] on failure.
## [br][b]Note:[/b] [param variable_name_to_invert] prevents [param substitutions] from substituting a certain variable.
func invert(target: PackedFloat64Array, variable_name_to_invert: String = "", substitutions: Dictionary[String, PackedFloat64Array] = {}) -> PackedFloat64Array:
	if content.size() == 1 and content[0] is String: # if f(x) = x then x = f(x)
		return BigNumRef.duplicate_num_only(target)
	
	if BigNumRef.g_is_nan(target):
		push_warning("Cannot invert NAN")
		return BigNumRef.BIGNUM_NAN.duplicate()

	if not is_content_valid:
		push_error("Formula with malformed content can't be used!")
		return BigNumRef.BIGNUM_NAN.duplicate()
	var s0: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
	for ref_variable_name in string_refs.keys():
		if ref_variable_name not in s0:
			s0[ref_variable_name] = ref_variable_name.d
	if not variable_name_to_invert.is_empty():
		s0.erase(variable_name_to_invert)
	var content_substituted: Array = content.map(_substitute_variable_keep_everything_else_item.bind(s0))
	var first_variable: bool = false
	for item in content_substituted:
		if item is String and first_variable == false:
			first_variable = true
		elif item is String and first_variable == true:
			push_error("'{0}': inversion returning NAN: Has multiple variables".format([self]))
			return BigNumRef.BIGNUM_NAN.duplicate()
		elif item is int:
			if not ("invert" in operation_definitions[item]) and (operation_definitions[item].invert is Callable):
				assert(false, "'{0}': inversion returning NAN: Uninvertible operation '{1}'(id {2})".format([self, operation_definitions[item].as_str, item]))
				return BigNumRef.BIGNUM_NAN.duplicate()
	if not first_variable:
		push_error("'{0}': inversion returning NAN: No variables".format([self, formula_as_str()]))
		return BigNumRef.BIGNUM_NAN.duplicate()
	var target_held := BigNumRef.duplicate_num_only(target)

	var head : int = 0
	var num_stack: Array = []
	var content_to_invert: Array = []
	var last_element_copied: int = 0
	while head < content_substituted.size():
		if content_substituted[head] is not int:
			num_stack.push_back(content_substituted[head])
		else:
			var op: Callable = operation_definitions[content_substituted[head]].evaluate
			var num_stack_to_evaluate: Array = []
			var eval_result = null
			
			for i in range(op.get_argument_count()):
				num_stack_to_evaluate.push_back(num_stack.pop_back())
				if num_stack_to_evaluate[-1] is String:
					eval_result = num_stack_to_evaluate[-1]
			if eval_result: # We can't invert at this stage yet, we're just evaluating evaluatable stuff
				var start_copy: int = head - op.get_argument_count()
				if content_to_invert.is_empty():
					content_to_invert = content_substituted.slice(start_copy, head + 1)
				else: 
					# [n n n n op(2) op(2) op(2) op(1)]
					#      1 1   1
					#    2 1 1   1     2
					#  3 2 1 1   1     2     3     4
					# [n n n op(1) n op(4)]
					#      1   1
					#  2 2 1   1   2   2
					#  order must be perserved as well
					var content_to_invert_starting_size: int = content_to_invert.size()
					for copy_head in range(start_copy + 1, head + 1):
						if copy_head > last_element_copied: 
							content_to_invert.push_back(content_substituted[copy_head])
						else: 	
							content_to_invert.insert(copy_head - start_copy - 1, content_substituted[copy_head - content_to_invert_starting_size])
			else:
				var num_stack_to_evaluate_converted: Array[PackedFloat64Array] = num_stack_to_evaluate.duplicate()
				eval_result = op.callv(num_stack_to_evaluate_converted)
			num_stack.push_back(eval_result)
			last_element_copied = head
		head += 1

	var second_content: Array[Callable] = []
	head = -1
	while not content_to_invert.is_empty():
		var invert_pop = content_to_invert.pop_back()
		if invert_pop is int:
			if not second_content.is_empty():
				second_content[head] = second_content[head].bind([] as PackedFloat64Array)
			second_content.push_back(operation_definitions[invert_pop].invert)
			head = second_content.size() - 1
		elif invert_pop is PackedFloat64Array:
			second_content[head] = second_content[head].bind(invert_pop)
		else:
			second_content[head] = second_content[head].bind([] as PackedFloat64Array)
		while (head != 0) and (second_content[head].get_argument_count() <= 1):
			head -= 1
		while (not second_content.is_empty())and(second_content[0].get_argument_count() == 1):
			target_held = second_content[0].call(target_held)
			if BigNumRef.g_is_nan(target_held):
				print("'{0}': inversion returning NAN: Formula cannot reach target '{1}'".format([self, BigNumRef.g_to_str(target)]))
				return target_held
			# if not BigNumRef.g_is_finite(target_held):
			# 	if BigNumRef.g_is_nan(target_held):
			# 		print("'{0}': inversion returning NAN: Formula cannot reach target '{1}'".format([self, BigNumRef.g_to_str(target)]))
			# 		return target_held
			# 	else:
			# 		print("'{0}': inversion returning INF: ".format([self]))
			# 		return target_held
			second_content.pop_front()
			head -= 1
	return target_held

func _substitute_variable_keep_everything_else_item(item, substitutions: Dictionary[String, PackedFloat64Array]):
	if item is String and item in substitutions.keys():
		return substitutions[item]
	return item

var _dirty_antiderivated_no_variable_name_warning: bool = false
## Get the formula's indefinite integral (also known as antiderivative) with respect towards [param variable_name]. 
## Some antiderivatived formulas are invertible, most of them that are are also invertible on other variables.[br]
## This returns a new FormulaRef. [br]
## [b]Note:[/b] The returned FormulaRef does not include the constant of integration.[br]
## [b]Note:[/b] If this is called on a FormulaRef that does not use [param variable_name] anywhere, this is equivalent to [code]this.mul(variable_name)[/code]
func antiderivated(variable_name: String = "x") -> FormulaRef:
	if variable_name.is_empty():
		push_error("Cannot antiderivate on no given variable")
		return FormulaRef.new(NAN)
	if not is_content_valid:
		push_error("Formula with malformed content can't be used")
		return FormulaRef.new(NAN)
	if variable_name in cached_antiderivatives.keys():
		return cached_antiderivatives[variable_name]
	var first_variable: bool = false
	for item in content:
		if item is String and (item == variable_name) and first_variable == false:
			first_variable = true
		elif item is String and (item == variable_name) and first_variable == true:
			push_error(false, "'{0}': Antiderivating failed, returning null: Formula has multiple variables".format([self]))
			cached_antiderivatives[variable_name] = null
			return FormulaRef.new(NAN)
	if not first_variable:
		if not _dirty_antiderivated_no_variable_name_warning:
			_dirty_antiderivated_no_variable_name_warning = true
			print("'{0}': variable '{1}' not found, returning k * {1}".format([self, variable_name]))

		return FormulaRef.new(content).mul(variable_name)
	_current_antiderivative_call_variable_name = variable_name
	var head: int = content.size() - 1
	var formula_stack: Array[Array] = []
	_massive_formula = false
	_substitution_stack.clear()
	var complex_heads: Array[int] = []
	var variable_head: int = -1
	var variable_row: int = -1
	while head >= 0:
		var curr = content[head]
		if curr is int:
			formula_stack.push_back([curr])
			if "inner_antiderivated" not in operation_definitions[curr]:
				complex_heads.push_back(formula_stack.size() - 1)
		elif curr is String:
			variable_row = operation_definitions[formula_stack[-1][0]].evaluate.get_argument_count() - formula_stack[-1].size()
			if curr == variable_name:
				if complex_heads.size() > 1:
					assert(false, "'{0}': Antiderivating failed, returning null: Trying to antiderivate a complex operation with a variable inside a complex operation".format([self]))
					return
				elif complex_heads.size() != 1:
					formula_stack[-1].push_back(_antiderivated_variable(curr))
				else:
					formula_stack[-1].push_back(curr)
				variable_head = formula_stack.size() - 1
				
			else:
				formula_stack[-1].push_back(curr)
		else: # PackedFloat64Array
			formula_stack[-1].push_back(curr)
		
		while (not formula_stack.is_empty()) and\
		(formula_stack[-1].size() > (operation_definitions[formula_stack[-1][0]].evaluate.get_argument_count())):
			
			var args: Array = formula_stack[-1].slice(1)
			args.reverse()
			var internal_variable_row: int = variable_row if formula_stack.size() - 1 == variable_head else -1
			var last_antiderivative_result: Array
			if internal_variable_row >= 0 and formula_stack:
				var op: Dictionary = operation_definitions[formula_stack[-1][0]]
				if not (("antiderivated" in operation_definitions[formula_stack[-1][0]]) and operation_definitions[formula_stack[-1][0]].antiderivated is Callable):
					push_error("'{0}': Antiderivating failed, returning null: operation '{1}'(id {2}) has no antiderivatives".format([self, op.as_str, formula_stack[-1][0]]))
					cached_antiderivatives[variable_name] = null
					return
				if complex_heads.is_empty():
					last_antiderivative_result = op.antiderivated.bindv(args).call(internal_variable_row)
					
				elif complex_heads[0] < formula_stack.size() - 1:
					if "inner_antiderivated" in op:
						last_antiderivative_result = op.inner_antiderivated.bindv(args).call(internal_variable_row)
					else:
						push_error("'{0}': Antiderivating failed, returning null: operation '{1}'(id {2}) cannot be antiderivated inside a complex operation".format([self, op.as_str, formula_stack[-1][0]]))
						cached_antiderivatives[variable_name] = null
						return
				else:
					last_antiderivative_result = op.antiderivated.bindv(args).call(internal_variable_row)
					for item in _substitution_stack:
						last_antiderivative_result = item.call(last_antiderivative_result)
			else:
				last_antiderivative_result = []
				for arg in args:
					if arg is Array:
						last_antiderivative_result.append_array(arg)
					else:
						last_antiderivative_result.append(arg)
				last_antiderivative_result.push_back(formula_stack[-1][0])
			if last_antiderivative_result.is_empty() and not _massive_formula:
				print("'{0}': Antiderivating failed, returning null: Error on antiderivating operation".format([self]))
				cached_antiderivatives[variable_name] = null
				return
			elif last_antiderivative_result.is_empty():
				push_warning("Formula is too powerful to be antiderivated meaningfully, returning a copy of formula")
				cached_antiderivatives[variable_name] = FormulaRef.new(self.content)
				return cached_antiderivatives[variable_name]
			if formula_stack.size() > 1:
				formula_stack[-2].append(last_antiderivative_result)
				if variable_head == formula_stack.size() - 1:
					variable_head -= 1
					variable_row = operation_definitions[formula_stack[-2][0]].evaluate.get_argument_count() - formula_stack[-2].size() + 1
				if complex_heads[-1] == formula_stack.size() - 1:
					complex_heads.pop_back()
				formula_stack.pop_back()
			else:
				formula_stack.clear()
				formula_stack.append(last_antiderivative_result)
				break
		if _massive_formula:
			push_warning("Formula is too powerful to be antiderivated meaningfully, returning a copy of formula")
			cached_antiderivatives[variable_name] = FormulaRef.new(self.content)
			return cached_antiderivatives[variable_name]
		head -= 1
	var result: FormulaRef = FormulaRef.new(formula_stack[0])
	result.string_refs = string_refs.duplicate()
	cached_antiderivatives[variable_name] = result
	return result

## Returns what definite integral of the formula will result in [param target] 
## with respect towards the name of the remaining variable 
## (sans the constant of integration, as if the definite integral ends/starts at 0).
## See [method antiderivated] and [method invert]
func invert_integral(target: PackedFloat64Array, variable_name: String = "", substitutions: Dictionary[String, PackedFloat64Array] = {}) -> PackedFloat64Array:
	
	var internal_substitutions: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
	for ref_variable_name in string_refs.keys():
		if ref_variable_name not in internal_substitutions:
			internal_substitutions[ref_variable_name] = ref_variable_name.d
	if not variable_name.is_empty():
		internal_substitutions.erase(variable_name)
	var content_substituted: Array = content.map(_substitute_variable_keep_everything_else_item.bind(internal_substitutions))
	var first_variable: bool = false
	for item in content_substituted:
		if item is String and first_variable == false:
			first_variable = true
			variable_name = item
		elif item is String and first_variable == true:
			push_error("'{0}': inverting the antiderivate returning NAN: Has multiple variables".format([self]))
			return BigNumRef.BIGNUM_NAN.duplicate()
	if not first_variable: # Only very technically an error, this is Fine otherwise
		#print("'{0}': variable not found, evaluating the inverse of k * x instead.".format([self]))
		return BigNumRef.g_div(target, evaluate(substitutions))
	
	return antiderivated(variable_name).invert(target, variable_name, substitutions)

# the logic that profectus once used for constant of integration of a function
# i see no functionality in that, but i guess i should port it
## Returns the difference between the the mean of f(start) and f(end) and the definite integral f(start) to f(end).[br]
## [b]Warning:[/b] [param variable_name] [b]will[/b] replace the ones given at [param substitutions](Substitutions given won't be mutated).
func get_deviation_of_integration(
	variable_name: String = "x", 
	start: PackedFloat64Array = BigNumRef.BIGNUM_ZERO,
	end: PackedFloat64Array = BigNumRef.BIGNUM_ONE,
	substitutions: Dictionary[String, PackedFloat64Array] = {}
) -> PackedFloat64Array:
	var s0: Dictionary = substitutions.duplicate()
	s0[variable_name] = start.duplicate()
	var s1: Dictionary = substitutions.duplicate()
	s1[variable_name] = end.duplicate()
	var integral_end: PackedFloat64Array = antiderivated(variable_name).evaluate(s1)
	var integral_start: PackedFloat64Array = antiderivated(variable_name).evaluate(s0)
	var integral: PackedFloat64Array = g_sub(integral_end, integral_start)
	
	var mean: PackedFloat64Array = BigNumRef.g_div(BigNumRef.g_add(evaluate(s0),evaluate(s1)), BIGNUM_TWO)
	return BigNumRef.g_sub(mean, integral)

## Returns a copy of the FormulaRef with its amount of constants reduced to as minimum as possible (i.e. a constant 1 + 2 formula is turned into a constant 3 )
func folded() -> FormulaRef:
	var head: int = 0
	var num_stack: Array = []
	var result_content: Array = []
	var last_element_copied: int = 0
	while head < content.size():
		if content[head] is not int:
			num_stack.push_back(content[head])
		else:
			var op: Callable = operation_definitions[content[head]].evaluate
			var num_stack_to_evaluate: Array = []
			var eval_result = null
			
			for i in range(op.get_argument_count()):
				num_stack_to_evaluate.push_back(num_stack.pop_back())
				if num_stack_to_evaluate[-1] is String:
					eval_result = num_stack_to_evaluate[-1]
			if eval_result: # Strings cannot be folded!
				var start_copy: int = head - op.get_argument_count()
				if result_content.is_empty():
					result_content = result_content.slice(start_copy, head + 1)
				else: 
					# [n n n n op(2) op(2) op(2) op(1)]
					#      1 1   1
					#    2 1 1   1     2
					#  3 2 1 1   1     2     3     4
					# [n n n op(1) n op(4)]
					#      1   1
					#  2 2 1   1   2   2
					#  order must be perserved as well
					var content_to_invert_starting_size: int = result_content.size()
					for copy_head in range(start_copy + 1, head + 1):
						if copy_head > last_element_copied: 
							result_content.push_back(result_content[copy_head])
						else: 	
							result_content.insert(copy_head - start_copy - 1, result_content[copy_head - content_to_invert_starting_size])
			else:
				var num_stack_to_evaluate_converted: Array[PackedFloat64Array] = num_stack_to_evaluate.duplicate()
				eval_result = op.callv(num_stack_to_evaluate_converted)
			num_stack.push_back(eval_result)
			last_element_copied = head
		head += 1
	var result: FormulaRef = FormulaRef.new(result_content)
	return result


## Calculates the cost of the next [param amount] buyables.
## [br][param buyable]: The [BigNumRef] or [String] that represents the buyable. If given String, then put the value bought in [param substitutions] in the [param buyable] key.
## [br][param cumulative_cost]: Whether or not to count spent resources on each purchase or not. If true, costs will be approximated for performance, skewing towards fewer purchases.
## [br][param direct_sum_amount]: How many of the most expensive purchases should be manually summed for better accuracy. If negative uses [member default_direct_sum_on_cumulative] or [member default_direct_sum_on_final]
## [br][b]Warning:[/b] If [param buyable] is a String and it is not subsituted in [param substitutions], the formula won't work correctly!
func calculate_cost(
	amount: PackedFloat64Array,
	buyable,
	substitutions: Dictionary[String, PackedFloat64Array],
	cumulative_cost: bool = true,
	direct_sum_amount: int = -1
) -> PackedFloat64Array:
	if BigNumRef.g_eq(amount, BigNumRef.BIGNUM_ONE):
		return evaluate(substitutions)
	if direct_sum_amount < 0:
		direct_sum_amount = default_direct_sum_on_cumulative if cumulative_cost else default_direct_sum_on_final
	var bought: PackedFloat64Array
	var buyable_name_in_formula: String
	if buyable is String:
		buyable_name_in_formula = buyable
		bought = substitutions[buyable_name_in_formula].duplicate()
	elif buyable is Object:
		if buyable in string_refs.values():
			buyable_name_in_formula = string_refs.find_key(buyable)
			bought = buyable.d
		else:
			push_error("Cannot find object {0} in formula".format([var_to_str(bought)]))
			return BigNumRef.BIGNUM_NAN.duplicate()
	else:
		push_error("Unexpected type of {0} given as buyable (Expected types: String, Object)".format([type_string(typeof(buyable))]))
		return BigNumRef.BIGNUM_NAN.duplicate()
	
	var new_amount := BigNumRef.g_add(bought, amount)
	var target_amount := new_amount
	
	new_amount = BigNumRef.g_num_max(BigNumRef.g_sub(new_amount, BigNumRef.from_float(direct_sum_amount)), bought)
	var result := BigNumRef.BIGNUM_ZERO.duplicate()

	if BigNumRef.g_gt(amount, BigNumRef.from_float(direct_sum_amount)):
		if cumulative_cost:
			var s0: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
			s0[buyable_name_in_formula] = new_amount
			result = BigNumRef.g_sub(
				antiderivated(buyable_name_in_formula).evaluate(s0),
				antiderivated(buyable_name_in_formula).evaluate(substitutions)
			)
			if BigNumRef.g_gt(target_amount, BigNumRef.from_float(FLOAT_MAX_SAFE_INTEGER)): 
				return BigNumRef.g_add(
					result,
					BigNumRef.g_mul(BigNumRef.g_sub(target_amount, new_amount), evaluate(s0))
				)
		else:
			var s0: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
			s0[buyable_name_in_formula] = new_amount
			result = evaluate(s0)
			new_amount = BigNumRef.g_add(new_amount, BigNumRef.BIGNUM_ONE)
			if BigNumRef.g_gt(target_amount, BigNumRef.from_float(FLOAT_MAX_SAFE_INTEGER)):
				return BigNumRef.g_mul(
					result,
					BigNumRef.g_add(BigNumRef.g_sub(target_amount, new_amount), BigNumRef.BIGNUM_ONE)
				)
	
	var s1: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
	for i in range(BigNumRef.to_float(new_amount), target_amount):
		s1[buyable_name_in_formula] = BigNumRef.from_float(i)
		result = BigNumRef.g_add(result, evaluate(s1))
	return result
	
var _dirty_substitutionless_warning: bool = false
## Calculates the maximum amount of purchases possible, given [param res].
## [br][param buyable]: The [BigNumRef] or [String] that represents the buyable. If given string, then put the value bought in [param substitutions] in the [param buyable] key.
## [br][param cumulative_cost]: Whether or not to count spent resources on each purchase or not. If true, costs will be approximated for performance, skewing towards fewer purchases.
## [br][param direct_sum_amount]: How many of the most expensive purchases should be manually summed for better accuracy. If negative uses [member default_direct_sum_on_cumulative] or [member default_direct_sum_on_final]
## [br][param max_bulk_amount]: The maximum amount of buyables that can be bought at once. If 1 or [param max_bulk_amount] <= [param direct_sum_amount] then the formula does not need to be invertible.
## [br][b]Note:[/b] If [param buyable] is a String and it is not subsituted in [param substitutions], the formula won't work correctly!
func calculate_max_affordable(
	res: PackedFloat64Array,
	buyable,
	substitutions: Dictionary[String, PackedFloat64Array],
	cumulative_cost: bool = true, 
	direct_sum_amount: int = -1,
	max_bulk_amount: PackedFloat64Array = BigNumRef.BIGNUM_INF
) -> PackedFloat64Array:
	var original_direct_sum_amount := direct_sum_amount
	var bought: PackedFloat64Array
	var buyable_name_in_formula: String
	if buyable is String:
		buyable_name_in_formula = buyable
	elif buyable is Object:
		if buyable in string_refs.values():
			buyable_name_in_formula = string_refs.find_key(buyable)
			bought = buyable.d
		else:
			push_error("Cannot find object {0} in formula".format([var_to_str(bought)]))
			return BigNumRef.BIGNUM_ZERO.duplicate()
	else:
		push_error("Unexpected type of {0} given as buyable (Expected types: String, Object)".format([type_string(typeof(buyable))]))
		return BigNumRef.BIGNUM_ZERO.duplicate()

	var substitutions_local: Dictionary[String, PackedFloat64Array] = substitutions.duplicate()
	if buyable is String and buyable_name_in_formula not in substitutions.keys():
		if _dirty_substitutionless_warning:
			push_warning("substitutions does not contain the amount of already bought items, assuming 0 items bought.")
			_dirty_substitutionless_warning = true
			var main_loop: SceneTree = Engine.get_main_loop()
			if is_instance_valid(main_loop):
				var timer = main_loop.create_timer(60, false)
				timer.timeout.connect(func (): _dirty_substitutionless_warning = false)
		bought = BigNumRef.BIGNUM_ZERO.duplicate()
		substitutions_local[buyable_name_in_formula] = bought
	else:
		bought = substitutions[buyable_name_in_formula].duplicate()
	
	var s0 := substitutions.duplicate()
	if direct_sum_amount < 0:
		direct_sum_amount = default_direct_sum_on_cumulative if cumulative_cost else default_direct_sum_on_final
	#if cumulative_cost and BigNumRef.g_compare_abs(res, MAX_MULT) > 0:
		#cumulative_cost = false
	if BigNumRef.g_eq(BigNumRef.BIGNUM_ONE, max_bulk_amount):
		return BigNumRef.BIGNUM_ONE if BigNumRef.g_gte(res, evaluate(substitutions)) else BigNumRef.BIGNUM_ZERO
	var affordable: PackedFloat64Array = BigNumRef.BIGNUM_ZERO
	if BigNumRef.g_gt(max_bulk_amount, BigNumRef.from_float(direct_sum_amount)):
		if cumulative_cost:
			var total_res := BigNumRef.g_add(res, antiderivated(buyable_name_in_formula).evaluate(substitutions_local))
			
			s0.erase(buyable_name_in_formula)
			affordable = BigNumRef.g_sub(BigNumRef.g_floor(invert_integral(total_res, buyable_name_in_formula, s0)), bought)
		else:
			affordable = BigNumRef.g_floor(invert(res, buyable_name_in_formula, substitutions_local))
	if BigNumRef.g_is_nan(affordable):
		return BigNumRef.BIGNUM_ZERO.duplicate()
	affordable = BigNumRef.g_num_min(max_bulk_amount, affordable)

	if direct_sum_amount > 0:
		var pre_sum: PackedFloat64Array = affordable.duplicate()
		affordable = BigNumRef.g_num_max(BigNumRef.g_sub(affordable, BigNumRef.from_float(direct_sum_amount)), BigNumRef.BIGNUM_ZERO)
		var sum: PackedFloat64Array
		s0[buyable_name_in_formula] = BigNumRef.g_add(bought, affordable)
		if cumulative_cost:
			sum = calculate_cost(affordable, buyable_name_in_formula, s0, true, original_direct_sum_amount)
		else:	
			sum = evaluate(s0)
		while BigNumRef.g_lt(affordable, max_bulk_amount) and\
		BigNumRef.g_lt(affordable, BigNumRef.from_float(FLOAT_MAX_SAFE_INTEGER)) and\
		BigNumRef.g_gte(BigNumRef.g_add(pre_sum, BigNumRef.from_float(direct_sum_max_additional_iterations)), affordable):
			s0[buyable_name_in_formula] = BigNumRef.g_add(s0[buyable_name_in_formula], affordable)
			var next = evaluate(s0)
			if BigNumRef.g_lte(BigNumRef.g_add(sum, next), res):
				affordable = BigNumRef.g_add(affordable, BigNumRef.BIGNUM_ONE)
				sum = BigNumRef.g_add(sum, next)
			else:
				break

	return BigNumRef.BIGNUM_ZERO.duplicate() if BigNumRef.g_is_nan(affordable) or BigNumRef.g_lt(affordable, BigNumRef.BIGNUM_ZERO) else affordable

func formula_as_str(substitutions: Dictionary[String, String] = {}) -> String:
	if not is_content_valid:
		return "INVALID FORMULA (content: {0})".format([content])
	if content.is_empty():
		return "Empty Formula"
	var num_stack : Array[String] = []
	for item in content:
		if item is String: # Variable
			if item in substitutions.keys():
				item = substitutions[item]
			num_stack.push_back(item)
		elif item is PackedFloat64Array: # Number
			num_stack.push_back(BigNumRef.g_to_str(item))
		elif item is int: # Operation
			var op_size: int = operation_definitions[item].evaluate.get_argument_count()
			var to_replace: Array[String] = num_stack.slice(op_size, -1)
			num_stack.resize(num_stack.size() - op_size)
			num_stack.push_back(operation_definitions[item].as_str.format(to_replace))
	return num_stack[0]

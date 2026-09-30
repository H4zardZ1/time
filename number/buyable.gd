extends Node
class_name Buyable

enum CostModes {
	## The buyable scales additively.
	ARITHMETIC,
	## The buyable scales multicatively.
	GEOMETRIC,
	## The buyable scales based on [member formula]. Both [member starting_cost] and [member scale] is ignored if you use this mode.[br]
	## [b]Note[/b]: Simple addition in the formula can break buyables.
	FORMULA
}
signal bought_changed(old_amount: PackedFloat64Array, new_amount: PackedFloat64Array)
## Whether [member scale] scales additively, multicatively or based on a certain formula.
@export var scale_type: CostModes = CostModes.ARITHMETIC
## Helper parameter to set [member starting_cost] during [method Node._ready].[br]
## After this node is ready, use and edit [member starting_cost] instead. 
@export var starting_starting_cost: BigNumResource
## The starting cost of this item.
var starting_cost: PackedFloat64Array
## Helper parameter to set [member scale] during [method Node._ready].[br]
## After this node is ready, use and edit [member scale] instead. 
@export var starting_scale: BigNumResource
## How much the next item costs when you buy this item.
var scale: PackedFloat64Array
@export var can_buy: bool = true
## Whether to update the projection of [method buy_max] every time [member res_ref] changes.
@export var always_update: bool = true
## Whether [member formats](and consequently [method get_projection]) takes rounding errors of adding/subtracting large numbers into account.
@export var use_change_on_projection_string: bool = false
## (Only applies to formula) Whether or not to count spent resources on each purchase or not.
@export var cumulative_cost: bool = true
## Helper parameter to set [member default_bulk_amount] during [method Node._ready]. Optional as [member default_bulk_amount] defaults to infinity.[br]
## After this node is ready, use and edit [member default_bulk_amount] instead.
@export var starting_default_bulk_amount: BigNumResource
## What is the default amount a single [method buy_bulk] call will try to buy. Defaults to infinity.
var default_bulk_amount: PackedFloat64Array = BigNumRef.BIGNUM_INF
## How much items can be bought.
var projected_buy_max: PackedFloat64Array
## How much will [member bought] change when you buy the maximum amount of items you can buy.
var projected_bought_change: PackedFloat64Array
## The total cost of the maximum items you can buy.
var projected_buy_max_cost: PackedFloat64Array
## How much will [member res_ref] change when you buy the maximum amount of items you can buy.
var projected_res_change: PackedFloat64Array


var formats: Dictionary:
	get = get_format

## The resource that will be spent to buy the buyable.
var res_ref: BigNumRef = null:
	set(value):
		if is_instance_valid(res_ref):
			if res_ref.n_changed.is_connected(update_buy_max_projection):
				res_ref.n_changed.disconnect(update_buy_max_projection)
		if always_update and is_instance_valid(value):
			value.n_changed.connect(update_buy_max_projection)
		res_ref = value
	get:
		return res_ref
## The amount of items that is already bought.
var bought := BigNumRef.new()
## The formula. Applied if [param scale] is [enum CostModes.FORMULA].
var formula: FormulaRef = FormulaRef.new(bought)
var additional_substitutions: Dictionary[String, PackedFloat64Array]
func _ready() -> void:
	if is_instance_valid(starting_starting_cost):
		starting_cost = starting_starting_cost.n
		starting_starting_cost = null
	if is_instance_valid(starting_scale):
		scale = starting_scale.n
		starting_scale = null
	if is_instance_valid(starting_default_bulk_amount):
		default_bulk_amount = starting_default_bulk_amount.n
		starting_default_bulk_amount = null
## Tries to buy [param bulk_amount] or less, spending [member res_ref].
func buy_bulk(bulk_amount: PackedFloat64Array = default_bulk_amount):
	if not can_buy:
		return
	if BigNumRef.g_lt(bulk_amount, BigNumRef.BIGNUM_ONE):
		return
	if not is_instance_valid(res_ref):
		assert(false, "buyable '{0}' doesn't have a resource to spend.".format([self]))
		return
	if scale_type != CostModes.FORMULA and (BigNumRef.g_is_nan(scale) or BigNumRef.g_is_nan(scale)):
		assert(false, "buyable '{0}' is missing either scale or starting cost.".format([self]))
		return
	var amount: PackedFloat64Array
	match scale_type:
		CostModes.GEOMETRIC:
			amount = BigNumRef.afford_geometric_series(res_ref.d, starting_cost, scale, bought.d)
			amount = BigNumRef.g_num_min(amount, bulk_amount)
			res_ref.n_sub(BigNumRef.sum_geometric_series(amount, starting_cost, scale, bought.d))
		CostModes.ARITHMETIC:
			amount = BigNumRef.afford_arithmetic_series(res_ref.d, starting_cost, scale, bought.d)
			amount = BigNumRef.g_num_min(amount, bulk_amount)
			res_ref.n_sub(BigNumRef.sum_arithmetic_series(amount, starting_cost, scale, bought.d))
		CostModes.FORMULA:
			amount = formula.calculate_max_affordable(res_ref.d, bought, additional_substitutions, cumulative_cost, -1, bulk_amount)
			res_ref.n_sub(formula.calculate_cost(amount, bought, additional_substitutions, cumulative_cost))
	var old_amount: PackedFloat64Array = bought.d
	bought.n_add(amount)
	bought_changed.emit(old_amount, bought.d)
	return

## Tries to buy one item, spending [member res_ref].
func buy_one() -> void:
	if not can_buy:
		return
	if not is_instance_valid(res_ref):
		assert(false, "buyable '{0}' doesn't have a resource to spend.".format([self]))
		return
	if absf(bought.d[0]) >= 1:
		push_warning("buyable '{0}' bought is too large to handle buying one properly".format([self]))
		return
	if scale_type != CostModes.FORMULA and (BigNumRef.g_is_nan(scale) or BigNumRef.g_is_nan(scale)):
		assert(false, "buyable '{0}' is missing either scale or starting cost.".format([self]))
		return
	match scale_type:
		CostModes.GEOMETRIC:
			var amount: PackedFloat64Array = BigNumRef.afford_geometric_series(res_ref.d, starting_cost, scale, bought.d)
			if not BigNumRef.g_eq(amount, BigNumRef.BIGNUM_ZERO):
				bought.n_add(BigNumRef.BIGNUM_ONE)
				bought_changed.emit(BigNumRef.g_sub(bought.d, BigNumRef.BIGNUM_ONE), bought.d)
				res_ref.n_sub(BigNumRef.sum_geometric_series(BigNumRef.from_float(1), starting_cost, scale, bought.d))
		CostModes.ARITHMETIC:
			var amount: PackedFloat64Array = BigNumRef.afford_arithmetic_series(res_ref.d, starting_cost, scale, bought.d)
			if not BigNumRef.g_eq(amount, BigNumRef.BIGNUM_ZERO):
				bought.n_add(BigNumRef.BIGNUM_ONE)
				bought_changed.emit(BigNumRef.g_sub(bought.d, BigNumRef.BIGNUM_ONE), bought.d)
				res_ref.n_sub(BigNumRef.sum_arithmetic_series(BigNumRef.from_float(1), starting_cost, scale, bought.d))
		CostModes.FORMULA:
			var amount: PackedFloat64Array = formula.calculate_max_affordable(res_ref.d, bought, additional_substitutions, cumulative_cost, -1, BigNumRef.BIGNUM_ONE)
			if not BigNumRef.g_eq(amount, BigNumRef.BIGNUM_ZERO):
				bought.n_add(BigNumRef.BIGNUM_ONE)
				bought_changed.emit(BigNumRef.g_sub(bought.d, BigNumRef.BIGNUM_ONE), bought.d)
				res_ref.n_sub(formula.calculate_cost(BigNumRef.BIGNUM_ONE, bought, additional_substitutions, cumulative_cost))
				


## Updates the projection of the maximum amount of items you can buy.
func update_buy_max_projection() -> void:
	if not is_instance_valid(res_ref):
		assert(false, "buyable '{0}' doesn't have a resource to spend.".format([self]))
		return
	if scale_type != CostModes.FORMULA and (BigNumRef.g_is_nan(scale) or BigNumRef.g_is_nan(scale)):
		assert(false, "buyable '{0}' is missing either scale or starting cost.".format([self]))
		return
	match scale_type:
		CostModes.GEOMETRIC:
			projected_buy_max = BigNumRef.afford_geometric_series(res_ref.d, starting_cost, scale, bought.d)
			projected_buy_max_cost = BigNumRef.sum_geometric_series(projected_buy_max, starting_cost, scale, bought.d)
		CostModes.ARITHMETIC:
			projected_buy_max = BigNumRef.afford_arithmetic_series(res_ref.d, starting_cost, scale, bought.d)
			projected_buy_max_cost = BigNumRef.sum_arithmetic_series(projected_buy_max, starting_cost, scale, bought.d)
		CostModes.FORMULA:
			projected_buy_max = formula.calculate_max_affordable(res_ref.d, bought, additional_substitutions, cumulative_cost, -1, BigNumRef.BIGNUM_INF)
			projected_buy_max_cost = formula.calculate_cost(projected_buy_max, bought, additional_substitutions, cumulative_cost)
	projected_bought_change = BigNumRef.g_sub(bought.d, BigNumRef.g_add(bought.d, projected_buy_max))
	projected_res_change = BigNumRef.g_sub(res_ref.d, BigNumRef.g_sub(res_ref.d, projected_buy_max_cost))

## Gets the projection of a [method buy_bulk] call with [param bulk_amount].[br]
## Returns an dictionary that has two values:[br]
## - "bought" is the amount of the buyable bought by the call. [br]
## - "cost" is the cost for that amount of buyable. [br]
## [param use_change] Whether to take rounding errors of adding/subtracting large numbers into account.
func get_buy_bulk_projection(bulk_amount: PackedFloat64Array = default_bulk_amount, use_change: bool = use_change_on_projection_string) -> Dictionary[String, PackedFloat64Array]:
	if not is_instance_valid(res_ref):
		assert(false, "buyable '{0}' doesn't have a resource to spend.".format([self]))
		return {
			"bought": BigNumRef.BIGNUM_ZERO.duplicate(),
			"res": BigNumRef.BIGNUM_ZERO.duplicate()
		}
	if BigNumRef.g_lt(bulk_amount, BigNumRef.BIGNUM_ONE):
		return {
			"bought": BigNumRef.BIGNUM_ZERO.duplicate(),
			"res": BigNumRef.BIGNUM_ZERO.duplicate()
		}
	var amount: PackedFloat64Array
	var cost: PackedFloat64Array
	match scale_type:
		CostModes.GEOMETRIC:
			amount = BigNumRef.afford_geometric_series(res_ref.d, starting_cost, scale, bought.d)
			amount = BigNumRef.g_num_min(amount, bulk_amount)
			cost = BigNumRef.sum_geometric_series(amount, starting_cost, scale, bought.d)
		CostModes.ARITHMETIC:
			amount = BigNumRef.afford_arithmetic_series(res_ref.d, starting_cost, scale, bought.d)
			amount = BigNumRef.g_num_min(amount, bulk_amount)
			cost = BigNumRef.sum_arithmetic_series(amount, starting_cost, scale, bought.d)
		CostModes.FORMULA:
			amount = formula.calculate_max_affordable(res_ref.d, bought, additional_substitutions, cumulative_cost, -1, bulk_amount)
			cost = formula.calculate_cost(amount, bought, additional_substitutions, cumulative_cost)
		_:
			amount = BigNumRef.BIGNUM_NAN
			cost = BigNumRef.BIGNUM_NAN
	if use_change:
		amount = BigNumRef.g_sub(bought.d, BigNumRef.g_add(bought.d, amount))
		cost = BigNumRef.g_sub(res_ref.d, BigNumRef.g_sub(res_ref.d, cost))
	return {
		"bought": amount,
		"res": cost
	}


func get_format() -> Dictionary:
	var format_types: Dictionary
	if use_change_on_projection_string:
		format_types = {
		"bought": BigNumRef.g_to_str(projected_bought_change),
		"res": BigNumRef.g_to_str(projected_res_change)
		}
	else:
		format_types = {
		"bought": BigNumRef.g_to_str(projected_buy_max),
		"res": BigNumRef.g_to_str(projected_buy_max_cost)
		}
	return format_types

## Override this function to change how "resetting" this node behaves.
## Normally, resetting sets the bought amount to 0.
func reset():
	bought.n_replace(BigNumRef.BIGNUM_ZERO)

func get_max_projection() -> String:
	return "Buy {bought}\nCost: {res}".format(formats)

func save_data():
	PlayerData.data[var_to_str(self.get_path())] = bought.n

func load_data():
	if PlayerData.data.has(var_to_str(self.get_path())):
		bought.l_from_str(PlayerData.data[var_to_str(self.get_path())])
	else:
		bought.n_replace(BigNumRef.BIGNUM_ZERO)

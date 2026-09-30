extends Node
class_name Upgrade

@export var cost: BigNumResource

signal upgrade_bought()
signal bought_changed()
signal upgrade_reset()

## The resouce that will be spent to buy the upgrade.
var res_ref: BigNumRef
@export var can_buy: bool
@export var subtract_on_buy: bool
var bought: bool

func upgrade_cost_reachable() -> bool:
	if not is_instance_valid(res_ref):
		push_error("Upgrade '{0}' doesn't have a resource to spend.".format([self]))
		return false
	return BigNumRef.g_gte(res_ref.d, cost.n)

func buy_upgrade() -> void:
	if (not can_buy) or (not upgrade_cost_reachable()):
		print("not enough resref")
		return
	if subtract_on_buy:
		res_ref.n_sub(cost.n)
	bought = true
	upgrade_bought.emit()
	bought_changed.emit()

func reset() -> void:
	if bought == true:
		upgrade_reset.emit()
		bought_changed.emit()
	bought = false

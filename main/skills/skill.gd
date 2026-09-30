extends Control

@export var point_node: Node
# "current p"
var p: BigNumRef = BigNumRef.new(1)
var progress_towards_next: BigNumRef = BigNumRef.new()
var total_p: BigNumRef = BigNumRef.new(1)
var skills_already_bought: Array[Upgrade] = []

signal skill_bought(upgrade: int)
signal skill_reset()

@export var upgrades_parent_node: Node
@export var p_label: Label
var scaling_formula: FormulaRef

func _init():
	scaling_formula = FormulaRef.new(1e10).pow_base_mutate(total_p)
# Called when the node enters the scene tree for the first time.
func _ready():
	p.n_changed.connect(on_p_change, CONNECT_DEFERRED)
	for upgrade_untyped in upgrades_parent_node.get_children():
		var u: Upgrade = upgrade_untyped as Upgrade
		if not u:
			continue
		u.res_ref = p
		u.upgrade_bought.connect(_on_upgrade_bought.bind(u))
# Callable
func _on_upgrade_bought(u: Upgrade) -> void:
	skills_already_bought.push_back(u)
	var i: int = u.get_index(false)
	skill_bought.emit(i)

func on_p_change() -> void:
	p_label.text = "You have {n} skill points".format({"n": p.n_str_to_decimal_places(0)})
 
func reset_point() -> void:
	var extra_p : PackedFloat64Array
	progress_towards_next.add(point_node.p)
	extra_p = scaling_formula.calculate_max_affordable(progress_towards_next.d, p, {})
	extra_p = BigNumRef.g_num_max(extra_p, BigNumRef.from_float(0))
	total_p.n_add(extra_p)
	p.n_add(extra_p)
	point_node.reset()

func reset_skills():
	for u in skills_already_bought:
		u.bought = false
	skill_reset.emit()
	skills_already_bought.clear()
	p.replace(total_p)
	point_node.reset()

#func erase_skill(u: Upgrade):
	#

func save_data():
	var result: Dictionary[String, Variant] = {}
	result.p = p.d
	result.t = total_p.d
	result.next = progress_towards_next.d
	var us: PackedInt32Array = skills_already_bought.map(_get_id_of_upgrade)
	result.us = us
	PlayerData.data.skill_point = result

func _get_id_of_upgrade(o: Node) -> int:
	return o.get_index(false)

func load_data():
	if "skill_point" not in PlayerData.data:
		p.v_replace(1)
		total_p.v_replace(1)
		progress_towards_next.v_replace(0)
		for u in skills_already_bought:
			u.bought = false
		skills_already_bought.clear()
	else:
		var to_load: Dictionary = PlayerData.data.skill_point
		if to_load.is_empty(): # WHAT HOW
			p.v_replace(1)
			total_p.v_replace(1)
			progress_towards_next.v_replace(0)
			for u in skills_already_bought:
				u.bought = false
			skills_already_bought.clear()
			return
		p.n_replace(to_load.p)
		total_p.n_replace(to_load.t)
		progress_towards_next.n_replace(to_load.next)
		for node_id in to_load.us:
			upgrades_parent_node.get_child(node_id).bought = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

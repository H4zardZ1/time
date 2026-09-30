extends Panel


@export var x_button: BaseButton
@export var const_button: BaseButton

var p: BigNumRef = BigNumRef.new()

var delta_p: BigNumRef:
	get = get_delta_p

var x_n: PackedFloat64Array:
	get = get_x_n

@onready var delta_const: Buyable = $DeltaConst
@onready var x: Buyable = $X
@onready var x_mod: ModifierNode = $XModifiers
@onready var dl: RichTextLabel = $DeltaLabel
# Called when the node enters the scene tree for the first time.
func _ready():

	delta_const.res_ref = p
	x.res_ref = delta_const.bought

	Ticker.timeout.connect(_on_tick)
	p.n_changed.connect(_on_p_change, 1)
	delta_const.bought.n_changed.connect(_on_delta_const_change, 1)
	x.bought.n_changed.connect(_on_x_change, 1)

	reset.call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func get_delta_p():
	var result: BigNumRef = BigNumRef.new(0)

	result.add(delta_const.bought)
	result.n_add(BigNumRef.g_mul(x_n, x.bought.d))

	return result

func get_x_n():
	return x_mod.n_apply(BigNumRef.from_float(0))

func reset():
	p.d = BigNumRef.from_float(0)
	for child in get_children():
		if child.has_method("reset"):
			child.reset()

func _skill_bought(skill: String):
	if skill == "ticks_x":
		set_ticks_x_active(true)


func _on_tick():
	p.add(delta_p)
	
	var s: String = "[center]"
	if not x.bought.n_eq(BigNumRef.from_float(0)):
		if not x.bought.n_eq(BigNumRef.from_float(1)):
			s += "{m}x + ".format({"m": x.bought.n_str()})
		else:
			s += "x + "
	s += BigNumRef.g_to_str(delta_const.bought.d)
	s += "\nx = {v}".format({"v": BigNumRef.g_to_str(x_n)})
	s += "\n...= {0} points/tick".format([delta_p.n_str_to_decimal_places(2)])
	
	dl.text = s

func _on_p_change():
	($Label as Label).text = "You have {n} points.".format({"n": BigNumRef.g_to_str(p.d)})
	$BuyGrid/ConstButton.tooltip_text = const_button.start_v.format(delta_const.formats)

func _on_delta_const_change():
	x_button.tooltip_text = x_button.start_v.format(x.formats)
	const_button.tooltip_text = const_button.start_v.format(delta_const.formats)

func _on_x_change():
	x_button.tooltip_text = x_button.start_v.format(x.formats)

func set_ticks_x_active(state: bool):
	$XModifiers/TicksX.active = state

func save_data():
	var result: Dictionary = {}
	result.p = p.n_str()
	PlayerData.data[var_to_str(self.get_path())] = result

func load_data():
	if PlayerData.data.has(var_to_str(self.get_path())):
		p.l_from_str(PlayerData.data[var_to_str(self.get_path())].p)
	else:
		p.l_from_str("0")

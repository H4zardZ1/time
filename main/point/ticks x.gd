extends ModifierNode

var ticks := BigNumRef.new()

func _ready():
	Ticker.timeout.connect(_on_tick)

func reset():
	ticks.n_replace(BigNumRef.BIGNUM_ZERO)

func _on_tick():
	ticks.n_add(BigNumRef.BIGNUM_ONE)

func _custom_modifier(n: PackedFloat64Array) -> PackedFloat64Array:
	return BigNumRef.g_add(n, ticks.d)

func save_data():
	PlayerData.data["ticks_x"] = ticks.n_str()

func load_data():
	if PlayerData.data.has("ticks_x"):
		ticks.l_from_str(PlayerData.data["ticks_x"])
	else:
		ticks.v_replace(0)

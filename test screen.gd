extends CanvasLayer

var d: bool = false
var v: bool = false
# Called when the node enters the scene tree for the first time.
@onready var n1_input: LineEdit = $TextEdit
@onready var n2_input: LineEdit = $TextEdit2
@onready var opt: OptionButton = $OptionButton
@onready var label: Label = $Label

var n: PackedFloat64Array

func _ready():
	d_up()
	test_value.call_deferred()

func test_value():
	var formula: FormulaRef = FormulaRef.new("x0").pow_mutate(
		FormulaRef.new(1.5).add_mutate(FormulaRef.new(2.5).div_mutate("x1"))
	).mul_mutate(3000)
	var antiderivated: FormulaRef = formula.antiderivated("x0")
	var fifty_as_bignum: PackedFloat64Array = BigNumRef.from_float(50)
	var invert_result: PackedFloat64Array = \
	antiderivated.invert(BigNumRef.from_float(125_000_000), "x1", {"x0": fifty_as_bignum})
	print(invert_result)
	print(BigNumRef.g_to_str(invert_result))
	var result: PackedFloat64Array = antiderivated.evaluate({"x0": fifty_as_bignum, "x1": invert_result})
	print(result)
	print(BigNumRef.g_to_str(result))
	var err: PackedFloat64Array = BigNumRef.g_sub(BigNumRef.from_float(125_000_000), result)
	print(err)
	print(BigNumRef.g_to_str(err))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func d_up():
	if not d:
		update.call_deferred()
		d = true

func update():
	var op := opt.selected
	var v1 := BigNumRef.from_str(n1_input.text)
	var v2 := BigNumRef.from_str(n2_input.text)
	match op:
		0:
			n = BigNumRef.g_add(v1, v2)
		1:
			n = BigNumRef.g_mul(v1, v2)
		2:
			n = BigNumRef.g_div(v1, v2)
		3:
			n = BigNumRef.g_pow(v1, v2)
		4:
			n = BigNumRef.g_log(v2, v1)
		5:
			n = BigNumRef.g_tetrate(v1, v2)
		_:
			n = v1 # I don't need a new Dictionary, just THE v1 will suffice
	label.text = BigNumRef.g_to_str(n)
	d = false

func _on_text_edit_text_submitted(_new_text):
	d_up()

func _on_option_button_item_selected(_index):
	d_up()

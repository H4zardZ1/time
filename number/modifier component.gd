extends Resource
class_name ModifierComponent


enum ModifierType {
  CUSTOM = -1,
  ADD,
  SUBTRACT,
  MULTIPLY,
  DIVIDE,
  DIVIDEND,
  POW,
  POW_BASE,
  ROOT,
  ROOT_BASE,
  LOG,
  LOG_BASE,
  TETRATE,
  TETRATE_BASE,
  TETRATE_PAYLOAD,
  ITERATED_LOG,
  TETRATE_ROOT,
  TETRATE_LOG
}

# const _VALUE_RANGE = [
#   [1],
#   [1],
#   [1],
#   [1],
#   [1],
#   [1],
#   [1],
#   [1],
#   [1],
#   [1],
#   [1, 2],
#   [1, 2],
#   [2],
#   [2],
#   [1],
#   [1]
# ]

@export var values: Array[BigNumResource] = []
@export var op_type: ModifierType = ModifierType.ADD
@export var linear_tetration: bool = false
@export var active: bool = false

var n2: PackedFloat64Array:
  get:
    return values[0].n

func apply(n: PackedFloat64Array) -> PackedFloat64Array:
  match op_type:
    ModifierType.ADD:
      return BigNumRef.g_add(n, n2)
    ModifierType.SUBTRACT:
      return BigNumRef.g_sub(n, n2)
    ModifierType.MULTIPLY:
      return BigNumRef.g_mul(n, n2)
    ModifierType.DIVIDE:
      return BigNumRef.g_div(n, n2)
    ModifierType.DIVIDEND:
      return BigNumRef.g_div(n2, n)
    ModifierType.POW:
      return BigNumRef.g_pow(n2, n)
    ModifierType.POW_BASE:
      return BigNumRef.g_pow(n, n2)
    ModifierType.ROOT:
      return BigNumRef.g_root(n2, n)
    ModifierType.ROOT_BASE:
      return BigNumRef.g_root(n, n2)
    ModifierType.LOG:
      return BigNumRef.g_log(n2, n)
    ModifierType.LOG_BASE:
      return BigNumRef.g_log(n, n2)
    ModifierType.TETRATE:
      return BigNumRef.g_tetrate(n2, n, values[1].n, linear_tetration)
    ModifierType.TETRATE_BASE:
      return BigNumRef.g_tetrate(n, n2, values[1].n, linear_tetration)
    ModifierType.TETRATE_PAYLOAD:
      return BigNumRef.g_tetrate(n2, values[1].n, n, linear_tetration)
    ModifierType.ITERATED_LOG:
      return BigNumRef.g_i_log(n, n2, values[1].n, linear_tetration)
    ModifierType.TETRATE_ROOT:
      return BigNumRef.g_sroot(n, n2)
    ModifierType.TETRATE_LOG:
      return BigNumRef.g_slog(n, n2, linear_tetration)
    _:
      return custom_op(n)

## Override this function if you want to create a custom Modifier.
func custom_op(_n: PackedFloat64Array) -> PackedFloat64Array:
  return _n
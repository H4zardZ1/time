extends Buyable


# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass # Replace with function body.


#func _process(delta):
	#pass

func reset():
	bought.n_replace(BigNumRef.BIGNUM_ONE)

func load_data():
	if PlayerData.data.has(var_to_str(self.get_path())):
		bought.l_from_str(PlayerData.data[var_to_str(self.get_path())])
	else:
		bought.n_replace(BigNumRef.BIGNUM_ONE)

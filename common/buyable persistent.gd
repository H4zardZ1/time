extends Buyable

@export var node_save_name: String = ""

func save_data():
	PlayerData.data[node_save_name] = bought.n_str()

func load_data():
	if PlayerData.data.has(self.get_path()):
		bought.l_from_str(PlayerData.data[node_save_name])
	else:
		bought.l_from_str("0")
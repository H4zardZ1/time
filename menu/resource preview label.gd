extends RichTextLabel


@export var points_node: Node
@export var skills_node: Node

# No idea if onreadying this does anything, buuuut
@onready var nodes_to_check: Dictionary[Node, Dictionary] = {
	points_node: {
		"color": Color.WHITE,
		"resource_name": "Points: "
	},
	skills_node: {
		"color": Color.LIGHT_GRAY,
		"resource_name": "Skill Points: "
	}

}




func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 5 == 4:
		text = ""
		for node in nodes_to_check.keys():
			if not (is_instance_valid(node) and\
			(node.p is BigNumRef) and\
			is_instance_valid(node.p) and\
			node.p.n_gt(BigNumRef.BIGNUM_ZERO)):
				continue
			push_color(nodes_to_check[node].color)
			if nodes_to_check[node].color.ok_hsl_l <= 0.25:
				push_outline_color(Color.WHITE)
			else:
				push_outline_color(Color.BLACK)
			append_text("{0}{1}\n".format([nodes_to_check[node].resource_name, 
			node.p.n_str()]))
			pop()
			pop()

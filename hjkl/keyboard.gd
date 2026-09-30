extends Node

# Use Vector2i since I'm pretty sure no keyboard can ever reach 2bil in length or breadth
var keyboard_layouts: Dictionary = {
	"qwerty": [
		# This looks like slightly misaligned, because 
		"~` 1! 2@ 3# 4$ 5% 6^ 7& 8* 9( 0) -_ =+",
		"  qQ wW eE rR tT yY uU iI oO pP [{ ]} |\\",
		"  aA sS dD fF gG hH jJ kK lL ;: '`\"",
		"  zZ xX cC vV bB nN mM ,< .> /?" 
		# TODO: Add spaces
	],
	"keypad": [
		"  / * -",
		"7 8 9 +",
		"4 5 6",
		"1 2 3",
		"  0 ."
	]
}



func key_to_vector(keyboard_layout: Array, key: String):
	for row_n in range(keyboard_layout.size()):
		var row: Array
		if keyboard_layout[row_n] is String:
			row = (keyboard_layout[row_n] as String).split(" ", true)
		elif keyboard_layout[row_n] is Array:
			row = keyboard_layout[row_n]
		else:
			assert(false, "Can't use '{row}' as row of a keyboard".format({"row": keyboard_layout[row_n]}))
			return Vector2i(-1, 0)
		for column_n in range(row.size()):
			if (row[column_n] as String).contains(key):
				return Vector2i (column_n, row_n)
	push_error("'{key}' not found in keyboard layout".format({"key": key}))
	return Vector2i(-1, 0)

func find_pattern(locations: Array[Vector2i]):
	var result: Dictionary = {}
	for n in locations:
		pass
	return result
	

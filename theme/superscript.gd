@tool
# Having a class name is handy for picking the effect in the Inspector.
class_name RichTextSuperscript
extends RichTextEffect


var bbcode = "ssc"


func _process_custom_fx(char_fx: CharFXTransform):
	# We can't shrink the text's width via char_fx, so we just make this function put the text up
	char_fx.offset += Vector2(0, -6) 
	return true

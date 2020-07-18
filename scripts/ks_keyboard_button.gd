extends KSButtonPressable


class_name KSButtonKeyboard


var key_value : String setget set_key_value
var text_label


func _init():
	text_label = get_node("2DTextLabel")
	text_label.set_font_size_multiplier(4)


func set_key_value(new_value : String):
	key_value = new_value
	text_label.set_text(key_value)


func button_press(other_area: Area):
	.button_press(other_area)
	

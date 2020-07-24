extends Spatial


class_name KeyboardScreen


onready var keyboard = $Keyboard
onready var title_lable = $TitleLabel
onready var keyboard_output_label = $KeyboardOutputLabel


func set_enter_callback(callback_func, args):
	keyboard.set_enter_callback(callback_func, args)


func set_placeholder(placeholder : String):
	keyboard_output_label.set_text(placeholder)


func set_label(label : String):
	title_lable.set_text(label)

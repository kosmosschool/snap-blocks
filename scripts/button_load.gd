extends KSButtonPressable


# button used to load creation
class_name ButtonLoad


var file_name : String setget set_file_name


func set_file_name(new_value):
	file_name = new_value

# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	save_system.load_creation(file_name)

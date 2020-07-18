extends KSButtonPressable


# button to take cover pic for creation
class_name ButtonCancelPic


onready var screens_controller = get_node(global_vars.ALL_SCREENS_PATH)


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	screens_controller.change_screen("LoadScreen")

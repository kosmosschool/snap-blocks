extends KSButtonPressable


# button used to delete saved files
class_name ButtonDelete


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	var load_screen = get_parent()
	load_screen.toggle_delete_mode()

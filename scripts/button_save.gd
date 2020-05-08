extends KSButtonPressable


# button used to save current creation
class_name ButtonSave



# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	save_system.save_creation()
	
	var load_screen = get_parent()
	load_screen.refresh_files()

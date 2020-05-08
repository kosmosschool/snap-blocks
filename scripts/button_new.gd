extends KSButtonPressable


# button used to create a new creation file and clear the current one
class_name ButtonNew


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	save_system.clear_and_new()

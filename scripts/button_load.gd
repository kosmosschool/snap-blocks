extends KSButtonPressable


# button used to load creation
class_name ButtonLoad


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	save_system.load_creation("user://creation_2.json")

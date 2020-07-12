extends KSButtonPressable


# button to take cover pic for creation
class_name ButtonTakePic


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	var save_cam = get_node("../SaveCam")
	save_cam.save_picture()

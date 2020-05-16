extends BaseController


class_name ControllerRecolor


func _process(delta):
	if not selected:
		return
	
	switch_material(vr.get_controller_axis(vr.AXIS.RIGHT_JOYSTICK_X))


# overriding from parent
func _on_ARVRController_button_pressed(button_number):
	if not selected:
		return
	
	if button_number == vr.CONTROLLER_BUTTON.INDEX_TRIGGER:
		var overlapping_block_area = get_overlapping_area()
		
		if overlapping_block_area:
			# delete block from multi mesh
			overlapping_block_area.recolor()


# overriding from parent
func _on_Base_Controller_controller_selected():
	pass


# overriding from parent
func _on_Base_Controller_controller_unselected():
	pass

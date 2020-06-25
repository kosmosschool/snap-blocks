extends BaseController


class_name ControllerDelete


# overriding from parent
func _on_ARVRController_button_pressed(button_number):
	if not selected:
		return
	
	if not game_settings.get_interaction_enabled():
		return
		
	if button_number == vr.CONTROLLER_BUTTON.INDEX_TRIGGER:
		var overlapping_block_area = get_overlapping_area()
		
		if overlapping_block_area:
			# delete block from multi mesh
			overlapping_block_area.delete_from_multi_mesh()


# overriding from parent
func _on_Base_Controller_controller_selected():
	pass


# overriding from parent
func _on_Base_Controller_controller_unselected():
	pass

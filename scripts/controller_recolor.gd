extends BaseController


class_name ControllerRecolor


onready var big_polyhedron_mesh = $TogglePolyhedron
onready var mini_polyhedron_mesh = $RecolorPolyhedron


func _ready():
	update_mesh_colors()


# overriding from parent
func _on_ARVRController_button_pressed(button_number):
	if not selected:
		return
	
	if button_number == vr.CONTROLLER_BUTTON.INDEX_TRIGGER:
		var overlapping_block_area = get_overlapping_area()
		
		if overlapping_block_area:
			# delete block from multi mesh
			overlapping_block_area.recolor(controller_side_string)


# overriding from parent
func _on_Base_Controller_controller_selected():
	update_mesh_colors()


# overriding from parent
func _on_Base_Controller_controller_unselected():
	pass


func update_mesh_colors() -> void:
	big_polyhedron_mesh.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))
	mini_polyhedron_mesh.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))


func _on_Controller_System_joystick_x_axis_pushed_right(side : String):
	if side != controller_side_string:
		return
	
	if not selected:
		return
	
	color_system.rotate_material(0, controller_side_string)
	update_mesh_colors()


func _on_Controller_System_joystick_x_axis_pushed_left(side : String):
	if side != controller_side_string:
		return
	
	if not selected:
		return
	
	color_system.rotate_material(1, controller_side_string)
	update_mesh_colors()

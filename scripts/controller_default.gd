extends BaseController


class_name ControllerDefault


onready var building_block_base = preload("res://scenes/building_blocks/block_base_cube.tscn")
onready var mini_cube_mesh = $Cube
#onready var ghost_building_block_base = preload("res://scenes/building_blocks/ghost_block_base.tscn")


func _ready():
	mini_cube_mesh.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))

# overriding from parent
func _on_ARVRController_button_pressed(button_number):
	if not selected:
		return
	# if grip trigger pressed while B button being held down
#	if vr.button_pressed(vr.BUTTON.B) and button_number == vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
#		create_ghost_block()
	
	if button_number == vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
		var overlapping_block_area = get_overlapping_area()
		
		if overlapping_block_area:
			overlapping_block_area.remove_from_multi_mesh(controller_grab)
		else:
			create_block()


# overriding from parent
func _on_Base_Controller_controller_selected():
	update_mesh_color()


# overriding from parent
func _on_Base_Controller_controller_unselected():
	pass


func create_block() -> void:
	# don't create if already holding something
	if controller_grab.held_object:
		return
	
	var overlapping_block = get_overlapping_block()
	
	if overlapping_block:
		return
	
	var block_instance = building_block_base.instance()
	all_building_blocks.add_child(block_instance)
	
	var new_origin = controller_grab.global_transform.origin + controller_grab.global_transform.basis.z * -0.058
	
	block_instance.global_transform.origin = new_origin
	block_instance.global_transform.basis = controller_grab.global_transform.basis
	block_instance.set_color(color_system.get_current_color_name(controller_side_string))
	
	controller_grab.start_grab_hinge_joint(block_instance)


func _on_Controller_System_joystick_x_axis_pushed_right(side : String):
	if side != controller_side_string:
		return
	
	if not selected:
		return
	
	color_system.rotate_material(0, controller_side_string)
	update_mesh_color()


func _on_Controller_System_joystick_x_axis_pushed_left(side : String):
	if side != controller_side_string:
		return
	
	if not selected:
		return
		
	color_system.rotate_material(1, controller_side_string)
	update_mesh_color()


func update_mesh_color():
	mini_cube_mesh.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))

#func create_ghost_block() -> void:
#	var overlapping_block = get_overlapping_block()
#
#	if not overlapping_block:
#		return
#
#	var ghost_block_instance = ghost_building_block_base.instance()
#	movable_world_node.add_child(ghost_block_instance)
#
#	# position
#	ghost_block_instance.global_transform = overlapping_block.global_transform
#
#	# grab
#	controller_grab.start_grab_hinge_joint(ghost_block_instance)

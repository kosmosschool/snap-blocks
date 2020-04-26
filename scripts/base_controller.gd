extends Spatial


class_name BaseController


signal controller_selected
signal controller_unselected

var select_default := false
var selected := false setget set_selected, get_selected

onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var grab_area_right = get_node(global_vars.CONTR_RIGHT_PATH + "/controller_grab/GrabArea")
onready var controller_grab = get_node(global_vars.CONTR_RIGHT_PATH + "/controller_grab")
onready var all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH) 
onready var movable_world_node = get_node(global_vars.MOVABLE_WORLD_PATH)
onready var building_block_base = preload("res://scenes/building_blocks/block_base_cube.tscn")
onready var ghost_building_block_base = preload("res://scenes/building_blocks/ghost_block_base.tscn")


func set_selected(new_value):
	selected = new_value
	visible = new_value
	
	if new_value:
		emit_signal("controller_selected")
	else:
		emit_signal("controller_unselected")


func get_selected():
	return selected


func _ready():
	right_controller.connect("button_pressed", self, "_on_right_ARVRController_button_pressed")
	connect("controller_selected", self, "_on_Base_Controller_controller_selected")
	connect("controller_unselected", self, "_on_Base_Controller_controller_unselected")


# implement this in child
func _on_right_ARVRController_button_pressed(button_number):
	# if grip trigger pressed while B button being held down
	if vr.button_pressed(vr.BUTTON.B) and button_number == vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
		create_ghost_block()
	
	if button_number == vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
		var overlapping_block_area = get_overlapping_area()
		
		if overlapping_block_area:
			overlapping_block_area.remove_from_multi_mesh()
		else:
			create_block()


# implement this in child
func _on_Base_Controller_controller_selected():
	pass


# implement this in child
func _on_Base_Controller_controller_unselected():
	pass


func get_overlapping_area() -> Area:
	# check if hovering over block
	var overlapping_areas = controller_grab.overlapping_areas()
	
	for area in overlapping_areas:
		if area is BlockArea:
			return area
	
	return null


func get_overlapping_block() -> BuildingBlockSnappable:
	# check if hovering over block
	var overlapping_objects = controller_grab.overlapping_objects()
	
	for obj in overlapping_objects:
		if obj is BuildingBlockSnappable:
			return obj
	
	return null


func create_block() -> void:
	# don't create if already holding something
	if controller_grab.held_object:
		return
	
	var block_instance = building_block_base.instance()
	all_building_blocks.add_child(block_instance)
	
	var new_origin = controller_grab.global_transform.origin + controller_grab.global_transform.basis.z * -0.076
	
	block_instance.global_transform.origin = new_origin
	block_instance.global_transform.basis = controller_grab.global_transform.basis
	
	controller_grab.start_grab_hinge_joint(block_instance)


func create_ghost_block() -> void:
	var overlapping_block = get_overlapping_block()
	
	if not overlapping_block:
		return
	
	var ghost_block_instance = ghost_building_block_base.instance()
	movable_world_node.add_child(ghost_block_instance)
	
	# position
	ghost_block_instance.global_transform = overlapping_block.global_transform

	# grab
	controller_grab.start_grab_hinge_joint(ghost_block_instance)

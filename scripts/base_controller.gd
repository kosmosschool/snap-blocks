extends Spatial


class_name BaseController


signal controller_selected
signal controller_unselected

var select_default := false
var controller_side_string : String
var selected := false setget set_selected, get_selected

onready var ar_vr_controller = get_parent().get_parent().get_parent()
onready var controller_grab = get_node("../../ControllerGrab")
onready var all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH)
onready var controller_system = get_node(global_vars.CONTROLLER_SYSTEM_PATH)

enum ControllerSide {RIGHT, LEFT}
export(ControllerSide) var controller_side


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
	ar_vr_controller.connect("button_pressed", self, "_on_ARVRController_button_pressed")
	connect("controller_selected", self, "_on_Base_Controller_controller_selected")
	connect("controller_unselected", self, "_on_Base_Controller_controller_unselected")
	controller_system.connect("joystick_x_axis_pushed_right", self, "_on_Controller_System_joystick_x_axis_pushed_right")
	controller_system.connect("joystick_x_axis_pushed_left", self, "_on_Controller_System_joystick_x_axis_pushed_left")
	
	if controller_side == ControllerSide.RIGHT:
		controller_side_string = "right"
	else:
		controller_side_string = "left"


# implement this in child
#func _on_ARVRController_button_pressed(button_number):
#	if not selected:
#		return


# implement this in child
func _on_Base_Controller_controller_selected():
	pass


# implement this in child
func _on_Base_Controller_controller_unselected():
	pass


func _on_Controller_System_joystick_x_axis_pushed_right(side : String):
	pass


func _on_Controller_System_joystick_x_axis_pushed_left(side : String):
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

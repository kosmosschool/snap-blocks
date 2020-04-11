extends Spatial


class_name BaseController


signal controller_selected
signal controller_unselected

var select_default := false
var selected := false setget set_selected, get_selected

onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var grab_area_right = get_node(global_vars.CONTR_RIGHT_PATH + "/controller_grab/GrabArea")
onready var controller_grab = get_node(global_vars.CONTR_RIGHT_PATH + "/controller_grab")
onready var building_block_base = preload("res://scenes/building_blocks/block_base.tscn")
onready var all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH) 


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
		duplicate_block()


# implement this in child
func _on_Base_Controller_controller_selected():
	pass


# implement this in child
func _on_Base_Controller_controller_unselected():
	pass
	

func duplicate_block():
	
	# check if hovering over block
	var overlapping_objects = controller_grab.overlapping_objects()
	
	for obj in overlapping_objects:
		if not obj is BuildingBlockSnappable:
			continue
		
		# duplicate if it's a building block snappable
		var block_instance = building_block_base.instance()
		all_building_blocks.add_child(block_instance)
		# position
		block_instance.global_transform = obj.global_transform
		
		# grab
		controller_grab.start_grab_hinge_joint(block_instance)

extends Node


# takes care of the logic for the different typess of controllers
class_name ControllerSystem


signal controller_type_changed

var controller_type := 0
#var selected_controller
var all_controllers : Array
var move_mode := false
var initial_distance := 0.0
var scale_multiplier := 1.0
var initial_world_scale := 1.0
var world_scale_max := 3.0
var world_scale_min := 0.5
var right_contr_initial_y : float
var left_contr_initial_y : float

onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var left_controller = get_node(global_vars.CONTR_LEFT_PATH)
#onready var tablet = get_node(global_vars.TABLET_PATH)
onready var ar_vr_origin = get_node(global_vars.AR_VR_ORIGIN_PATH)
onready var button_click_sound = $AudioStreamPlayer3DClick


func _ready():
	if right_controller:
		right_controller.connect("button_pressed", self, "_on_right_ARVRController_button_pressed")
		all_controllers = right_controller.get_node("KSControllerRight/ControllerTypes").get_children()
		set_controller_type(controller_type)
	
	if left_controller:
		left_controller.connect("button_pressed", self, "_on_left_ARVRController_button_pressed")
#		tablet.visible = false


func _process(delta):
	if move_mode:
		process_move_mode()


func _on_right_ARVRController_button_pressed(button_number):
	# check for A button press
	if button_number == vr.CONTROLLER_BUTTON.XA:
		# play sound on press
		if button_click_sound:
			button_click_sound.play()
		roundrobin()
	
	# if grip trigger is pressed and it's also pressed on the left one
	if button_number == vr.CONTROLLER_BUTTON.GRIP_TRIGGER and vr.button_pressed(vr.BUTTON.LEFT_GRIP_TRIGGER):
		# enter move mode
		move_mode = true


func _on_left_ARVRController_button_pressed(button_number):
	# check for A button press
	if button_number == vr.CONTROLLER_BUTTON.XA:
		if button_click_sound:
			button_click_sound.play()
#		toggle_tablet()
	
	# if grip trigger is pressed and it's also pressed on the left one
	if button_number == vr.CONTROLLER_BUTTON.GRIP_TRIGGER and vr.button_pressed(vr.BUTTON.RIGHT_GRIP_TRIGGER):
		# enter move mode
		move_mode = true


func process_move_mode() -> void:
	# check if scale mode buttons still pressed
	if not vr.button_pressed(vr.BUTTON.LEFT_GRIP_TRIGGER) and not vr.button_pressed(vr.BUTTON.RIGHT_GRIP_TRIGGER):
		move_mode = false
		initial_distance = 0.0
		initial_world_scale = 1.0
#		right_contr_initial_y = right_controller.global_transform.origin.y
#		left_contr_initial_y = right_controller.global_transform.origin.y
		return
	
#	var right_contr_origin = right_controller.global_transform.origin
#	var left_contr_origin = left_controller.global_transform.origin
#	right_controller.global_transform.origin = Vector3(right_contr_origin.x, right_contr_initial_y, right_contr_origin.z)
#	left_controller.global_transform.origin = Vector3(left_contr_origin.x, left_contr_initial_y, left_contr_origin.z)
	
	# calculate initial distance between the controllers
	if initial_distance == 0.0:
		initial_world_scale = ar_vr_origin.get_world_scale()
		initial_distance = controller_distance()
	
	
	var dist_diff = controller_distance() - initial_distance
	# change world scale as controllers move
#	var new_world_scale = clamp(
#		initial_world_scale + dist_diff * scale_multiplier / ar_vr_origin.get_world_scale(),
#		world_scale_min,
#		world_scale_max)
#
	
#	right_controller.global_transform.scaled(Vector3.ONE * new_world_scale)
#	left_controller.global_transform.scaled(Vector3.ONE * new_world_scale)


func controller_distance() -> float:
	return right_controller.global_transform.origin.distance_to(left_controller.global_transform.origin)


# switches to the next controller type
func roundrobin() -> void:
	var new_ct = 0
	if controller_type + 1 < all_controllers.size():
		new_ct = controller_type + 1
	emit_signal("controller_type_changed")
	set_controller_type(new_ct)


func set_controller_type(new_ct : int) -> void:
	controller_type = new_ct
	# update mesh
	if all_controllers:
		# hide all
		for child in all_controllers:
			child.set_selected(false)
		# show the new one. this assumes meshes are in the same order as the enum ControllerType
		#selected_controller = right_controller_models.get_child(new_ct)
		all_controllers[new_ct].set_selected(true)


#func toggle_tablet():
#	tablet.visible = !tablet.visible

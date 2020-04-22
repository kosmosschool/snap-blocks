extends Node


# logic for moving
class_name MovementSystem


var move_mode := false
#var initial_distance := 0.0
#var right_contr_initial_y : float
#var left_contr_initial_y : float
#var right_contr_origin : Vector3
#var left_contr_origin : Vector3
var right_contr_origin_prev : Vector3
var left_contr_origin_prev : Vector3
var movement_init := false
var triggers_synced := false
var rot_vec_prev : Vector3
var rotate_around_name_prev : String


onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var left_controller = get_node(global_vars.CONTR_LEFT_PATH)
onready var ar_vr_origin = get_node(global_vars.AR_VR_ORIGIN_PATH)


func _ready():
	if right_controller:
		right_controller.connect("button_pressed", self, "_on_right_ARVRController_button_pressed")
	
	if left_controller:
		left_controller.connect("button_pressed", self, "_on_left_ARVRController_button_pressed")


func _process(delta):
	if move_mode:
		process_move_mode()


func _on_right_ARVRController_button_pressed(button_number):
	# if grip trigger is pressed and it's also pressed on the left one
	if button_number == vr.CONTROLLER_BUTTON.INDEX_TRIGGER and vr.button_pressed(vr.BUTTON.LEFT_INDEX_TRIGGER):
		# enter move mode
		move_mode = true


func _on_left_ARVRController_button_pressed(button_number):
	# if grip trigger is pressed and it's also pressed on the right one
	if button_number == vr.CONTROLLER_BUTTON.INDEX_TRIGGER and vr.button_pressed(vr.BUTTON.RIGHT_INDEX_TRIGGER):
		# enter move mode
		move_mode = true


func process_move_mode() -> void:
	# check if scale mode buttons still pressed
	if vr.button_pressed(vr.BUTTON.LEFT_INDEX_TRIGGER) and vr.button_pressed(vr.BUTTON.RIGHT_INDEX_TRIGGER):
		# little hack because the last pressed trigger isn't registred in the first frame this method starts
		triggers_synced = true
	
	
	if (triggers_synced and (
		not vr.button_pressed(vr.BUTTON.LEFT_INDEX_TRIGGER) or
		not vr.button_pressed(vr.BUTTON.RIGHT_INDEX_TRIGGER))):
		
		move_mode = false
		movement_init = false
		triggers_synced = false
		return
	
	var right_contr_origin = right_controller.transform.origin
	var left_contr_origin = left_controller.transform.origin
	
	if not movement_init:
		# else the translation delta will be off when we go out of movement mode and back again
		right_contr_origin_prev = right_contr_origin
		left_contr_origin_prev = left_contr_origin
	
	
	var diff_right = right_contr_origin - right_contr_origin_prev
	var diff_left =  left_contr_origin - left_contr_origin_prev
	
	# only translate by min of diff_right or diff_left
	var translate_by : Vector3
	var rotate_around : Vector3
	var rotate_by : Vector3
	var rotate_around_name
	if diff_right.length_squared() < diff_left.length_squared():
		translate_by = diff_right
		rotate_around = right_contr_origin
		rotate_by = left_contr_origin
		rotate_around_name = "right"
		
	else:
		translate_by = diff_left
		rotate_around = left_contr_origin
		rotate_by = right_contr_origin
		rotate_around_name = "left"
	
	var forward_vec = ar_vr_origin.transform.basis.z
	var global_forward = Vector3.FORWARD * -1
	var cross_trans = global_forward.cross(forward_vec)
	var dot_trans = forward_vec.dot(global_forward)
	var final_angle_translation = atan2(cross_trans.dot(Vector3(0, 1, 0)), dot_trans)
	
	translate_by = translate_by.rotated(Vector3(0, 1, 0), final_angle_translation)

	ar_vr_origin.transform.origin -= translate_by

	# get signed angle
	var rot_vec = (rotate_by - rotate_around).slide(Vector3(0, 1, 0))
	
	if not movement_init:
		# else the angle will be off when we go out of movement mode and back again
		rot_vec_prev = rot_vec
		movement_init = true
	
	if rotate_around_name_prev != rotate_around_name:
		# else the angle will be off when we switch rotating hand
		rot_vec_prev = rot_vec
	
	var cross = rot_vec_prev.cross(rot_vec)
	var dot = rot_vec.dot(rot_vec_prev)
	var final_angle = atan2(cross.dot(Vector3(0, 1, 0)), dot)
	
	ar_vr_origin.rotate_y(final_angle  * -1)
	
	
	right_contr_origin_prev = right_contr_origin
	left_contr_origin_prev = left_contr_origin
	rot_vec_prev = rot_vec
	rotate_around_name_prev = rotate_around_name
	

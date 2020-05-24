extends Node


# logic for movement
class_name MovementSystem


var prev_move_mode := false
var right_contr_origin_prev : Vector3
var left_contr_origin_prev : Vector3
var movement_init := false
var triggers_synced := false
var rot_vec_prev : Vector3
var rotate_around_name_prev : String
var movement_speed := 1.5
var ar_vr_origin_prev_origin : Vector3
var total_moved_distance := 0.0 setget , get_total_moved_distance

var rotation_parent
var rotation_remote_trans

onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var left_controller = get_node(global_vars.CONTR_LEFT_PATH)
onready var ar_vr_origin = get_node(global_vars.AR_VR_ORIGIN_PATH)


func get_total_moved_distance():
	return total_moved_distance


func _ready():
	# we'll use the RemoteTransform to rotate properly
	rotation_parent = Spatial.new()
	rotation_remote_trans = RemoteTransform.new()
	rotation_remote_trans.set_remote_node(ar_vr_origin.get_path())
	rotation_remote_trans.set_update_scale(false)
	
	var main_node = get_node("/root/Main")
	main_node.add_child(rotation_parent)
	rotation_parent.add_child(rotation_remote_trans)
	


func _process(delta):
	process_move_mode()


func process_move_mode() -> void:
	if vr.button_pressed(vr.BUTTON.LEFT_INDEX_TRIGGER) and vr.button_pressed(vr.BUTTON.RIGHT_INDEX_TRIGGER):
		var right_contr_origin = right_controller.transform.origin
		var left_contr_origin = left_controller.transform.origin
		
		if not prev_move_mode:
			right_contr_origin_prev = right_contr_origin
			left_contr_origin_prev = left_contr_origin
	
		var diff_right = right_contr_origin - right_contr_origin_prev
		var diff_left =  left_contr_origin - left_contr_origin_prev
	
		# only translate by min of diff_right or diff_left
		var translate_by : Vector3
		var rotate_around : Vector3
		var rotate_by : Vector3
		var rotate_around_name : String
		var rotate_around_global_orig : Vector3
		if diff_right.length_squared() < diff_left.length_squared():
			translate_by = diff_right
			rotate_around = right_contr_origin
			rotate_around_global_orig = right_controller.global_transform.origin
			rotate_by = left_contr_origin
			rotate_around_name = "right"
			
		else:
			translate_by = diff_left
			rotate_around = left_contr_origin
			rotate_around_global_orig = left_controller.global_transform.origin
			rotate_by = right_contr_origin
			rotate_around_name = "left"
		
		var forward_vec = ar_vr_origin.transform.basis.z
		var global_forward = Vector3.FORWARD * -1
		var cross_trans = global_forward.cross(forward_vec)
		var dot_trans = forward_vec.dot(global_forward)
		var final_angle_translation = atan2(cross_trans.dot(Vector3(0, 1, 0)), dot_trans)
		
		translate_by = translate_by.rotated(Vector3(0, 1, 0), final_angle_translation) * movement_speed
	
		ar_vr_origin.transform.origin -= translate_by

		# get signed angle
		var rot_vec = (rotate_by - rotate_around).slide(Vector3(0, 1, 0))
		
		if not prev_move_mode:
			rot_vec_prev = rot_vec
		
		if rotate_around_name_prev != rotate_around_name:
			# else the angle will be off when we switch rotating hand
			rot_vec_prev = rot_vec
		
		var cross = rot_vec_prev.cross(rot_vec)
		var dot = rot_vec.dot(rot_vec_prev)
		var final_angle = atan2(cross.dot(Vector3(0, 1, 0)), dot)
		
		rotation_parent.global_transform.origin = rotate_around_global_orig
		rotation_remote_trans.global_transform.origin = ar_vr_origin.global_transform.origin
		
		rotation_parent.rotate_y(final_angle  * -1)
		
		total_moved_distance += ar_vr_origin.transform.origin.distance_to(ar_vr_origin_prev_origin)
		
		ar_vr_origin_prev_origin = ar_vr_origin.transform.origin
		right_contr_origin_prev = right_contr_origin
		left_contr_origin_prev = left_contr_origin
		rot_vec_prev = rot_vec
		rotate_around_name_prev = rotate_around_name
		prev_move_mode = true
	else:
		prev_move_mode = false
	

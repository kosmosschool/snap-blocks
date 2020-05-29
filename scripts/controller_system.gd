extends Node


# takes care of the logic for the different typess of controllers
class_name ControllerSystem


signal controller_type_changed(controller_side)
signal joystick_x_axis_pushed_right(controller_side)
signal joystick_x_axis_pushed_left(controller_side)


var controller_types : Dictionary
#var selected_controller
var all_controllers : Dictionary
var move_mode := false
var initial_distance := 0.0
var right_contr_initial_y : float
var left_contr_initial_y : float
var prev_joystick_x_right := 0.0
var prev_joystick_x_left := 0.0

onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var left_controller = get_node(global_vars.CONTR_LEFT_PATH)
onready var tablet = get_node(global_vars.TABLET_PATH)
onready var ar_vr_origin = get_node(global_vars.AR_VR_ORIGIN_PATH)
onready var button_click_sound = $AudioStreamPlayer3DClick
onready var BUTTON_TO_ANIMATION = {
		vr.BUTTON.LEFT_INDEX_TRIGGER: "button_trigger",
		vr.BUTTON.LEFT_THUMBSTICK: "button_toggle",
		vr.BUTTON.X: "button_A",
		vr.BUTTON.ENTER: "button_home",
		vr.BUTTON.LEFT_GRIP_TRIGGER: "button_grab",
		vr.BUTTON.RIGHT_INDEX_TRIGGER: "button_trigger",
		vr.BUTTON.RIGHT_THUMBSTICK: "button_toggle",
		vr.BUTTON.A: "button_A",
#		vr.BUTTON.ENTER: "button_home", oculus button has blink animation, but no use now
		vr.BUTTON.RIGHT_GRIP_TRIGGER: "button_grab",
	}


func _ready():
	controller_types = {
		"right": 0,
		"left": 0
	}
	
	if right_controller:
		right_controller.connect("button_pressed", self, "_on_right_ARVRController_button_pressed")
		all_controllers["right"] = right_controller.get_node("KSControllerRight/ControllerTypes").get_children()
		set_controller_type(0, "right")
	
	if left_controller:
		left_controller.connect("button_pressed", self, "_on_left_ARVRController_button_pressed")
		all_controllers["left"] = left_controller.get_node("KSControllerLeft/ControllerTypes").get_children()
		set_controller_type(0, "left")
		tablet.visible = false


func _process(delta):
	update_joystick_x_axis()


func _on_right_ARVRController_button_pressed(button_number):
	# check for A button press
	if button_number == vr.CONTROLLER_BUTTON.XA:
		# play sound on press
		if button_click_sound and sound_settings.get_contr_button_sound():
			button_click_sound.global_transform.origin = right_controller.global_transform.origin
			button_click_sound.play()
		roundrobin("right")


func _on_left_ARVRController_button_pressed(button_number):
	# check for A button press
	if button_number == vr.CONTROLLER_BUTTON.XA:
		# play sound on press
		if button_click_sound and sound_settings.get_contr_button_sound():
			button_click_sound.global_transform.origin = left_controller.global_transform.origin
			button_click_sound.play()
		roundrobin("left")
	
	if button_number == vr.CONTROLLER_BUTTON.YB:
		if button_click_sound and sound_settings.get_contr_button_sound():
			button_click_sound.global_transform.origin = left_controller.global_transform.origin
			button_click_sound.play()
		toggle_tablet()


func get_controller_type(side : String):
	if not controller_types.has(side):
		return null
	
	return controller_types[side] 


func controller_distance() -> float:
	return right_controller.global_transform.origin.distance_to(left_controller.global_transform.origin)


# switches to the next controller type
func roundrobin(side : String) -> void:
	var new_ct = 0
	if controller_types[side] + 1 < all_controllers[side].size():
		new_ct = controller_types[side] + 1
	emit_signal("controller_type_changed", side)
	set_controller_type(new_ct, side)


func set_controller_type(new_ct : int, side : String) -> void:
	controller_types[side] = new_ct
	# update mesh
	if all_controllers.has(side):
		# hide all
		for child in all_controllers[side]:
			child.set_selected(false)
			
		all_controllers[side][new_ct].set_selected(true)


func toggle_tablet():
	tablet.visible = !tablet.visible


func update_joystick_x_axis() -> void:
	var joystick_x_right = vr.get_controller_axis(vr.AXIS.RIGHT_JOYSTICK_X)
	var joystick_x_left = vr.get_controller_axis(vr.AXIS.LEFT_JOYSTICK_X)
	# only switch if joystick x went smaller than 0.5 previously
	if abs(prev_joystick_x_right) < 0.5:
		if joystick_x_right > 0.5:
			emit_signal("joystick_x_axis_pushed_right", "right")
		
		if joystick_x_right < -0.5:
			emit_signal("joystick_x_axis_pushed_left", "right")
	
	if abs(prev_joystick_x_left) < 0.5:
		if joystick_x_left > 0.5:
			emit_signal("joystick_x_axis_pushed_right", "left")
		
		if joystick_x_left < -0.5:
			emit_signal("joystick_x_axis_pushed_left", "left")
	
	prev_joystick_x_right = joystick_x_right
	prev_joystick_x_left = joystick_x_left


func button_blink(button : int, state : bool):
	# make a specific button blink or stop blinking on active controller
	var side: String
	
	if button > 15:
		side = "right"
	else:
		side = "left"

	var type_index = controller_types[side]
	var animation_player = all_controllers[side][type_index].get_node("AnimationPlayer")
	
	if state:
		animation_player.play(BUTTON_TO_ANIMATION[button])
	else:
		animation_player.stop(true)


func stop_all_button_blink() -> void:
	# stops all button blink animations animations
	for c in all_controllers["right"]:
		var curr_anim = c.get_node("AnimationPlayer")
		if curr_anim:
			curr_anim.stop()
	
	for c in all_controllers["left"]:
		var curr_anim = c.get_node("AnimationPlayer")
		if curr_anim:
			curr_anim.stop()

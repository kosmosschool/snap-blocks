extends Spatial


# logic for tutorial in the beginning of Snap Blocks
class_name TutorialController


var STEP_1_TEXT = "Welcome to Snap Blocks!\n\nLet's quickly go through the basics. Press the index trigger to start."
var STEP_2_TEXT = "Press and hold the grip trigger to create a Block."
var STEP_3_TEXT = "Good, now bring it close to the Block in front of you to snap it."
var STEP_4_TEXT = "That's why it's called Snap Blocks :-) Do one more!"
var STEP_5_TEXT = "Awesome! You can change the color of the Block by pushing your joystick to the left or right. Try it."
var STEP_6_TEXT = "Perfect. Now create a new Block and snap it to the others."
var STEP_7_TEXT = "Great! You can also change the color of a Block that's already snapped. Press A to change to the re-coloring tool."
var STEP_8_TEXT = "Good. Now touch a Block with the tip of your tool and press the index trigger to change its color."
var STEP_9_TEXT = "Good job! You can also delete Blocks. Press A again to change to the deletion tool."
var STEP_10_TEXT = "To delete a Block, touch it with the tip of your tool and press the index trigger."
var STEP_11_TEXT = "Cool. Press and hold the right and left index triggers to move around and rotate."
var STEP_12_TEXT = "Great, great! Press Y to open your tablet."
var STEP_13_TEXT = "You can load premade Creations from the Gallery. Give it a try."
var STEP_14_TEXT = "Yay! You can look around, keep working on it or even save it as your own. Press the Files menu button."
var STEP_15_TEXT = "Here you can save and load your Creations.\nNow, it's time to build. Have fun!\n\nPress Y to end the tutorial."

var all_step_texts : Array

var current_step = 0
var total_steps : int
var step_finish_button := -1
var current_tooltip_instance
var waiting_for_area_added := false
var waiting_for_joystick_push := false
var waiting_for_recolor := false
var waiting_for_deletion := false
var waiting_for_distance_moved := false
var finish_after_step := true
var distance_delta : float
var text_fade_in_counter := 0.0
var text_fade_in_duration := 1.0
var text_fade_in := false
var tooltip_text_label : Node
var initial_text_color : Color
var transparent_color := Color(0.7, 0.4, 0.4, 1.0)
var tutorial_finished := false
var finish_tutorial_duration := 3.0
var finish_tutorial_counter := 0.0
var waiting_for_screen_change_name : String
var waiting_for_file_load := false


onready var tooltip_scene = preload("res://scenes/tooltip.tscn")
onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var left_controller = get_node(global_vars.CONTR_LEFT_PATH)
onready var block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)
onready var controller_system = get_node(global_vars.CONTROLLER_SYSTEM_PATH)
onready var tablet = get_node(global_vars.TABLET_PATH)
onready var screens_controller = tablet.get_node("Screens")
onready var audio_player = $AudioStreamPlayer3D
onready var audio_player_finish = $AudioStreamPlayerFinish


func _ready():
	sound_settings.set_block_snap_sound(false)
	sound_settings.set_contr_button_sound(false)
	all_step_texts = [
		STEP_1_TEXT, STEP_2_TEXT, STEP_3_TEXT, STEP_4_TEXT, STEP_5_TEXT, STEP_6_TEXT,
		STEP_7_TEXT, STEP_8_TEXT, STEP_9_TEXT, STEP_10_TEXT, STEP_11_TEXT, STEP_12_TEXT,
		STEP_13_TEXT, STEP_14_TEXT, STEP_15_TEXT
	]
	
	total_steps = all_step_texts.size()
	
	right_controller.connect("button_pressed", self, "_on_right_ARVRController_button_pressed")
	left_controller.connect("button_pressed", self, "_on_left_ARVRController_button_pressed")
	
	block_chunks_controller.connect("area_added", self, "_on_Block_Chunks_Controller_area_added")
	block_chunks_controller.connect("area_recolored", self, "_on_Block_Chunks_Controller_area_recolored")
	block_chunks_controller.connect("area_deleted", self, "_on_Block_Chunks_Controller_area_deleted")
	
	controller_system.connect("joystick_x_axis_pushed_right", self, "_on_Controller_System_joystick_x_axis_pushed_right")
	controller_system.connect("joystick_x_axis_pushed_left", self, "_on_Controller_System_joystick_x_axis_pushed_left")
	
	screens_controller.connect("screen_changed", self, "_on_Screens_Controller_screen_changed")
	
	save_system.connect("file_loaded", self, "_on_Save_System_file_loaded")
	
	current_tooltip_instance = create_tooltip_instance()
	tooltip_text_label = current_tooltip_instance.get_node("Bubble/2DTextLabel")
	initial_text_color = tooltip_text_label.get_font_color()
	
	next_step()


func _process(delta):
	if waiting_for_distance_moved:
		if movement_system.get_total_moved_distance() > distance_delta:
			waiting_for_distance_moved = false
			next_step()
	
	# fade in text
	if text_fade_in:
		text_fade_in_counter += delta
		var new_color = transparent_color.linear_interpolate(
			initial_text_color,
			text_fade_in_counter / text_fade_in_duration
		)
		tooltip_text_label.set_font_color(new_color)
		if text_fade_in_counter > text_fade_in_duration:
			text_fade_in_counter = 0.0
			text_fade_in = false
			tooltip_text_label.set_font_color(initial_text_color)
	
	if tutorial_finished:
		finish_tutorial_counter += delta
		if finish_tutorial_counter > finish_tutorial_duration:
			tutorial_finished = false
			finish_tutorial_counter = 0.0
			queue_free()


func _on_right_ARVRController_button_pressed(button_number):
	# need to add 16 because we're using the button numbers mapped over both controllers
	# see vr_autoload.gd
	if button_number + 16 == step_finish_button:
		step_finish_button = -1
		next_step()


func _on_left_ARVRController_button_pressed(button_number):
	if button_number == step_finish_button:
		step_finish_button = -1
		next_step()


func _on_Block_Chunks_Controller_area_added():
	if waiting_for_area_added:
		waiting_for_area_added = false
		next_step()


func _on_Controller_System_joystick_x_axis_pushed_right(_side):
	if waiting_for_joystick_push:
		waiting_for_joystick_push = false
		next_step()


func _on_Controller_System_joystick_x_axis_pushed_left(_side):
	if waiting_for_joystick_push:
		waiting_for_joystick_push = false
		next_step()


func _on_Block_Chunks_Controller_area_recolored():
	if waiting_for_recolor:
		waiting_for_recolor = false
		next_step()


func _on_Block_Chunks_Controller_area_deleted():
	if waiting_for_deletion:
		waiting_for_deletion = false
		next_step()


func _on_Screens_Controller_screen_changed(screen_name):
	if waiting_for_screen_change_name == "LoadScreen":
		waiting_for_screen_change_name = ""
		next_step()


func _on_Save_System_file_loaded():
	if waiting_for_file_load:
		waiting_for_file_load = false
		next_step()


func run_current_step():
	change_tooltip_text()
	
	match current_step:
		1:
			controller_system.button_blink(vr.BUTTON.RIGHT_INDEX_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0, -0.02, -0.03))
			step_finish_button = vr.BUTTON.RIGHT_INDEX_TRIGGER
		2:
			controller_system.button_blink(vr.BUTTON.RIGHT_GRIP_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.025, 0.03))
			step_finish_button = vr.BUTTON.RIGHT_GRIP_TRIGGER
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		3:
			controller_system.button_blink(vr.BUTTON.RIGHT_GRIP_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_area_added = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		4:
			controller_system.button_blink(vr.BUTTON.RIGHT_GRIP_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_area_added = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		5:
			controller_system.button_blink(vr.BUTTON.RIGHT_THUMBSTICK, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0.019, 0.006, -0.014))
			step_finish_button = -1
			waiting_for_joystick_push = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		6:
			controller_system.button_blink(vr.BUTTON.RIGHT_GRIP_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_area_added = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		7:
			controller_system.button_blink(vr.BUTTON.A, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0.001, -0.002, 0.002))
			step_finish_button = vr.BUTTON.A
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		8:
			controller_system.button_blink(vr.BUTTON.RIGHT_INDEX_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0, -0.02, -0.03))
			waiting_for_recolor = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		9:
			controller_system.button_blink(vr.BUTTON.A, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0.001, -0.002, 0.002))
			step_finish_button = vr.BUTTON.A
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		10:
			controller_system.button_blink(vr.BUTTON.RIGHT_INDEX_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0, -0.02, -0.03))
			waiting_for_deletion = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		11:
			controller_system.button_blink(vr.BUTTON.RIGHT_INDEX_TRIGGER, true)
			controller_system.button_blink(vr.BUTTON.LEFT_INDEX_TRIGGER, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0, -0.02, -0.03))
			current_tooltip_instance.set_secondary_attach_to_path(global_vars.CONTR_LEFT_PATH)
			current_tooltip_instance.set_secondary_line_attach_to_offset(Vector3(0, -0.02, -0.03))
			current_tooltip_instance.set_secondary_line(true)
			waiting_for_distance_moved = true
			distance_delta = movement_system.get_total_moved_distance() + 0.5
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
			global_functions.vibrate_controller_timed(0.3, left_controller, 0.3)
			# set controller back to default controller
			controller_system.set_controller_type(0, "right")
		12:
			controller_system.button_blink(vr.BUTTON.RIGHT_INDEX_TRIGGER, false)
			controller_system.button_blink(vr.BUTTON.Y, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_LEFT_PATH)
			current_tooltip_instance.set_bubble_offset(Vector3(0.17, 0.12, -0.03))
			current_tooltip_instance.set_line_bubble_offset(Vector3(-0.065, -0.065, 0))
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0.003, -0.001, -0.014))
			current_tooltip_instance.set_secondary_line(false)
			step_finish_button = vr.BUTTON.Y
			global_functions.vibrate_controller_timed(0.3, left_controller, 0.3)
		13:
			controller_system.button_blink(vr.BUTTON.Y, false)
			current_tooltip_instance.set_attach_to_path(global_vars.TABLET_PATH)
			current_tooltip_instance.set_bubble_offset(Vector3(0.3, 0.18, -0.02))
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.105, 0.03, 0.003))
			# load gallery view
			screens_controller.change_screen("GalleryScreen")
			waiting_for_file_load = true
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		14:
			current_tooltip_instance.set_attach_to_path(global_vars.TABLET_PATH)
			current_tooltip_instance.set_bubble_offset(Vector3(0.3, 0.18, -0.02))
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0.14, 0.081, 0.003))
			waiting_for_screen_change_name = "LoadScreen"
			global_functions.vibrate_controller_timed(0.3, right_controller, 0.3)
		15:
			controller_system.button_blink(vr.BUTTON.Y, true)
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_LEFT_PATH)
			current_tooltip_instance.set_bubble_offset(Vector3(0.3, 0.15, -0.02))
			current_tooltip_instance.set_line_bubble_offset(Vector3(-0.065, -0.065, 0))
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0.003, -0.001, -0.014))
			step_finish_button = vr.BUTTON.Y
			global_functions.vibrate_controller_timed(0.3, left_controller, 0.3)


func next_step():
	controller_system.stop_all_button_blink()
	if current_step != total_steps:
		# go to next step
		current_step += 1
		run_current_step()
		if current_tooltip_instance:
			audio_player.global_transform.origin = current_tooltip_instance.global_transform.origin
		
		if current_step != 1:
			audio_player.play()
			current_tooltip_instance.play_animation_close_open()
	else:
		finish_tutorial()


func change_tooltip_text():
	current_tooltip_instance.set_text(all_step_texts[current_step - 1])
	tooltip_text_label.set_font_color(transparent_color)
	text_fade_in = true


func create_tooltip_instance():
	var tool_tip_instance = tooltip_scene.instance()
	add_child(tool_tip_instance)
	return tool_tip_instance


# warning-ignore:function_conflicts_variable
func finish_tutorial():
	tutorial_finished = true
	sound_settings.set_block_snap_sound(true)
	sound_settings.set_contr_button_sound(true)
	save_system.user_prefs_save("seen_tutorial", true)
	audio_player_finish.play()
	current_tooltip_instance.play_animation_close()

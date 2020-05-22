extends Spatial


# logic for tutorial in the beginning of Snap Blocks
class_name TutorialController


var STEP_1_TEXT = "Welcome to Snap Blocks! Let's quickly go through the basics. Press index trigger to start."
var STEP_2_TEXT = "Press and hold grip trigger to create a Block."
var STEP_3_TEXT = "Good, now drop it on the floor. Create a second Block and bring it close to the first one to snap it."
var STEP_4_TEXT = "That's why it's called Snap Blocks :-) Do one more!"
var STEP_5_TEXT = "Awesome! You can change the color of the Block by pressing your joystick to the left or right. Try it."
var STEP_6_TEXT = "Perfect. Now create a new Block and snap it to the others."
var STEP_7_TEXT = "Great! You can also change the color of a Block that's already snapped. Press A to change to the re-coloring tool."
var STEP_8_TEXT = "Good. Now touch a Block with the tip of your tool and press index trigger to change its color."
var STEP_9_TEXT = "Good job! You can also delete Blocks. Press A again to change to the delete tool."
var STEP_10_TEXT = "To delete a Block, touch it with the tip of your tool and press the index trigger."
var STEP_11_TEXT = "Cool. Press and hold right and left index triggers to move around and rotate"
var STEP_12_TEXT = "Great, great! One last thing. Press X to open your tablet."
var STEP_13_TEXT = "Here you can save and load your Creations. That's it! We wish you a lot of fun with Snap Blocks!"

var all_step_texts : Array

var current_step = 0
var total_steps : int
var step_finish_button := -1
var current_tooltip_instance
var waiting_for_area_added := false
var waiting_for_joystick_push := false

onready var tooltip_scene = preload("res://scenes/tooltip.tscn")
onready var right_controller = get_node(global_vars.CONTR_RIGHT_PATH)
onready var left_controller = get_node(global_vars.CONTR_LEFT_PATH)
onready var all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH)
onready var controller_system = get_node(global_vars.CONTROLLER_SYSTEM_PATH)


func _ready():
	all_step_texts = [
		STEP_1_TEXT, STEP_2_TEXT, STEP_3_TEXT, STEP_4_TEXT, STEP_5_TEXT, STEP_6_TEXT,
		STEP_7_TEXT, STEP_8_TEXT, STEP_9_TEXT, STEP_10_TEXT, STEP_11_TEXT, STEP_12_TEXT,
		STEP_13_TEXT
	]
	
	total_steps = all_step_texts.size()
	
	right_controller.connect("button_pressed", self, "_on_right_ARVRController_button_pressed")
	left_controller.connect("button_pressed", self, "_on_left_ARVRController_button_pressed")
	
	all_block_areas.connect("area_added", self, "_on_All_Block_Areas_area_added")
	
	controller_system.connect("joystick_x_axis_pushed_right", self, "_on_Controller_System_joystick_x_axis_pushed_right")
	controller_system.connect("joystick_x_axis_pushed_left", self, "_on_Controller_System_joystick_x_axis_pushed_left")
	
	current_tooltip_instance = create_tooltip_instance()
	
	next_step()


func _process(delta):
	vr.get_controller_axis(vr.AXIS.RIGHT_JOYSTICK_X)


func _on_right_ARVRController_button_pressed(button_number):
	# need to add 16 because we're using the button numbers mapped over both controllers
	# see vr_autoload.gd
	if button_number + 16 == step_finish_button:
		next_step()


func _on_left_ARVRController_button_pressed(button_number):
	if button_number == step_finish_button:
		next_step()


func _on_All_Block_Areas_area_added():
	if waiting_for_area_added:
		waiting_for_area_added = false
		next_step()


func _on_Controller_System_joystick_x_axis_pushed_right():
	if waiting_for_joystick_push:
		waiting_for_joystick_push = false
		next_step()


func _on_Controller_System_joystick_x_axis_pushed_left():
	if waiting_for_joystick_push:
		waiting_for_joystick_push = false
		next_step()


func run_current_step():
	current_tooltip_instance.set_text(all_step_texts[current_step - 1])
	
	match current_step:
		1:
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(0, -0.02, -0.03))
			current_tooltip_instance.set_secondary_line(true)
			step_finish_button = vr.BUTTON.RIGHT_INDEX_TRIGGER
		2:
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			current_tooltip_instance.set_secondary_line(false)
			step_finish_button = vr.BUTTON.RIGHT_GRIP_TRIGGER
		3:
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_area_added = true
		4:
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_area_added = true
		5:
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_joystick_push = true
		6:
			current_tooltip_instance.set_attach_to_path(global_vars.CONTR_RIGHT_PATH)
			current_tooltip_instance.set_line_attach_to_offset(Vector3(-0.01, -0.02, 0.03))
			step_finish_button = -1
			waiting_for_area_added = true


func next_step():
	# delete old tooltip
#	if current_tooltip_instance:
#		current_tooltip_instance.queue_free()
	
	if current_step != total_steps:
		# go to next step
		current_step += 1
		run_current_step()
	else:
		# end tutorial
		pass


func create_tooltip_instance():
	var tool_tip_instance = tooltip_scene.instance()
	add_child(tool_tip_instance)
	return tool_tip_instance

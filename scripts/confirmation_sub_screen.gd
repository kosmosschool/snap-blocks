extends Spatial


class_name ConfirmationSubScreen


var count_down = false
var counter = 0.0
var fade_out_time = 2.0

onready var screens_controller = get_node(global_vars.ALL_SCREENS_PATH)


func _ready():
	connect("visibility_changed", self, "_on_Confirmation_Sub_Screen_visibility_changed")


func _process(delta):
	if count_down:
		# change back to load screen after fade_out_time is up
		counter += delta
		
		if counter > fade_out_time:
			counter = 0.0
			count_down = false
			visible = false
			var load_screen = screens_controller.get_node("LoadScreen")
			# update images on the buttons
			load_screen.display_load_buttons()
			screens_controller.change_screen("LoadScreen")


func _on_Confirmation_Sub_Screen_visibility_changed():
	if !is_visible_in_tree():
		set_process(false)
	else:
		count_down = true
		set_process(true)

extends Spatial


# takes care of logic for screens on tablet
class_name ScreensController


signal screen_changed(screen_name)

export var initial_screen : String

onready var all_screens = get_children()
onready var initial_screen_node = find_node(initial_screen)
onready var current_screen_name = initial_screen
onready var current_screen_node = initial_screen_node


func _ready():
	# only make initial screen visible to start
	if initial_screen:
		for screen in all_screens:
			screen.visible = false
		
		initial_screen_node.visible = true


func change_screen(new_screen_name : String):
		
	var new_screen_node = find_node(new_screen_name)
	if new_screen_node and current_screen_node:
		# hide old screen
		current_screen_node.visible = false
		
		# update current screen
		current_screen_name = new_screen_name
		current_screen_node = new_screen_node
		
		# show new screen
		current_screen_node.visible = true
		
		emit_signal("screen_changed", current_screen_name)


func show_keyboard(callback_func : Reference, args : Dictionary, label : String, placeholder : String):
	var keyboard_screen = $KeyboardScreen
	
	if not keyboard_screen:
		return
	
	keyboard_screen.set_enter_callback(callback_func, args)
	keyboard_screen.set_label(label)
	keyboard_screen.set_placeholder(placeholder)
	
	change_screen("KeyboardScreen")
	

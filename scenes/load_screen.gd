extends Spatial


class_name LoadScreen

var first_button_origin = Vector3(-0.12, 0.04, 0.003)
var offset_x = 0.05
var offset_y = 0.05

onready var file_button_scene = preload("res://scenes/ks_button_pressable.tscn")
onready var button_load_script = preload("res://scripts/button_load.gd")


func _ready():
	connect("visibility_changed", self, "_on_Load_Screen_visibility_changed")
	refresh_files()


func _on_Load_Screen_visibility_changed():
	if visible:
		refresh_files()


func refresh_files():
	# destroy old buttons
	var old_buttons = get_children()
	for o in old_buttons:
		o.queue_free()
	
	var all_files = save_system.get_all_saved_files()
	
	for i in range(all_files.size()):
		var file_button = file_button_scene.instance()
		file_button.set_script(button_load_script)
		add_child(file_button)
		file_button.set_file_name(all_files[i])
		var new_origin = first_button_origin + Vector3(i * offset_x, 0, 0)
		file_button.set_local_origin(new_origin)
		
		

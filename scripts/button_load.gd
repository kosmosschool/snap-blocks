extends KSButtonPressable


# button used to load creation
class_name ButtonLoad


var file_name : String setget set_file_name

onready var mesh_instance = $MeshInstance
onready var load_screen = get_parent().get_parent()
onready var delete_mat_0 = preload("res://materials/red_primary.tres")
onready var delete_mat_1 = preload("res://materials/red_secondary.tres")


func _ready():
	load_screen.connect("delete_mode_selected", self, "_on_Load_Screen_delete_mode_selected")
	load_screen.connect("load_mode_selected", self, "_on_Load_Screen_load_mode_selected")


func _on_Load_Screen_delete_mode_selected():
	mesh_instance.set_surface_material(0, delete_mat_0)
	mesh_instance.set_surface_material(1, delete_mat_1)


func _on_Load_Screen_load_mode_selected():
	mesh_instance.set_surface_material(0, default_mat_0)
	mesh_instance.set_surface_material(1, default_mat_1)


func set_file_name(new_value):
	file_name = new_value


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	if !load_screen.get_delete_mode():
		save_system.load_creation(file_name)
	else:
		save_system.delete_creation(file_name)
		load_screen.refresh_files()
		load_screen.toggle_delete_mode()

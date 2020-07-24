extends Node


# does stuff in the beginning
class_name WelcomeController

#var floor_init_origin = Vector3(0, 0, 0)
#var floor_init_basis = Basis()
var starting_cube_set := false
var starting_cube_timer := 0.0

onready var tutorial_scene = preload("res://scenes/tutorial_controller.tscn")
onready var block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)
onready var camera = get_node(global_vars.AR_VR_CAMERA_PATH)


func _ready():
	if save_system.user_prefs_get("seen_tutorial") != true:
		show_tutorial()
	
#	show_tutorial()


func _process(delta):
	if not starting_cube_set:
		# create starting cube after a certain time to make sure it's aligned with the user height
		if starting_cube_timer > 0.3:
			create_starting_cube()
			starting_cube_set = true
			starting_cube_timer = 0.0
			return
		
		starting_cube_timer += delta


func show_tutorial() -> void:
	var tutorial_instance = tutorial_scene.instance()
	get_node("/root/Main/Game").call_deferred("add_child", tutorial_instance)


func create_starting_cube() -> void:
	# reset all block chunks
	block_chunks_controller.reset()
	
	var y_value = 1.0
	if camera:
		if not is_nan(camera.transform.basis.x.x):
			y_value = camera.global_transform.origin.y - 0.2
			
	var starting_trans = Transform(Basis(), Vector3(0, y_value, -0.5))
	
	block_chunks_controller.add_block(starting_trans, "olive", false, true)


#func create_floor() -> void:
#	# creat initial floor out of cubes
#	var initial_trans = Transform(floor_init_basis, floor_init_origin)
#	var total_blocks = 100
#	var n_blocks_per_row = 10
#
#	for i in range(total_blocks):
#		var row = floor(i / n_blocks_per_row)
#		var col = i - (row * n_blocks_per_row)
#		var new_trans = Transform()
#		new_trans.origin = (initial_trans.origin +
#			col * 0.1 * initial_trans.basis.x -
#			row * 0.1 * initial_trans.basis.z
#		)
#		all_block_areas.add_block_area(new_trans, "olive", false)
#
#	multi_mesh.recreate()

extends Spatial


# logic for collection of all block areas of blocks added to MultiMesh
class_name AllBlockAreas


onready var block_area_script = load(global_vars.BLOCK_AREA_SCRIPT_PATH)
onready var cube_col_shape = load(global_vars.CUBE_COLLISION_SHAPE_PATH)
onready var controller_colors = get_node(global_vars.CONTROLLER_COLORS_PATH)
onready var audio_stream_player_snap := get_node("../AudioStreamPlayer3DSnap")


func add_block_area(
	cube_transform : Transform,
	block_material : Material,
	block_material_secondary : Material,
	play_sound : bool = true) -> Area:
	
	# create area
	var new_area = Area.new()
	add_child(new_area)
	new_area.global_transform = cube_transform
	# create CollisionShape
	
	var col_shape_node = CollisionShape.new()
	col_shape_node.set_shape(cube_col_shape)
	new_area.add_child(col_shape_node)
	new_area.monitoring = false
	new_area.set_script(block_area_script)
	new_area.set_collision_layer(2)
	new_area.collision_shape = col_shape_node
	new_area.set_block_material(block_material)
	new_area.set_block_material_secondary(block_material_secondary)

	
	if play_sound:
		play_snap_sound(new_area.global_transform.origin)
	
	return new_area


func play_snap_sound(new_pos : Vector3):
	if audio_stream_player_snap:
		audio_stream_player_snap.global_transform.origin = new_pos
		audio_stream_player_snap.play()


func recreate_from_save(saved_array : Array) -> void:
	# recreates all blocks from saved file
	
	# clear all areas
	var all_children = get_children()
	for c in all_children:
		c.queue_free()
	
	# recreate from saved
	for s in saved_array:
		var curr_mats = controller_colors.get_materials_by_name(s["material_name"])
		add_block_area(
			unserialize_transform(s["global_transform_serialized"]),
			curr_mats[0],
			curr_mats[1],
			false
		)


func unserialize_transform(transform_array : Array):
	if transform_array.size() != 12:
		print("unserialize_transform error: transform_array doesn't have 12 elements")
		return null


	var return_transform = Transform(
		Vector3(transform_array[0], transform_array[1], transform_array[2]),
		Vector3(transform_array[3], transform_array[4], transform_array[5]),
		Vector3(transform_array[6], transform_array[7], transform_array[8]),
		Vector3(transform_array[9], transform_array[10], transform_array[11])
	)

	return return_transform


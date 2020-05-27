extends Spatial


# logic for collection of all block areas of blocks added to MultiMesh
class_name AllBlockAreas


signal area_added

var all_origins : Array

onready var block_area_script = load(global_vars.BLOCK_AREA_SCRIPT_PATH)
onready var cube_col_shape = load(global_vars.CUBE_COLLISION_SHAPE_PATH)
onready var audio_stream_player_snap := get_node("../AudioStreamPlayer3DSnap")


func add_block_area(
	cube_transform : Transform,
	color_name : String,
	play_sound : bool = true) -> Area:
	
	# create area
	var new_area = Area.new()
	add_child(new_area)
	new_area.global_transform = cube_transform
	
	# create CollisionShape
	var col_shape_node = CollisionShape.new()
	col_shape_node.set_shape(cube_col_shape)
	col_shape_node.set_name("CollisionShape")
	new_area.add_child(col_shape_node)
	new_area.monitoring = false
	new_area.set_script(block_area_script)
	new_area.set_collision_layer(2)
	new_area.collision_shape = col_shape_node
	new_area.set_color_name(color_name)
	
	all_origins.append(round_origin(new_area.global_transform.origin))
	
	
	if play_sound:
		play_snap_sound(new_area.global_transform.origin)
	
	
#	print("total blocks: ", get_child_count())
	if get_child_count() != 1:
		emit_signal("area_added")
	
	return new_area


func play_snap_sound(new_pos : Vector3):
	print("sound_settings.get_block_snap_sound() ", sound_settings.get_block_snap_sound())
	if audio_stream_player_snap and sound_settings.get_block_snap_sound():
		audio_stream_player_snap.global_transform.origin = new_pos
		audio_stream_player_snap.play()


func clear() -> void:
	# clear all areas
	var all_children = get_children()
	for c in all_children:
		c.queue_free()
	
	all_origins.clear()


func recreate_from_save(saved_array : Array) -> Array:
	# recreates all blocks from saved file
	
	var added_areas : Array
	clear()
	
	# recreate from saved
	for s in saved_array:
		var added_area = add_block_area(
			unserialize_transform(s["global_transform_serialized"]),
			s["color_name"],
			false
		)
		added_areas.append(added_area)
	
	return added_areas


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


func remove_origin(block_orig : Vector3) -> void:
	all_origins.erase(round_origin(block_orig))


# called by ks_multi_mesh
func block_exists(block_orig : Vector3) -> bool:
	return all_origins.has(round_origin(block_orig))


func round_origin(vec : Vector3) -> Vector3:
	# rounds so that we can compare origins better
	var rs = 0.01
	return Vector3(stepify(vec.x, rs), stepify(vec.y, rs), stepify(vec.z, rs))

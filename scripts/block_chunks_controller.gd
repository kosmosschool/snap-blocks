extends Spatial


# overall logic forall BlockChunks
class_name BlockChunksController


signal area_added
signal area_loading_finished
signal area_chunk_loaded
signal area_recolored
signal area_deleted

var all_origins : Array
var loaded_areas: Array
var process_load_queue := false
var queue_counter := 0
var saved_array_queue : Array
var q_blocks_per_frame := 100
var current_chunk : BlockChunk

onready var block_chunk_scene = load(global_vars.BLOCK_CHUNK_SCENE_PATH)
onready var cube_col_shape = load(global_vars.CUBE_COLLISION_SHAPE_PATH)
onready var audio_stream_player_snap := get_node("../AudioStreamPlayer3DSnap")



func _process(delta):
	if process_load_queue:
		# recreate from saved
		var array_size = saved_array_queue.size()
		loaded_areas.clear()
		for i in range(array_size):
			if i == q_blocks_per_frame or queue_counter == 0:
				current_chunk.create_multi_mesh(loaded_areas, false)
				break
			
			var y = array_size - queue_counter
			
			var added_area = add_block(
				unserialize_transform(saved_array_queue[y]["global_transform_serialized"]),
				saved_array_queue[y]["color_name"],
				false
			)
			
			loaded_areas.append(added_area)
			queue_counter -= 1
		
		if queue_counter == 0:
			game_settings.set_interaction_enabled(true)
			process_load_queue = false
			current_chunk.create_multi_mesh()


#func get_chunk(index : int):
#	# the problem with this method is that we don't check if instance is valid
#	# we just use get_current_chunk() for now
#	var all_block_chunks = get_children()
#	if all_block_chunks.size() > index:
#		return all_block_chunks[index]
#
#	return null


func get_current_chunk():
	return current_chunk
#	var all_block_chunks = get_children()
#
#	for b in all_block_chunks:
#		if is_instance_valid(b):
#			return b


func add_block(
	cube_transform : Transform,
	color_name : String,
	play_sound : bool = true,
	update_multi_mesh = false):

	# right now we just work with one chunk
	# later on we might add logic for more chunks to improve performance
	var chunk = get_current_chunk()
	
	if not chunk:
		return null
	
	var new_area = chunk.add_block(cube_transform, color_name, update_multi_mesh)
	
	if not new_area:
		return null
	
	if play_sound:
		play_snap_sound(new_area.global_transform.origin)
	
	if chunk.block_count() != 1:
		# we need this in the tutorial
		emit_signal("area_added")
	
	return new_area


func play_snap_sound(new_pos : Vector3):
	if audio_stream_player_snap and sound_settings.get_block_snap_sound():
		audio_stream_player_snap.global_transform.origin = new_pos
		audio_stream_player_snap.play()


func create_chunk():
	# adds a BlockChunk
	var block_chunk = block_chunk_scene.instance()
	add_child(block_chunk)
	current_chunk = block_chunk


func reset():
	clear_all()
	create_chunk()


func clear_all() -> void:
	# clear all BlockChunks
	var all_children = get_children()
	for c in all_children:
		c.queue_free()


func clear_chunk(chunk_index : int) -> void:
	# clear blocks in a specific chunk
	var chunk = get_current_chunk()
	if chunk:
		chunk.clear()
	
	all_origins.clear()


func recreate_from_save(saved_array : Array) -> void:
	# recreates all blocks from saved file
	game_settings.set_interaction_enabled(false)
	reset()
	loaded_areas.clear()
	# we need to queue up else it takes too long to load
	process_load_queue = true
	saved_array_queue = saved_array
	queue_counter = saved_array.size()


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


func recolor_block(area : Area):
	var chunk = get_current_chunk()
	if chunk:
		chunk.recolor_block(area)
		emit_signal("area_recolored")


func remove_block(area : Area) -> void:
	var chunk = get_current_chunk()
	if chunk:
		chunk.remove_block(area)
		emit_signal("area_deleted")


# called by ks_multi_mesh
func get_block_with_orig(block_orig : Vector3):
	var chunk = get_current_chunk()
	if chunk:
		return chunk.get_block_with_orig(block_orig)
	
	return null


func delete_origins(area: Area):
	var chunk = get_current_chunk()
	if chunk:
		chunk.delete_origins(area)


func serialize_all():
	var block_areas_serialized : Array
	
	var all_block_chunks = get_children()
	for c in all_block_chunks:
		block_areas_serialized += c.serialize()
	
	return block_areas_serialized


func get_all_blocks():
	var all_blocks : Array
	
	var all_block_chunks = get_children()
	for c in all_block_chunks:
		all_blocks += c.get_all_blocks()
	
	return all_blocks


func add_placeholder(area: Area):
	var chunk = get_current_chunk()
	if chunk:
		chunk.add_placeholder(area)


func clear_placeholders(first_n : int = 0):
	var chunk = get_current_chunk()
	if chunk:
		chunk.clear_placeholders(first_n)


func remove_placeholder(area : Area) -> bool:
	var chunk = get_current_chunk()
	if chunk:
		return chunk.remove_placeholder(area)
		
	return false


func get_placeholders_size() -> int:
	var chunk = get_current_chunk()
	if chunk:
		return chunk.get_placeholders_size()
	
	return 0

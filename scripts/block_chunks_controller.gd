extends Spatial


# overall logic forall BlockChunks
class_name BlockChunksController


signal area_added
signal area_loading_finished
signal area_chunk_loaded

var all_origins : Array
var loaded_areas: Array
var process_load_queue := false
var queue_counter := 0
var saved_array_queue : Array
var q_blocks_per_frame := 100

#onready var multi_mesh = get_node(global_vars.MULTI_MESH_PATH)
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
				emit_signal("area_chunk_loaded", loaded_areas)
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
			process_load_queue = false
			emit_signal("area_loading_finished")


func get_chunk(index : int):
	var all_block_chunks = get_children()
	if all_block_chunks.size() > index:
		return all_block_chunks[index]
	
	return null


func add_block(
	cube_transform : Transform,
	color_name : String,
	play_sound : bool = true):

	
	# right now we just work with one chunk
	# later on we might add logic for more chunks to improve performance
	var chunk = get_chunk(0)
	
	if not chunk:
		return Area.new()
	
	var new_area = chunk.add_block(cube_transform, color_name)
	
	if play_sound:
		play_snap_sound(new_area.global_transform.origin)
	
	if chunk.block_count() != 1:
		emit_signal("area_added")
	
#	return new_area


func play_snap_sound(new_pos : Vector3):
	print("sound_settings.get_block_snap_sound() ", sound_settings.get_block_snap_sound())
	if audio_stream_player_snap and sound_settings.get_block_snap_sound():
		audio_stream_player_snap.global_transform.origin = new_pos
		audio_stream_player_snap.play()


func create_chunk():
	# adds a BlockChunk
	var block_chunk = block_chunk_scene.instance()
	add_child(block_chunk)


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
	var chunk = get_chunk(chunk_index)
	if chunk:
		chunk.clear()
	
	all_origins.clear()


func recreate_from_save(saved_array : Array) -> void:
	# recreates all blocks from saved file
#	multi_mesh.clear()
	clear_all()
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


func remove_origin(block_orig : Vector3) -> void:
	var chunk = get_chunk(0)
	if chunk:
		chunk.erase(block_orig)


# called by ks_multi_mesh
func block_exists(block_orig : Vector3) -> bool:
	var chunk = get_chunk(0)
	if chunk:
			return chunk.has_block(block_orig)
	
	return false


func serialize_all():
	var block_areas_serialized : Array
	
	var all_block_chunks = get_children()
	for c in all_block_chunks:
		block_areas_serialized.append(c.serialize())
	
	return block_areas_serialized

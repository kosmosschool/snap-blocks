extends Spatial


# logic for collection of all block areas of blocks added to MultiMesh
class_name AllBlockAreas

onready var block_area_script = load(global_vars.BLOCK_AREA_SCRIPT_PATH)
onready var audio_stream_player_snap := $AudioStreamPlayer3DSnap

func add_block_area(col_shape : CollisionShape, block_matrial : Material, play_sound : bool = true) -> Area:
	# create area
	var new_area = Area.new()
	add_child(new_area)
	new_area.global_transform = col_shape.get_global_transform()
	col_shape.get_parent().remove_child(col_shape)
	new_area.add_child(col_shape)
	new_area.monitoring = false
	new_area.set_script(block_area_script)
	new_area.set_collision_layer(2)
	new_area.collision_shape = col_shape
	new_area.set_block_material(block_matrial)
	
	# reset col shape's transform because it's now a child of the area which has its transform
	col_shape.transform = Transform()
	
	if play_sound:
		play_snap_sound(new_area.global_transform.origin)
	
	return new_area


func play_snap_sound(new_pos : Vector3):
	if audio_stream_player_snap:
		audio_stream_player_snap.global_transform.origin = new_pos
		audio_stream_player_snap.play()

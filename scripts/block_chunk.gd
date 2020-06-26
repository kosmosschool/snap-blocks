extends Spatial


class_name BlockChunk


var all_origins : Array
var all_origins_areas : Array

onready var multi_mesh = $MultiMeshInstance
onready var all_block_areas = $BlockAreas
onready var block_area_script = load(global_vars.BLOCK_AREA_SCRIPT_PATH)
onready var cube_col_shape = load(global_vars.CUBE_COLLISION_SHAPE_PATH)


func clear():
#	var all_block_areas = $BlockAreas.get_children()
	var block_areas_children = all_block_areas.get_children()
	for b in block_areas_children:
		b.queue_free()
	
	multi_mesh.clear()


func add_block(cube_transform : Transform, color_name : String, update_multi_mesh : bool = false) -> Area:
	# create area
	var new_area = Area.new()
	all_block_areas.add_child(new_area)
	new_area.global_transform = cube_transform
	
	# create CollisionShape
	var col_shape_node = CollisionShape.new()
	col_shape_node.set_shape(cube_col_shape)
	col_shape_node.set_name("CollisionShape")
	new_area.add_child(col_shape_node)
	new_area.monitoring = false
	new_area.set_script(block_area_script)
	new_area.set_collision_layer(2)
	new_area.set_color_name(color_name)
	
	all_origins.append(round_origin(new_area.global_transform.origin))
	all_origins_areas.append(new_area)
	
	if update_multi_mesh:
		# update multi mesh instance
		multi_mesh.add_recreate(new_area)
	
	return new_area


func recolor_block(area : Area):
	multi_mesh.recolor_block(area)


func remove_block(area) -> void:
	var i = all_origins.find(round_origin(area.global_transform.origin))
	if i == -1:
		return
	
	all_origins.remove(i)
	all_origins_areas.remove(i)
	multi_mesh.remove_area(area)


func get_block_with_orig(block_orig : Vector3):
	var i = all_origins.find(round_origin(block_orig))
	if i == -1:
		return
		
#	return all_origins.has(round_origin(block_orig))
	return all_origins_areas[i]


func block_count() -> int:
	var all_block_areas = $BlockAreas
	return all_block_areas.get_child_count()


func round_origin(vec : Vector3) -> Vector3:
	# rounds so that we can compare origins better
	var rs = 0.01
	return Vector3(stepify(vec.x, rs), stepify(vec.y, rs), stepify(vec.z, rs))


func serialize() -> Array:
	var serialized_block_areas : Array
	var all_block_areas = $BlockAreas.get_children()
	
	for b in all_block_areas:
		serialized_block_areas.append(b.serialize_for_save())
	
	return serialized_block_areas


func create_multi_mesh(new_areas : Array = get_all_blocks(), reset : bool = true):
	multi_mesh.create(new_areas, reset)


func get_all_blocks() -> Array:
	return $BlockAreas.get_children()

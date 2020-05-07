extends Node
# saves and reads from saved file

var current_file_path = "user://creation_2.json"

onready var all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH)
onready var multi_mesh = get_node(global_vars.MULTI_MESH_PATH)


func _ready():
	# check if file exits
#	var save_file = File.new()
#	if !save_file.file_exists(file_path):
#		# initialize if file doesn't exist
#		write_to_file({})
	pass



func save_creation():
	# this overrides the old file
	# get all block areas
	var block_areas_serialized : Array
	var block_areas = all_block_areas.get_children()
	for b in block_areas:
		block_areas_serialized.append(b.serialize_for_save())
	
	
	var new_data_dict = {
		"all_block_areas": block_areas_serialized,
	}
	
	# get multi mesh
	
	# save to file
	var save_file = File.new()
	var unsaved_json = to_json(new_data_dict)
	save_file.open(current_file_path, File.WRITE)
	save_file.store_string(unsaved_json)
	save_file.close()


func load_creation(saved_file_path : String):
	var save_file = File.new()
	save_file.open(saved_file_path, File.READ)
	var content = parse_json(save_file.get_as_text())
	
	if not content:
		return
	
	# create all block areas
	var added_areas = all_block_areas.recreate_from_save(content["all_block_areas"])
	
	# createa multi mesh
	multi_mesh.recreate(added_areas)

#func read_from_file() -> Dictionary:
#	# get file content
#	var save_file = File.new()
#	save_file.open(file_path, File.READ)
#	var content = parse_json(save_file.get_as_text())
#	save_file.close()
#	return content
#
#
#func write_to_file(new_content : Dictionary) -> void:
#	var save_file = File.new()
#	var empty_json = to_json(new_content)
#	save_file.open(file_path, File.WRITE)
#	save_file.store_string(empty_json)
#	save_file.close()
#
#
#func save(key : String, value):
#	var content = read_from_file()
#	content[key] = value
#	write_to_file(content)
#
#
#func get(key : String):
#	var content = read_from_file()
#	if content.has(key):
#		return content[key]
#	else:
#		return null

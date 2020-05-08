extends Node
# saves and reads from saved file

var save_dir = "user://saved_creations/"
var open_file_name : String

onready var all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH)
onready var multi_mesh = get_node(global_vars.MULTI_MESH_PATH)


func _ready():
	var dir = Directory.new()
	# create dir if it doesn't exist
	if not dir.dir_exists(save_dir):
		dir.make_dir(save_dir)
	
	open_new_file()


func open_new_file() -> void:
	var all_files = get_all_saved_files()
	var newest_number
	if all_files.empty():
		newest_number = 1
	else:
		# set open file name based on newest file's number
		# assumig all_files is order by created_at asc
		newest_number = get_file_number(all_files[-1])
		if newest_number == -1:
			return
		
		newest_number += 1
	open_file_name = str("creation_", newest_number, ".json")


func get_file_number(input_file_name : String) -> int:
	var r = RegEx.new()
	r.compile("_\\d*")
	var regex_result = r.search_all(input_file_name)
	if regex_result.empty():
		return -1

	return regex_result[0].get_string().to_int()

func save_creation():
	# this overrides the old file
	# get all block areas
	var block_areas_serialized : Array
	var block_areas = all_block_areas.get_children()
	
	# don't save if there are no blocks snapped together
	if block_areas.empty():
		return
	
	for b in block_areas:
		block_areas_serialized.append(b.serialize_for_save())
	
	
	var new_data_dict = {
		"all_block_areas": block_areas_serialized,
	}
	
	# save to file
	var save_file = File.new()
	var unsaved_json = to_json(new_data_dict)
	save_file.open(save_dir + open_file_name, File.WRITE)
	save_file.store_string(unsaved_json)
	save_file.close()


func load_creation(saved_file_name : String):
	print("saved_file_path ", saved_file_name)
	var save_file = File.new()
	save_file.open(save_dir + saved_file_name, File.READ)
	var content = parse_json(save_file.get_as_text())
	
	if not content:
		return
	
	# create all block areas
	var added_areas = all_block_areas.recreate_from_save(content["all_block_areas"])
	
	# createa multi mesh
	multi_mesh.recreate(added_areas)
	
	# update open file name
	open_file_name = saved_file_name


func get_all_saved_files():
	var all_file_paths : Array
	var dir = Directory.new()
	if dir.open(save_dir) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# make sure it's not a directory for some reason
				all_file_paths.append(file_name)
			
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	return all_file_paths


func clear_and_new() -> void:
	# deletes current creation, creates new file
	all_block_areas.clear()
	multi_mesh.clear()
	
	open_new_file()


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

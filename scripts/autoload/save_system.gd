extends Node


class_name SaveSystem


signal file_loaded

var save_dir = "user://saved_creations/"
var base_dir = "user://"
var user_prefs_file_name = "user_prefs.json"
var open_file_path : String

onready var all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH)
onready var multi_mesh = get_node(global_vars.MULTI_MESH_PATH)
onready var welcome_controller = get_node(global_vars.WELCOME_CONTROLLER_PATH)


func _ready():
#	get_tree().connect("on_request_permissions_result", self, "_on_Main_Loop_on_request_permissions_result")
#	copy_files_to_ext()
	
	var dir = Directory.new()
	# create dir if it doesn't exist
	if not dir.dir_exists(save_dir):
		dir.make_dir_recursive(save_dir)
	
	open_new_file()
	
	init_user_prefs()


# we don't use this yet, but leaving it in here for future reference
#func _on_Main_Loop_on_request_permissions_result(permission, granted):
#	print ("permission granted ", permission)


func has_permission(permission : String) -> bool:
	var granted_perms = OS.get_granted_permissions()
	
	for perm in granted_perms:
		if perm == permission:
			return true

	return false


func copy_files_to_ext() -> void:
	# copies all files to external storage (useful for debugging)
	# make sure you have read and write access to external storage in the export settings

	if (not has_permission("android.permission.READ_EXTERNAL_STORAGE") or
		not has_permission("android.permission.WRITE_EXTERNAL_STORAGE")):
		
		print("requesting permissions")
		OS.request_permissions()
		return
	
	var dest_path = "/sdcard/Snap Blocks Debug/"
	var dir = Directory.new()
	
	# make sur dest path exists
	if not dir.dir_exists(dest_path):
		var err = dir.make_dir_recursive(dest_path)
		if err != OK:
			print("Could not create directory: ", dest_path)


	if dir.open(save_dir) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# make sure it's not a directory for some reason
				dir.copy(str(save_dir, file_name), str(dest_path, file_name))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the save dir path")


func open_new_file() -> void:
	var all_files = get_all_saved_files(save_dir)
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
	open_file_path = str("user://saved_creations/creation_", newest_number, ".json")


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
		"app_version": global_functions.get_current_version(),
		"all_block_areas": block_areas_serialized,
	}
	
	# save to file
	var save_file = File.new()
	var unsaved_json = to_json(new_data_dict)
	save_file.open(open_file_path, File.WRITE)
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
	
	# if we loaded a fixed gallery file, create a new file to save to
	if "gallery_fixed" in saved_file_path:
		open_new_file()
	else:
		# update open file name
		open_file_path = saved_file_path
	
	
	emit_signal("file_loaded")


func delete_creation(saved_file_path : String):
	# delete file
	var dir = Directory.new()
	dir.remove(saved_file_path)
	
	open_new_file()


func get_all_saved_files(dir_path : String):
	var all_file_paths : Array
	var dir = Directory.new()
	if dir.open(dir_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# make sure it's not a directory for some reason
				if ".json" in file_name:
					all_file_paths.append(file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")
	
	# sort by file number, ascending
	all_file_paths.sort_custom(SortByFileNumber, "sort_ascending")
	
	return all_file_paths


func clear_and_new() -> void:
	# deletes current creation, creates new file
	all_block_areas.clear()
	multi_mesh.clear()
	welcome_controller.starting_cube_set = false
	
	open_new_file()


func get_button_pic_path(file_path : String):
	# returns button_pic_path based on file_path if it exists
	var curr_file = File.new()
	var err = curr_file.open(file_path, File.READ)
	
	if err != 0:
		return ""
	
	var file_text = curr_file.get_as_text()
	var content : Dictionary
	if file_text != "":
		var json_parsed = parse_json(file_text)
		if json_parsed is Dictionary:
			content = json_parsed
		else:
			return ""
	else:
		return ""
	curr_file.close()
	
	if content.has("button_pic_path"):
		return content["button_pic_path"]
	else:
		return ""


class SortByFileNumber:
	# we have to re-implement this function here again
	# because the inner class doesn't have access to the outer class
	# see here: https://github.com/godotengine/godot/issues/4472
	static func get_file_number(input_file_name : String) -> int:
		var r = RegEx.new()
		r.compile("_\\d*")
		var regex_result = r.search_all(input_file_name)
		if regex_result.empty():
			return -1
	
		return regex_result[0].get_string().to_int()
	
	# custom sorter class that sorts by file number
	static func sort_ascending(a, b):
		if get_file_number(a) < get_file_number(b):
			return true
		return false


### *** stuff related to user prefs below ***

func read_from_user_prefs_file() -> Dictionary:
	var dir = Directory.new()
	
	var curr_file = File.new()
	if not dir.file_exists(base_dir + user_prefs_file_name):
		curr_file.open(base_dir + user_prefs_file_name, File.WRITE_READ)
	else:
		curr_file.open(base_dir + user_prefs_file_name, File.READ)

	var file_text = curr_file.get_as_text()
	var content : Dictionary
	if file_text != "":
		content = parse_json(file_text)
	curr_file.close()

	return content


func write_to_user_prefs_file(new_content : Dictionary) -> void:
	var curr_file = File.new()
	var empty_json = to_json(new_content)
	curr_file.open(base_dir + user_prefs_file_name, File.WRITE)
	curr_file.store_string(empty_json)
	curr_file.close()


func user_prefs_save(key : String, value):
	var content = read_from_user_prefs_file()
	content[key] = value
	write_to_user_prefs_file(content)


func user_prefs_get(key : String):
	var content = read_from_user_prefs_file()
	if content.has(key):
		return content[key]
	else:
		return null


func init_user_prefs():
	user_prefs_save("app_version", global_functions.get_current_version())

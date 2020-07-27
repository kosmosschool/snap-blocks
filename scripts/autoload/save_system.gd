extends Node


class_name SaveSystem


signal file_loaded

var save_dir = "user://saved_creations/"
var save_dir_cover_pics = "user://creation_pics/"
var base_dir = "user://"
var user_prefs_file_name = "user_prefs.json"
var open_file_path : String
var open_file_name : String
var open_cover_pic_path : String

onready var block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)
onready var welcome_controller = get_node(global_vars.WELCOME_CONTROLLER_PATH)
onready var camera = get_node(global_vars.AR_VR_CAMERA_PATH)
onready var ar_vr_origin = get_node(global_vars.AR_VR_ORIGIN_PATH)
onready var screens_controller = get_node(global_vars.ALL_SCREENS_PATH)


func _ready():
#	get_tree().connect("on_request_permissions_result", self, "_on_Main_Loop_on_request_permissions_result")
#	copy_files_to_ext()
	
	var dir = Directory.new()
	# create save dir if it doesn't exist
	if not dir.dir_exists(save_dir):
		dir.make_dir_recursive(save_dir)
	
	# create save dir cover pics if it doesn't exist
	if not dir.dir_exists(save_dir_cover_pics):
		dir.make_dir_recursive(save_dir_cover_pics)
	
	
#	if dir.open(save_dir_cover_pics) == OK:
#		dir.list_dir_begin()
#		var file_name = dir.get_next()
#
#		while file_name != "":
#			print("file_name ", file_name)
#
#			file_name = dir.get_next()
#
#		dir.list_dir_end()
	
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
	
	open_file_name = str("creation_", newest_number)
	open_file_path = str("user://saved_creations/", open_file_name, ".json")


func get_file_number(input_file_name : String) -> int:
	var r = RegEx.new()
	r.compile("_\\d*")
	var regex_result = r.search_all(input_file_name)
	if regex_result.empty():
		return -1

	return regex_result[0].get_string().to_int()


func get_file_name_from_path(input_file_path : String) -> String:
	var r = RegEx.new()
	r.compile("(\\w*)\\.")
	var regex_result = r.search_all(input_file_path)
	if regex_result.empty():
		return ""

	return regex_result[0].get_string(1)


func save_creation():
	# this overrides the old file
	var block_areas_serialized = block_chunks_controller.serialize_all()
	
	open_cover_pic_path = str(save_dir_cover_pics, open_file_name, ".png")
	
	var new_data_dict = {
		"app_version": global_functions.get_current_version(),
		"all_block_areas": block_areas_serialized,
		"position": global_functions.transform_to_array(ar_vr_origin.global_transform),
		"cover_pic_path": open_cover_pic_path
	}
	
	# we need to take a cover pic before saving
	screens_controller.change_screen("CamScreen")

	# save to file
	write_file(open_file_path, new_data_dict)


func load_creation(saved_file_path : String):
	var content = read_file(saved_file_path)
	
	if not content:
		return
	
	if content.has("position"):
		ar_vr_origin.global_transform.origin = Vector3(content["position"][9],content["position"][10],content["position"][11])
	
	# create all block areas
	block_chunks_controller.recreate_from_save(content["all_block_areas"])
	
	# get cover pic path
	if content.has("cover_pic_path"):
		open_cover_pic_path = content["cover_pic_path"]
	
	# if we loaded a fixed gallery file, create a new file to save to
	if "gallery_fixed" in saved_file_path:
		open_new_file()
	else:
		# update open file name
		open_file_path = saved_file_path
		open_file_name = get_file_name_from_path(saved_file_path)
	
	
	emit_signal("file_loaded")


func delete_creation(saved_file_path : String):
	# delete file
	var dir = Directory.new()
	dir.remove(saved_file_path)
	
	open_new_file()


func share_gallery_creation(saved_file_path : String):
	var content = read_file(saved_file_path)
	
	if not content:
		return
		
	if not content.has("creation_name"):
		# open promopt to enter creation name
		var keyboard_cb = funcref(self, "share_gallery_creation_keyboard_cb")
		screens_controller.show_keyboard(
			keyboard_cb,
			{"saved_file_path" : saved_file_path},
			"What's your Creation called?",
			"Enter name"
		)
	elif not read_key_value(base_dir + user_prefs_file_name, "username"):
		# this means the user has not yet specified a username
		var keyboard_cb = funcref(self, "share_gallery_user_keyboard_cb")
		screens_controller.show_keyboard(
			keyboard_cb,
			{"saved_file_path" : saved_file_path},
			"What's your username?",
			"Enter username"
		)
	else:
		# make api request to share file to gallery
		screens_controller.change_screen("LoadScreen")
		print("Making API requst to share creation...")


func share_gallery_creation_keyboard_cb(creation_name : String, args : Dictionary):
	# called when user presses enter on the keyboard after enter the creation name
	# save creation name to file and share again
	if not args.has("saved_file_path"):
		return
	
	if not write_key_value(args["saved_file_path"], "creation_name", creation_name):
		print("Error: Something went wrong when trying to save the Creation name while share Creation to Gallery")
		return
	
	share_gallery_creation(args["saved_file_path"])


func share_gallery_user_keyboard_cb(username: String, args : Dictionary):
	if not args.has("saved_file_path"):
		return
	
	# called when user presses enter on keyboard after entering their username
	if not write_key_value(base_dir + user_prefs_file_name, "username", username):
		print("Error: Something went wrong when trying to save the username while sharing Creation to Gallery")
		return
	
	# share to gallery again
	share_gallery_creation(args["saved_file_path"])


func write_file(file_path : String, new_content : Dictionary) -> bool:
	var curr_file = File.new()
	var empty_json = to_json(new_content)
	var err = curr_file.open(file_path, File.WRITE)
	if err != OK:
		return false
	curr_file.store_string(empty_json)
	curr_file.close()
	return true


func read_file(file_path : String) -> Dictionary:
	var dir = Directory.new()
	
	var curr_file = File.new()
	var err
	if not dir.file_exists(file_path):
		err = curr_file.open(file_path, File.WRITE_READ)
	else:
		err = curr_file.open(file_path, File.READ)
	
	var content : Dictionary
	if err != OK:
		return content
		print("read_file: Couldn't open file to read")

	var file_text = curr_file.get_as_text()
	
	if file_text != "":
		content = parse_json(file_text)
	curr_file.close()

	return content


func write_key_value(file_path : String, key : String, value) -> bool:
	var content = read_file(file_path)
	content[key] = value
	return write_file(file_path, content)


func read_key_value(file_path : String, key : String):
	var content = read_file(file_path)
	if content.has(key):
		return content[key]
	else:
		return null
	

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
	block_chunks_controller.reset()
#	multi_mesh.clear()
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
	
	if content.has("cover_pic_path"):
		return content["cover_pic_path"]
	else:
		return ""


func init_user_prefs():
	write_key_value(base_dir + user_prefs_file_name, "app_version", global_functions.get_current_version())


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


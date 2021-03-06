extends Spatial


class_name LoadScreen


signal delete_mode_selected
signal share_gallery_mode_selected
signal load_mode_selected

var file_button_scene
var offset_x = 0.05
var offset_y = -0.05
var page_size := 8
var row_size := 4
var current_page := 1
var total_pages := 1
var all_files_paginated : Dictionary setget , get_all_files_paginated
var load_buttons : Array
var delete_mode := false setget , get_delete_mode
var share_gallery_mode := false setget , get_share_gallery_mode


onready var load_buttons_node = $LoadButtons
onready var button_prev = $ButtonPrevious
onready var button_next = $ButtonNext
onready var title_label = $TitleLabel
onready var button_load_script = preload("res://scripts/button_load.gd")

export var saved_files_path : String
export var LOAD_MODE_TITLE : String
export var DELETE_MODE_TITLE : String
export var SHARE_GALLERY_MODE_TITLE : String
export var EMPTY_TITLE : String
export var first_button_origin = Vector3(-0.105, 0, 0.003)


func get_all_files_paginated():
	return all_files_paginated


func get_delete_mode():
	return delete_mode


func get_share_gallery_mode():
	return share_gallery_mode


func _ready():
	file_button_scene = preload("res://scenes/ks_button_pressable_image.tscn")
	
	create_load_buttons()
	refresh_files()


func create_load_buttons() -> void:
	for i in range(page_size):
		var file_button = file_button_scene.instance()
		file_button.set_script(button_load_script)
		load_buttons_node.add_child(file_button)

		# position
		var offset_y_mod = floor(i / row_size)
		var offset_x_mod = i - (offset_y_mod * row_size)
		var new_origin = first_button_origin + Vector3(offset_x_mod * offset_x, offset_y_mod * offset_y, 0)
		file_button.set_local_origin(new_origin)
	
	load_buttons = load_buttons_node.get_children()


func refresh_files():
	var all_files : Array = save_system.get_all_saved_files(saved_files_path)
	
	all_files_paginated = paginate(all_files)
	
	if title_label:
		if all_files_paginated.empty():
			title_label.set_text(EMPTY_TITLE)
		else:
			title_label.set_text(LOAD_MODE_TITLE)
	
	# calculate how many pages we have
	total_pages = ceil(all_files.size() / float(page_size))
	
	display_load_buttons()
	update_change_page_buttons()


func display_load_buttons() -> void:
	# hide all to start
	for b in load_buttons:
		b.visible = false
	
	if all_files_paginated.empty() or not all_files_paginated.has(current_page):
		return
	
	var current_page_files = all_files_paginated[current_page]
	for i in range(current_page_files.size()):
		var current_button = load_buttons[i]
		current_button.visible = true
		current_button.set_file_path(saved_files_path + current_page_files[i])
		
		# update image
		var image_mesh = current_button.get_node("MeshInstanceImage")
		var image_path = save_system.get_button_pic_path(saved_files_path + current_page_files[i])
#		var image_tex
		var image_tex = ImageTexture.new()
		
		if image_path != "":
			if ResourceLoader.exists(image_path, "Image"):
				image_tex = load(image_path)
			else:
				# this is the case if we saved the image directly from the viewport (with the save cam)
				# it can't be loaded as resource such as imported images (which are already ImageTextures).
				# therefore, we need to create an ImageTexxture from it first
				var img = Image.new()
				img.load(image_path)
				image_tex.create_from_image(img)
			
		else:
			# set placeholder image
			image_tex = load("res://images/gallery_images/tree.jpg")
		
		image_mesh.get_surface_material(0).set_texture(SpatialMaterial.TEXTURE_ALBEDO, image_tex)


func paginate(input_array : Array) -> Dictionary:
	var return_dict : Dictionary
	
	for i in range(input_array.size()):
		var page = int(ceil((i + 1) / float(page_size)))
		if return_dict.has(page):
			return_dict[page].append(input_array[i])
		else:
			return_dict[page] = [input_array[i]]

	return return_dict


# called by next or previous page buttons
func change_page(page_direction : int) -> void:
	if page_direction == ButtonChangePageLoad.PageDirection.NEXT:
		if current_page == total_pages:
			return
		current_page += 1
	else:
		if current_page == 1:
			return
		current_page -= 1
	
	# update load buttons
	display_load_buttons()
	update_change_page_buttons()


func update_change_page_buttons() -> void:
	if all_files_paginated.empty():
		button_next.visible = false
		button_prev.visible = false
		return
		
	if total_pages == 1:
		button_next.visible = false
		button_prev.visible = false
		return
	else:
		button_next.visible = true
		button_prev.visible = true
	
	if current_page == 1:
		button_prev.visible = false
	elif current_page == total_pages:
		button_next.visible = false


func toggle_delete_mode():
	delete_mode = !delete_mode
	
	if delete_mode:
		if title_label:
			title_label.set_text(DELETE_MODE_TITLE)
		emit_signal("delete_mode_selected")
	else:
		if title_label:
			title_label.set_text(LOAD_MODE_TITLE)
		emit_signal("load_mode_selected")


func toggle_share_gallery_mode():
	share_gallery_mode = !share_gallery_mode
	
	if share_gallery_mode:
		if title_label:
			title_label.set_text(SHARE_GALLERY_MODE_TITLE)
		emit_signal("share_gallery_mode_selected")
	else:
		if title_label:
			title_label.set_text(LOAD_MODE_TITLE)
		emit_signal("load_mode_selected")
	

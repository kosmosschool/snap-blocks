extends Spatial


class_name LoadScreen


var first_button_origin = Vector3(-0.105, 0, 0.003)
var offset_x = 0.05
var offset_y = -0.05
var page_size := 8
var row_size := 4
var current_page := 1
var total_pages := 1
var all_files_paginated : Dictionary

onready var load_buttons_node = $LoadButtons
onready var button_prev = $ButtonPrevious
onready var button_next = $ButtonNext
onready var file_button_scene = preload("res://scenes/ks_button_pressable_text.tscn")
onready var button_load_script = preload("res://scripts/button_load.gd")


func _ready():
#	connect("visibility_changed", self, "_on_Load_Screen_visibility_changed")
	refresh_files()


#func _on_Load_Screen_visibility_changed():
#	if visible:
#		refresh_files()
#		update_change_page_buttons()


func refresh_files():
	var all_files : Array = save_system.get_all_saved_files()
	all_files_paginated = paginate(all_files)
	
	# calculate how many pages we have
	total_pages = ceil(all_files.size() / float(page_size))
	
	display_load_buttons()
	update_change_page_buttons()


func display_load_buttons() -> void:
	# destroy old buttons
	var old_buttons = load_buttons_node.get_children()
	for o in old_buttons:
		o.queue_free()
	
	var current_page_files = all_files_paginated[current_page]
	for i in range(current_page_files.size()):
		var file_button = file_button_scene.instance()
		file_button.set_script(button_load_script)
		load_buttons_node.add_child(file_button)
		file_button.set_file_name(current_page_files[i])

		# position
		
		var offset_y_mod = floor(i / row_size)
		var offset_x_mod = i - (offset_y_mod * row_size)
		var new_origin = first_button_origin + Vector3(offset_x_mod * offset_x, offset_y_mod * offset_y, 0)
		file_button.set_local_origin(new_origin)

		# update text and font size
		var current_file_number = save_system.get_file_number(current_page_files[i])
		var text_label = file_button.get_node("2DTextLabel")
		text_label.set_text(str(current_file_number))
		text_label.set_font_size_multiplier(4)
	
	

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
	

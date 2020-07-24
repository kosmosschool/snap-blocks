extends KSButtonPressable


# button used to share files to the Gallery
class_name ButtonShareGallery


onready var icon_mesh = $MeshInstanceIcon
onready var off_icon_mat = icon_mesh.get_surface_material(0)
onready var load_screen = get_parent()

export (Material) var on_icon_mat

# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	# if no saved files, don't go into share mode
	if load_screen.get_all_files_paginated().empty():
		is_on = false
		return
	
	load_screen.toggle_share_gallery_mode()
	
	# change icon
	if is_on and icon_mesh:
		icon_mesh.set_surface_material(0, on_icon_mat)
	elif not is_on:
		icon_mesh.set_surface_material(0, off_icon_mat)

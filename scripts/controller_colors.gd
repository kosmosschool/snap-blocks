extends Spatial


class_name ControllerColors

var current_color_index := 0
var all_ghost_materials : Array

onready var ar_vr_controller = get_parent().get_parent()
onready var mesh_instance = $MeshInstance

export (Array, Material) var all_materials


func _ready():
	ar_vr_controller.connect("button_pressed", self, "_on_ARVRController_button_pressed")
	update_mini_block(all_materials[current_color_index])
	create_ghost_materials()


func _on_ARVRController_button_pressed(button_number):
	# if grip trigger pressed while B button being held down
	if button_number == vr.CONTROLLER_BUTTON.XA:
		rotate_material()


func create_ghost_materials() -> void:
	for mat in all_materials:
		var current_color = mat.get_shader_param("color")
		var new_ghost_mat = SpatialMaterial.new()
		new_ghost_mat.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
		new_ghost_mat.set_albedo(Color(current_color.x, current_color.y, current_color.z, 0.5))
		all_ghost_materials.append(new_ghost_mat)


func rotate_material() -> void:
	if current_color_index + 1 == all_materials.size():
		current_color_index = 0
	else:
		current_color_index += 1
	
	update_mini_block(all_materials[current_color_index])


func update_mini_block(new_mat : Material) -> void:
	mesh_instance.set_surface_material(0, new_mat)


func get_current_material() -> Material:
	return all_materials[current_color_index]


func get_current_ghost_material() -> Material:
	return all_ghost_materials[current_color_index]

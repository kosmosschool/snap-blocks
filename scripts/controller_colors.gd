extends Spatial


class_name ControllerColors

var current_color_index := 0
var all_secondary_materials : Array
var all_ghost_materials : Array
var all_secondary_ghost_materials : Array

onready var ar_vr_controller = get_parent().get_parent()
onready var mesh_instance = $MeshInstance
onready var unshaded_color_shader = preload("res://shaders/unshaded_color.shader")

export (Array, Material) var all_materials


func _ready():
	ar_vr_controller.connect("button_pressed", self, "_on_ARVRController_button_pressed")
	create_ghost_and_secondary_materials()
	update_mini_block(all_materials[current_color_index], all_secondary_materials[current_color_index])


func _on_ARVRController_button_pressed(button_number):
	# if grip trigger pressed while B button being held down
	if button_number == vr.CONTROLLER_BUTTON.XA:
		rotate_material()


func create_ghost_and_secondary_materials() -> void:
	for mat in all_materials:
		var current_color = mat.get_shader_param("color")
		
		# ghost material
		var new_ghost_mat = SpatialMaterial.new()
		new_ghost_mat.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
		new_ghost_mat.set_albedo(Color(current_color.x, current_color.y, current_color.z, 0.5))
		all_ghost_materials.append(new_ghost_mat)
		
		# secondary ghost material
		# TODO: what happens if value negative?
		var new_secondary_ghost_mat = SpatialMaterial.new()
		new_secondary_ghost_mat.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
		new_secondary_ghost_mat.set_albedo(Color(current_color.x - 0.05, current_color.y - 0.05, current_color.z - 0.05, 0.5))
		all_secondary_ghost_materials.append(new_secondary_ghost_mat)
		
		# secondary material
		# TODO: what happens if value negative?
		var secondary_color = Vector3(current_color.x - 0.05, current_color.y - 0.05, current_color.z - 0.05)
		var new_secondary_mat = ShaderMaterial.new()
		new_secondary_mat.set_shader(unshaded_color_shader)
		new_secondary_mat.set_shader_param("color", secondary_color)
		all_secondary_materials.append(new_secondary_mat)


func rotate_material() -> void:
	if current_color_index + 1 == all_materials.size():
		current_color_index = 0
	else:
		current_color_index += 1
	
	update_mini_block(all_materials[current_color_index], all_secondary_materials[current_color_index])


func update_mini_block(new_mat_primary : Material, new_mat_secondary : Material) -> void:
	mesh_instance.set_surface_material(0, new_mat_primary)
	mesh_instance.set_surface_material(1, new_mat_secondary)


func get_current_material() -> Material:
	return all_materials[current_color_index]


func get_current_secondary_material() -> Material:
	return all_secondary_materials[current_color_index]


func get_current_ghost_material() -> Material:
	return all_ghost_materials[current_color_index]
	
	
func get_current_secondary_ghost_material() -> Material:
	return all_secondary_ghost_materials[current_color_index]

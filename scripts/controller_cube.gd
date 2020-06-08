extends Spatial

#var time : float = 0.0
#var run_animation : bool = false

onready var mini_cube_mesh = $Cube
onready var cube_left = $CubeLeft
onready var cube_right= $CubeRight
onready var animation_player_cubes = $AnimationPlayerCubes


#func _process(delta):
#	if run_animation == true:
#		time = time + delta
#		if time >= 0.25:
#			run_animation = false
#			time = 0.0


func set_cube_color(rotation_side: int, controller_side_string: String):
	
	if rotation_side == 0:
		cube_right.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))
		color_system.rotate_material(rotation_side, controller_side_string)
		cube_left.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))
#		run_animation = true
		animation_player_cubes.play("cube_right")
		
	elif rotation_side == 1:
		cube_left.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))
		color_system.rotate_material(rotation_side, controller_side_string)
		cube_right.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))
#		run_animation = true
		animation_player_cubes.play("cube_left")
	
	mini_cube_mesh.get_surface_material(0).set_shader_param("color", color_system.get_current_color(controller_side_string))



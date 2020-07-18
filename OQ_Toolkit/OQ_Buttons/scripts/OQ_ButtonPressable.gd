extends Spatial

# a button that needs to be physically pressed
class_name ButtonPressable

signal button_pressed

var touching := false
var at_default_pos := true
var triggering := false
var is_on := false
var hand_area: Area
var button_half_length_vector
var hand_pos: Vector3
var prev_hand_pos: Vector3
var dist := 0.0
var total_dist := 0.0
var lerp_weight: float
var start_time := 0.0
var speed := 2.0
var left_after_press = true

var initial_pos_local
var initial_pos_global
var button_forward_vector_norm
var z_scale
var button_mesh
var button_area
var default_mat_0
var default_mat_1

export var press_distance := 0.008
export(Material) var custom_mat_0
export(Material) var custom_mat_1
export(Material) var custom_mat_on_0
export(Material) var custom_mat_on_1
export var on_on_start := false


func _enter_tree():
	initial_pos_local = get_transform().origin
	initial_pos_global = get_global_transform().origin
	button_forward_vector_norm = get_transform().basis.z.normalized()
	z_scale = scale.z
	button_mesh = $MeshInstance
	button_area = $ButtonArea
	default_mat_0 = button_mesh.get_surface_material(0)
	default_mat_1 = button_mesh.get_surface_material(1)

	# connect to signals
	$ButtonArea.connect("area_entered", self, "_on_ButtonArea_area_entered")
	$ButtonArea.connect("area_exited", self, "_on_ButtonArea_area_exited")
	connect("visibility_changed", self, "_on_Button_Pressable_visibility_changed")
	
	button_half_length_vector = initial_pos_local + button_forward_vector_norm * z_scale / 2
	
	if custom_mat_0:
		button_mesh.set_surface_material(0, custom_mat_0)
	
	if custom_mat_1:
		button_mesh.set_surface_material(1, custom_mat_1)
	
	# initialize
	if (on_on_start):
		is_on = true
		button_turn_on()
	else:
		button_turn_off()
	
	if !is_visible_in_tree():
		set_process(false)
		set_physics_process(false)
		button_area.set_monitoring(false)


func _process(delta):
	
	if touching and left_after_press:
		# if hand is touching the button, we need to know how far in it is pressed
		
		# check how much hand pos has changed in buttons local z direction
		hand_pos = hand_area.global_transform.origin
		var hand_pos_change = hand_pos - prev_hand_pos
		
		var hand_pos_change_z_component = hand_pos_change.slide(button_forward_vector_norm)
		dist = hand_pos_change_z_component.length()
		
		if abs(dist) < 0.0005:
			return
		
		var new_origin = Vector3(initial_pos_local.x, initial_pos_local.y, transform.origin.z - dist)
		
		# only keep pushing back until press_distance is reached
		var total_dist = initial_pos_local.z - new_origin.z
		if total_dist < press_distance:
			transform.origin = new_origin
		elif total_dist > press_distance and !triggering:
			total_dist = initial_pos_local.z - press_distance
			transform.origin = Vector3(initial_pos_local.x, initial_pos_local.y, initial_pos_local.z)
			# trigger button press
			triggering = true
			left_after_press = false
			button_press(hand_area)
		
		prev_hand_pos = hand_pos

	elif !at_default_pos:
		# if not touching and not at default pos, bring back to default pos
		lerp_weight = start_time * speed
#		var move_by = lerp(dist, 0, lerp_weight)
		var move_by = lerp(total_dist, 0, lerp_weight)
		
		var new_origin = Vector3(initial_pos_local.x, initial_pos_local.y, initial_pos_local.z - move_by)
		
		transform.origin = new_origin
		
		start_time += delta
		
		if lerp_weight > 1:
			start_time = 0.0
			at_default_pos = true
			triggering = false
			transform.origin = initial_pos_local


func _on_ButtonArea_area_entered(area):
	# check if controller entered
	var area_parent = area.get_parent()
	if !area_parent:
		return
	
	if area_parent.name != "ControllerGrab":
		return
		
	if !global_functions.controller_node_from_child(area):
		return
	
	touching = true
	at_default_pos = false
	hand_area = area
	
	hand_pos = hand_area.global_transform.origin
	prev_hand_pos = hand_area.global_transform.origin


func _on_ButtonArea_area_exited(area):
	touching = false
	left_after_press = true


func _on_Button_Pressable_visibility_changed():
	# make sure we can't interact with this button if invisible
	if !is_visible_in_tree():
		set_process(false)
		set_physics_process(false)
		if button_area:
			button_area.set_monitoring(false)
	else:
		set_process(true)
		set_physics_process(true)
		if button_area:
			button_area.set_monitoring(true)


func set_local_origin(new_origin : Vector3):
	transform.origin = new_origin
	initial_pos_local = get_transform().origin
	initial_pos_global = get_global_transform().origin
	button_forward_vector_norm = get_transform().basis.z.normalized()
	button_half_length_vector = initial_pos_local + button_forward_vector_norm * z_scale / 2
	

func button_press(other_area: Area):
	is_on = !is_on
	switch_mat(is_on)
	emit_signal("button_pressed")


func button_turn_on():
	is_on = true
	switch_mat(true)


func button_turn_off():
	is_on = false
	switch_mat(false)


func switch_mat(_is_on):
	if not _is_on:
		if custom_mat_0 and custom_mat_on_0:
			# only set custom mat if there was a custom on mat
			button_mesh.set_surface_material(0, custom_mat_0)
		elif custom_mat_on_0:
			# only set default mat if there was a custom on mat
			button_mesh.set_surface_material(0, default_mat_0)
			
		if custom_mat_1 and custom_mat_on_1:
			# only set custom mat if there was a custom on mat
			button_mesh.set_surface_material(1, custom_mat_1)
		elif custom_mat_on_1:
			# only set default mat if there was a custom on mat
			button_mesh.set_surface_material(1, default_mat_1)
	else:
		if custom_mat_on_0:
			button_mesh.set_surface_material(0, custom_mat_on_0)
		if custom_mat_on_1:
			button_mesh.set_surface_material(1, custom_mat_on_1)

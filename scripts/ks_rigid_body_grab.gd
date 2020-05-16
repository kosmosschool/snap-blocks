extends Feature_RigidBodyGrab

class_name KSRigidBodyGrab


onready var controller_system = get_node(global_vars.CONTROLLER_SYSTEM_PATH)

# overriding from parent
func _on_ARVRController_button_pressed(button_number):
	if button_number != vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
		return
	
	if vr.button_pressed(vr.BUTTON.B):
		return
	
	if controller_system.get_controller_type() != 0:
		return
	
	# if grab button, grab
	grab()


# overriding from parent to allow grabbing rigid bodies with MODE_KINEMATIC
func grab():
	if (held_object):
		return
	
	# find the right rigid body to grab
	var grabbable_rigid_body = null
	var bodies = grab_area.get_overlapping_bodies();
	if len(bodies) > 0:
		for body in bodies:
			if body is KSGrabbableRigidBody:
#				var current_mode = body.get_mode()
#				if (current_mode == RigidBody.MODE_RIGID or current_mode == RigidBody.MODE_KINEMATIC) and body.is_grabbable:
				if body.is_grabbable:
#					body.set_mode(RigidBody.MODE_KINEMATIC)
#					if (current_mode == RigidBody.MODE_KINEMATIC):
#						body.set_mode(RigidBody.MODE_RIGID)
					grabbable_rigid_body = body

	if grabbable_rigid_body:
		match grab_type:
			vr.GrabTypes.KINEMATIC:
				start_grab_kinematic(grabbable_rigid_body);
			vr.GrabTypes.VELOCITY:
				start_grab_velocity(grabbable_rigid_body);
			vr.GrabTypes.HINGEJOINT:
				start_grab_hinge_joint(grabbable_rigid_body);


func overlapping_objects():
	# returns overlapping bodies
	return grab_area.get_overlapping_bodies();


func overlapping_areas():
	# returns overlapping bodies
	return grab_area.get_overlapping_areas();

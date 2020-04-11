extends OQClass_GrabbableRigidBody


# makes rigid body grabbable
class_name KSGrabbableRigidBody


signal grab_started
signal grab_ended

var grabbed_by : Node


func grab_init(node, grab_type: int):
	.grab_init(node, grab_type)
	grabbed_by = node
	emit_signal("grab_started")


func grab_release():
	.grab_release()
	grabbed_by = null
	emit_signal("grab_ended")

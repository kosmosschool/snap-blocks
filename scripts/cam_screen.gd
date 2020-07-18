extends Spatial


class_name CamScreen


onready var cam_sub_screen = $CamSubScreen
onready var confirmation_sub_screen = $ConfirmationSubScreen


func _ready():
	connect("visibility_changed", self, "_on_Cam_Screen_visibility_changed")
	cam_sub_screen.visible = true
	confirmation_sub_screen.visible = false


func _on_Cam_Screen_visibility_changed():
	if !is_visible_in_tree():
		cam_sub_screen.visible = false
		confirmation_sub_screen.visible = false
	else:
		cam_sub_screen.visible = true
		confirmation_sub_screen.visible = false


func show_pic_confirmation():
	# called after taking pic
	cam_sub_screen.visible = false
	confirmation_sub_screen.visible = true

extends Node


# does stuff in the beginning
class_name WelcomeController


onready var tutorial_scene = preload("res://scenes/tutorial_controller.tscn")


func _ready():
	if save_system.user_prefs_get("seen_tutorial") != true:
		show_tutorial()



func show_tutorial() -> void:
	var tutorial_instance = tutorial_scene.instance()
	get_node("/root/Main").call_deferred("add_child", tutorial_instance)

extends Node


# global game settings
class_name GameSettings


var interaction_enabled := true setget set_interaction_enabled, get_interaction_enabled


func set_interaction_enabled(new_value):
	interaction_enabled = new_value


func get_interaction_enabled():
	return interaction_enabled

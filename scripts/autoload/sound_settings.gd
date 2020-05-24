extends Node


# global sound settings
class_name SoundSettings


var block_snap_sound := true setget set_block_snap_sound, get_block_snap_sound
var contr_button_sound := true setget set_contr_button_sound, get_contr_button_sound


func set_block_snap_sound(new_value):
	block_snap_sound = new_value


func get_block_snap_sound():
	block_snap_sound


func set_contr_button_sound(new_value):
	contr_button_sound = new_value


func get_contr_button_sound():
	return contr_button_sound

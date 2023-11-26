@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("UnicodeNormalizer", "res://addons/goutte.unicode/singleton/UnicodeNormalizer.gd")


func _exit_tree():
	remove_autoload_singleton("UnicodeNormalizer")

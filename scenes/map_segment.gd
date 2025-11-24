extends Node2D
class_name MapSegment

signal layout_loaded

@export var layout_scenes: Array[PackedScene]
var loaded=false


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not loaded:
		var layout = layout_scenes.pick_random().instantiate()
		loaded=true
		add_child(layout)
		layout_loaded.emit()
	

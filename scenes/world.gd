extends Node2D

var segment_scene = preload("res://scenes/map_segment.tscn")
var next_segment_location = Vector2(0,0)

# Called when the node enters the scene tree for the first time.

func load_next_segment():
	var segment:MapSegment = segment_scene.instantiate()
	segment.global_position = next_segment_location
	segment.layout_loaded.connect(load_next_segment)
	add_child(segment)
	next_segment_location.y -= 648
	

func _ready() -> void:
	load_next_segment()

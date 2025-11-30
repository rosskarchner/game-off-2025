extends Node2D

var segment_scene = preload("res://scenes/map_segment.tscn")
var next_segment_location = Vector2(0,0)
var game_over_scene = preload("res://scenes/game_over_screen.tscn")

# Called when the node enters the scene tree for the first time.

func load_next_segment(should_position_player=false):
	var segment:MapSegment = segment_scene.instantiate()
	segment.global_position = next_segment_location
	segment.layout_loaded.connect(load_next_segment)
	if should_position_player:
		segment.layout_loaded.connect(segment.position_player)
	add_child(segment)
	next_segment_location.y -= 648
	

func _ready() -> void:
	load_next_segment(true)

func out_of_power() -> void:
	var game_over = game_over_scene.instantiate()
	add_child(game_over)

func _on_player_died() -> void:
	var game_over = game_over_scene.instantiate()
	add_child(game_over)

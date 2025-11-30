extends Node2D
class_name PlayerSpawnLocation

var player_scene = preload("res://scenes/player.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if len(players) > 0:
		pass
	else:
		var player:Player = player_scene.instantiate()
		player.position = self.position 
		add_sibling(player)

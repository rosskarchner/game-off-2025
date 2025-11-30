extends Node2D


var gull_scene = preload("res://scenes/mob.tscn")
var notaduck_scene = preload("res://scenes/mob-notaduck.tscn")

var spawned = false


func spawn(scene:PackedScene):
	var mob = scene.instantiate()
	mob.position = self.position
	add_sibling(mob)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if spawned:
		return
	spawned = true
	var player:Player = get_tree().get_first_node_in_group("player")
	var chance_of_notaduck = (float(player.current_level) /5.0 ) *.20
	if randf() <= chance_of_notaduck:
		spawn(notaduck_scene)
	else:
		spawn(gull_scene) 

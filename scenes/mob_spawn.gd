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
	# Fixed difficulty scaling: caps at 40% instead of 96% at level 24
	# Level 1: 2%, Level 10: 20%, Level 20: 40%, Level 30+: 40%
	var chance_of_notaduck = min(0.4, float(player.current_level) * 0.02)
	if randf() <= chance_of_notaduck:
		spawn(notaduck_scene)
	else:
		spawn(gull_scene) 

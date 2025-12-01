extends Node2D
class_name MapSegment

signal layout_loaded

@export var layout_scenes: Array[PackedScene]
var loaded = false
var layout: Node


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not loaded:
		layout = layout_scenes.pick_random().instantiate()

		# Generate a tilemap color that contrasts well with dark blue background
		var tilemap_color: Color
		while true:
			tilemap_color = Color(randf(), randf(), randf())
			# Ensure sufficient brightness (luminance > 0.3)
			var luminance = 0.299 * tilemap_color.r + 0.587 * tilemap_color.g + 0.114 * tilemap_color.b
			# Avoid colors too similar to dark blue by checking blue channel isn't dominant
			var is_too_blue = tilemap_color.b > 0.6 and tilemap_color.r < 0.4 and tilemap_color.g < 0.4
			if luminance > 0.3 and not is_too_blue:
				break

		layout.get_node("TileMapLayer").modulate=tilemap_color

		loaded = true
		if randf() < 0.5:
			var container = Node2D.new()
			container.scale.x = -1
			container.position.x = 1152
			add_child(container)
			container.add_child(layout)
		else:
			add_child(layout)
		layout_loaded.emit()

func position_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERROR: Player not found in group")
		return
	if not layout:
		print("ERROR: Layout not set")
		return

	var spawn_position = find_spawn_location(layout)
	if spawn_position:
		print("Found spawn position at: ", spawn_position.global_position)
		player.global_position = spawn_position.global_position
		print("Positioned player at: ", player.global_position)
	else:
		print("ERROR: PlayerSpawnLocation not found in layout")

func find_spawn_location(node: Node) -> PlayerSpawnLocation:
	if node is PlayerSpawnLocation:
		return node
	for child in node.get_children():
		var result = find_spawn_location(child)
		if result:
			return result
	return null

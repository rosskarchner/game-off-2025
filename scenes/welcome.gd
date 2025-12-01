extends Node2D

var world_scene=preload("res://scenes/world.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_packed(world_scene)


func screen_shake(intensity: float = 10.0, duration: float = 0.1) -> void:
	"""Quick screen shake effect. intensity controls how far the camera moves, duration controls how long it lasts."""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var original_offset = camera.offset
	var shake_duration = duration / 8.0  # Duration of each shake

	# Create a tween that chains all the shakes together
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	for i in range(8):
		var random_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", original_offset + random_offset, shake_duration)

	# Return to original position
	tween.tween_property(camera, "offset", original_offset, 0.1)

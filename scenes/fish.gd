extends CharacterBody2D
class_name Fish


const SPEED = 300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	

	move_and_slide()


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if is_on_floor():
		var player:Player = get_tree().get_first_node_in_group("player")
		player.remaining_fish_power += 50
		queue_free()

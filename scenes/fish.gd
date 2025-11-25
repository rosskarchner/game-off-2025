extends CharacterBody2D
class_name Fish


const SPEED = 300.0
var free_fall = false


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if free_fall and not is_on_floor():
		velocity += get_gravity() * delta

	

	move_and_slide()

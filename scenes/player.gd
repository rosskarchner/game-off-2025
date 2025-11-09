extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 550.0
const JUMP_VELOCITY = -450.0

var facing: FacingDirections = FacingDirections.Left
var last_direction:float=0.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		last_direction  = direction
		velocity.x = direction * SPEED
		sprite.flip_h = velocity.x > 0
		if direction > 0:
			facing = FacingDirections.Right
		else:
			facing = FacingDirections.Left
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED*delta*6)
		

	move_and_slide()

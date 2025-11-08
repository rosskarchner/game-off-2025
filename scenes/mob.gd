extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite_2d: Sprite2D = $Sprite2D

const SPEED = 400.0
const JUMP_VELOCITY = -550.0

var facing: FacingDirections = FacingDirections.Right
var last_direction:float=0.0

var should_flap:=false
@onready var baseline_height:= global_position.y

func check_flap():
	if global_position.y > baseline_height +75:
		should_flap = true
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if should_flap:
		velocity.y = JUMP_VELOCITY
		should_flap = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	var direction:Vector2
	if facing == FacingDirections.Right:
		direction = Vector2.RIGHT
	else:
		direction = Vector2.LEFT
		

	velocity.x = (direction * SPEED).x
	sprite_2d.flip_h = velocity.x < 0


	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED*delta*6)
		

	move_and_slide()

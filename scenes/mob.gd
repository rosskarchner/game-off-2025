extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite_2d: Sprite2D = $Sprite2D

const SPEED = 400.0
const JUMP_VELOCITY = -550.0

var facing: FacingDirections = FacingDirections.Right
var last_direction:float=0.0

var should_flap:=false
@onready var baseline_height:= global_position.y
@onready var player = get_tree().get_first_node_in_group("player")

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



func _on_bonk_detector_area_entered(_area: Area2D) -> void:
	print("I've been bonked")
	queue_free()


func _on_evaluate_player_position_timeout() -> void:
	var player_distance = global_position.distance_to(player.global_position)
	if player_distance < 300:
		if global_position.y > player.global_position.y:
			baseline_height -= 100
		else:
			baseline_height +=100
		if global_position.x > player.global_position.x:
			facing = FacingDirections.Left
		else:
			facing = FacingDirections.Right
	print(player_distance)

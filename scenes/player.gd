extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var right_visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $Node2D/RightVisibleOnScreenNotifier2D
@onready var left_visible_on_screen_notifier_2d_2: VisibleOnScreenNotifier2D = $Node2D/LeftVisibleOnScreenNotifier2D2

var doppelganger:Sprite2D

const SPEED = 700.0
const JUMP_VELOCITY = -350.0

var min_x=-64
var max_x=1152+32
var facing:FacingDirections= FacingDirections.Right

func setup_doppelganger()->void:
	if doppelganger:
		doppelganger.queue_free()
	doppelganger = Sprite2D.new()
	doppelganger.texture = sprite_2d.texture
	doppelganger.flip_h = sprite_2d.flip_h
	if facing == FacingDirections.Left:
		doppelganger.position = Vector2(1152, sprite_2d.position.y)
	else:
		doppelganger.position = Vector2(-1152, sprite_2d.position.y)
	doppelganger.name = "Doppelganger"
	add_child(doppelganger)	
	

func _process(delta: float) -> void:
	if not doppelganger:
		setup_doppelganger()

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
		velocity.x = direction * SPEED
		sprite_2d.flip_h = velocity.x < 0
		if doppelganger:
			doppelganger.flip_h = sprite_2d.flip_h
		if direction > 0:
			facing = FacingDirections.Right
			doppelganger.position.x = -1152
		else:
			facing = FacingDirections.Left
			doppelganger.position.x = 1152
			
			
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	position.x = clampf(position.x,min_x,max_x)





func _on_right_visible_on_screen_notifier_2d_screen_exited() -> void:
	if facing == FacingDirections.Right:
		position.x = 0


func _on_left_visible_on_screen_notifier_2d_2_screen_exited() -> void:
	if facing == FacingDirections.Left:
		position.x=1152

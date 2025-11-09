extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var jump_cooldown_timer: Timer = $JumpCooldownTimer

const SPEED = 550.0
const JUMP_VELOCITY = -450.0

var facing: FacingDirections = FacingDirections.Left
var last_direction:float=0.0
var grounded:=true
var near_ground:=true
var moving:=false
var did_jump:= false

func update_sprite():
	if sprite.animation == "flap" and sprite.is_playing():
		return
	var where = "grounded" if grounded else "airborne"
	var state ="moving" if moving else "still"
	if not grounded and velocity.y > 0:
		state = "falling"

	sprite.play(where + "-" + state)

func _process(_delta: float) -> void:
	update_sprite()

func _physics_process(delta: float) -> void:
	grounded = is_on_floor()
	near_ground = ground_detector.is_colliding()
	# Add the gravity.
	if not grounded:
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and jump_cooldown_timer.is_stopped():
		velocity.y = JUMP_VELOCITY
		jump_cooldown_timer.start()
		sprite.play("flap")

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
	if grounded:
		velocity.x = move_toward(velocity.x, 0, SPEED*delta*6)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*delta*24)
	moving = !is_zero_approx(velocity.x)	

	move_and_slide()

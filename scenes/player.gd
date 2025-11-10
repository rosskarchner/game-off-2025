extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var flap_cooldown_timer: Timer = $JumpCooldownTimer

## Arcade Joust-style constants
const FORWARD_SPEED = 300.0  ## Constant horizontal movement speed
const FLAP_FORCE = -600.0    ## Upward thrust per flap
const MAX_FALL_SPEED = 600.0 ## Terminal velocity while falling
const GRAVITY_SCALE = 1.8    ## Makes gravity feel heavier/more pressing
const FLAP_COOLDOWN = 0.15   ## Min time between flaps (prevents spam)

var facing: FacingDirections = FacingDirections.Right
var last_direction: float = 1.0
var grounded: bool = true
var near_ground: bool = true
var moving: bool = false

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

	# Apply gravity with terminal velocity FIRST
	if not grounded:
		var gravity = get_gravity().y * GRAVITY_SCALE
		velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, gravity * delta)
	else:
		# Only reset velocity when on ground if not flapping this frame
		if not Input.is_action_just_pressed("ui_accept"):
			velocity.y = 0.0

	# Handle flapping (thrust upward) - happens after gravity so it can override
	if Input.is_action_just_pressed("ui_accept") and flap_cooldown_timer.is_stopped():
		velocity.y = FLAP_FORCE
		flap_cooldown_timer.start()
		sprite.play("flap")

	# Constant forward movement in current facing direction
	var direction_multiplier = 1.0 if facing == FacingDirections.Right else -1.0
	velocity.x = FORWARD_SPEED * direction_multiplier
	sprite.flip_h = facing == FacingDirections.Right

	# Handle direction toggle with left/right input
	if Input.is_action_just_pressed("ui_left"):
		facing = FacingDirections.Left
	elif Input.is_action_just_pressed("ui_right"):
		facing = FacingDirections.Right

	moving = true  ## Always moving forward

	move_and_slide()


func _on_bonking_detector_area_entered(area: Area2D) -> void:
	print("bonk")


func _on_bonked_detector_area_entered(area: Area2D) -> void:
	print("oh no I'm bonked")

extends CharacterBody2D
enum FacingDirections {Right,Left}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var flap_cooldown_timer: Timer = $JumpCooldownTimer
@onready var camera_2d: Camera2D = $Camera2D

var death_scene = preload("res://scenes/player_death.tscn")

## Arcade Joust-style constants
const FLAP_FORCE = -600.0    ## Upward thrust per flap
const MAX_FALL_SPEED = 600.0 ## Terminal velocity while falling
const GRAVITY_SCALE = 1.8    ## Makes gravity feel heavier/more pressing
const FLAP_COOLDOWN = 0.15   ## Min time between flaps (prevents spam)

## Horizontal Movement Constants
const MAX_SPEED = 400.0      ## Maximum horizontal speed
const RUN_ACCEL = 1000.0     ## Acceleration on ground
const RUN_DECEL = 800.0      ## Friction on ground
const AIR_ACCEL = 600.0      ## Acceleration in air (less control)
const AIR_DECEL = 200.0      ## Air resistance (gliding feel)

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

	# Horizontal Movement (Joust-style inertia)
	var target_direction = Input.get_axis("ui_left", "ui_right")
	
	# Determine acceleration/deceleration based on state
	var accel = RUN_ACCEL if grounded else AIR_ACCEL
	var decel = RUN_DECEL if grounded else AIR_DECEL
	
	if target_direction:
		# Accelerate towards target direction
		velocity.x = move_toward(velocity.x, target_direction * MAX_SPEED, accel * delta)
		facing = FacingDirections.Right if target_direction > 0 else FacingDirections.Left
	else:
		# Decelerate (friction/air resistance)
		velocity.x = move_toward(velocity.x, 0, decel * delta)

	sprite.flip_h = facing == FacingDirections.Right
	moving = abs(velocity.x) > 10.0 # Consider moving if speed is significant

	move_and_slide()


func _on_bonking_detector_area_entered(area: Area2D) -> void:
	print("bonk")


func _on_bonked_detector_area_entered(_area: Area2D) -> void:
	var parent = get_parent()
	var death = death_scene.instantiate()
	death.position = position
	parent.add_child(death)
	camera_2d.reparent(death)
	queue_free()
	

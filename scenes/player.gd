extends CharacterBody2D
class_name Player

enum FacingDirections {Right,Left}

signal died
signal out_of_power
signal fish_power_changed(new_value)
signal max_level_changed(new_value)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var flap_cooldown_timer: Timer = $JumpCooldownTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var body_collision_shape_2d: CollisionShape2D = $BodyCollisionShape2D
@onready var bonking_detector: Area2D = $BonkingDetector
@onready var bonked_detector: Area2D = $BonkedDetector

var max_level=1:
	set(new_max_level):
		max_level = new_max_level
		max_level_changed.emit(new_max_level)

var current_level:int:
	get():
		return int(abs(global_position.y-648)/648)+1

var remaining_fish_power = 100.0:
	set(new_value):
		remaining_fish_power = clampf(new_value,-1.0,100.0)
		if remaining_fish_power < 0.0:
			out_of_power.emit()
		fish_power_changed.emit(new_value)
		
func play_flap_sound():
	var player=%FlapSounds.get_children().pick_random()
	player.play()


var death_scene = preload("res://scenes/player_death.tscn")

## Arcade Joust-style constants
const FLAP_FORCE = -700.0    ## Upward thrust per flap (increased from -600 to reduce button mashing)
const MAX_FALL_SPEED = 600.0 ## Terminal velocity while falling
const GRAVITY_SCALE = 1.3    ## Makes gravity feel heavier/more pressing (reduced from 1.8 for better feel)
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

func _ready() -> void:
	# Set up fixed-size bonk detection hitboxes (40px height - small, consistent)
	# This prevents unfair deaths when the physics hitbox changes size
	if bonking_detector:
		for child in bonking_detector.get_children():
			if child is CollisionShape2D:
				if child.shape is RectangleShape2D:
					child.shape.size.y = 40  # Fixed small size

	if bonked_detector:
		for child in bonked_detector.get_children():
			if child is CollisionShape2D:
				if child.shape is RectangleShape2D:
					child.shape.size.y = 40  # Fixed small size

func update_sprite():
	if sprite.animation == "flap" and sprite.is_playing():
		return
	var where = "grounded" if grounded else "airborne"
	var state ="moving" if moving else "still"
	if not grounded and velocity.y > 0:
		state = "falling"

	sprite.play(where + "-" + state)



func _physics_process(delta: float) -> void:
	grounded = is_on_floor()
	near_ground = ground_detector.is_colliding()

	# Update collision shape FIRST, before any physics
	if grounded or near_ground:
		body_collision_shape_2d.shape.size.y = 95
	else:
		body_collision_shape_2d.shape.size.y = 40

	# Apply gravity with terminal velocity FIRST
	if not grounded:
		var gravity = get_gravity().y * GRAVITY_SCALE
		velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, gravity * delta)
	else:
		# Only reset velocity when on ground if not flapping this frame
		if not Input.is_action_just_pressed("ui_accept"):
			velocity.y = 0.0

	# Passive power drain - creates urgency to collect fish
	remaining_fish_power -= 0.5 * delta

	if remaining_fish_power > 0.0:
		# Handle flapping (thrust upward) - happens after gravity so it can override
		if Input.is_action_just_pressed("ui_accept") and flap_cooldown_timer.is_stopped():
			play_flap_sound()
			velocity.y = FLAP_FORCE
			flap_cooldown_timer.start()
			sprite.play("flap")
			remaining_fish_power -= 1.0  # Reduced from 1.6 due to passive drain

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
	else:
		velocity.x = 0.0
	sprite.flip_h = facing == FacingDirections.Right
	moving = abs(velocity.x) > 10.0 # Consider moving if speed is significant

	move_and_slide()

	# Update sprite AFTER physics, so it reflects current state
	update_sprite()


func _on_bonking_detector_area_entered(_area: Area2D) -> void:
	BonkNoises.play()


func _on_bonked_detector_area_entered(_area: Area2D) -> void:
	BonkNoises.play()
	var parent = get_parent()
	var death = death_scene.instantiate()
	death.position = position
	call_deferred("_finalize_death", parent, death)
	died.emit()

func _finalize_death(parent: Node, death: Node) -> void:
	# Validate parent is still valid (could be freed during scene transition)
	if not parent or not is_instance_valid(parent):
		push_error("Player: Parent node invalid during death, using fallback")
		# Use root as fallback
		get_tree().root.add_child(death)
		if camera_2d and is_instance_valid(camera_2d):
			camera_2d.reparent(death)
		queue_free()
		return

	parent.add_child(death)
	camera_2d.reparent(death)
	queue_free()
	


func _on_evaluate_level_timeout() -> void:
	if current_level > max_level:
		max_level = current_level


func _on_walking_sound_timer_timeout() -> void:
	if grounded and moving:
		var walking_sound = $WalkingSounds.get_children().pick_random()
		walking_sound.play()

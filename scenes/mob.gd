extends CharacterBody2D


enum FacingDirections {Right, Left}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

@export var mob_definition: MobDefinition

var facing: FacingDirections = FacingDirections.Right
var baseline_height: float = 0.0
var should_flap: bool = false
var time_alive: float = 0.0

# AI state variables
var target_player = null
var behavior_timer: float = 0.0
var movement_timer: float = 0.0
var current_direction: float = 1.0
var is_pursuing: bool = false
var base_y_position: float = 0.0

func _ready() -> void:
	if not mob_definition:
		push_error("Mob requires a mob_definition to be set")
		queue_free()
		return

	# Apply sprite frames if defined
	if mob_definition.sprite_frames:
		sprite.sprite_frames = mob_definition.sprite_frames

	baseline_height = global_position.y + mob_definition.baseline_height_offset
	base_y_position = global_position.y

func _physics_process(delta: float) -> void:
	if not mob_definition:
		return

	time_alive += delta

	match mob_definition.behavior_type:
		MobDefinition.BehaviorType.SIMPLE:
			update_simple_behavior(delta)
		MobDefinition.BehaviorType.AI_CONTROLLED:
			update_ai_behavior(delta)
		MobDefinition.BehaviorType.SINE_PATROL:
			update_sine_patrol_behavior(delta)

	move_and_slide()

## Simple behavior: target-seeking with flapping
func update_simple_behavior(delta: float) -> void:
	# Add gravity (only if gravity_multiplier is > 0)
	if not is_on_floor():
		if mob_definition.gravity_multiplier > 0:
			velocity.y += get_gravity().y * mob_definition.gravity_multiplier * delta
		else:
			velocity.y = 0  # No gravity, maintain height

	# Handle flap
	if should_flap:
		velocity.y = mob_definition.flap_strength
		should_flap = false

	# Check if we need to flap
	if global_position.y > baseline_height + (mob_definition.height_adjustment_range * 1.5):
		should_flap = true

	# Horizontal movement
	var direction = Vector2.RIGHT if facing == FacingDirections.Right else Vector2.LEFT
	velocity.x = (direction * mob_definition.horizontal_speed).x
	sprite.flip_h = velocity.x > 0

	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, mob_definition.horizontal_speed * delta * 6)

## AI-controlled behavior with PATROL/AGGRESSIVE/DEFENSIVE/RANDOM modes
func update_ai_behavior(delta: float) -> void:
	# Add gravity (only if gravity_multiplier is > 0)
	if not is_on_floor():
		if mob_definition.gravity_multiplier > 0:
			velocity.y += get_gravity().y * mob_definition.gravity_multiplier * delta
		else:
			velocity.y = 0  # No gravity, maintain height

	behavior_timer += delta

	# Make decisions at intervals
	if behavior_timer >= mob_definition.reaction_time:
		behavior_timer = 0.0
		decide_ai_action()

	# Handle horizontal movement
	var direction = Vector2.RIGHT if current_direction > 0 else Vector2.LEFT
	velocity.x = direction.x * mob_definition.horizontal_speed
	sprite.flip_h = velocity.x > 0

	# Handle flapping for AI behaviors
	if should_flap:
		velocity.y = mob_definition.flap_strength
		should_flap = false

	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, mob_definition.horizontal_speed * delta * 6)

## Sine wave patrol with pursuit (Pterodactyl style)
func update_sine_patrol_behavior(delta: float) -> void:
	target_player = find_target_player()

	if target_player and target_player.is_alive:
		pursue_player(delta)
	else:
		patrol_sine_wave(delta)

func patrol_sine_wave(_delta: float) -> void:
	is_pursuing = false

	# Fly in a sine wave pattern
	var sine_offset = sin(time_alive * mob_definition.sine_wave_frequency) * mob_definition.sine_wave_amplitude
	velocity.x = mob_definition.flight_speed
	velocity.y = (base_y_position + sine_offset - global_position.y) * 2.0

func pursue_player(delta: float) -> void:
	is_pursuing = true

	if target_player == null:
		return

	# Accelerate toward player
	var direction_to_player = (target_player.global_position - global_position).normalized()
	velocity = direction_to_player * mob_definition.pursuit_speed

	# Add slight sine wave to make movement less predictable
	var sine_offset = sin(time_alive * mob_definition.sine_wave_frequency * 1.5) * (mob_definition.sine_wave_amplitude * 0.5)
	velocity.y += sine_offset * delta * 60.0

	# Check if close enough to grab
	var distance_to_player = global_position.distance_to(target_player.global_position)
	if distance_to_player <= mob_definition.grab_range:
		grab_player(target_player)

func decide_ai_action() -> void:
	target_player = find_target_player()

	match mob_definition.ai_behavior:
		MobDefinition.AIBehavior.AGGRESSIVE:
			decide_aggressive_action()
		MobDefinition.AIBehavior.DEFENSIVE:
			decide_defensive_action()
		MobDefinition.AIBehavior.PATROL:
			decide_patrol_action()
		MobDefinition.AIBehavior.RANDOM:
			decide_random_action()

func decide_aggressive_action() -> void:
	if target_player == null or not target_player.is_alive:
		current_direction = 1.0 if randf() > 0.5 else -1.0
		return

	# Move toward player
	var direction_to_player = sign(target_player.global_position.x - global_position.x)
	current_direction = direction_to_player

	# Flap to match or exceed player height
	if target_player.global_position.y < global_position.y - 20:
		should_flap = true

func decide_defensive_action() -> void:
	if target_player == null or not target_player.is_alive:
		current_direction = 1.0 if randf() > 0.5 else -1.0
		return

	var distance_to_player = global_position.distance_to(target_player.global_position)

	if distance_to_player < mob_definition.attack_range:
		# Too close - maintain height advantage and back off
		if target_player.global_position.y < global_position.y:
			should_flap = true
		# Occasionally reverse direction
		if randf() < 0.3:
			current_direction *= -1
	else:
		# Patrol normally
		if randf() < 0.1:
			current_direction *= -1

func decide_patrol_action() -> void:
	# Simple patrol with occasional flapping
	if randf() < 0.05:
		current_direction *= -1

	if randf() < mob_definition.flap_frequency:
		should_flap = true

func decide_random_action() -> void:
	# Erratic behavior
	if randf() < 0.2:
		current_direction = 1.0 if randf() > 0.5 else -1.0

	if randf() < 0.4:
		should_flap = true

func find_target_player():
	if not player:
		return null

	var distance = global_position.distance_to(player.global_position)

	# For simple behavior, use detection range to decide if we should track player
	if mob_definition.behavior_type == MobDefinition.BehaviorType.SIMPLE:
		if distance < mob_definition.detection_range:
			# Adjust baseline height based on player position
			if global_position.y > player.global_position.y:
				baseline_height -= mob_definition.height_adjustment_range
			else:
				baseline_height += mob_definition.height_adjustment_range

			# Turn toward player
			if global_position.x > player.global_position.x:
				facing = FacingDirections.Left
			else:
				facing = FacingDirections.Right
			return player

	# For AI behaviors, just find nearest player in range
	if distance <= mob_definition.detection_range:
		return player

	return null

func grab_player(p_player) -> void:
	if p_player and p_player.is_alive:
		p_player.take_damage(999)  # Instant kill

func _on_bonk_detector_area_entered(_area: Area2D) -> void:
	print("I've been bonked")
	queue_free()

func _on_evaluate_player_position_timeout() -> void:
	# Legacy timer - can be used if still in scene
	find_target_player()

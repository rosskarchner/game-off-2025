extends CharacterBody2D


enum FacingDirections {Right, Left}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var fish_sprite: Sprite2D = $FishSprite

var fish_scene = preload("res://scenes/fish.tscn")

@export var mob_definition: MobDefinition

var facing: FacingDirections = FacingDirections.Right
var baseline_height: float = 0.0
var should_flap: bool = false
var time_alive: float = 0.0
var is_in_flipped_parent: bool = false

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

	# Check if we're in a flipped parent (check up the hierarchy)
	var current = get_parent()
	while current:
		if current is Node2D and current.scale.x < 0:
			is_in_flipped_parent = true
			break
		current = current.get_parent()

	# Apply sprite frames if defined
	if mob_definition.sprite_frames:
		sprite.sprite_frames = mob_definition.sprite_frames

	baseline_height = global_position.y + mob_definition.baseline_height_offset
	base_y_position = global_position.y

	# Adjust baseline height if spawned too close to ceiling/floor
	adjust_baseline_height_to_safe_space()

	# Set baseline well above spawn so mob will naturally fly upward
	baseline_height = global_position.y - (mob_definition.height_adjustment_range * 2.0)

	print("Mob baseline_height: ", baseline_height, " global_position.y: ", global_position.y, " spawn offset: ", mob_definition.baseline_height_offset)

	# Start with an upward impulse to get the mob moving
	should_flap = true

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

	# Prevent pushing through walls
	prevent_wall_penetration()

	# Reset arc of flight if constrained by collision
	reset_arc_on_constraint()

	# Change direction if hit a wall
	handle_wall_collision()

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
		sprite.play("flap")
		should_flap = false

	# Dynamically adjust flap range based on available space
	var safe_range = get_safe_amplitude()

	# Check if we need to flap
	if global_position.y > baseline_height + (safe_range * 1.5):
		should_flap = true

	# Escape from ceiling by forcing downward movement away from it
	if is_on_ceiling():
		# Force a downward velocity (positive Y) to push away from ceiling
		# Flap strength is negative (upward), so negate it to push downward
		velocity.y = -mob_definition.flap_strength * 0.5  # Positive value pushing downward
		should_flap = false  # Don't flap while on ceiling
		if time_alive < 5.0:  # Debug: only print for first 5 seconds
			print("CEILING DETECTED - forcing downward, velocity.y: ", velocity.y)

	# Update baseline_height if we've moved to a new floor level
	if is_on_floor():
		# Keep baseline slightly above current floor
		baseline_height = global_position.y - mob_definition.height_adjustment_range
		# Don't let baseline stay locked to spawn point - allow upward movement
		if global_position.y < baseline_height + mob_definition.height_adjustment_range:
			baseline_height = global_position.y - mob_definition.height_adjustment_range

	# Debug: Print flap info once when on ground
	if is_on_floor() and time_alive < 0.1:
		print("On floor - baseline: ", baseline_height, " pos.y: ", global_position.y, " safe_range: ", safe_range, " should_flap: ", should_flap)

	# Horizontal movement
	var direction = Vector2.RIGHT if facing == FacingDirections.Right else Vector2.LEFT
	if is_in_flipped_parent:
		direction = -direction
	velocity.x = (direction * mob_definition.horizontal_speed).x
	sprite.flip_h = facing == FacingDirections.Right

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
	if is_in_flipped_parent:
		direction = -direction
	velocity.x = direction.x * mob_definition.horizontal_speed
	sprite.flip_h = current_direction > 0

	# Continuous height maintenance for AI mobs with targets
	if target_player and is_instance_valid(target_player):
		if mob_definition.ai_behavior == MobDefinition.AIBehavior.DEFENSIVE:
			var desired_height = target_player.global_position.y - 150.0
			if global_position.y > desired_height:
				should_flap = true
		elif mob_definition.ai_behavior == MobDefinition.AIBehavior.AGGRESSIVE:
			var desired_height = target_player.global_position.y - 100.0
			if global_position.y > desired_height:
				should_flap = true

	# Escape from ceiling by forcing downward movement
	if is_on_ceiling():
		velocity.y = -mob_definition.flap_strength * 0.5  # Positive value pushing downward
		should_flap = false  # Don't flap while on ceiling
	# Handle flapping for AI behaviors
	elif should_flap:
		velocity.y = mob_definition.flap_strength
		should_flap = false

	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, mob_definition.horizontal_speed * delta * 6)

## Sine wave patrol with pursuit (Pterodactyl style)
func update_sine_patrol_behavior(delta: float) -> void:
	target_player = find_target_player()

	if target_player and is_instance_valid(target_player):
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
	if target_player == null or not is_instance_valid(target_player):
		current_direction = 1.0 if randf() > 0.5 else -1.0
		return

	# Move toward player
	var direction_to_player = sign(target_player.global_position.x - global_position.x)
	current_direction = direction_to_player

	# Try to stay above the player for an advantage
	var desired_height = target_player.global_position.y - 100.0  # 100 pixels above player
	if global_position.y > desired_height:
		should_flap = true

func decide_defensive_action() -> void:
	if target_player == null or not is_instance_valid(target_player):
		current_direction = 1.0 if randf() > 0.5 else -1.0
		return

	var distance_to_player = global_position.distance_to(target_player.global_position)

	# Always try to stay above the player
	var desired_height = target_player.global_position.y - 150.0  # 150 pixels above player

	if global_position.y > desired_height:
		# Below desired height, flap to go up
		should_flap = true
		if time_alive < 2.0:
			print("Hunter flapping: mob at y=", global_position.y, " desired=", desired_height)

	if distance_to_player < mob_definition.attack_range:
		# Too close - back off horizontally
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

func reset_arc_on_constraint() -> void:
	# If moving upward and hit something, reset baseline to current position
	if velocity.y < 0 and is_on_ceiling():
		baseline_height = global_position.y
		velocity.y = 0
		should_flap = false
	# If hit a wall while moving upward, also reset
	elif velocity.y < 0 and is_on_wall():
		baseline_height = global_position.y
		velocity.y = 0
		should_flap = false

func prevent_wall_penetration() -> void:
	# If pushed into a wall, try to push back out
	if is_on_wall():
		# Get the wall normal and push away from it
		var push_direction = get_wall_normal()
		# Move slightly away from the wall to prevent sticking
		global_position += push_direction * 2.0
		# Stop horizontal velocity to prevent re-penetration
		velocity.x = 0

func handle_wall_collision() -> void:
	# Change direction if the mob hits a wall
	if is_on_wall():
		match mob_definition.behavior_type:
			MobDefinition.BehaviorType.SIMPLE:
				facing = FacingDirections.Left if facing == FacingDirections.Right else FacingDirections.Right
			MobDefinition.BehaviorType.AI_CONTROLLED:
				current_direction *= -1.0

func adjust_baseline_height_to_safe_space() -> void:
	# Check if there's enough space above and below the baseline
	var space_state = get_world_2d().direct_space_state
	var probe_distance = mob_definition.height_adjustment_range * 2.0

	# Check space above baseline
	var query_up = PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x, baseline_height),
		Vector2(global_position.x, baseline_height - probe_distance)
	)
	var result_up = space_state.intersect_ray(query_up)
	var space_above = probe_distance if not result_up else (Vector2(global_position.x, baseline_height) - result_up.position).length()

	# Check space below baseline
	var query_down = PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x, baseline_height),
		Vector2(global_position.x, baseline_height + probe_distance)
	)
	var result_down = space_state.intersect_ray(query_down)
	var space_below = probe_distance if not result_down else (result_down.position - Vector2(global_position.x, baseline_height)).length()

	# If not enough space, shift baseline to center of available space
	if space_above < mob_definition.height_adjustment_range or space_below < mob_definition.height_adjustment_range:
		var shift = (space_below - space_above) / 2.0
		baseline_height += shift

func get_safe_amplitude() -> float:
	# Use a raycast to detect available space above and below
	var space_state = get_world_2d().direct_space_state
	var default_range = mob_definition.height_adjustment_range

	# Cast upward
	var query_up = PhysicsRayQueryParameters2D.create(global_position, global_position - Vector2(0, default_range * 3))
	var result_up = space_state.intersect_ray(query_up)
	var space_above = default_range * 3 if not result_up else (global_position - result_up.position).length()

	# Cast downward
	var query_down = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, default_range * 3))
	var result_down = space_state.intersect_ray(query_down)
	var space_below = default_range * 3 if not result_down else (result_down.position - global_position).length()

	# Return the smaller of the available space and default range
	var available = minf(space_above, space_below)
	return minf(available / 2.0, default_range)

func find_target_player():
	if not player:
		return null

	var distance = global_position.distance_to(player.global_position)

	# For simple behavior, use detection range to decide if we should track player
	if mob_definition.behavior_type == MobDefinition.BehaviorType.SIMPLE:
		if distance < mob_definition.detection_range and has_line_of_sight(player):
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

	# For AI behaviors, just find nearest player in range (with line of sight check)
	if distance <= mob_definition.detection_range:
		var has_sight = has_line_of_sight(player)
		if time_alive < 2.0:
			print("Hunter: distance=", distance, " in_range=", distance <= mob_definition.detection_range, " has_los=", has_sight)
		if has_sight:
			return player

	return null

func has_line_of_sight(target: Node2D) -> bool:
	"""Check if there's a clear line of sight to the target."""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	# Ignore the mob itself and the target in the raycast
	query.exclude = [self, target]
	# Only check collision with STATIC layer (walls), not floors/platforms
	query.collision_mask = 1  # Layer 1 is STATIC
	var result = space_state.intersect_ray(query)
	# If no collision, we have line of sight
	return result == null

func grab_player(p_player) -> void:
	if p_player and is_instance_valid(p_player):
		p_player.queue_free()  # Instant kill

func _on_bonk_detector_area_entered(_area: Area2D) -> void:
	var fish:Fish = fish_scene.instantiate()
	fish.position = position
	call_deferred("add_sibling", fish)
	call_deferred("queue_free")

func _on_evaluate_player_position_timeout() -> void:
	# Legacy timer - can be used if still in scene
	find_target_player()

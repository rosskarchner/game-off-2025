extends CharacterBody2D
class_name Fish


const SPEED = 300.0
var has_landed = false
@onready var slurp: AudioStreamPlayer = $Slurp
var is_being_picked_up = false
var already_picked_up = false
var pickup_start_time = 0.0
const PICKUP_DURATION = 0.25
var wiggle_material: Material


func _ready() -> void:
	# Create and apply wiggle shader material
	var shader = load("res://scenes/fish_wiggle.gdshader")
	wiggle_material = ShaderMaterial.new()
	wiggle_material.shader = shader
	material = wiggle_material


func _physics_process(delta: float) -> void:
	# While being picked up, move towards the FishHole
	if is_being_picked_up:
		var fish_hole = get_tree().get_first_node_in_group("FishHole")
		if fish_hole:
			# Lerp towards FishHole position
			var elapsed = Time.get_ticks_msec() / 1000.0 - pickup_start_time
			var progress = min(elapsed / PICKUP_DURATION, 1.0)

			# Shrink and move to fish hole
			scale = lerp(Vector2.ONE, Vector2.ZERO, progress)
			global_position = global_position.lerp(fish_hole.global_position, progress * 0.1)
		# Stop wiggling while being picked up
		if wiggle_material:
			wiggle_material.set_shader_parameter("is_wiggling", false)
		return

	if has_landed:
		# Only wiggle when on the ground
		if wiggle_material:
			wiggle_material.set_shader_parameter("is_wiggling", is_on_floor())
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	# Check for player overlap when fish first lands
	if is_on_floor() and not has_landed:
		has_landed = true
		check_player_overlap()


func check_player_overlap() -> void:
	# Check if player is already overlapping the pickup area
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		# Use a generous overlap check (fish pickup radius)
		if distance < 50:  # Adjust this value based on your collision shapes
			pickup_fish(player)

func pickup_fish(player: Player) -> void:
	# Guard: prevent multiple pickups
	if already_picked_up:
		return
	already_picked_up = true

	slurp.play()
	var fish_hole = get_tree().get_first_node_in_group("FishHole")
	if not fish_hole:
		print("ERROR: FishHole not found in any group")
		player.remaining_fish_power += 50
		queue_free()
		return

	print("Found FishHole, starting pickup animation")
	is_being_picked_up = true
	pickup_start_time = Time.get_ticks_msec() / 1000.0
	player.remaining_fish_power += 50
	await slurp.finished
	queue_free()

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if is_on_floor():
		var player:Player = get_tree().get_first_node_in_group("player")
		if player:
			pickup_fish(player)

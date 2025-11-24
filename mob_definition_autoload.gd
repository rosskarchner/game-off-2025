## Auto-generates mob definition resources on startup if they don't exist
extends Node

const MobDefinition = preload("res://resources/mob_definition.gd")


func _ready() -> void:
	# Only generate if in editor
	if not Engine.is_editor_hint():
		return

	var definitions_dir = "res://resources/mob_definitions/"

	# Create directory if it doesn't exist
	var dir_path = definitions_dir.trim_suffix("/")
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Creating mob_definitions directory...")
		DirAccess.make_dir_absolute(dir_path)

	# Check if any definitions already exist
	var has_definitions = false
	var dir = DirAccess.open(definitions_dir)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				has_definitions = true
				break
			file = dir.get_next()
		dir.list_dir_end()

	# If we already have definitions, don't regenerate
	if has_definitions:
		print("Mob definitions already exist, skipping generation")
		return

	print("Generating mob definition resources...")
	generate_mob_definitions()

func generate_mob_definitions() -> void:
	"""Generate all mob definition .tres files."""
	var definitions = [
		{
			"path": "res://resources/mob_definitions/gull_simple.tres",
			"mob_name": "Gull",
			"point_value": 100,
			"max_health": 1,
			"horizontal_speed": 400.0,
			"flap_strength": -550.0,
			"flap_cooldown": 0.11,
			"gravity_multiplier": 1.0,
			"behavior_type": 0,
			"detection_range": 300.0,
			"reaction_time": 1.5,
			"height_adjustment_range": 50.0,
		},
		{
			"path": "res://resources/mob_definitions/bounder_patrol.tres",
			"mob_name": "Bounder",
			"point_value": 500,
			"max_health": 1,
			"horizontal_speed": 120.0,
			"flap_strength": -280.0,
			"flap_cooldown": 0.2,
			"gravity_multiplier": 0.94,
			"behavior_type": 1,
			"ai_behavior": 2,
			"detection_range": 300.0,
			"reaction_time": 0.5,
			"attack_range": 200.0,
			"flap_frequency": 0.3,
		},
		{
			"path": "res://resources/mob_definitions/hunter_defensive.tres",
			"mob_name": "Hunter",
			"point_value": 750,
			"max_health": 1,
			"horizontal_speed": 150.0,
			"flap_strength": -310.0,
			"flap_cooldown": 0.16,
			"gravity_multiplier": 0.93,
			"behavior_type": 1,
			"ai_behavior": 1,
			"detection_range": 350.0,
			"reaction_time": 0.35,
			"attack_range": 200.0,
			"flap_frequency": 0.35,
		},
		{
			"path": "res://resources/mob_definitions/shadow_aggressive.tres",
			"mob_name": "ShadowLord",
			"point_value": 1000,
			"max_health": 1,
			"horizontal_speed": 190.0,
			"flap_strength": -340.0,
			"flap_cooldown": 0.13,
			"gravity_multiplier": 0.92,
			"behavior_type": 1,
			"ai_behavior": 0,
			"detection_range": 450.0,
			"reaction_time": 0.2,
			"attack_range": 200.0,
			"flap_frequency": 0.4,
		},
		{
			"path": "res://resources/mob_definitions/pterodactyl.tres",
			"mob_name": "Pterodactyl",
			"point_value": 0,
			"max_health": 999,
			"horizontal_speed": 400.0,
			"flap_strength": -550.0,
			"flap_cooldown": 0.11,
			"gravity_multiplier": 0.0,
			"behavior_type": 2,
			"detection_range": 800.0,
			"sine_wave_amplitude": 50.0,
			"sine_wave_frequency": 2.0,
			"flight_speed": 220.0,
			"pursuit_speed": 280.0,
			"grab_range": 30.0,
		},
	]

	for def_data in definitions:
		var path: String = def_data["path"]
		var definition = MobDefinition.new()

		# Set all properties from the definition data
		for key in def_data:
			if key != "path":
				definition.set(key, def_data[key])

		# Save the resource
		var result = ResourceSaver.save(definition, path)
		if result == OK:
			print("✓ Created: ", path)
		else:
			print("✗ Failed to create: ", path, " (error: ", error_string(result), ")")

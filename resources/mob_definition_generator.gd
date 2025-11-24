## Utility script to generate mob definition resources
## Run this once to create all the mob definition .tres files properly
extends Node

const MobDefinition = preload("res://resources/mob_definition.gd")

static func generate_all() -> void:
	"""Generate all mob definition resources."""
	var definitions = [
		{
			"path": "res://resources/mob_definitions/gull_simple.tres",
			"name": "Gull",
			"point_value": 100,
			"max_health": 1,
			"horizontal_speed": 400.0,
			"flap_strength": -550.0,
			"flap_cooldown": 0.11,
			"gravity_multiplier": 1.0,
			"behavior_type": 0,  # SIMPLE
			"detection_range": 300.0,
			"reaction_time": 1.5,
			"height_adjustment_range": 50.0,
		},
		{
			"path": "res://resources/mob_definitions/bounder_patrol.tres",
			"name": "Bounder",
			"point_value": 500,
			"max_health": 1,
			"horizontal_speed": 120.0,
			"flap_strength": -280.0,
			"flap_cooldown": 0.2,
			"gravity_multiplier": 0.94,
			"behavior_type": 1,  # AI_CONTROLLED
			"ai_behavior": 2,  # PATROL
			"detection_range": 300.0,
			"reaction_time": 0.5,
			"attack_range": 200.0,
			"flap_frequency": 0.3,
		},
		{
			"path": "res://resources/mob_definitions/hunter_defensive.tres",
			"name": "Hunter",
			"point_value": 750,
			"max_health": 1,
			"horizontal_speed": 150.0,
			"flap_strength": -310.0,
			"flap_cooldown": 0.16,
			"gravity_multiplier": 0.93,
			"behavior_type": 1,  # AI_CONTROLLED
			"ai_behavior": 1,  # DEFENSIVE
			"detection_range": 350.0,
			"reaction_time": 0.35,
			"attack_range": 200.0,
			"flap_frequency": 0.35,
		},
		{
			"path": "res://resources/mob_definitions/shadow_aggressive.tres",
			"name": "ShadowLord",
			"point_value": 1000,
			"max_health": 1,
			"horizontal_speed": 190.0,
			"flap_strength": -340.0,
			"flap_cooldown": 0.13,
			"gravity_multiplier": 0.92,
			"behavior_type": 1,  # AI_CONTROLLED
			"ai_behavior": 0,  # AGGRESSIVE
			"detection_range": 450.0,
			"reaction_time": 0.2,
			"attack_range": 200.0,
			"flap_frequency": 0.4,
		},
		{
			"path": "res://resources/mob_definitions/pterodactyl.tres",
			"name": "Pterodactyl",
			"point_value": 0,
			"max_health": 999,
			"horizontal_speed": 400.0,
			"flap_strength": -550.0,
			"flap_cooldown": 0.11,
			"gravity_multiplier": 0.0,
			"behavior_type": 2,  # SINE_PATROL
			"detection_range": 800.0,
			"sine_wave_amplitude": 50.0,
			"sine_wave_frequency": 2.0,
			"flight_speed": 220.0,
			"pursuit_speed": 280.0,
			"grab_range": 30.0,
		},
	]

	for def_data in definitions:
		var path = def_data["path"]
		var definition = MobDefinition.new()

		# Set all properties from the definition data
		for key in def_data:
			if key != "path" and definition.has_meta("_prop_" + key) or key in definition:
				definition.set(key, def_data[key])

		# Save the resource
		var result = ResourceSaver.save(definition, path)
		if result == OK:
			print("✓ Created: ", path)
		else:
			print("✗ Failed to create: ", path, " (error code: ", result, ")")

# Call this in the editor to generate the resources
static func generate_from_editor() -> void:
	"""Call this from the editor console to generate mob definitions."""
	print("Generating mob definition resources...")
	generate_all()
	print("Done!")

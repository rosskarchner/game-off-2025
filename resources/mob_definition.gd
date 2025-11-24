extends Resource

class_name MobDefinition

## Resource for defining mob behavior, movement, and appearance
## Can be used to configure any flying bird enemy with various behavior modes

enum BehaviorType {
	SIMPLE,              # Basic target-seeking (current mob.gd style)
	AI_CONTROLLED,       # Advanced AI with behavior modes (PATROL, AGGRESSIVE, etc.)
	SINE_PATROL,         # Sine wave patrol with pursuit mode (Pterodactyl style)
	STATIONARY_HAZARD    # Stationary enemy (LavaTroll style)
}

enum AIBehavior {
	AGGRESSIVE,  # Actively pursues player
	DEFENSIVE,   # Maintains distance, cautious
	PATROL,      # Follows set patterns
	RANDOM       # Erratic movement
}

## Basic Properties
@export var mob_name: String = "Bird"
@export var sprite_frames: SpriteFrames
@export var point_value: int = 100
@export var max_health: int = 1

## Movement Parameters
@export var horizontal_speed: float = 400.0
@export var flap_strength: float = -550.0
@export var flap_cooldown: float = 0.11
@export var gravity_multiplier: float = 1.0
@export var max_fall_speed: float = 0.0  # 0.0 means no limit

## Behavior Configuration
@export var behavior_type: BehaviorType = BehaviorType.SIMPLE
@export var ai_behavior: AIBehavior = AIBehavior.PATROL

## Detection and Reaction Parameters
@export var detection_range: float = 300.0
@export var reaction_time: float = 1.5
@export var attack_range: float = 200.0

## Advanced Flight Parameters (for SINE_PATROL behavior)
@export var sine_wave_amplitude: float = 50.0
@export var sine_wave_frequency: float = 2.0
@export var pursuit_speed: float = 280.0
@export var flight_speed: float = 220.0
@export var grab_range: float = 30.0

## Flap Parameters (for AI-controlled behavior)
@export var flap_frequency: float = 0.3  # Probability of flapping per decision

## Baseline height parameters
@export var baseline_height_offset: float = 0.0
@export var height_adjustment_range: float = 50.0  # How much to adjust baseline on detection

func _init(
	p_mob_name: String = "Bird",
	p_sprite_frames: SpriteFrames = null,
	p_point_value: int = 100,
	p_horizontal_speed: float = 400.0,
	p_flap_strength: float = -550.0,
	p_behavior_type: BehaviorType = BehaviorType.SIMPLE
) -> void:
	mob_name = p_mob_name
	sprite_frames = p_sprite_frames
	point_value = p_point_value
	horizontal_speed = p_horizontal_speed
	flap_strength = p_flap_strength
	behavior_type = p_behavior_type

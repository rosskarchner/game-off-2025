extends Node2D
## WrappingController handles screen wrapping for any Node2D with a Sprite2D
## Add this as a child to any node that needs wrap-around functionality

class_name WrappingController

@export var world_width: float = 1152.0
@export var show_doppelganger_threshold: float = 200.0  ## Distance from edge to show doppelganger

var doppelganger: Sprite2D
var parent_sprite: Sprite2D


func _ready() -> void:
	# Get reference to parent's sprite
	parent_sprite = get_parent().find_child("Sprite2D", true, false)

	if not parent_sprite:
		push_warning("WrappingController: No Sprite2D found on parent node")
		return

	# Create doppelganger sprite
	_create_doppelganger()


func _process(delta: float) -> void:
	if not parent_sprite or not doppelganger:
		return

	# Update doppelganger position relative to parent
	_update_doppelganger()

	# Check if we need to wrap
	_check_and_wrap()


func _create_doppelganger() -> void:
	doppelganger = Sprite2D.new()
	doppelganger.texture = parent_sprite.texture
	doppelganger.flip_h = parent_sprite.flip_h
	doppelganger.flip_v = parent_sprite.flip_v
	doppelganger.scale = parent_sprite.scale
	doppelganger.name = "Doppelganger"
	add_child(doppelganger)


func _update_doppelganger() -> void:
	if not doppelganger or not parent_sprite:
		return

	var parent = get_parent()
	var parent_global_x = parent.global_position.x

	# Sync sprite properties
	doppelganger.texture = parent_sprite.texture
	doppelganger.flip_h = parent_sprite.flip_h
	doppelganger.flip_v = parent_sprite.flip_v
	doppelganger.scale = parent_sprite.scale

	# Position doppelganger on the opposite side
	# Determine which side of screen we're closer to
	var wrapped_x = wrapf(parent_global_x, 0, world_width)
	var distance_to_right = world_width - wrapped_x
	var distance_to_left = wrapped_x

	if distance_to_right < show_doppelganger_threshold:
		# Near right edge, show doppelganger on left
		doppelganger.visible = true
		doppelganger.global_position = parent.global_position - Vector2(world_width, 0)
	elif distance_to_left < show_doppelganger_threshold:
		# Near left edge, show doppelganger on right
		doppelganger.visible = true
		doppelganger.global_position = parent.global_position + Vector2(world_width, 0)
	else:
		# Far from edges, hide doppelganger
		doppelganger.visible = false


func _check_and_wrap() -> void:
	var parent = get_parent()
	var parent_x = parent.global_position.x

	# Wrap position using wrapf (more reliable than fmod)
	parent.global_position.x = wrapf(parent_x, 0, world_width)


func wrap_position(pos: Vector2) -> Vector2:
	## Public method to wrap a position (useful for wrapping other objects)
	var wrapped_x = fmod(pos.x, world_width)
	if wrapped_x < 0:
		wrapped_x += world_width
	return Vector2(wrapped_x, pos.y)

extends CanvasLayer

@onready var message: Label = %Message

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player:Player = get_tree().get_first_node_in_group("player")
	if player.remaining_fish_power < 0.0:
		message.text = "You ran out of fish power. This is how birds work."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()

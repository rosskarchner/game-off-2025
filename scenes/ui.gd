extends CanvasLayer

@onready var progress_bar: ProgressBar = $HBoxContainer2/ProgressBar


func _on_player_fish_power_changed(new_value):
	progress_bar.value = new_value

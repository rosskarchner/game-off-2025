extends CanvasLayer

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var max_level_field: Label = %MaxLevelField


func _on_player_fish_power_changed(new_value):
	progress_bar.value = new_value

func _on_player_max_level_changed(new_value: Variant) -> void:
	max_level_field.text = str(new_value)

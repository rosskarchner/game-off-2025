extends Node

func play():
	var players=get_children()
	var audio_player = players.pick_random()
	# Add pitch variation to reduce repetitiveness
	audio_player.pitch_scale = randf_range(0.9, 1.1)
	audio_player.play()

extends Node

func play():
	var players=get_children()
	players.pick_random().play()

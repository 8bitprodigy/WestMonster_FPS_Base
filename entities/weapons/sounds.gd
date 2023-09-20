extends Node3D

func play(sound_name:String):
	get_node(sound_name).play()
	pass

func sound(sound_name:String):
	return get_node(sound_name)

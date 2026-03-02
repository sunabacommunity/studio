extends RefCounted

func loadDress1() -> Node3D:
	var dressScene : PackedScene = load("res://Engine/FemaleDresses/DressRig1.tscn")
	return dressScene.instantiate()

func loadDress2() -> Node3D:
	var dressScene : PackedScene = load("res://Engine/FemaleDresses/DressRig2.tscn")
	return dressScene.instantiate()

func loadDress3() -> Node3D:
	var dressScene : PackedScene = load("res://Engine/FemaleDresses/DressRig3.tscn")
	return dressScene.instantiate()

func loadDress4() -> Node3D:
	var dressScene : PackedScene = load("res://Engine/FemaleDresses/DressRig4.tscn")
	return dressScene.instantiate()

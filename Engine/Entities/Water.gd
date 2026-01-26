extends Area3D
class_name Water

var isWater: bool = true
@onready var splashAudioStream: AudioStream = load("res://Engine/Entities/splash.ogg")
@onready var swirlAudioStream: AudioStream = load("res://Engine/Entities/swirl.ogg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func awake():
	pass
	
func on_body_entered(body: Node3D):
	if body is CharacterBody3D:
		var splashAudioStreamPlayer := AudioStreamPlayer.new()
		splashAudioStreamPlayer.stream = splashAudioStream
		add_child(splashAudioStreamPlayer)
		splashAudioStreamPlayer.finished.connect(func():
			splashAudioStreamPlayer.queue_free()
		)
		splashAudioStreamPlayer.play()

func on_body_exited(body: Node3D):
	if body is CharacterBody3D:
		var swirlAudioStreamPlayer := AudioStreamPlayer.new()
		swirlAudioStreamPlayer.stream = swirlAudioStream
		add_child(swirlAudioStreamPlayer)
		swirlAudioStreamPlayer.finished.connect(func():
			swirlAudioStreamPlayer.queue_free()
		)
		swirlAudioStreamPlayer.play()

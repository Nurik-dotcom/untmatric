extends Node

var sounds = {
	"click": load("res://audio/click.wav"),
	"relay": load("res://audio/relay.wav"),
	"error": load("res://audio/error.wav")
}

func play(sound_name: String):
	if sounds.has(sound_name):
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = sounds[sound_name]
		player.play()
		player.finished.connect(player.queue_free)

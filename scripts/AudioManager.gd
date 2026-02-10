extends Node

var sounds = {
	"click": load("res://audio/click.wav"),
	"relay": load("res://audio/relay.wav"),
	"error": load("res://audio/error.wav")
}

var pool = []

func play(sound_name: String):
	if sounds.has(sound_name):
		play_stream(sounds[sound_name])

func play_stream(stream: AudioStream):
	var player = _get_available_player()
	player.stream = stream
	player.play()

func _get_available_player() -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player

	var player = AudioStreamPlayer.new()
	add_child(player)
	pool.append(player)
	return player

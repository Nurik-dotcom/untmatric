extends Node

const POOL_SIZE := 8

var sounds = {
	"click": load("res://audio/click.wav"),
	"relay": load("res://audio/relay.wav"),
	"error": load("res://audio/error.wav")
}

var _pool: Array[AudioStreamPlayer] = []
var _next_index: int = 0

func _ready() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)

func play(sound_name: String) -> void:
	if not sounds.has(sound_name):
		return
	var player: AudioStreamPlayer = _pool[_next_index]
	_next_index = (_next_index + 1) % POOL_SIZE
	player.stop()
	player.stream = sounds[sound_name]
	player.play()

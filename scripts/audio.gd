## Проигрывание коротких звуков через пул AudioStreamPlayer.
##
## Автозагрузка (autoload) с именем Audio. Все эффекты — Kenney, лицензия CC0.
extends Node

const SOUNDS := {
	"jump": preload("res://assets/sfx/jump.ogg"),
	"coin": preload("res://assets/sfx/coin.ogg"),
	"gem": preload("res://assets/sfx/gem.ogg"),
	"heart": preload("res://assets/sfx/heart.ogg"),
	"stomp": preload("res://assets/sfx/stomp.ogg"),
	"hurt": preload("res://assets/sfx/hurt.ogg"),
	"win": preload("res://assets/sfx/win.ogg"),
	"gameover": preload("res://assets/sfx/gameover.ogg"),
}

const VOICES := 8

var muted := false

var _voices: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)


## Проигрывает звук по имени. Неизвестное имя молча игнорируется.
func play(id: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if muted or not SOUNDS.has(id):
		return
	var voice := _voices[_next]
	_next = (_next + 1) % VOICES
	voice.stream = SOUNDS[id]
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.play()

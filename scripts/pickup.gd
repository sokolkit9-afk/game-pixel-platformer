## Подбираемый предмет: монета, самоцвет или сердце.
##
## Вид задаётся свойством kind до добавления в сцену.
class_name Pickup
extends Area2D

## Игрок подобрал предмет. value — очки (или +1 жизнь для сердца).
signal picked(kind: String, value: int)

## Амплитуда и скорость покачивания спрайта в воздухе.
const BOB_AMPLITUDE := 1.5
const BOB_SPEED := 3.0

@export var kind := "coin"

var _time := 0.0
var _taken := false

@onready var sprite: Sprite2D = $Sprite


## Описание предмета: тайл, очки, звук.
static func info_for(id: String) -> Dictionary:
	match id:
		"gem":
			return {"tile": Tiles.GEM, "value": 50, "sound": "gem"}
		"heart":
			return {"tile": Tiles.HEART, "value": 1, "sound": "heart"}
		_:
			return {"tile": Tiles.COIN, "value": 10, "sound": "coin"}


func _ready() -> void:
	sprite.texture = Tiles.tile(info_for(kind)["tile"])
	# Разный сдвиг фазы, чтобы предметы не качались синхронно.
	_time = float(get_instance_id() % 100) * 0.05
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	sprite.position.y = sin(_time * BOB_SPEED) * BOB_AMPLITUDE


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	var player: Player = body
	if not player.alive:
		return

	_taken = true
	set_deferred("monitoring", false)
	var info := info_for(kind)
	Audio.play(info["sound"])
	picked.emit(kind, info["value"])

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.9, 1.9), 0.18)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)

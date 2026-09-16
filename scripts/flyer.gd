## Врага-«летун»: висит в воздухе и качается вверх-вниз по синусоиде.
##
## Физика ему не нужна, поэтому это обычный Node2D с областью касания.
class_name Flyer
extends Node2D

signal defeated

## Скорость вертикальных колебаний (радиан в секунду).
const BOB_SPEED := 2.2
## Размах колебаний в пикселях.
const BOB_AMPLITUDE := 34.0
const HALF_HEIGHT := 10.0

const FRAMES := [Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2)]
const FRAME_TIME := 0.12

var _origin_y := 0.0
var _time := 0.0
var _frame_timer := 0.0
var _frame_index := 0
var _dead := false

@onready var sprite: Sprite2D = $Sprite
@onready var touch: Area2D = $TouchArea


func _ready() -> void:
	_origin_y = position.y
	sprite.texture = Tiles.character(FRAMES[0])
	touch.body_entered.connect(_on_touch_body_entered)


func _process(delta: float) -> void:
	if _dead:
		return

	_time += delta
	position.y = _origin_y + sin(_time * BOB_SPEED) * BOB_AMPLITUDE

	_frame_timer += delta
	if _frame_timer >= FRAME_TIME:
		_frame_timer -= FRAME_TIME
		_frame_index = (_frame_index + 1) % FRAMES.size()
	sprite.texture = Tiles.character(FRAMES[_frame_index])


func _on_touch_body_entered(body: Node2D) -> void:
	if _dead or not body is Player:
		return
	var player: Player = body
	if not player.alive:
		return

	var feet := player.global_position.y + 11.0
	var top := global_position.y - HALF_HEIGHT
	if player.velocity.y > 0.0 and feet <= top + 10.0:
		_stomped()
		player.bounce()
	else:
		player.die()


func _stomped() -> void:
	if _dead:
		return
	_dead = true
	touch.set_deferred("monitoring", false)
	Audio.play("stomp")
	defeated.emit()

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.3), 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

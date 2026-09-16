## Число, нарисованное тайлами-цифрами из тайлсета.
##
## Обычный Label на пиксельной графике выглядит чужеродно, поэтому счёт
## собирается из спрайтов: строка 8 листа tiles.png — это цифры 0..9.
class_name DigitLabel
extends Node2D

var _value := 0
var _digits := 3
var _sprites: Array[Sprite2D] = []


## Задаёт количество разрядов и пересобирает спрайты.
func setup(digits: int) -> void:
	_digits = maxi(digits, 1)
	_rebuild()


func set_value(v: int) -> void:
	_value = v
	_refresh()


func _rebuild() -> void:
	for s in _sprites:
		s.queue_free()
	_sprites.clear()
	for i in _digits:
		var sprite := Sprite2D.new()
		# Позиция — левый край строки, поэтому сдвигаем на половину тайла.
		sprite.position = Vector2(i * Tiles.TILE + Tiles.TILE * 0.5, Tiles.TILE * 0.5)
		add_child(sprite)
		_sprites.append(sprite)
	_refresh()


func _refresh() -> void:
	if _sprites.is_empty():
		return
	var text := str(absi(_value))
	while text.length() < _digits:
		text = "0" + text
	if text.length() > _digits:
		text = text.substr(text.length() - _digits, _digits)
	for i in _sprites.size():
		_sprites[i].texture = Tiles.digit(text[i].to_int())

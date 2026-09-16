## Экранный интерфейс: монеты, самоцветы, жизни и подсказка по управлению.
##
## Счёт рисуется тайлами-цифрами, поэтому HUD собирается кодом, а не в сцене.
## Модальные панели (пауза, победа, проигрыш) живут отдельно — см. overlay.gd.
class_name Hud
extends CanvasLayer

const MARGIN := 8.0
const VIEW := Vector2(360.0, 180.0)
## Сколько сердец максимум помещается в строке жизней.
const MAX_LIVES := 5

var _coin_label: DigitLabel
var _gem_label: DigitLabel
var _hearts: Array[Sprite2D] = []
var _hint: Label


func _ready() -> void:
	_build()


func set_coins(value: int) -> void:
	_coin_label.set_value(value)


func set_gems(value: int) -> void:
	_gem_label.set_value(value)


func set_lives(value: int, total: int) -> void:
	for i in _hearts.size():
		var full := i < value
		_hearts[i].texture = Tiles.tile(Tiles.HEART if full else Tiles.HEART_EMPTY)
		_hearts[i].visible = i < total


## Короткая подсказка внизу экрана. Не перекрывает игру и не блокирует ввод.
func show_hint(text: String) -> void:
	_hint.text = text
	_hint.visible = true


func hide_hint() -> void:
	_hint.visible = false


func _build() -> void:
	var coin_icon := _make_icon(Tiles.COIN, Vector2(MARGIN, MARGIN))
	add_child(coin_icon)

	_coin_label = DigitLabel.new()
	_coin_label.position = Vector2(MARGIN + Tiles.TILE + 2.0, MARGIN)
	add_child(_coin_label)
	_coin_label.setup(2)

	var gem_width := Tiles.TILE * 2
	var gem_x := VIEW.x - MARGIN - gem_width
	_gem_label = DigitLabel.new()
	_gem_label.position = Vector2(gem_x, MARGIN)
	add_child(_gem_label)
	_gem_label.setup(2)
	add_child(_make_icon(Tiles.GEM, Vector2(gem_x - Tiles.TILE - 2.0, MARGIN)))

	for i in MAX_LIVES:
		var heart := _make_icon(Tiles.HEART, Vector2(MARGIN + i * Tiles.TILE, MARGIN + Tiles.TILE + 4.0))
		heart.visible = false
		add_child(heart)
		_hearts.append(heart)

	# Control-обёртка нужна, чтобы Label корректно растянулся по ширине экрана.
	var ui := Control.new()
	ui.position = Vector2.ZERO
	ui.size = VIEW
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)

	_hint = UiTheme.make_label("", 12, UiTheme.TEXT_DIM)
	_hint.position = Vector2(0.0, VIEW.y - 26.0)
	_hint.size = Vector2(VIEW.x, 20.0)
	_hint.visible = false
	ui.add_child(_hint)


func _make_icon(at: Vector2i, position: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = Tiles.tile(at)
	sprite.position = position + Vector2(Tiles.TILE, Tiles.TILE) * 0.5
	return sprite

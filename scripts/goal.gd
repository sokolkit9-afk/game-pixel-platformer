## Финиш: флагшток с флагом. Как только игрок касается — уровень пройден.
class_name Goal
extends Node2D

signal reached

## Высота флагштока в тайлах.
const POLE_HEIGHT := 5
## Размер полотнища флага в пикселях.
const FLAG_WIDTH := 15.0
const FLAG_HEIGHT := 11.0
const FLAG_COLOR := Color("e0483a")
const FLAG_OUTLINE := Color("2b2b3a")

var _reached := false

@onready var area: Area2D = $Area


func _ready() -> void:
	_build()
	area.body_entered.connect(_on_body_entered)


func _build() -> void:
	for i in POLE_HEIGHT:
		var pole := Sprite2D.new()
		var top := i == POLE_HEIGHT - 1
		pole.texture = Tiles.tile(Tiles.POLE_TOP if top else Tiles.POLE)
		pole.position = Vector2(0.0, -i * Tiles.TILE)
		add_child(pole)

	# Полотнище — треугольный вымпел: из квадратных тайлов флаг не собрать.
	var base := Vector2(Tiles.TILE * 0.5, float(-(POLE_HEIGHT - 1) * Tiles.TILE) - FLAG_HEIGHT * 0.5)
	add_child(_make_pennant(base, 1.5, FLAG_OUTLINE))
	add_child(_make_pennant(base, 0.0, FLAG_COLOR))


func _make_pennant(at: Vector2, grow: float, color: Color) -> Polygon2D:
	var pennant := Polygon2D.new()
	pennant.polygon = PackedVector2Array([
		Vector2(-grow, -grow),
		Vector2(FLAG_WIDTH + grow, FLAG_HEIGHT * 0.5),
		Vector2(-grow, FLAG_HEIGHT + grow),
	])
	pennant.color = color
	pennant.position = at
	return pennant


func _on_body_entered(body: Node2D) -> void:
	if _reached or not body is Player:
		return
	var player: Player = body
	if not player.alive:
		return
	_reached = true
	player.win()
	reached.emit()

## Главное меню: заголовок на фоне игрового пейзажа, кнопки и экран управления.
extends Control

const GAME_SCENE := "res://scenes/Main.tscn"
const VIEW := Vector2(360.0, 180.0)

const HELP_TEXT := """← → или A D — бежать
ПРОБЕЛ, W или ↑ — прыжок
ESC — пауза, R — заново
Собирайте монеты и самоцветы,
прыгайте врагам на голову
и добегите до флага справа."""

var _menu_box: VBoxContainer
var _help_panel: PanelContainer


func _ready() -> void:
	theme = UiTheme.theme()
	position = Vector2.ZERO
	_build()


func _unhandled_input(event: InputEvent) -> void:
	# ESC на экране управления возвращает в меню, а не закрывает игру.
	if _help_panel != null and _help_panel.visible and event.is_action_pressed("ui_cancel"):
		_toggle_help()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_add_backdrop()
	_add_ground()

	var title := UiTheme.make_label("ПИКСЕЛЬНЫЙ БЕГУН", UiTheme.TITLE_SIZE)
	title.position = Vector2(0.0, 6.0)
	title.size = Vector2(VIEW.x, 34.0)
	add_child(title)

	var subtitle := UiTheme.make_label("платформер на Godot 4 · графика Kenney (CC0)", 13, UiTheme.TEXT_DIM)
	subtitle.position = Vector2(0.0, 40.0)
	subtitle.size = Vector2(VIEW.x, 16.0)
	add_child(subtitle)

	# Кнопки упираются нижней гранью в линию травы — так меню выглядит собранным.
	_menu_box = VBoxContainer.new()
	_menu_box.position = Vector2(95.0, 56.0)
	_menu_box.add_theme_constant_override("separation", 4)
	add_child(_menu_box)

	_add_menu_button("ИГРАТЬ", _start_game)
	_add_menu_button("УПРАВЛЕНИЕ", _toggle_help)
	_add_menu_button("ВЫХОД", _quit)

	_help_panel = _make_help_panel()
	add_child(_help_panel)
	_help_panel.visible = false

	_menu_box.get_child(0).call_deferred("grab_focus")


func _add_backdrop() -> void:
	var sky := ColorRect.new()
	sky.color = UiTheme.SKY
	sky.position = Vector2.ZERO
	sky.size = VIEW
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)


## Полоска земли внизу — чтобы меню выглядело частью игры, а не пустой формой.
func _add_ground() -> void:
	var columns := int(VIEW.x / Tiles.TILE) + 1
	for i in columns:
		var x := float(i * Tiles.TILE)
		_add_tile(Tiles.DIRT, Vector2(x, VIEW.y - Tiles.TILE))
		_add_tile(Tiles.GRASS, Vector2(x, VIEW.y - Tiles.TILE * 2.0))

	var hero := TextureRect.new()
	hero.texture = Tiles.character(Vector2i(0, 0))
	hero.position = Vector2(26.0, VIEW.y - Tiles.TILE * 2.0 - 24.0)
	hero.size = Vector2(24.0, 24.0)
	hero.stretch_mode = TextureRect.STRETCH_KEEP
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero)


func _add_tile(at: Vector2i, position: Vector2) -> void:
	var rect := TextureRect.new()
	rect.texture = Tiles.tile(at)
	rect.position = position
	rect.size = Vector2(Tiles.TILE, Tiles.TILE)
	rect.stretch_mode = TextureRect.STRETCH_KEEP
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func _add_menu_button(text: String, handler: Callable) -> void:
	var button := UiTheme.make_button(text, 26.0)
	button.pressed.connect(handler)
	_menu_box.add_child(button)


func _make_help_panel() -> PanelContainer:
	# Панель во весь экран, содержимое центрирует контейнер: не нужно вручную
	# считать размеры и гадать, когда они посчитаются.
	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	column.add_child(UiTheme.make_label("УПРАВЛЕНИЕ", 18))
	column.add_child(UiTheme.make_label(HELP_TEXT, 12))

	var back := UiTheme.make_button("НАЗАД", 24.0)
	back.pressed.connect(_toggle_help)
	column.add_child(back)
	return panel


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _toggle_help() -> void:
	_help_panel.visible = not _help_panel.visible
	_menu_box.visible = not _help_panel.visible
	if _help_panel.visible:
		_help_panel.get_child(0).get_child(2).call_deferred("grab_focus")
	else:
		_menu_box.get_child(1).call_deferred("grab_focus")


func _quit() -> void:
	get_tree().quit()

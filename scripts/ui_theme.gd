## Единый стиль интерфейса: пиксельный шрифт и цвета, взятые из тайлсета.
##
## Палитра снята прямо с тайлов земли Kenney, поэтому меню не выбивается из игры.
class_name UiTheme
extends RefCounted

const FONT_PATH := "res://assets/fonts/Tiny5-Regular.ttf"

const SKY := Color("8cc7eb")
const PANEL := Color("2f3346")
const OUTLINE := Color("1d2030")
const DIRT := Color("cb815e")
const DIRT_DARK := Color("9f5a52")
const DIRT_LIGHT := Color("f4ac66")
const GRASS := Color("2eb082")
const TEXT := Color("fdf6e3")
const TEXT_DIM := Color("c9c3b4")
const DANGER := Color("e0483a")

const TITLE_SIZE := 30
const BUTTON_SIZE := 18
const TEXT_SIZE := 15

static var _font: Font = null
static var _theme: Theme = null


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH)
	return _font


## Общая тема: применяется к Control-узлам, дальше наследуется детьми.
static func theme() -> Theme:
	if _theme != null:
		return _theme

	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = TEXT_SIZE

	t.set_stylebox("normal", "Button", _box(DIRT, OUTLINE))
	t.set_stylebox("hover", "Button", _box(DIRT_LIGHT, OUTLINE))
	t.set_stylebox("pressed", "Button", _box(DIRT_DARK, OUTLINE))
	t.set_stylebox("focus", "Button", _box(DIRT, GRASS))
	t.set_stylebox("disabled", "Button", _box(DIRT_DARK, OUTLINE))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", OUTLINE)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)
	t.set_font_size("font_size", "Button", BUTTON_SIZE)

	t.set_stylebox("panel", "PanelContainer", _box(PANEL, OUTLINE))
	t.set_color("font_color", "Label", TEXT)

	_theme = t
	return _theme


## Кнопка меню с прямыми углами и пиксельной рамкой.
static func make_button(text: String, height: float = 28.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(170.0, height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	return button


## Подпись с тёмной обводкой, чтобы читалась на любом фоне.
static func make_label(text: String, size: int = TEXT_SIZE, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 5)
	return label


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	# Прямые углы — скругления спорят с пиксельной графикой.
	box.set_corner_radius_all(0)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 5.0
	box.content_margin_bottom = 5.0
	return box

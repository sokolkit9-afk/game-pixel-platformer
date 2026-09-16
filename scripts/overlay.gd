## Всплывающая панель поверх игры: пауза, победа, проигрыш.
##
## Работает и при `get_tree().paused = true` — поэтому process_mode = ALWAYS.
class_name Overlay
extends CanvasLayer

## Игрок нажал кнопку. id — то, что передали в show_panel.
signal action(id: String)

const VIEW := Vector2(360.0, 180.0)
const PANEL_WIDTH := 240.0

var _root: Control
var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _hint: Label
var _buttons: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide_panel()


## Показывает панель. buttons — массив словарей {"id": String, "text": String}.
func show_panel(
	title: String,
	subtitle: String,
	buttons: Array,
	hint: String = "",
	title_color: Color = UiTheme.TEXT
) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", title_color)
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	_hint.text = hint
	_hint.visible = hint != ""

	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()

	for spec in buttons:
		var button := UiTheme.make_button(spec["text"], 24.0)
		var id: String = spec["id"]
		button.pressed.connect(func() -> void: action.emit(id))
		_buttons.add_child(button)

	_root.visible = true
	if _buttons.get_child_count() > 0:
		_buttons.get_child(0).call_deferred("grab_focus")


func hide_panel() -> void:
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func _build() -> void:
	_root = Control.new()
	_root.position = Vector2.ZERO
	_root.size = VIEW
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.07, 0.11, 0.62)
	dim.position = Vector2.ZERO
	dim.size = VIEW
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.theme = UiTheme.theme()
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_root.add_child(_panel)
	_center(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	_panel.add_child(column)

	_title = UiTheme.make_label("", 20)
	column.add_child(_title)

	_subtitle = UiTheme.make_label("", 13, UiTheme.TEXT_DIM)
	column.add_child(_subtitle)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 5)
	column.add_child(_buttons)

	_hint = UiTheme.make_label("", 13, UiTheme.TEXT_DIM)
	column.add_child(_hint)


## Панель растёт от центра: offsets нулевые при якорях 0.5, а
## GROW_DIRECTION_BOTH раздвигает её симметрично. Считать размер не нужно,
## поэтому результат не зависит от момента, когда посчитан min size.
func _center(control: Control) -> void:
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = 0.0
	control.offset_right = 0.0
	control.offset_top = 0.0
	control.offset_bottom = 0.0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH

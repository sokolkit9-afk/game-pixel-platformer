## Дымовой тест: поднимает главную сцену, прокручивает физику и проверяет,
## что игрок приземляется, прыгает, бежит, собирает предметы и доходит до финиша.
##
## Запуск:
##   godot --headless --path . res://tests/SmokeTest.tscn
##
## Возвращает код 0, если все проверки пройдены.
extends Node

## Сколько физических кадров между шагами теста.
const FRAMES_PER_STEP := 45
## Шаги 1..6 — бег и прыжок, 7..9 — проверка финиша.
const RUN_STEPS := 6
const STEPS := 9
## Насколько близко к флагу поставить игрока перед проверкой финиша.
const GOAL_APPROACH := 36.0

var _main: Node2D
var _step := 0
var _frames := 0

var _start_x := 0.0
var _ground_y := INF
var _jump_min_y := INF
var _tracking_jump := false

var _failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)

	print("=== smoke test ===")
	print("Input Map: move_left=%s move_right=%s jump=%s restart=%s" % [
		InputMap.has_action("move_left"),
		InputMap.has_action("move_right"),
		InputMap.has_action("jump"),
		InputMap.has_action("restart"),
	])

	var level: Level = _main.level
	print("уровень: %d x %d тайлов, спавн=%s, финиш=%s" % [
		level.width, level.height, level.player_spawn, level.goal_cell,
	])
	print("враги: ходоков=%d, летунов=%d, предметов=%d" % [
		level.walker_cells.size(), level.flyer_cells.size(), level.pickup_cells.size(),
	])
	print("узлов в мире: %d" % _main.world.get_child_count())

	_start_x = _main.player.global_position.x


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _tracking_jump:
		_jump_min_y = minf(_jump_min_y, _main.player.global_position.y)

	if _frames % FRAMES_PER_STEP != 0:
		return
	_step += 1
	_act(_step)
	_report(_step)
	if _step >= STEPS:
		_finish()


## Сценарий ввода по шагам.
func _act(step: int) -> void:
	match step:
		2:
			Input.action_press("move_right")
		3:
			Input.action_press("jump")
			_tracking_jump = true
		4:
			Input.action_release("jump")
			Input.action_release("move_right")
			_tracking_jump = false
		7:
			# Ставим игрока чуть левее флага и идём в него пешком.
			var goal_x: float = _main.level.goal_cell.x * Tiles.TILE + Tiles.TILE * 0.5
			_main.player.global_position = Vector2(goal_x - GOAL_APPROACH, _ground_y)
			Input.action_press("move_right")
		9:
			Input.action_release("move_right")


func _report(step: int) -> void:
	var p: Player = _main.player
	var pos := p.global_position

	match step:
		1:
			_ground_y = pos.y
			if not p.is_on_floor():
				_failures.append("игрок не встал на землю после спавна")
			if pos.y > _main.level.pixel_size().y:
				_failures.append("игрок провалился сквозь пол: y=%.1f" % pos.y)
		2:
			if absf(pos.y - _ground_y) > 2.0:
				_failures.append("игрок съезжает с ровной земли: y=%.1f" % pos.y)
		4:
			if _jump_min_y > _ground_y - 30.0:
				_failures.append("прыжок слишком низкий: минимум y=%.1f при земле %.1f"
					% [_jump_min_y, _ground_y])
			if pos.x < _start_x + 30.0:
				_failures.append("игрок не сдвинулся вправо: x=%.1f" % pos.x)
		6:
			if not p.alive:
				_failures.append("игрок погиб на ровном участке")
			if _main.coins <= 0:
				_failures.append("ни одна монета не подобрана")
		RUN_STEPS:
			if not p.is_on_floor():
				_failures.append("игрок не стоит на земле после остановки")
		STEPS:
			if _main.state != 2:
				_failures.append("финиш не сработал, состояние=%d" % _main.state)

	print("шаг %d | x=%7.1f y=%6.1f | на земле=%-5s | скорость=(%6.1f, %6.1f) | жив=%-5s | жизни=%d | монеты=%d | самоцветы=%d | очки=%d" % [
		step, pos.x, pos.y, p.is_on_floor(), p.velocity.x, p.velocity.y,
		p.alive, _main.lives, _main.coins, _main.gems, _main.score,
	])


func _finish() -> void:
	print("=== результат ===")
	if _failures.is_empty():
		print("OK: все проверки пройдены")
	else:
		for f in _failures:
			print("FAIL: %s" % f)
	get_tree().quit(0 if _failures.is_empty() else 1)

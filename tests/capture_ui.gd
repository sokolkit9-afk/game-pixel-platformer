## Захват кадров интерфейса: меню, экран управления, пауза и экран победы.
##
## Запуск (нужно окно, headless не рендерит):
##   godot --path . res://tests/CaptureUi.tscn
extends Node

const OUT_DIR := "res://preview"
## Страховка: если что-то зависнет, тест всё равно завершится.
const WATCHDOG := 40.0


func _ready() -> void:
	_start_watchdog()
	await _run()


func _run() -> void:
	# 1. Главное меню.
	# Тип не выводим намеренно: дальше зовём приватные методы сцен напрямую.
	var menu = load("res://scenes/Menu.tscn").instantiate()
	add_child(menu)
	await _settle(24)
	await _shot("ui_menu")

	# 2. Экран управления.
	menu._toggle_help()
	await _settle(8)
	await _shot("ui_help")
	menu.queue_free()
	await _settle(4)

	# 3. Игра, пауза и победа.
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _settle(30)
	await _shot("ui_game")

	main._pause()
	await _settle(8)
	await _shot("ui_pause")
	main._resume()
	await _settle(4)

	main._on_goal_reached()
	await _settle(8)
	await _shot("ui_win")

	print("capture done")
	get_tree().quit()


func _start_watchdog() -> void:
	var timer := Timer.new()
	timer.wait_time = WATCHDOG
	timer.one_shot = true
	timer.timeout.connect(func() -> void:
		push_warning("watchdog: захват не завершился вовремя")
		get_tree().quit(1)
	)
	add_child(timer)
	timer.start()


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


## Кадр уже нарисован к моменту следующего process_frame — отдельного
## сигнала от RenderingServer не ждём, он в headless не приходит.
func _shot(name: String) -> void:
	await _settle(3)
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	image.save_png(path)
	print("saved %s %s" % [ProjectSettings.globalize_path(path), image.get_size()])

## Отладочный захват кадров: запускает игру в обычном окне, ждёт отрисовки
## и сохраняет несколько скриншотов в preview/.
##
## Запуск (нужно окно, headless не рендерит):
##   godot --path . res://tests/Capture.tscn
extends Node

const SHOTS := [45.0, 800.0, 1700.0]
const OUT_DIR := "res://preview"

var _main: Node2D


func _ready() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	_run()


func _run() -> void:
	# Даём сцене собраться и прогрузиться.
	for i in 20:
		await get_tree().process_frame

	for i in SHOTS.size():
		var x: float = SHOTS[i]
		_main.player.global_position = Vector2(x, _main.player.global_position.y)
		# Ждём, пока камера переедет на новое место.
		for j in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := "%s/capture_%d.png" % [OUT_DIR, i]
		image.save_png(path)
		print("saved ", ProjectSettings.globalize_path(path), " at x=", x)

	get_tree().quit()

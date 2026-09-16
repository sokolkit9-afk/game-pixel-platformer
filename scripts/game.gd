## Главный узел: собирает уровень, ведёт счёт, управляет паузой и экранами итогов.
extends Node2D

const PlayerScene := preload("res://scenes/Player.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const FlyerScene := preload("res://scenes/Flyer.tscn")
const PickupScene := preload("res://scenes/Pickup.tscn")
const GoalScene := preload("res://scenes/Goal.tscn")

const MENU_SCENE := "res://scenes/Menu.tscn"

const START_LIVES := 3
const MAX_LIVES := 5
## Пауза перед возрождением после смерти.
const RESPAWN_DELAY := 1.3
## Сколько секунд висит подсказка по управлению в начале уровня.
const HINT_TIME := 6.0

const SCORE_COIN := 10
const SCORE_GEM := 50
const SCORE_STOMP := 100
const SCORE_LIFE_BONUS := 100

## Подсказка должна влезать в 360 точек по ширине — иначе обрезается по краям.
const HINT := "← → — бежать   ПРОБЕЛ — прыжок   ESC — пауза"
## Насколько медленнее мира движется слой облаков.
const SKY_PARALLAX := 0.35

enum State { PLAY, DEAD, WON, OVER }

var level: Level
var player: Player

var state := State.PLAY
var paused := false
var lives := START_LIVES
var coins := 0
var gems := 0
var score := 0

var _respawn_timer := 0.0
var _r_down := false

@onready var world: Node2D = $World
@onready var hud: Hud = $HUD
@onready var overlay: Overlay = $Overlay


func _ready() -> void:
	_build_level()
	_spawn_player()
	_spawn_world_objects()
	_update_hud()

	overlay.action.connect(_on_overlay_action)
	hud.show_hint(HINT)
	get_tree().create_timer(HINT_TIME).timeout.connect(_hide_hint)


func _process(delta: float) -> void:
	_update_sky()

	if _restart_pressed():
		get_tree().reload_current_scene()
		return

	if state == State.DEAD:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			if lives > 0:
				_respawn()
			else:
				state = State.OVER


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAY or not _is_pause_event(event):
		return
	if paused:
		_resume()
	else:
		_pause()


# --- сборка сцены ---

func _build_level() -> void:
	level = Level.new()
	level.name = "Level"
	world.add_child(level)


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	# spawn — это низ клетки, а коллизия игрока центрирована: поднимаем на полувысоту.
	player.position = level.player_spawn - Vector2(0.0, 11.0)
	player.fall_limit_y = level.pixel_size().y + 40.0
	world.add_child(player)
	player.died.connect(_on_player_died)
	player.reached_goal.connect(_on_goal_reached)

	var camera: Camera2D = player.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(level.pixel_size().x)
	camera.limit_bottom = int(level.pixel_size().y)


func _spawn_world_objects() -> void:
	for cell in level.walker_cells:
		var enemy: Enemy = EnemyScene.instantiate()
		enemy.position = Level.cell_center(cell)
		world.add_child(enemy)
		enemy.defeated.connect(_on_enemy_defeated)

	for cell in level.flyer_cells:
		var flyer: Flyer = FlyerScene.instantiate()
		flyer.position = Level.cell_center(cell)
		world.add_child(flyer)
		flyer.defeated.connect(_on_enemy_defeated)

	for entry in level.pickup_cells:
		var pickup: Pickup = PickupScene.instantiate()
		pickup.kind = entry[1]
		pickup.position = Level.cell_center(entry[0])
		world.add_child(pickup)
		pickup.picked.connect(_on_picked)

	if level.goal_cell.x >= 0:
		var goal: Goal = GoalScene.instantiate()
		goal.position = Level.cell_center(level.goal_cell)
		world.add_child(goal)
		goal.reached.connect(_on_goal_reached)


# --- события игры ---

func _on_picked(kind: String, value: int) -> void:
	match kind:
		"coin":
			coins += 1
			score += SCORE_COIN
		"gem":
			gems += 1
			score += SCORE_GEM
		"heart":
			lives = mini(lives + 1, MAX_LIVES)
	_update_hud()


func _on_enemy_defeated() -> void:
	score += SCORE_STOMP


func _on_player_died() -> void:
	if state != State.PLAY:
		return
	lives -= 1
	state = State.DEAD
	_respawn_timer = RESPAWN_DELAY
	_update_hud()
	if lives <= 0:
		Audio.play("gameover")
		_show_result(
			"ИГРА ОКОНЧЕНА",
			"Собрано очков: %d\nМонет: %d   Самоцветов: %d" % [score, coins, gems],
			UiTheme.DANGER
		)


func _on_goal_reached() -> void:
	if state == State.WON:
		return
	state = State.WON
	score += lives * SCORE_LIFE_BONUS
	Audio.play("win")
	_show_result(
		"УРОВЕНЬ ПРОЙДЕН!",
		"Очки: %d\nМонет: %d   Самоцветов: %d\nБонус за жизни: +%d"
			% [score, coins, gems, lives * SCORE_LIFE_BONUS],
		UiTheme.DIRT_LIGHT
	)


func _on_overlay_action(id: String) -> void:
	match id:
		"resume":
			_resume()
		"restart":
			get_tree().reload_current_scene()
		"menu":
			get_tree().change_scene_to_file(MENU_SCENE)


# --- пауза и экраны итогов ---

func _pause() -> void:
	paused = true
	world.process_mode = Node.PROCESS_MODE_DISABLED
	hud.hide_hint()
	overlay.show_panel("ПАУЗА", "", [
		{"id": "resume", "text": "ПРОДОЛЖИТЬ"},
		{"id": "restart", "text": "НАЧАТЬ ЗАНОВО"},
		{"id": "menu", "text": "В ГЛАВНОЕ МЕНЮ"},
	], "ESC — вернуться в игру")


func _resume() -> void:
	paused = false
	world.process_mode = Node.PROCESS_MODE_INHERIT
	overlay.hide_panel()


func _show_result(title: String, subtitle: String, color: Color) -> void:
	hud.hide_hint()
	overlay.show_panel(title, subtitle, [
		{"id": "restart", "text": "НАЧАТЬ ЗАНОВО"},
		{"id": "menu", "text": "В ГЛАВНОЕ МЕНЮ"},
	], "", color)


# --- служебное ---

func _respawn() -> void:
	player.alive = true
	player.finished = false
	player.velocity = Vector2.ZERO
	player.position = level.player_spawn - Vector2(0.0, 11.0)
	player.collision_layer = 2
	player.collision_mask = 1
	player.visual.scale = Vector2.ONE
	state = State.PLAY


func _update_hud() -> void:
	hud.set_coins(coins)
	hud.set_gems(gems)
	hud.set_lives(lives, maxi(lives, START_LIVES))


## Небо едет за игроком медленнее мира — получается параллакс.
func _update_sky() -> void:
	if level == null or level.sky == null or player == null:
		return
	level.sky.position.x = -player.global_position.x * SKY_PARALLAX


func _hide_hint() -> void:
	if state == State.PLAY and not paused:
		hud.hide_hint()


func _is_pause_event(event: InputEvent) -> bool:
	if InputMap.has_action("pause") and event.is_action_pressed("pause"):
		return true
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.pressed and not key.echo and key.keycode == KEY_ESCAPE
	return false


## Срабатывает один раз на нажатие R — и через Input Map, и просто по клавише.
func _restart_pressed() -> bool:
	# R работает и на экранах итогов, но не когда открыта пауза — там свои кнопки.
	if paused:
		return false
	var down := false
	if InputMap.has_action("restart"):
		down = Input.is_action_pressed("restart")
	else:
		down = Input.is_key_pressed(KEY_R)
	var just := down and not _r_down
	_r_down = down
	return just

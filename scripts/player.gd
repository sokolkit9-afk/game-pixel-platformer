## Игрок: бег, прыжок с «coyote time» и буфером ввода, отскок от врагов.
class_name Player
extends CharacterBody2D

signal died
signal reached_goal

const SPEED := 100.0
const GROUND_ACCEL := 900.0
const AIR_ACCEL := 550.0
const FRICTION := 1100.0
const GRAVITY := 1000.0
const MAX_FALL_SPEED := 420.0
const JUMP_VELOCITY := -360.0
## Во сколько раз обрезается прыжок, если отпустить кнопку раньше.
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.09
const JUMP_BUFFER := 0.12
const STOMP_BOUNCE := -250.0
const DEATH_KNOCKBACK := -220.0

## Кадры анимации бега из листа персонажей (колонка, строка).
const FRAMES := [Vector2i(0, 0), Vector2i(1, 0)]
const FRAME_TIME := 0.16

## Ниже этой отметки по Y падение считается смертельным.
var fall_limit_y := 400.0

var alive := true
## Уровень пройден: игрок замирает на месте, но не проваливается сквозь пол.
var finished := false

var _facing := 1
var _coyote := 0.0
var _jump_buffer := 0.0
var _jump_was_down := false
var _frame_timer := 0.0
var _frame_index := 0
var _tween: Tween = null

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	# Низ спрайта совпадает с низом коллизии — персонаж не «висит» в воздухе.
	sprite.texture = Tiles.character(FRAMES[0])


func _physics_process(delta: float) -> void:
	if finished:
		velocity = Vector2.ZERO
		return

	if not alive:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		move_and_slide()
		return

	var dir := 0.0
	if _pressed("move_left", [KEY_A, KEY_LEFT]):
		dir -= 1.0
	if _pressed("move_right", [KEY_D, KEY_RIGHT]):
		dir += 1.0

	var jump_now := _pressed("jump", [KEY_SPACE, KEY_W, KEY_UP])
	if jump_now and not _jump_was_down:
		_jump_buffer = JUMP_BUFFER
	_jump_was_down = jump_now

	# --- горизонталь ---
	if dir != 0.0:
		_facing = 1 if dir > 0.0 else -1
		var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
	else:
		var fric := FRICTION if is_on_floor() else FRICTION * 0.35
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# --- вертикаль ---
	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0
		_squash(Vector2(0.82, 1.2))
		Audio.play("jump")

	# Отпустил кнопку — прыжок короче.
	if not jump_now and velocity.y < 0.0:
		velocity.y = maxf(velocity.y, JUMP_VELOCITY * JUMP_CUT)

	move_and_slide()

	if global_position.y > fall_limit_y:
		die()

	_animate(delta)


func _animate(delta: float) -> void:
	var running := is_on_floor() and absf(velocity.x) > 8.0
	if running:
		_frame_timer += delta
		if _frame_timer >= FRAME_TIME:
			_frame_timer -= FRAME_TIME
			_frame_index = (_frame_index + 1) % FRAMES.size()
	else:
		_frame_timer = 0.0
		_frame_index = 0
	sprite.texture = Tiles.character(FRAMES[_frame_index])
	sprite.flip_h = _facing < 0


## Отскок после удара по врагу сверху.
func bounce() -> void:
	velocity.y = STOMP_BOUNCE
	_squash(Vector2(1.25, 0.78))


func die() -> void:
	if not alive:
		return
	alive = false
	velocity = Vector2(0.0, DEATH_KNOCKBACK)
	collision_layer = 0
	collision_mask = 0
	Audio.play("hurt")
	died.emit()


func win() -> void:
	if not alive or finished:
		return
	finished = true
	velocity = Vector2.ZERO
	_squash(Vector2(1.15, 1.15))
	reached_goal.emit()


func _squash(target: Vector2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visual.scale = Vector2.ONE
	_tween = create_tween()
	_tween.tween_property(visual, "scale", target, 0.06)
	_tween.tween_property(visual, "scale", Vector2.ONE, 0.12)


## Читает действие из Input Map, а если его там нет — прямо с клавиатуры.
func _pressed(action: String, keys: Array) -> bool:
	if InputMap.has_action(action):
		return Input.is_action_pressed(action)
	for key in keys:
		if Input.is_key_pressed(key):
			return true
	return false

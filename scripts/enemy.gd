## Врага-«ходок»: патрулирует платформу, разворачивается у стены и на краю.
##
## Прыжок игроку на голову убивает врага, касание сбоку — убивает игрока.
class_name Enemy
extends CharacterBody2D

signal defeated

const SPEED := 28.0
const GRAVITY := 900.0
const MAX_FALL := 420.0
## Пауза после разворота, чтобы враг не «дёргался» на краю.
const TURN_COOLDOWN := 0.12
## Полувысота коллизии — нужна для проверки удара сверху.
const HALF_HEIGHT := 10.0

const FRAMES := [Vector2i(2, 0), Vector2i(3, 0)]
const FRAME_TIME := 0.22

var _dir := -1
var _flip_cooldown := 0.0
var _frame_timer := 0.0
var _frame_index := 0
var _dead := false

@onready var sprite: Sprite2D = $Sprite
@onready var ledge: RayCast2D = $LedgeCheck
@onready var touch: Area2D = $TouchArea


func _ready() -> void:
	sprite.texture = Tiles.character(FRAMES[0])
	_sync_ledge()
	touch.body_entered.connect(_on_touch_body_entered)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	else:
		velocity.y = 0.0

	velocity.x = _dir * SPEED
	move_and_slide()

	_flip_cooldown = maxf(_flip_cooldown - delta, 0.0)
	if _flip_cooldown <= 0.0:
		if is_on_wall():
			_flip()
		elif is_on_floor():
			ledge.force_raycast_update()
			if not ledge.is_colliding():
				_flip()

	_animate(delta)


func _animate(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer >= FRAME_TIME:
		_frame_timer -= FRAME_TIME
		_frame_index = (_frame_index + 1) % FRAMES.size()
	sprite.texture = Tiles.character(FRAMES[_frame_index])


func _flip() -> void:
	_dir = -_dir
	_flip_cooldown = TURN_COOLDOWN
	_sync_ledge()


func _sync_ledge() -> void:
	ledge.position = Vector2(_dir * 8.0, 0.0)


func _on_touch_body_entered(body: Node2D) -> void:
	if _dead or not body is Player:
		return
	var player: Player = body
	if not player.alive:
		return

	var feet := player.global_position.y + 11.0
	var top := global_position.y - HALF_HEIGHT
	# Сверху и падает вниз — это удар, а не столкновение.
	if player.velocity.y > 0.0 and feet <= top + 10.0:
		_stomped()
		player.bounce()
	else:
		player.die()


func _stomped() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	touch.set_deferred("monitoring", false)
	Audio.play("stomp")
	defeated.emit()

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 0.25), 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

# res://scripts/Player.gd
extends CharacterBody2D

# --- Добавьте это ---
var health: int = 100
var score: int = 0

# Константы для настройки физики персонажа
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

func _physics_process(delta):
	# Применение гравитации
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Обработка горизонтального движения
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Обработка прыжка
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- ОБРАБОТКА АТАКИ ---
	if Input.is_action_just_pressed("attack"):
		_perform_attack()

	# Перемещение персонажа с учетом столкновений
	move_and_slide()

# --- ДОБАВЛЯЕМ МЕТОД АТАКИ ---
func _perform_attack():
	# Показываем визуальный эффект атаки
	$AttackVisual.visible = true
	# Активируем коллайдер атаки на один кадр
	$AttackVisual/AttackCollision.set_deferred("disabled", false)

	# Ждем следующего физического кадра, чтобы проверить столкновения
	await get_tree().physics_frame

	# Отключаем коллайдер и визуальный эффект
	$AttackVisual/AttackCollision.set_deferred("disabled", true)
	$AttackVisual.visible = false

# --- ОБРАБОТЧИК СТОЛКНОВЕНИЙ АТАКИ ---
# Этот метод будет вызываться, когда коллайдер атаки сталкивается с чем-то
func _on_AttackCollision_area_entered(area):
	# Проверяем, является ли объект, с которым мы столкнулись, врагом.
	# Для этого предположим, что у врагов есть группа "enemy" или метка.
	if area.is_in_group("enemy"):
		# Отправляем сигнал врагу, что по нему попали.
		# Предполагается, что у врага есть метод `take_damage`.
		area.take_damage(10) # Наносим 10 урона
		# Можно добавить визуальный или звуковой эффект

func set_health(new_health: int):
	health = clamp(new_health, 0, 100) # Ограничиваем здоровье от 0 до 100
	print("Player health set to: ", health)

func set_score(new_score: int):
	score = max(new_score, 0) # Счет не может быть меньше 0
	print("Player score set to: ", score)

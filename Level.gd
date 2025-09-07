# res://scripts/Level.gd
extends Node2D

@export var gravity: float = 980.0

@onready var player: CharacterBody2D = $Player
@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
# Добавляем ссылку на PauseLoadGameMenu
@onready var pause_load_game_menu: Control = $PauseMenuLayer/PauseMenu/PauseLoadGameMenu

@onready var message_label: Label = $UI/HUD/MessageLabel
# - ДОБАВЛЯЕМ ССЫЛКИ НА HUD -
@onready var health_label: Label = $UI/HUD/CanvasLayer/UI/MarginContainer/HBoxContainer/HealthLabel
@onready var score_label: Label = $UI/HUD/CanvasLayer/UI/MarginContainer/HBoxContainer/ScoreLabel

var score: int = 0
var health: int = 100
var is_game_over: bool = false
var is_game_paused: bool = false

func _ready():
	print("Level scene loaded")

	# Инициализация HUD
	update_hud()

	# - ИНИЦИАЛИЗАЦИЯ ИГРОКА -
	# Здесь вызываем метод для инициализации игрока из сохранения или по умолчанию
	_initialize_player_from_save_data()

	# - КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: УСТАНАВЛИВАЕМ ССЫЛКУ НА ИГРОКА В GAME MANAGER -
	GameManager.set_player_reference(player)
	print("Player reference set in GameManager from Level scene.")

	# - ИНИЦИАЛИЗАЦИЯ МЕНЮ ПАУЗЫ -
	if pause_menu:
		pause_menu.hide()
		# Подключаем сигналы меню паузы
		_connect_pause_menu_signals()

		# --- НОВОЕ: Подключение сигнала из PauseLoadGameMenu ---
		if pause_load_game_menu and not pause_load_game_menu.is_connected("load_game_requested", Callable(self, "_on_pause_load_game_requested")):
			var err = pause_load_game_menu.connect("load_game_requested", Callable(self, "_on_pause_load_game_requested"))
			if err == OK:
				print("Level: Connected 'load_game_requested' signal from PauseLoadGameMenu.")
			else:
				push_error("Level: Failed to connect 'load_game_requested' signal from PauseLoadGameMenu. Error: ", err)
		# --- КОНЕЦ НОВОГО ---

	print("Level initialized")

	is_game_over = false # Убедитесь, что сброшено
	set_process_unhandled_input(true) # Убедитесь, что включено

# --- НОВЫЙ МЕТОД: Подключение сигналов меню паузы ---
func _connect_pause_menu_signals():
	if not pause_menu.is_connected("resumed", Callable(self, "_on_pause_menu_resumed")):
		pause_menu.connect("resumed", Callable(self, "_on_pause_menu_resumed"))
	if not pause_menu.is_connected("exit_requested", Callable(self, "_on_pause_menu_exit_requested")):
		pause_menu.connect("exit_requested", Callable(self, "_on_pause_menu_exit_requested"))
	print("Level: Pause menu signals connected.")

# --- НОВЫЙ МЕТОД: Обработка сигнала загрузки из меню паузы ---
func _on_pause_load_game_requested(slot_index: int):
	print("Level: Loading game from slot ", slot_index, " requested from pause menu.")

	# 1. Скрыть меню паузы
	if pause_menu:
		pause_menu.hide_pause_menu() # Предполагается, что такой метод есть

	# 2. Снять паузу
	is_game_paused = false
	get_tree().paused = false
	print("Level: Pause disabled after load request.")

	# 3. Загрузить данные из слота
	# Предполагается, что GameManager.load_game_from_slot(slot_index)
	# загружает данные в GameManager.player_data и устанавливает current_save_slot.
	# Затем _initialize_player_from_save_data() будет использовать эти данные.
	GameManager.load_game_from_slot(slot_index)
	print("Level: Game data loaded from slot ", slot_index, " by GameManager.")

	# 4. Инициализировать игрока из загруженных данных
	# Этот метод уже существует и должен корректно обновить состояние игрока
	_initialize_player_from_save_data()
	print("Level: Player re-initialized from loaded data.")

	# 5. (Опционально) Обновить HUD, если он зависит от данных, которые могли измениться при загрузке
	update_hud()
	print("Level: HUD updated after loading.")

# - ИНИЦИАЛИЗАЦИЯ ИГРОКА ИЗ СОХРАНЕНИЯ ИЛИ ПО УМОЛЧАНИЮ -
func _initialize_player_from_save_data():
	# - ВОССТАНОВЛЕНИЕ СОСТОЯНИЯ ИГРОКА -
	# Получаем данные игрока из GameManager
	# Предполагается, что GameManager.load_game_from_slot заполняет player_data
	var player_data = GameManager.get_player_data()
	if not player_data.is_empty():
		if player_data.has("position"):
			player.position = Vector2(player_data["position"].x, player_data["position"].y)
		if player_data.has("health"):
			health = player_data["health"]
			player.health = health # Предполагается, что у Player.gd есть var health
		if player_data.has("score"):
			score = player_data["score"]
			player.score = score # Предполагается, что у Player.gd есть var score
		# Если в сохранении есть сложность
		if player_data.has("difficulty"):
			GameManager.set_difficulty(player_data["difficulty"])
		print("Level: Player initialized from save data.")
	else:
		# Если данных нет, инициализируем игрока по умолчанию
		health = 100
		score = 0
		player.health = health
		player.score = score
		# Сложность можно установить через GameManager, если нужно
		# GameManager.set_difficulty(...)
		print("Level: Starting new game with default player values.")

# - ДОБАВЛЯЕМ МЕТОД ДЛЯ ОБНОВЛЕНИЯ HUD -
func update_hud():
	if health_label:
		health_label.text = "Health: " + str(health)
	if score_label:
		score_label.text = "Score: " + str(score)

# - ОБНОВЛЯЕМ HUD КАЖДЫЙ КАДР -
func _process(_delta):
	if is_game_over or is_game_paused:
		return
	# Другая игровая логика, если есть

# - МЕТОДЫ ДЛЯ ИЗМЕНЕНИЯ ЗДОРОВЬЯ И СЧЕТА -
# Теперь, когда у нас есть HUD, мы должны обновлять его при изменении этих значений.
func take_damage(amount: int):
	health -= amount
	health = max(0, health) # Здоровье не может быть меньше 0
	player.set_health(health) # Обновляем здоровье у игрока, если нужно
	update_hud() # Обновляем HUD
	if health <= 0:
		game_over()

func add_score(points: int):
	score += points
	player.set_score(score) # Обновляем счет у игрока, если нужно
	update_hud() # Обновляем HUD

func game_over():
	if is_game_over:
		return
	is_game_over = true
	print("Game Over!")
	show_message("Game Over!", 3.0)
	# ✅ Отключаем обработку _unhandled_input
	set_process_unhandled_input(false)
	# Здесь можно добавить другую логику окончания игры
	# Например, переход в главное меню через таймер
	# await get_tree().create_timer(3.0).timeout
	# if is_game_over: # Проверяем, не был ли сброшен флаг
	#     get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# - МЕТОДЫ ДЛЯ ПАУЗЫ -
func _unhandled_input(event):
	# Добавим отладочный вывод ТОЛЬКО для действий "pause"
 	# Это поможет увидеть, если событие действительно приходит
	if event.is_action("pause") and event is InputEventKey and event.pressed:
		print("Level._unhandled_input: 'pause' action key event: ", event.as_text(), " (Keycode: ", event.keycode, ")")

	if event.is_action_pressed("pause") and not is_game_over:
		print("Level._unhandled_input: Pause action pressed and game is NOT over. Processing...")
		if not is_game_paused:
			pause_game()
		else:
			resume_game()
		get_viewport().set_input_as_handled()
		print("Level._unhandled_input: Event handled for pause.")
	elif is_game_over:
		# ✅ ВАЖНО: Сообщаем Godot, что событие обработано (даже если мы его игнорируем)
		# Это предотвращает повторную отправку события
		if event is InputEventKey and event.pressed:
			print("Level._unhandled_input: Game is over. Key '", event.as_text(), "' ignored.")
		get_viewport().set_input_as_handled()
		# print("Level._unhandled_input: Event handled (game over).") # Можно убрать, чтобы не засорять консоль
	else:
		# Для всех остальных событий, если игра не окончена и это не "pause"
		# Также можно добавить set_input_as_handled, если вы уверены, что обработали всё.
		# Если не уверены, лучше не трогать.
		pass

func pause_game():
	if is_game_paused or is_game_over:
		return
	print("DEBUG: LEVEL: Pausing game...")
	is_game_paused = true
	get_tree().paused = true
	if pause_menu:
		# Передаем ссылку на игрока и текущие данные в меню паузы
		pause_menu.show_pause_menu(player, health, score)
	print("DEBUG: LEVEL: Game paused.")

func resume_game():
	if not is_game_paused:
		return
	print("Resuming game...")
	is_game_paused = false
	get_tree().paused = false
	if pause_menu:
		pause_menu.hide_pause_menu()
	print("Game resumed")

# - ОБРАБОТЧИКИ СИГНАЛОВ ОТ МЕНЮ ПАУЗЫ -
func _on_pause_menu_resumed():
	print("PAUSE MENU RESUMED SIGNAL RECEIVED IN LEVEL!")
	resume_game()

func _on_pause_menu_exit_requested():
	print("LEVEL: PAUSE MENU EXIT REQUESTED SIGNAL RECEIVED!")
	is_game_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# - МЕТОД ДЛЯ ПОКАЗА СООБЩЕНИЙ -
func show_message(text: String, hide_after: float = 0.0):
	if message_label:
		message_label.text = text
		message_label.show()
		if hide_after > 0:
			await get_tree().create_timer(hide_after).timeout
			# Проверяем, не изменился ли текст за время ожидания
			if message_label and message_label.text == text:
				message_label.hide()

# res://scripts/PauseMenu.gd
extends Control

signal resumed
signal exit_requested

@onready var resume_button = $MarginContainer/VBoxContainer/ResumeButton
@onready var save_game_button = $MarginContainer/VBoxContainer/SaveGameButton
@onready var load_game_button = $MarginContainer/VBoxContainer/LoadGameButton
@onready var preferences_button = $MarginContainer/VBoxContainer/PreferencesButton
@onready var about_button = $MarginContainer/VBoxContainer/AboutButton
@onready var exit_button = $MarginContainer/VBoxContainer/ExitButton

@onready var pause_save_game_menu = $PauseSaveGameMenu
@onready var pause_load_game_menu = $PauseLoadGameMenu
@onready var pause_preferences_menu = $PausePreferencesMenu
@onready var pause_about_menu = $PauseAboutMenu

var _player: CharacterBody2D = null
var _health: int = 100
var _score: int = 0

func _ready():
	hide()
	set_process_unhandled_input(true)
	_connect_main_buttons()
	_connect_submenu_signals()
	hide_all_submenus()
	print("PauseMenu signals connected")

func _connect_main_buttons():
	var button_connections = {
		resume_button: "_on_resume_button_pressed",
		save_game_button: "_on_save_game_button_pressed",
		load_game_button: "_on_load_game_button_pressed",
		preferences_button: "_on_pause_preferences_button_pressed", # ✅ Исправлено имя метода
		about_button: "_on_about_button_pressed",
		exit_button: "_on_exit_button_pressed"
	}

	# ✅ Этот цикл находится ВНУТРИ метода и корректно использует button_connections
	for button in button_connections.keys():
		var method_name = button_connections[button]
		if button and self.has_method(method_name):
			var callable = Callable(self, method_name)
			if !button.is_connected("pressed", callable):
				var err = button.connect("pressed", callable)
				if err == OK:
					print("CODE CONNECTED '", button.name, ".pressed' to '", method_name, "'")
				else:
					print("Failed to connect '", button.name, ".pressed' to '", method_name, "', error: ", err)

# ✅ Метод для обработки нажатия кнопки "Preferences"
func _on_pause_preferences_button_pressed():
	hide_main_menu()
	if pause_preferences_menu:
		pause_preferences_menu.initialize_menu()
		pause_preferences_menu.show()

func _connect_submenu_signals():
	var submenus = [pause_save_game_menu, pause_load_game_menu, pause_preferences_menu, pause_about_menu]
	for menu in submenus:
		if menu and menu.has_signal("back_pressed"):
			var method_name = "_on_" + menu.name.to_snake_case() + "_back_pressed"
			if self.has_method(method_name):
				var callable = Callable(self, method_name)
				if not menu.is_connected("back_pressed", callable):
					menu.connect("back_pressed", callable)

func show_pause_menu(player_node: CharacterBody2D, health: int, score: int):
	show()
	_player = player_node
	_health = health
	_score = score
	show_main_menu()
	print("Pause menu shown")

func hide_pause_menu():
	hide()

func show_main_menu():
	hide_all_submenus()
	$MarginContainer/VBoxContainer.show()

func hide_main_menu():
	$MarginContainer/VBoxContainer.hide()

func hide_all_submenus():
	for menu in [pause_save_game_menu, pause_load_game_menu, pause_preferences_menu, pause_about_menu]:
		if menu:
			menu.hide()

func _on_resume_button_pressed():
	hide_pause_menu()
	emit_signal("resumed")

func _on_save_game_button_pressed():
	print("PAUSE MENU: SAVE GAME BUTTON PRESSED!")
	hide_main_menu()
	if pause_save_game_menu and pause_save_game_menu.has_method("initialize_menu"):
		pause_save_game_menu.initialize_menu(_player, _health, _score)
	pause_save_game_menu.show()

func _on_load_game_button_pressed():
	hide_main_menu()
	if pause_load_game_menu and pause_load_game_menu.has_method("initialize_menu"):
		pause_load_game_menu.initialize_menu()
		pause_load_game_menu.show()

# ✅ Этот метод теперь просто вызывает _on_pause_preferences_button_pressed
# Он нужен для обратной совместимости, если на кнопку в сцене визуально подключен именно он.
func _on_preferences_button_pressed():
	_on_pause_preferences_button_pressed()

func _unhandled_input(event):
	if is_visible() and event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and key_event.pressed:
			# ✅ Сначала проверяем, открыто ли какое-либо подменю
			if pause_save_game_menu.visible or pause_load_game_menu.visible or pause_preferences_menu.visible or pause_about_menu.visible:
				# ✅ Эмулируем нажатие кнопки "Back" в активном подменю
				if pause_save_game_menu.visible:
					pause_save_game_menu._on_back_button_pressed()
				elif pause_load_game_menu.visible:
					pause_load_game_menu._on_back_button_pressed()
				elif pause_preferences_menu.visible:
					pause_preferences_menu._on_back_button_pressed() # ✅ Эмулируем нажатие кнопки "Back"
				elif pause_about_menu.visible:
					pause_about_menu._on_back_button_pressed()
				# ✅ ВАЖНО: Обрабатываем событие, чтобы оно не всплыло дальше
				get_viewport().set_input_as_handled()
				return
			else:
				# ✅ Только если подменю не открыто, возобновляем игру
				_on_resume_button_pressed()
				get_viewport().set_input_as_handled()
				return

func _on_about_button_pressed():
	hide_main_menu()
	if pause_about_menu:
		pause_about_menu.show()

func _on_exit_button_pressed():
	emit_signal("exit_requested")

func _on_pause_save_game_menu_back_pressed():
	show_main_menu()

func _on_pause_load_game_menu_back_pressed():
	show_main_menu()

func _on_pause_preferences_menu_back_pressed():
	show_main_menu()

func _on_pause_about_menu_back_pressed():
	show_main_menu()

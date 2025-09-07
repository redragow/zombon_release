# res://scripts/MainMenu.gd
extends Control

@onready var main_menu_content = $MainMenuContent
@onready var difficulty_menu = $DifficultyMenu
@onready var load_menu = $LoadGameMenu
@onready var preferences_menu = $PreferencesMenu
@onready var about_menu = $AboutMenu

func _ready():
	hide_all_submenus()
	print("Main Menu initialized")
	_connect_main_buttons()
	_connect_submenu_signals()

func _connect_main_buttons():
	$MainMenuContent/MarginContainer/VBoxContainer/NewGameButton.connect("pressed", Callable(self, "_on_new_game_button_pressed"))
	$MainMenuContent/MarginContainer/VBoxContainer/LoadGameButton.connect("pressed", Callable(self, "_on_load_game_button_pressed"))
	$MainMenuContent/MarginContainer/VBoxContainer/PreferencesButton.connect("pressed", Callable(self, "_on_preferences_button_pressed"))
	$MainMenuContent/MarginContainer/VBoxContainer/AboutButton.connect("pressed", Callable(self, "_on_about_button_pressed"))
	$MainMenuContent/MarginContainer/VBoxContainer/ExitButton.connect("pressed", Callable(self, "_on_exit_game_button_pressed"))

func _connect_submenu_signals():
	difficulty_menu.connect("back_pressed", Callable(self, "_on_difficulty_menu_back_pressed"))
	load_menu.connect("back_pressed", Callable(self, "_on_load_menu_back_pressed"))
	preferences_menu.connect("back_pressed", Callable(self, "_on_preferences_menu_back_pressed"))
	about_menu.connect("back_pressed", Callable(self, "_on_about_menu_back_pressed"))

func _on_new_game_button_pressed():
	hide_main_menu()
	difficulty_menu.show()

func _on_load_game_button_pressed():
	hide_main_menu()
	load_menu.initialize_menu()

func _on_preferences_button_pressed():
	print("Preferences button pressed")
	hide_main_menu()
	if preferences_menu:
		preferences_menu.initialize_menu() # Используем initialize_menu

func _on_about_button_pressed():
	hide_main_menu()
	about_menu.show()

func _on_exit_game_button_pressed():
	get_tree().quit()

func hide_main_menu():
	main_menu_content.hide()

func show_main_menu():
	hide_all_submenus()
	main_menu_content.show()

func hide_all_submenus():
	for menu in [difficulty_menu, load_menu, preferences_menu, about_menu]:
		if menu:
			menu.hide()

# Сигналы от подменю
func _on_difficulty_menu_back_pressed():
	show_main_menu()

func _on_load_menu_back_pressed():
	show_main_menu()

func _on_preferences_menu_back_pressed():
	show_main_menu()

func _on_about_menu_back_pressed():
	show_main_menu()

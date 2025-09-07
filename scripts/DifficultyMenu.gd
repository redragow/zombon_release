# res://scripts/DifficultyMenu.gd
extends Control

signal back_pressed

@onready var easy_button = $MarginContainer/VBoxContainer/EasyButton
@onready var medium_button = $MarginContainer/VBoxContainer/MediumButton
@onready var hard_button = $MarginContainer/VBoxContainer/HardButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton

func _ready():
	hide()
	print("DifficultyMenu initialized")
	_connect_buttons()

func _connect_buttons():
	easy_button.connect("pressed", Callable(self, "_on_easy_button_pressed"))
	medium_button.connect("pressed", Callable(self, "_on_medium_button_pressed"))
	hard_button.connect("pressed", Callable(self, "_on_hard_button_pressed"))
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

func _on_easy_button_pressed():
	start_game_with_difficulty(0)

func _on_medium_button_pressed():
	start_game_with_difficulty(1)

func _on_hard_button_pressed():
	start_game_with_difficulty(2)

func start_game_with_difficulty(difficulty_level):
	if Engine.has_singleton("GameManager"):
		GameManager.set_difficulty(difficulty_level)
		GameManager.set_game_state(1)  # PLAYING
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

func _on_back_button_pressed():
	hide()
	emit_signal("back_pressed")

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

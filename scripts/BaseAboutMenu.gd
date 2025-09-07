# res://scripts/BaseAboutMenu.gd
class_name BaseAboutMenu
extends Control

# --- АБСТРАКТНЫЙ МЕТОД ---
# Дочерние классы ДОЛЖНЫ реализовать этот метод для получения ссылки на кнопку "Назад"
func _get_back_button() -> Button:
	push_error("Method '_get_back_button' must be overridden in child class!")
	return null

# --- ОБЩИЙ СИГНАЛ ---
signal back_pressed

# --- ОБЩАЯ ЛОГИКА ---
func _ready():
	hide()
	var back_btn = _get_back_button()
	if back_btn and not back_btn.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_btn.connect("pressed", Callable(self, "_on_back_button_pressed"))
	print("BaseAboutMenu initialized")

func _on_back_button_pressed():
	hide()
	emit_signal("back_pressed")

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

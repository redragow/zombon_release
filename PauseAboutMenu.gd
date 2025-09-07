# res://scripts/PauseAboutMenu.gd
extends "BaseAboutMenu.gd"

# --- РЕАЛИЗАЦИЯ АБСТРАКТНОГО МЕТОДА ---
func _get_back_button() -> Button:
	return $PauseAboutMarginContainer/PauseAboutVBoxContainer/PauseAboutBackButton

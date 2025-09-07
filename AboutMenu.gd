# res://scripts/AboutMenu.gd
extends "BaseAboutMenu.gd"

# --- РЕАЛИЗАЦИЯ АБСТРАКТНОГО МЕТОДА ---
func _get_back_button() -> Button:
	return $AboutMarginContainer/AboutVBoxContainer/AboutBackButton

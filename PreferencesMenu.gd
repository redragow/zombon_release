# res://scripts/PreferencesMenu.gd
extends "BasePreferencesMenu.gd"

# Словарь для сопоставления имен действий с именами кнопок в сцене
@export var action_button_names: Dictionary = {
	ACTION_LEFT: "LeftButton",
	ACTION_RIGHT: "RightButton",
	ACTION_JUMP: "JumpButton",
	ACTION_ATTACK: "AttackButton"
}

# --- РЕАЛИЗАЦИЯ АБСТРАКТНЫХ МЕТОДОВ ---
func _get_button_for_action(action_name: String) -> Button:
	var button_node_name = action_button_names.get(action_name, "")
	if button_node_name != "":
		return find_child(button_node_name, true, false)
	return null

func _get_reset_button() -> Button:
	return $MarginContainer/VBoxContainer/ResetButton

func _get_back_button() -> Button:
	return $MarginContainer/VBoxContainer/PreferencesBackButton

func _get_message_label() -> Label:
	return $MarginContainer/VBoxContainer/MessageLabel

# --- ДОПОЛНИТЕЛЬНАЯ ИНИЦИАЛИЗАЦИЯ (если нужна) ---
func _ready():
	# Вызываем _ready() родительского класса
	super._ready()
	# Дополнительная логика, специфичная для главного меню (если есть)

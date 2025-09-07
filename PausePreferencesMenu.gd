# res://scripts/PausePreferencesMenu.gd
extends "BasePreferencesMenu.gd"

# Словарь для сопоставления имен действий с именами кнопок в сцене
@export var action_button_names: Dictionary = {
	ACTION_LEFT: "PausePrefsLeftButton",
	ACTION_RIGHT: "PausePrefsRightButton",
	ACTION_JUMP: "PausePrefsJumpButton",
	ACTION_ATTACK: "PausePrefsAttackButton"
}

# --- РЕАЛИЗАЦИЯ АБСТРАКТНЫХ МЕТОДОВ ---
func _get_button_for_action(action_name: String) -> Button:
	var button_node_name = action_button_names.get(action_name, "")
	if button_node_name != "":
		return find_child(button_node_name, true, false)
	return null

func _get_reset_button() -> Button:
	return $PausePrefsMarginContainer/PausePrefsVBoxContainer/PausePrefsResetButton

func _get_back_button() -> Button:
	return $PausePrefsMarginContainer/PausePrefsVBoxContainer/PausePrefsBackButton

func _get_message_label() -> Label:
	return $PausePrefsMarginContainer/PausePrefsVBoxContainer/PausePrefsMessageLabel

# --- ДОПОЛНИТЕЛЬНАЯ ИНИЦИАЛИЗАЦИЯ ---
func _ready():
	# Вызываем _ready() родительского класса
	super._ready() # <-- Исправлено: Используем super
	# Устанавливаем режим обработки, специфичный для паузы
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	print("PausePreferencesMenu specific initialization")

func initialize_menu():
	super.initialize_menu() # <-- Исправлено: Используем super
	print("PausePreferencesMenu initialized via initialize_menu()")

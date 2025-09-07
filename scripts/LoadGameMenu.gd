# res://scripts/LoadGameMenu.gd
# Этот скрипт полностью дублирует логику из PauseSaveGameMenu.gd для меню загрузки
# чтобы избежать проблем с наследованием и сигналами.
extends Control

# Сигнал для возврата в родительское меню
signal back_pressed

const SLOTS_PER_PAGE = 5
const TOTAL_SLOTS = 100
var current_page = 0
var total_pages = 20

# --- Методы для получения ссылок на узлы ---
func _get_slot_container() -> VBoxContainer:
	return $LoadMenuMarginContainer/LoadMenuVBoxContainer/LoadMenuSlotContainer

func _get_prev_button() -> Button:
	return $LoadMenuMarginContainer/LoadMenuVBoxContainer/LoadMenuNavigationContainer/LoadMenuPrevButton

func _get_next_button() -> Button:
	return $LoadMenuMarginContainer/LoadMenuVBoxContainer/LoadMenuNavigationContainer/LoadMenuNextButton

func _get_page_label() -> Label:
	return $LoadMenuMarginContainer/LoadMenuVBoxContainer/LoadMenuNavigationContainer/LoadMenuPageLabel

func _get_message_label() -> Label:
	return $LoadMenuMarginContainer/LoadMenuVBoxContainer/LoadMenuMessageLabel

func _get_back_button() -> Button:
	return $LoadMenuMarginContainer/LoadMenuVBoxContainer/LoadMenuBackButton

# --- Инициализация ---
func _ready():
	hide()
	print("LoadGameMenu initialized")
	_connect_signals() # Подключение сигналов из кода (на всякий случай, если в .tscn их нет)
	update_navigation()
	# Устанавливаем жёлтый цвет для текста сообщения
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.add_theme_color_override("font_color", Color(1, 1, 0)) # Жёлтый цвет

# --- Подключение сигналов с проверкой ---
func _connect_signals():
	var back_btn = _get_back_button()
	if back_btn and not back_btn.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_btn.connect("pressed", Callable(self, "_on_back_button_pressed"))

	var prev_btn = _get_prev_button()
	# ✅ ИСПРАВЛЕНИЕ: Проверка is_connected перед подключением
	if prev_btn and not prev_btn.is_connected("pressed", Callable(self, "_on_prev_button_pressed")):
		prev_btn.connect("pressed", Callable(self, "_on_prev_button_pressed"))

	var next_btn = _get_next_button()
	# ✅ ИСПРАВЛЕНИЕ: Проверка is_connected перед подключением
	if next_btn and not next_btn.is_connected("pressed", Callable(self, "_on_next_button_pressed")):
		next_btn.connect("pressed", Callable(self, "_on_next_button_pressed"))

# --- Логика пагинации ---
func _on_prev_button_pressed():
	if current_page > 0:
		current_page -= 1
		update_page()
		update_navigation()

func _on_next_button_pressed():
	if current_page < total_pages - 1:
		current_page += 1
		update_page()
		update_navigation()

# --- Обновление содержимого страницы ---
func update_page():
	var slot_container = _get_slot_container()
	if not slot_container:
		return

	# Очищаем контейнер
	for child in slot_container.get_children():
		child.queue_free()

	# Создаем кнопки слотов для текущей страницы
	var start_slot = current_page * SLOTS_PER_PAGE
	var end_slot = min(start_slot + SLOTS_PER_PAGE, TOTAL_SLOTS)

	for i in range(start_slot, end_slot):
		var slot_button = Button.new()
		slot_button.name = "SlotButton" + str(i)
		# --- НАЧАЛО ИЗМЕНЕНИЯ: Установка размера ---
		slot_button.custom_minimum_size = Vector2(200, 50)
		# --- КОНЕЦ ИЗМЕНЕНИЯ ---
		slot_button.text = "Slot " + str(i)

		# Проверяем, существует ли файл сохранения
		var save_path = "user://save_" + str(i) + ".save"
		if FileAccess.file_exists(save_path):
			# ... (остальная логика для существующих слотов) ...
			slot_button.text += " (Saved)"
			slot_button.connect("pressed", Callable(self, "_on_slot_button_pressed").bind(i))
		else:
			# ... (остальная логика для пустых слотов) ...
			slot_button.text += " (Empty)"
			slot_button.disabled = true

		slot_container.add_child(slot_button)

# --- Обновление навигации ---
func update_navigation():
	var prev_btn = _get_prev_button()
	var next_btn = _get_next_button()
	var page_lbl = _get_page_label()

	if prev_btn:
		prev_btn.disabled = (current_page == 0)
	if next_btn:
		next_btn.disabled = (current_page >= total_pages - 1)
	if page_lbl:
		page_lbl.text = "Page " + str(current_page + 1) + " of " + str(total_pages)

# --- Обработка нажатия на слот ---
func _on_slot_button_pressed(slot_index: int):
	print("LoadGameMenu: Slot button ", slot_index, " pressed.")
	# 1. Загрузить данные через GameManager
	# ✅ ИСПРАВЛЕНИЕ: Используем правильный метод из GameManager.gd
	var success = GameManager.load_game_data_only(slot_index)
	if success:
		# 2. Перейти на сцену уровня
		get_tree().change_scene_to_file("res://scenes/Level.tscn")
	else:
		# Обработка ошибки загрузки (опционально)
		var msg_lbl = _get_message_label()
		if msg_lbl:
			msg_lbl.text = "Failed to load slot " + str(slot_index) + "."
			# Можно добавить таймер для возврата к предыдущему сообщению

# --- Обработка кнопки "Назад" ---
func _on_back_button_pressed():
	hide()
	emit_signal("back_pressed")

# --- Публичный метод для инициализации меню ---
func initialize_menu():
	show()
	current_page = 0
	update_page()
	update_navigation()
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.text = "Select a slot to load."

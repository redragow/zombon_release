# res://scripts/PauseLoadGameMenu.gd
# Этот скрипт полностью самостоятелен для меню загрузки в паузе.
extends Control

# Сигнал для возврата в родительское меню паузы
signal back_pressed
# Сигнал для запроса загрузки игры (обрабатывается в Level.gd)
signal load_game_requested(slot_index: int)

const SLOTS_PER_PAGE = 5
const TOTAL_SLOTS = 100
var current_page = 0
var total_pages = 20

# --- Методы для получения ссылок на узлы ---
func _get_slot_container() -> VBoxContainer:
	return $PauseLoadMenuMarginContainer/PauseLoadMenuVBoxContainer/PauseLoadMenuSlotContainer

func _get_prev_button() -> Button:
	return $PauseLoadMenuMarginContainer/PauseLoadMenuVBoxContainer/PauseLoadMenuNavigationContainer/PauseLoadMenuPrevButton

func _get_next_button() -> Button:
	return $PauseLoadMenuMarginContainer/PauseLoadMenuVBoxContainer/PauseLoadMenuNavigationContainer/PauseLoadMenuNextButton

func _get_page_label() -> Label:
	return $PauseLoadMenuMarginContainer/PauseLoadMenuVBoxContainer/PauseLoadMenuNavigationContainer/PauseLoadMenuPageLabel

func _get_message_label() -> Label:
	return $PauseLoadMenuMarginContainer/PauseLoadMenuVBoxContainer/PauseLoadMenuMessageLabel

func _get_back_button() -> Button:
	return $PauseLoadMenuMarginContainer/PauseLoadMenuVBoxContainer/PauseLoadMenuBackButton

# --- Инициализация ---
func _ready():
	hide()
	print("PauseLoadGameMenu initialized")
	_connect_signals() # Подключаем все сигналы
	update_navigation() # Устанавливаем начальное состояние навигации

# --- Подключение всех сигналов с проверкой на дубликаты ---
func _connect_signals():
	var back_btn = _get_back_button()
	if back_btn and not back_btn.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_btn.connect("pressed", Callable(self, "_on_back_button_pressed"))

	var prev_btn = _get_prev_button()
	if prev_btn and not prev_btn.is_connected("pressed", Callable(self, "_on_prev_button_pressed")):
		prev_btn.connect("pressed", Callable(self, "_on_prev_button_pressed"))

	var next_btn = _get_next_button()
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

# --- Обновление состояния кнопок навигации и метки страницы ---
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

# --- Обработка нажатия на кнопку слота ---
func _on_slot_button_pressed(slot_index: int):
	print("PauseLoadGameMenu: Load requested from slot ", slot_index)
	# Эмитируем сигнал, который будет обработан в Level.gd для выполнения загрузки
	emit_signal("load_game_requested", slot_index)

# --- Обработка нажатия кнопки "Назад" ---
func _on_back_button_pressed():
	hide()
	emit_signal("back_pressed")

# --- Публичный метод для инициализации и отображения меню ---
func initialize_menu():
	show()
	current_page = 0
	update_page()
	update_navigation()
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.text = "Select a slot to load."

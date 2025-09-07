# res://scripts/BaseLoadGameMenu.gd
class_name BaseLoadGameMenu
extends Control

signal back_pressed # Сигнал для возврата в родительское меню

const SLOTS_PER_PAGE = 5
const TOTAL_SLOTS = 100

var current_page: int = 0
var total_pages: int = 20

# --- АБСТРАКТНЫЕ МЕТОДЫ ---
# Дочерние классы ДОЛЖНЫ реализовать эти методы
func _get_slot_container() -> VBoxContainer:
	push_error("Method '_get_slot_container' must be overridden in child class!")
	return null

func _get_prev_button() -> Button:
	push_error("Method '_get_prev_button' must be overridden in child class!")
	return null

func _get_next_button() -> Button:
	push_error("Method '_get_next_button' must be overridden in child class!")
	return null

func _get_page_label() -> Label:
	push_error("Method '_get_page_label' must be overridden in child class!")
	return null

func _get_message_label() -> Label:
	push_error("Method '_get_message_label' must be overridden in child class!")
	return null

func _get_back_button() -> Button:
	push_error("Method '_get_back_button' must be overridden in child class!")
	return null

# --- ОБЩАЯ ЛОГИКА ---
func _ready():
	hide()
	_connect_signals()
	update_navigation()

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

func initialize_menu():
	show()
	current_page = 0
	# ✅ КРИТИЧЕСКОЕ ИЗМЕНЕНИЕ: Переподключаем сигналы ПЕРЕД обновлением состояния.
	# Это гарантирует, что кнопки "Prev" и "Next" будут работать, даже если
	# что-то пошло не так при первом вызове _ready().
	_connect_signals()
	update_page()
	_hide_message()

func update_page():
	var container = _get_slot_container()
	for child in container.get_children():
		child.queue_free()

	var start_slot = current_page * SLOTS_PER_PAGE
	for i in range(SLOTS_PER_PAGE):
		var slot_index = start_slot + i
		var button = Button.new()
		button.name = "Slot" + str(slot_index)
		button.text = "Slot " + str(slot_index + 1)

		if GameManager.slot_exists(slot_index):
			var timestamp = GameManager.get_slot_timestamp(slot_index)
			if timestamp > 0:
				var date = Time.get_date_string_from_unix_time(timestamp)
				var time = Time.get_time_string_from_unix_time(timestamp)
				button.text += "\n" + date + " " + time
			button.connect("pressed", Callable(self, "_on_slot_pressed").bind(slot_index))
		else:
			button.text += "\nEmpty"
			button.disabled = true
			button.modulate = Color(0.7, 0.7, 0.7)

		container.add_child(button)

	update_navigation()

func update_navigation():
	var prev_btn = _get_prev_button()
	var next_btn = _get_next_button()
	var page_lbl = _get_page_label()

	if prev_btn:
		prev_btn.disabled = current_page == 0
	if next_btn:
		next_btn.disabled = current_page == total_pages - 1
	if page_lbl:
		page_lbl.text = "Page " + str(current_page + 1) + " of " + str(total_pages)

func _on_slot_pressed(slot_index):
	if GameManager.slot_exists(slot_index):
		_show_message("Loading game from slot " + str(slot_index + 1) + "...")

		var success = false

		# ✅ Проверяем, в каком контексте мы находимся
		if get_parent().name == "MainMenu": # Загрузка из главного меню
			success = GameManager.load_game_data_only(slot_index)
			if success:
				_show_message("Data loaded! Starting game...", 2.0)
				await get_tree().create_timer(2.0).timeout
				get_tree().change_scene_to_file("res://scenes/Level.tscn")
			else:
				_show_message("Error loading data.", 2.0)
		else: # Загрузка из меню паузы (PauseMenu)
			success = GameManager.load_game(slot_index)
			if success:
				_show_message("Game loaded successfully!", 2.0)
				# Снимаем паузу (если были в паузе)
				get_tree().paused = false
				# Закрываем меню
				hide()
				# Уведомляем родительское меню
				emit_signal("back_pressed")
				# Перезагружаем текущую сцену, чтобы применить данные
				get_tree().reload_current_scene()
			else:
				_show_message("Error loading game.", 2.0)
	else:
		_show_message("Slot is empty.", 2.0)

# --- Обработка "Назад" (переопределяется в дочерних классах) ---
func _on_back_button_pressed():
	hide()
	emit_signal("back_pressed")

# --- Вспомогательные методы ---
func _show_message(text: String, hide_after: float = 0.0):
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.text = text
		msg_lbl.show()
		if hide_after > 0:
			await get_tree().create_timer(hide_after).timeout
			if msg_lbl.text == text:
				_hide_message()

func _hide_message():
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.hide()
		msg_lbl.text = ""

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

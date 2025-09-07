# res://scripts/PauseSaveGameMenu.gd
extends Control

# Сигнал для возврата в меню паузы
signal back_pressed

const SLOTS_PER_PAGE = 5
const TOTAL_SLOTS = 100
var current_page = 0
var total_pages = 20

# ✅ Пути исправлены согласно вашей сцене
@onready var slot_container = $PauseSaveMenuMarginContainer/PauseSaveMenuVBoxContainer/PauseSaveMenuSlotContainer
@onready var prev_button = $PauseSaveMenuMarginContainer/PauseSaveMenuVBoxContainer/PauseSaveMenuNavigationContainer/PauseSaveMenuPrevButton
@onready var next_button = $PauseSaveMenuMarginContainer/PauseSaveMenuVBoxContainer/PauseSaveMenuNavigationContainer/PauseSaveMenuNextButton
@onready var page_label = $PauseSaveMenuMarginContainer/PauseSaveMenuVBoxContainer/PauseSaveMenuNavigationContainer/PauseSaveMenuPageLabel
@onready var message_label = $PauseSaveMenuMarginContainer/PauseSaveMenuVBoxContainer/PauseSaveMenuMessageLabel
@onready var back_button = $PauseSaveMenuMarginContainer/PauseSaveMenuVBoxContainer/PauseSaveMenuBackButton
@onready var confirmation_dialog: AcceptDialog = $PauseSaveMenuConfirmationDialog

func _ready():
	hide()
	print("PauseSaveGameMenu initialized")
	_connect_signals()
	update_navigation()

	# Устанавливаем жёлтый цвет для текста сообщения
	if message_label:
		message_label.add_theme_color_override("font_color", Color(1, 1, 0)) # Жёлтый цвет

# --- Настройка внешнего вида ConfirmationDialog ---
	if confirmation_dialog:
		# 1. Устанавливаем цвет текста (белый или жёлтый)
		confirmation_dialog.add_theme_color_override("font_color", Color(1, 1, 0)) # Жёлтый
		# Или: confirmation_dialog.add_theme_color_override("font_color", Color(1, 1, 1)) # Белый

		# 2. Убираем белую рамку (обводку)
		confirmation_dialog.add_theme_color_override("border_color", Color(0, 0, 0, 0)) # Прозрачный
		confirmation_dialog.add_theme_color_override("border_color_focus", Color(0, 0, 0, 0))

		# 3. (Опционально) Можно изменить фон
		confirmation_dialog.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.1)) # Тёмный фон

func _connect_signals():
	if !back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	if !prev_button.is_connected("pressed", Callable(self, "_on_prev_button_pressed")):
		prev_button.connect("pressed", Callable(self, "_on_prev_button_pressed"))
	if !next_button.is_connected("pressed", Callable(self, "_on_next_button_pressed")):
		next_button.connect("pressed", Callable(self, "_on_next_button_pressed"))

func _on_back_button_pressed():
	print("PAUSE SAVE GAME MENU BACK BUTTON PRESSED!")
	clear_message()
	hide()
	emit_signal("back_pressed")

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

func _on_slot_pressed(slot_index):
	print("SAVE SLOT ", slot_index, " PRESSED!")
	var slot_exists = GameManager.slot_exists(slot_index)
	if slot_exists:
		# Показываем диалог подтверждения
		confirmation_dialog.dialog_text = "Slot " + str(slot_index + 1) + " already has a save.
Overwrite it?"
		# Подключаемся к сигналам с флагом ONE_SHOT (автоматически отключатся после срабатывания)
		confirmation_dialog.connect("confirmed", Callable(self, "_perform_save").bind(slot_index), CONNECT_ONE_SHOT)
		confirmation_dialog.connect("canceled", Callable(self, "_on_confirmation_canceled"), CONNECT_ONE_SHOT)
		confirmation_dialog.popup_centered()
		# Блокируем UI
		_disable_all_buttons()
	else:
		# Сохраняем без подтверждения
		_perform_save(slot_index)

func _on_confirmation_canceled():
	print("Save confirmation canceled by user (X or Cancel pressed)")
	_enable_all_buttons()

func update_page():
	for child in slot_container.get_children():
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
				button.text += "\n" + date + " " + time + "\n(Click to Overwrite)"
		else:
			button.text += "\nEmpty\n(Click to Save)"
		button.connect("pressed", Callable(self, "_on_slot_pressed").bind(slot_index))
		slot_container.add_child(button)

	update_navigation()

func update_navigation():
	prev_button.disabled = current_page == 0
	next_button.disabled = current_page == total_pages - 1
	page_label.text = "Page " + str(current_page + 1) + " of " + str(total_pages)

func _perform_save(slot_index):
	_show_message("Saving game to slot " + str(slot_index + 1) + "...")

	# Получаем данные игрока
	var player = GameManager.get_player_reference()
	if not player:
		_show_message("Error: Player not found!", 2.0)
		_enable_all_buttons()
		return

	# Сохраняем через GameManager
	if GameManager.save_game(slot_index, player.position, player.health, player.score):
		_show_message("Game saved successfully to slot " + str(slot_index + 1), 2.0)
		update_page()
	else:
		_show_message("Error saving game to slot " + str(slot_index + 1), 2.0)

	_enable_all_buttons()

func initialize_menu(player_node = null, _initial_health: int = 100, _initial_score: int = 0):
	show()
	if player_node:
		GameManager.set_player_reference(player_node)
	update_page()

func _show_message(text: String, hide_after: float = 0.0):
	if message_label:
		message_label.text = text
		message_label.show()
		if hide_after > 0:
			# Используем таймер без await, чтобы не блокировать выполнение
			var timer = get_tree().create_timer(hide_after)
			timer.connect("timeout", Callable(self, "_on_message_timer_timeout").bind(text))

func _on_message_timer_timeout(expected_text):
	if message_label and message_label.text == expected_text:
		_hide_message()

func _hide_message():
	if message_label:
		message_label.hide()
		message_label.text = ""

func clear_message():
	_hide_message()

func _disable_all_buttons():
	for child in slot_container.get_children():
		if child is Button:
			child.disabled = true
	back_button.disabled = true
	prev_button.disabled = true
	next_button.disabled = true

func _enable_all_buttons():
	for child in slot_container.get_children():
		if child is Button:
			child.disabled = false
	back_button.disabled = false
	prev_button.disabled = false
	next_button.disabled = false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled() # Важно: предотвращает всплытие события

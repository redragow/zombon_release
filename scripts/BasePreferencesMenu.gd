# res://scripts/BasePreferencesMenu.gd
class_name BasePreferencesMenu
extends Control

# --- АБСТРАКТНЫЕ МЕТОДЫ ---
# Дочерние классы ДОЛЖНЫ реализовать эти методы для получения ссылок на свои кнопки
func _get_button_for_action(_action_name: String) -> Button:
	push_error("Method '_get_button_for_action' must be overridden in child class!")
	return null

func _get_reset_button() -> Button:
	push_error("Method '_get_reset_button' must be overridden in child class!")
	return null

func _get_back_button() -> Button:
	push_error("Method '_get_back_button' must be overridden in child class!")
	return null

func _get_message_label() -> Label:
	push_error("Method '_get_message_label' must be overridden in child class!")
	return null

# --- ОБЩИЕ КОНСТАНТЫ И ПЕРЕМЕННЫЕ ---
# Сигнал для уведомления родительского меню о необходимости вернуться назад
signal back_pressed

# Определим константы для имен действий
const ACTION_LEFT = "move_left"
const ACTION_RIGHT = "move_right"
const ACTION_JUMP = "jump"
const ACTION_ATTACK = "attack"

# Текст по умолчанию для строки сообщений меню
const DEFAULT_MESSAGE = "Click to change the controls"

# Словарь стандартных настроек: действие -> код клавиши по умолчанию
const DEFAULT_INPUTS = {
	ACTION_LEFT: KEY_A,
	ACTION_RIGHT: KEY_D,
	ACTION_JUMP: KEY_SPACE,
	ACTION_ATTACK: KEY_Z
}

# Переменные для отслеживания ожидания ввода
var waiting_for_action: String = ""
var waiting_button_node: Button = null
var ignore_next_escape: bool = false  # ✅ Флаг для игнорирования следующего Esc

# --- ОБЩАЯ ЛОГИКА ---
func _ready():
	hide()
	set_process_unhandled_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS # ✅ Обрабатывать ввод даже на паузе
	print("BasePreferencesMenu initialized")
	_connect_action_buttons()  # Подключаем сигналы кнопок
	_update_action_labels()    # Обновляем отображение клавиш

func _connect_action_buttons():
	for action_name in [ACTION_LEFT, ACTION_RIGHT, ACTION_JUMP, ACTION_ATTACK]:
		var button_node = _get_button_for_action(action_name)
		if button_node and button_node is Button:
			button_node.connect("pressed", Callable(self, "_on_action_button_pressed").bind(action_name))
			print("Connected button for action '", action_name, "'")

# --- ОБЩАЯ ЛОГИКА НАЗНАЧЕНИЯ КЛАВИШ ---
func _on_action_button_pressed(action_name: String):
	if waiting_for_action != "":
		return
	print("Configuring action: ", action_name)
	waiting_for_action = action_name
	waiting_button_node = _get_button_for_action(action_name)
	if waiting_button_node:
		waiting_button_node.text = "Press a key..."
		_set_action_buttons_disabled(true)
		_set_interface_buttons_disabled(true)
	_show_message("Press a key for '" + action_name + "'. Press 'Escape' to cancel.")

# Обработка ввода пользователя для переназначения клавиш
func _input(event):
	# --- ОБРАБОТКА СОБЫТИЙ КЛАВИАТУРЫ ---
	if waiting_for_action != "" and event is InputEventKey and event.pressed:
		# ✅ Проверка 'echo' ТОЛЬКО для InputEventKey
		if event.echo:
			return # Игнорируем повторяющиеся события

		var key_event = event as InputEventKey

		# --- ОБРАБОТКА ESCAPE ДЛЯ ОТМЕНЫ ---
		if key_event.keycode == KEY_ESCAPE:
			_show_message("Cancelled.")
			_restore_waiting_button_text()
			_set_action_buttons_disabled(false)
			_set_interface_buttons_disabled(false)
			_reset_waiting() # <-- Сбрасываем состояние ожидания
			# ✅ Устанавливаем флаг, чтобы игнорировать следующее нажатие Esc
			# Это предотвратит выход из меню, если событие Esc будет обработано
			# другим блоком кода позже.
			ignore_next_escape = true
			# Используем call_deferred для сброса флага в следующем кадре,
			# после обработки текущего события.
			call_deferred("_deferred_reset_ignore_escape")

			await get_tree().create_timer(2.0).timeout
			_show_default_message()
			# Явно помечаем событие как обработанное
			get_viewport().set_input_as_handled()
			return

		# --- СПИСОК ЗАПРЕЩЕННЫХ КЛАВИШ (мгновенная отмена без сообщений) ---
		# ✅ FIX: Изменено поведение для Enter, Win (Meta), F8.
		# Теперь они ведут себя как Escape: немедленно сбрасывают состояние и возвращают интерфейс в норму.
		match key_event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_META, KEY_F8:
				# Восстанавливаем текст кнопки
				_restore_waiting_button_text()
				# Включаем все кнопки
				_set_action_buttons_disabled(false)
				_set_interface_buttons_disabled(false)
				# Сбрасываем состояние ожидания и визуальное состояние кнопки
				_reset_waiting() # <-- Сбрасываем состояние ожидания
				# ✅ Устанавливаем флаг, чтобы игнорировать следующее нажатие Esc
				ignore_next_escape = true
				call_deferred("_deferred_reset_ignore_escape")
				# ✅ FIX: Сбрасываем сообщение в дефолтное состояние
				_show_default_message()
				get_viewport().set_input_as_handled()
				return # <-- ВАЖНО: return здесь, чтобы не продолжать основную логику

		# --- Основная логика назначения ---
		var is_same_key = false
		var current_events = InputMap.action_get_events(waiting_for_action)
		for ev in current_events:
			if ev.is_match(key_event):
				is_same_key = true
				break

		if is_same_key:
			_show_message("Key '" + _get_key_text_from_event(key_event) + "' is already assigned to '" + waiting_for_action + "'.")
			_restore_waiting_button_text()
			_set_action_buttons_disabled(false)
			_set_interface_buttons_disabled(false)
			_reset_waiting() # <-- Сбрасываем состояние ожидания
			await get_tree().create_timer(2.0).timeout
			_show_default_message()
			get_viewport().set_input_as_handled()
		else:
			var conflicting_action = ""
			for action_name_check in [ACTION_LEFT, ACTION_RIGHT, ACTION_JUMP, ACTION_ATTACK]:
				if action_name_check == waiting_for_action:
					continue
				var check_events = InputMap.action_get_events(action_name_check)
				for ev in check_events:
					if ev.is_match(key_event):
						conflicting_action = action_name_check
						break
				if conflicting_action != "":
					break

			if conflicting_action != "":
				_show_message("Key '" + _get_key_text_from_event(key_event) + "' is already used for '" + conflicting_action + "'!")
				_restore_waiting_button_text()
				_set_action_buttons_disabled(false)
				_set_interface_buttons_disabled(false)
				_reset_waiting() # <-- Сбрасываем состояние ожидания
				await get_tree().create_timer(2.0).timeout
				_show_default_message()
				get_viewport().set_input_as_handled()
			else:
				InputMap.action_erase_events(waiting_for_action)
				InputMap.action_add_event(waiting_for_action, key_event)
				_show_message("Key '" + _get_key_text_from_event(key_event) + "' assigned to '" + waiting_for_action + "'.")
				_update_action_labels()
				_reset_waiting() # <-- Сбрасываем состояние ожидания
				_set_action_buttons_disabled(false)
				_set_interface_buttons_disabled(false)
				# Явно сбрасываем визуальное состояние для кнопки, которая только что завершила назначение
			if waiting_button_node:
				_reset_button_visual_state(waiting_button_node)
				await get_tree().create_timer(2.0).timeout
				_show_default_message()
				get_viewport().set_input_as_handled()

	# --- ОБРАБОТКА МЫШИ (без event.echo) ---
	if waiting_for_action != "" and event is InputEventMouseButton and event.pressed:
		var mouse_event = event as InputEventMouseButton

		# --- Основная логика назначения для мыши ---
		var is_same_key = false
		var current_events = InputMap.action_get_events(waiting_for_action)
		for ev in current_events:
			if ev.is_match(mouse_event):
				is_same_key = true
				break

		if is_same_key:
			_show_message("Mouse button '" + _get_key_text_from_event(mouse_event) + "' is already assigned to '" + waiting_for_action + "'.")
			_restore_waiting_button_text()
			_set_action_buttons_disabled(false)
			_set_interface_buttons_disabled(false)
			_reset_waiting() # <-- Сбрасываем состояние ожидания
			await get_tree().create_timer(2.0).timeout
			_show_default_message()
			get_viewport().set_input_as_handled()
		else:
			var conflicting_action = ""
			for action_name_check in [ACTION_LEFT, ACTION_RIGHT, ACTION_JUMP, ACTION_ATTACK]:
				if action_name_check == waiting_for_action:
					continue
				var check_events = InputMap.action_get_events(action_name_check)
				for ev in check_events:
					if ev.is_match(mouse_event):
						conflicting_action = action_name_check
						break
				if conflicting_action != "":
					break

			if conflicting_action != "":
				_show_message("Mouse button '" + _get_key_text_from_event(mouse_event) + "' is already used for '" + conflicting_action + "'!")
				_restore_waiting_button_text()
				_set_action_buttons_disabled(false)
				_set_interface_buttons_disabled(false)
				_reset_waiting() # <-- Сбрасываем состояние ожидания
				await get_tree().create_timer(2.0).timeout
				_show_default_message()
				get_viewport().set_input_as_handled()
			else:
				InputMap.action_erase_events(waiting_for_action)
				InputMap.action_add_event(waiting_for_action, mouse_event)
				_show_message("Mouse button '" + _get_key_text_from_event(mouse_event) + "' assigned to '" + waiting_for_action + "'.")
				_update_action_labels()
				_reset_waiting() # <-- Сбрасываем состояние ожидания
				_set_action_buttons_disabled(false)
				_set_interface_buttons_disabled(false)
				# Явно сбрасываем визуальное состояние для кнопки, которая только что завершила назначение
			if waiting_button_node:
				_reset_button_visual_state(waiting_button_node)
				await get_tree().create_timer(2.0).timeout
				_show_default_message()
				get_viewport().set_input_as_handled()

	# --- Обработка возврата в родительское меню ---
	# Обрабатываем Esc ТОЛЬКО если мы НЕ в режиме ожидания ввода.
	# Это предотвращает выход из меню во время переназначения клавиш.
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# ✅ Проверка 'echo' ТОЛЬКО для InputEventKey
		if event.echo:
			return

		# Если мы в режиме ожидания ввода, Esc должен быть обработан
		# только логикой внутри блока "if waiting_for_action != "" and event is InputEventKey..."
		# Поэтому здесь мы его игнорируем.
		if waiting_for_action != "":
			# Можем явно пометить событие как обработанное, хотя логика в верхнем блоке _input
			# должна была его поймать.
			get_viewport().set_input_as_handled()
			return

		# Если НЕ в режиме переназначения, проверяем флаг ignore_next_escape
		if ignore_next_escape:
			get_viewport().set_input_as_handled()
			# Сбрасываем флаг
			ignore_next_escape = false
			return

		# Если НЕ в режиме переназначения и не нужно игнорировать Esc — возвращаемся в родительское меню
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
		return

# --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ---

# НОВЫЙ МЕТОД: Сбрасывает визуальное состояние (фокус, hover) для конкретной кнопки
# Это помогает избежать "залипания" выделения
func _reset_button_visual_state(button: Button):
	if not button:
		return
	# 1. Убираем фокус ввода
	button.release_focus()

	# 2. Принудительно сбрасываем визуальное состояние Hover/Pressed
	#    В Godot 4.x нет прямых set_draw_hover/set_draw_pressed, поэтому используем косвенные методы:

	#    a. Временное отключение/включение (наиболее надежный способ)
	#       Это часто сбрасывает внутреннее состояние "hover" или "pressed"
	var original_disabled_state = button.disabled
	button.disabled = true
	# Используем call_deferred, чтобы изменение состояния произошло в следующем кадре,
	# после того, как текущее событие ввода будет полностью обработано.
	button.call_deferred("set_disabled", original_disabled_state)

	#    b. Принудительная перерисовка (дополнительная мера)
	button.queue_redraw()

	# Примечание: set_pressed(false) влияет на состояние Toggle, а не на визуальное нажатие.
	# set_mouse_filter(MOUSE_FILTER_STOP) / PASS не влияет на Hover.
	# Поэтому временный disable/enable - наиболее эффективный путь.

# Вспомогательная функция для получения читаемого текста из события ввода
func _get_key_text_from_event(event):
	if event is InputEventKey:
		var key_event = event as InputEventKey
		match key_event.keycode:
			KEY_SPACE:
				return "Space"
			KEY_BACKSPACE:
				return "Backspace"
			KEY_ENTER, KEY_KP_ENTER:
				return "Enter"
			KEY_ESCAPE:
				return "Escape"
			KEY_TAB:
				return "Tab"
			KEY_SHIFT:
				return "Shift"
			KEY_CTRL:
				return "Ctrl"
			KEY_ALT:
				return "Alt"
			KEY_META:
				return "Meta"
		var key_text = key_event.as_text()
		if key_text.is_empty() or key_text.begins_with("Unknown") or key_text.begins_with("Unmapped"):
			if key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
				return char(key_event.keycode)
			elif key_event.keycode >= KEY_0 and key_event.keycode <= KEY_9:
				return char(key_event.keycode)
			else:
				return "Key " + str(key_event.keycode)
		return key_text
	# Обработчик кнопок у джойстика
	elif event is InputEventJoypadButton:
		var joy_event = event as InputEventJoypadButton
		match joy_event.button_index:
			0: return "Joypad X"
			1: return "Joypad O"
			2: return "Joypad □"
			3: return "Joypad △"
			4: return "Joypad L1"
			5: return "Joypad R1"
			6: return "Joypad L2"
			7: return "Joypad R2"
			8: return "Joypad Select"
			9: return "Joypad Start"
			10: return "Joypad L3"
			11: return "Joypad R3"
			12: return "Joypad ↑"
			13: return "Joypad ↓"
			14: return "Joypad ←"
			15: return "Joypad →"
		return "Joypad Btn " + str(joy_event.button_index)
	elif event is InputEventJoypadMotion:
		var motion_event = event as InputEventJoypadMotion
		match motion_event.axis:
			0:
				if motion_event.axis_value < 0:
					return "Joypad ← (Stick)"
				else:
					return "Joypad → (Stick)"
			1:
				if motion_event.axis_value < 0:
					return "Joypad ↑ (Stick)"
				else:
					return "Joypad ↓ (Stick)"
		return "Joypad Axis " + str(motion_event.axis)
	# Обработчик кнопок у мышки
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			_:
				return "Mouse " + str(mouse_event.button_index)
	return "???"

# Восстанавливает исходный текст на кнопке, которая ожидала ввода
func _restore_waiting_button_text():
	if waiting_button_node:
		var events = InputMap.action_get_events(waiting_for_action)
		if events.size() > 0:
			waiting_button_node.text = _get_key_text_from_event(events[0])
		else:
			waiting_button_node.text = "<Not Set>"
		# waiting_button_node.disabled = false # Это делает _set_action_buttons_disabled(false)
		# Не будем устанавливать disabled здесь, чтобы не конфликтовать с _set_action_buttons_disabled

# Сбрасывает состояние ожидания ввода
func _reset_waiting():
	# Сохраняем ссылку, так как waiting_for_action будет очищен
	var button_to_reset = waiting_button_node
	waiting_for_action = ""
	waiting_button_node = null

	# Явно сбрасываем визуальное состояние для кнопки, которая ожидала ввода
	if button_to_reset:
		_reset_button_visual_state(button_to_reset)

# Отключает или включает все кнопки действий
func _set_action_buttons_disabled(disabled: bool):
	for action_name in [ACTION_LEFT, ACTION_RIGHT, ACTION_JUMP, ACTION_ATTACK]:
		var button_node = _get_button_for_action(action_name)
		if button_node and button_node != waiting_button_node:
			button_node.disabled = disabled

# Отключает или включает кнопки интерфейса (Reset, Back)
func _set_interface_buttons_disabled(disabled: bool):
	var reset_btn = _get_reset_button()
	var back_btn = _get_back_button()
	if reset_btn:
		reset_btn.disabled = disabled
	if back_btn:
		back_btn.disabled = disabled

# Обновляет текст на кнопках действий
func _update_action_labels():
	print("Updating action labels...")
	for action_name in [ACTION_LEFT, ACTION_RIGHT, ACTION_JUMP, ACTION_ATTACK]:
		var button_node = _get_button_for_action(action_name)
		if button_node:
			var events = InputMap.action_get_events(action_name)
			if events.size() > 0:
				var key_text = _get_key_text_from_event(events[0])
				button_node.text = key_text
			else:
				button_node.text = "<Not Set>"
			button_node.disabled = false
	_hide_message()

# Показывает сообщение и (опционально) скрывает его через hide_after секунд
func _show_message(text: String, hide_after: float = 0.0):
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.text = text
		msg_lbl.show()
		if hide_after > 0:
			await get_tree().create_timer(hide_after).timeout
			if msg_lbl.text == text:
				_show_default_message()

func _show_default_message():
	var msg_lbl = _get_message_label()
	if msg_lbl:
		msg_lbl.text = DEFAULT_MESSAGE
		msg_lbl.show()

func _hide_message():
	_show_default_message()

# --- ОБРАБОТКА КНОПКИ "НАЗАД" (переопределяется в дочерних классах, если нужно особое поведение) ---
func _on_back_button_pressed():
	if waiting_for_action != "":
		_restore_waiting_button_text()
		_set_action_buttons_disabled(false)
		_set_interface_buttons_disabled(false)
		# Явно сбрасываем визуальное состояние, если меню закрывается во время ожидания
		_reset_waiting()
	hide()
	emit_signal("back_pressed")

# --- ОБРАБОТКА КНОПКИ "СБРОС" ---
func _on_reset_button_pressed():
	# Явно получаем ссылку на кнопку Reset для сброса её визуального состояния
	var reset_btn = _get_reset_button()

	for action_name in DEFAULT_INPUTS.keys():
		InputMap.action_erase_events(action_name)
		var key_event = InputEventKey.new()
		key_event.keycode = DEFAULT_INPUTS[action_name]
		InputMap.action_add_event(action_name, key_event)
	_update_action_labels()
	_show_message("Defaults restored.", 2.0)

	# Явно сбрасываем визуальное состояние кнопки Reset
	if reset_btn:
		_reset_button_visual_state(reset_btn)

	await get_tree().create_timer(2.1).timeout
	_show_default_message()

# --- ПУБЛИЧНЫЙ МЕТОД ДЛЯ ИНИЦИАЛИЗАЦИИ ---
func initialize_menu():
	self.show()
	waiting_for_action = ""
	waiting_button_node = null
	get_tree().create_timer(0.1).timeout.connect(_update_action_labels_after_delay)
	_show_default_message()

func _update_action_labels_after_delay():
	_update_action_labels()

# Вспомогательный метод для сброса флага ignore_next_escape в следующем кадре
func _deferred_reset_ignore_escape():
	ignore_next_escape = false

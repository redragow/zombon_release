extends Control

signal back_pressed

func _ready():
    hide()
    setup_ui()

func setup_ui():
    # Настройка внешнего вида
    if get_node_or_null("MarginContainer/VBoxContainer/TitleLabel"):
        var title = get_node("MarginContainer/VBoxContainer/TitleLabel")
        title.add_theme_font_size_override("font_size", 24)
    
    # Настройка кнопок
    var buttons = [
        get_node_or_null("MarginContainer/VBoxContainer/EasyButton"),
        get_node_or_null("MarginContainer/VBoxContainer/MediumButton"),
        get_node_or_null("MarginContainer/VBoxContainer/HardButton"),
        get_node_or_null("MarginContainer/VBoxContainer/BackButton")
    ]
    
    for button in buttons:
        if button:
            button.add_theme_stylebox_override("normal", create_button_style(Color(0.2, 0.2, 0.2, 0.8)))
            button.add_theme_stylebox_override("hover", create_button_style(Color(0.3, 0.3, 0.3, 0.9)))
            button.add_theme_stylebox_override("pressed", create_button_style(Color(0.1, 0.1, 0.1, 1.0)))

func create_button_style(color):
    var style = StyleBoxFlat.new()
    style.bg_color = color
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.5, 0.5, 0.5)
    style.content_margin_left = 10
    style.content_margin_top = 5
    style.content_margin_right = 10
    style.content_margin_bottom = 5
    return style

func _on_easy_button_pressed():
    print("Easy difficulty selected")
    start_game_with_difficulty("EASY")

func _on_medium_button_pressed():
    print("Medium difficulty selected")
    start_game_with_difficulty("MEDIUM")

func _on_hard_button_pressed():
    print("Hard difficulty selected")
    start_game_with_difficulty("HARD")

func start_game_with_difficulty(difficulty_name):
    # Устанавливаем сложность через GameManager
    if Engine.has_singleton("GameManager"):
        match difficulty_name:
            "EASY":
                GameManager.set_difficulty(0)  # Difficulty.EASY
            "MEDIUM":
                GameManager.set_difficulty(1)  # Difficulty.MEDIUM
            "HARD":
                GameManager.set_difficulty(2)  # Difficulty.HARD
        
        GameManager.set_game_state(1)  # GameState.PLAYING
        print("Starting game with difficulty: ", difficulty_name)
    
    # Переходим к игровой сцене
    var error = get_tree().change_scene_to_file("res://scenes/Game.tscn")
    if error != OK:
        print("Error loading Game scene: ", error)

func _on_back_button_pressed():
    print("Back to main menu from New Game")
    hide()
    emit_signal("back_pressed")
extends Control

func _ready():
	# Загрузка языковых настроек
	TranslationServer.set_locale(DataManager.data.get("SettingsGame", {}).get("language", "en"))
	
	# Установка размера окна
	DisplayServer.window_set_size(
		Vector2i(
			DataManager.data.get("SettingsGame", {}).get("width", 1600),
			DataManager.data.get("SettingsGame", {}).get("height", 900)
		)
	)
	# Обновление отображения денег
	get_node("Panel/HBoxContainer/Label").text = str(ResourceManager.resources_money)

func on_new_game_pressed():
	UiManager.menu_object = load("res://Scenes/SupportScenes/choose_game_mode.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(UiManager.menu_object)

func shop():
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(UiManager.menu_object)

func settings():
	get_tree().change_scene_to_file("res://Scenes/UI/MenuSettings.tscn")

func on_quit_pressed():
	get_tree().quit()

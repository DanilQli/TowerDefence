extends Control

@onready var crit_label = get_node("Panel/HBoxContainer/Label2")
@onready var but_1 = get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/Button_1")
@onready var but_2 = get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/Button_2")
@onready var but_3 = get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/Button_3")
@onready var but_4 = get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/Button_4")
@onready var but_5 = get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/Button_5")

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
	get_node("Panel/HBoxContainer/Label").text = str(DataManager.data_money)
	get_node("Panel/HBoxContainer/Label2").text = str(DataManager.critical_damage)
	but_1.pressed.connect(on_new_game_pressed)
	but_2.pressed.connect(shop)
	but_3.pressed.connect(settings)
	but_4.pressed.connect(promotion)
	but_5.pressed.connect(on_quit_pressed)
	
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/Button_4/NinePatchRect").visible = check_promotion()

func on_new_game_pressed():
	UiManager.menu_object = load("res://Scenes/SupportScenes/choose_game_mode.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(UiManager.menu_object)

func shop():
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(UiManager.menu_object)

func promotion():
	UiManager.menu_object = load("res://Scenes/SupportScenes/promotion.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(UiManager.menu_object)

func settings():
	get_tree().change_scene_to_file("res://Scenes/UI/MenuSettings.tscn")

func on_quit_pressed():
	get_tree().quit()

func show_critical_damage():
	crit_label.text = str(DataManager.critical_damage)

func check_promotion():
	for i in range(len(DataManager.promotion_progress_level)):
		if int(DataManager.promotion_progress_level[i]) != 0:
			if len(str(DataManager.promotion_progress_level_data_end[i][int(DataManager.promotion_progress_level[i]) - 1])) < 4:
				return true
	return false
	

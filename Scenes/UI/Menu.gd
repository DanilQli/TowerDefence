extends Control

# Используем %UniqueName, чтобы не зависеть от структуры сцены (Mobile/PC)
@onready var money_label = %MoneyLabel
@onready var crit_label = %CritLabel

@onready var but_new_game = %ButtonNewGame
@onready var but_shop = %ButtonShop
@onready var but_settings = %ButtonSettings
@onready var but_promotion = %ButtonPromotion
@onready var but_exit = %ButtonExit
@onready var but_task = %ButtonTask

# Дополнительные элементы (убедись, что они есть в обеих сценах или проверяй на null)
@onready var promotion_badge = but_promotion.get_node_or_null("NinePatchRect")
@onready var task_badge = but_task.get_node_or_null("NinePatchRect/NinePatchRect")

func _ready():
	# Загрузка языковых настроек
	TranslationServer.set_locale(DataManager.data.get("SettingsGame", {}).get("language", "en"))
	
	# Установка размера окна (только для ПК)
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		DisplayServer.window_set_size(
			Vector2i(
				DataManager.data.get("SettingsGame", {}).get("width", 1600),
				DataManager.data.get("SettingsGame", {}).get("height", 900)
			)
		)
	
	# Обновление отображения денег
	if money_label: money_label.text = str(DataManager.data_money)
	if crit_label: crit_label.text = str(DataManager.critical_damage)
	
	# Подключение сигналов
	if but_new_game: but_new_game.pressed.connect(on_new_game_pressed)
	if but_shop: but_shop.pressed.connect(shop)
	if but_settings: but_settings.pressed.connect(settings)
	if but_promotion: but_promotion.pressed.connect(promotion)
	if but_exit: but_exit.pressed.connect(on_quit_pressed)
	if but_task: but_task.pressed.connect(task)
	
	# Бейджи (красные точки)
	if promotion_badge: promotion_badge.visible = check_promotion()
	if task_badge: task_badge.visible = check_task()

func on_new_game_pressed():
	UiManager.menu_object = load("res://Scenes/SupportScenes/choose_game_mode.tscn").instantiate()
	_hide_main_ui()
	get_node(".").add_child(UiManager.menu_object)

func task():
	UiManager.menu_object = load("res://Scenes/SupportScenes/daily_tasks.tscn").instantiate()
	_hide_main_ui()
	get_node(".").add_child(UiManager.menu_object)
	
func shop():
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	_hide_main_ui()
	get_node(".").add_child(UiManager.menu_object)

func promotion():
	UiManager.menu_object = load("res://Scenes/SupportScenes/promotion.tscn").instantiate()
	_hide_main_ui()
	get_node(".").add_child(UiManager.menu_object)

func settings():
	get_tree().change_scene_to_file("res://Scenes/UI/MenuSettings.tscn")

func on_quit_pressed():
	get_tree().quit()

func show_critical_damage():
	if crit_label: crit_label.text = str(DataManager.critical_damage)

func check_promotion():
	for i in range(len(DataManager.promotion_progress_level)):
		if int(DataManager.promotion_progress_level[i]) != 0:
			if len(str(DataManager.promotion_progress_level_data_end[i][int(DataManager.promotion_progress_level[i]) - 1])) < 4:
				return true
	return false
	
func check_task():
	for i in range(len(TasksManager.list_tasks_you)):
		if int(TasksManager.list_tasks_you[i][2]) >= int(TasksManager.list_tasks_you[i][1]):
			return true
	return false

# Хелпер для скрытия UI (разная структура сцен)
func _hide_main_ui():
	# Ищем контейнеры, которые нужно скрыть при открытии окна
	if has_node("MarginContainer2"): get_node("MarginContainer2").visible = false
	if has_node("Reward"): get_node("Reward").visible = false

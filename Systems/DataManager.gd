## Класс, управляющий загрузкой и сохранением игровых данных из JSON
extends Node

var tower_data: Dictionary = {}
var list_wave_gift: Array = []
var level_option: Array = []
var data: Dictionary = {}
var promotion_progress: Array = []
var promotion_progress_level: Array = []
var promotion_progress_level_data_end: Array = []
var tasks_day_you_progress: Array = []

var promotion_stars: int
var promotion_level: int
var promotion_open_level: int

var strengthening_enemies: float
var strengthening_enemies_dop: float
var strengthening_money: float
var glory_vip: bool
var glory_level: int
var glory_progress: int
var glory_rewards_level_get: Array = []
## Деньги
var data_money: int = 0
## Критический урон
var critical_damage: int
var TYPE_ITEMS: Dictionary
var data_wave = {
	level_0=[[["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]], [["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]], [["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]]],
	level_1=[[["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6]]],
	level_2=[[["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]]]
}
## Вызывается при запуске. Загружает и парсит данные
func _ready() -> void:
	TYPE_ITEMS = {0: [Callable(DataManager, "add_critical_damage"), "KEY_CRITICAL_DAMAGE", preload("res://Assets/Icons/critical_damage.png"), "res://Scenes/SupportScenes/panel_rewards_violet.tscn"],
	1: [Callable(DataManager, "add_data_money"), "KEY_MONEY", preload("res://Assets/Button/money.png"), "res://Scenes/SupportScenes/panel_rewards_green.tscn"],
	2: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_1.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_1_open.png")],
	3: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_2.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_2_open.png")],
	4: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_3.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_3_open.png")],
	5: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_4.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_4_open.png")],
	6: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_5.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_5_open.png")],
	7: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_6.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_6_open.png")],
	8: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_7.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_7_open.png")],
	9: [Callable(DataManager, "add_box"), "KEY_BOX", preload("res://Assets/Icons/box_8.png"), "res://Scenes/SupportScenes/panel_rewards_orange.tscn", preload("res://Assets/Icons/box_8_open.png")],
	10: [Callable(DataManager, "add_data_token"), "KEY_MONEY", preload("res://Assets/Icons/token.png"), "res://Scenes/SupportScenes/panel_rewards_green.tscn"],}
	Logger.log(Logger.LogLevel.INFO, "DataManager initializing")
	load_game_data()

## Загружает json-файл, инициализирует словарь данных
func load_game_data() -> void:
	var file = FileAccess.open("res://Files/resurse.json", FileAccess.READ)
	if file == null:
		Logger.log(Logger.LogLevel.ERROR, "Failed to open resurse.json")
		return
	
	var content = file.get_as_text()
	var result = JSON.parse_string(content)
	
	if typeof(result) != TYPE_DICTIONARY:
		Logger.log(Logger.LogLevel.ERROR, "Invalid JSON format")
		return
	
	data = result
	parse_game_data()

## Разбирает все подкатегории данных
func parse_game_data() -> void:
	_parse_resources()
	_parse_towers()
	_parse_settings()
	_parse_levels()
	_parse_promotion()
	_parse_tasks()
	_parse_path_of_glory()
	data_wave = WaveGenerator.generate_default_waves(data_wave)

## Извлекает значения ресурсов
func _parse_resources() -> void:
	data_money = data.get("Resources", {}).get("money", 0)
	critical_damage = data.get("Resources", {}).get("critical_damage", 0)

func _parse_tasks() -> void:
	TasksManager.count_end_game = data.get("Tasks", {}).get("count_end_game", 0)
	TasksManager.count_spend_money = data.get("Tasks", {}).get("count_spend_money", 0)
	TasksManager.count_end_game_company = data.get("Tasks", {}).get("count_end_game_company", 0)
	TasksManager.win_several_times = data.get("Tasks", {}).get("win_several_times", [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	TasksManager.support_damage = data.get("Tasks", {}).get("support_damage", 0)
	TasksManager.support_win_unique_count = data.get("Tasks", {}).get("support_win_unique_count", 0)
	TasksManager.win_one_hp_count = data.get("Tasks", {}).get("win_one_hp_count", 0)
	
	TasksManager.daily_task_update_day = int(data.get("Tasks", {}).get("daily_task_update_day", 0))
	TasksManager.daily_task_update_week = int(data.get("Tasks", {}).get("daily_task_update_week", 0))
	TasksManager.list_tasks_you = data.get("Tasks", {}).get("list_tasks_you", 0)
	TasksManager.daily_task_career_you = data.get("Tasks", {}).get("daily_task_career_you", 0)

## Добавить монеты
func add_data_money(value: int) -> void:
	if value < 0:
		TasksManager.count_spend_money += value
		TasksManager.check_tasks_not_in_game_session()
	data_money += value
	data["Resources"]["money"] = data_money
	
## Добавить критический урон(в случаи улучшении карт)
func add_critical_damage(val: int) -> void:
	critical_damage += val
	data["Resources"]["critical_damage"] = critical_damage

## Добавить карты башни, которые были получены из сундука
func add_box(box_card):
	for i in range(len(box_card)):
		TowerCards.add_cards(box_card[i][0], box_card[i][1])
	write_file()
	
## Загружает данные всех башен в словарь
func _parse_towers() -> void:
	var turrets = data.get("Turrets", {})
	var towers_data: Dictionary = {}
	for name in turrets.keys():
		towers_data[name] = turrets[name]
	var turretss = towers_data.keys()
	turretss.sort_custom(func(a, b): 
		return int(a.split("_")[1].split("T")[0]) < int(b.split("_")[1].split("T")[0])
	)
	for tower_id in turretss:
		tower_data[tower_id] = towers_data[tower_id]

## Загружает прочие числовые настройки (усиления денег, врагов и т.д.)
func _parse_settings() -> void:
	var settings = data.get("Settings", {})
	strengthening_enemies = settings.get("strengthening_enemies", 0)
	strengthening_enemies_dop = settings.get("strengthening_enemies_dop", 0)
	strengthening_money = settings.get("strengthening_money", 0)
	list_wave_gift = settings.get("list_wave_gift", [])
	
	var game_settings = data.get("SettingsGame", {})
	ResourceManager.best_score = game_settings.get("best_score", 0)

## Загружает параметры уровня кампании
func _parse_levels() -> void:
	level_option = data.get("LevelOption", {}).get("level", [])
	
func _parse_promotion() -> void:
	promotion_progress = data.get("Promotion", {}).get("progress", [])
	promotion_progress_level = data.get("Promotion", {}).get("progress_level", [])
	promotion_progress_level_data_end = data.get("Promotion", {}).get("progress_level_data_end", [])
	promotion_stars = int(data.get("Promotion", {}).get("stars", 0))
	promotion_level = int(data.get("Promotion", {}).get("level", 0))
	promotion_open_level = int(data.get("Promotion", {}).get("open_level", 0))

func _parse_path_of_glory() -> void:
	glory_vip = data.get("PathOfGlory", {}).get("vip", false)
	glory_level = data.get("PathOfGlory", {}).get("level", 0)
	glory_progress = data.get("PathOfGlory", {}).get("progress", 0)
	glory_rewards_level_get = data.get("PathOfGlory", {}).get("rewards_level_get", [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]])

## Сохраняет текущее состояние игры в файл
func write_file() -> void:
	_update_data_before_save()
	var file = FileAccess.open("res://Files/resurse.json", FileAccess.WRITE)
	if file == null:
		Logger.log(Logger.LogLevel.ERROR, "Failed to open resurse.json for writing")
		return
	var json_string = JSON.stringify(data, "  ")
	file.store_string(json_string)
	Logger.log(Logger.LogLevel.INFO, "Game data saved successfully")

## Обновляет структуру данных перед сохранением
func _update_data_before_save() -> void:
	if not data.has("Resources"):
		data["Resources"] = {}
	data["Resources"]["money"] = data_money
	data["Resources"]["critical_damage"] = critical_damage
	
	data["Promotion"]["progress"] = promotion_progress
	data["Promotion"]["progress_level"] = promotion_progress_level
	data["Promotion"]["progress_level_data_end"] = promotion_progress_level_data_end
	data["Promotion"]["stars"] = promotion_stars
	data["Promotion"]["level"] = promotion_level
	data["Promotion"]["open_level"] = promotion_open_level
	
	if not data.has("Turrets"):
		data["Turrets"] = {}
	for name in tower_data.keys():
		data["Turrets"][name] = tower_data[name]
	
	if not data.has("Settings"):
		data["Settings"] = {}
	data["Settings"]["strengthening_enemies"] = strengthening_enemies
	data["Settings"]["strengthening_enemies_dop"] = strengthening_enemies_dop
	data["Settings"]["strengthening_money"] = strengthening_money
	data["Settings"]["list_wave_gift"] = list_wave_gift
	
	if not data.has("SettingsGame"):
		data["SettingsGame"] = {}
	data["SettingsGame"]["best_score"] = ResourceManager.best_score
	
	if not data.has("LevelOption"):
		data["LevelOption"] = {}
	data["LevelOption"]["level"] = level_option

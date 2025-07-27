## Класс, управляющий загрузкой и сохранением игровых данных из JSON
extends Node

var tower_data: Dictionary = {}
var list_wave_gift: Array = []
var level_option: Array = []
var data: Dictionary = {}

var strengthening_enemies: float
var strengthening_enemies_dop: float
var strengthening_money: float
## Деньги
var data_money: int = 0
## Критический урон
var critical_damage: int

var data_wave = {
	level_0=[[["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]], [["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]], [["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]]],
	level_1=[[["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6]]],
	level_2=[[["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]], [["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], ["Enemy_4", 0.3]], [["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]], [["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35], ["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1], ["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3], ["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]], [["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3], ["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]]]
}

## Вызывается при запуске. Загружает и парсит данные
func _ready() -> void:
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
	data_wave = WaveGenerator.generate_default_waves(data_wave)

## Извлекает значения ресурсов
func _parse_resources() -> void:
	data_money = data.get("Resources", {}).get("money", 0)
	critical_damage = data.get("Resources", {}).get("critical_damage", 0)

## Добавить монеты
func data_money_add(value: int) -> void:
	data_money += value
	data["Resources"]["money"] = data_money

## Списать монеты
func data_money_spend(value: int) -> void:
	data_money -= value
	data["Resources"]["money"] = data_money
	
## Добавить критический урон(в случаи улучшении карт)
func add_critical_damage(val: int) -> void:
	critical_damage += val
	data["Resources"]["critical_damage"] = critical_damage
	
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

## Сохраняет текущее состояние игры в файл
func write_file() -> void:
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

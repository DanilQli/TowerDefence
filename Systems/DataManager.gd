## Класс, управляющий загрузкой и сохранением игровых данных из JSON
extends Node

var tower_data: Dictionary = {}
var enemy_data: Dictionary = {}
var wave_data: Array = []
var list_wave_gift: Array = []
var level_option: Array = []
var data: Dictionary = {}

var strengthening_enemies: float
var strengthening_enemies_dop: float
var strengthening_money: float

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
	_parse_enemies()
	_parse_waves()
	_parse_settings()
	_parse_levels()
	DataManager.wave_data = WaveGenerator.generate_default_waves(DataManager.wave_data)

## Извлекает значения ресурсов
func _parse_resources() -> void:
	ResourceManager.resources_money = data.get("Resources", {}).get("money", 0)

## Загружает данные всех башен в словарь
func _parse_towers() -> void:
	var turrets = data.get("Turrets", {})
	for name in turrets.keys():
		tower_data[name] = turrets[name]

## Загружает данные всех врагов
func _parse_enemies() -> void:
	var enemies = data.get("Enemies", {})
	for name in enemies.keys():
		enemy_data[name] = enemies[name]

## Загружает данные всех волн игры
func _parse_waves() -> void:
	var wave = data.get("WaveData", {})
	for i in range(wave.size()):
		var key = "level_" + str(i)
		if wave.has(key):
			wave_data.append(wave[key])
		else:
			wave_data.append([])

## Загружает прочие числовые настройки (усиления денег, врагов и т.д.)
func _parse_settings() -> void:
	var settings = data.get("Settings", {})
	strengthening_enemies = settings.get("strengthening_enemies", 0)
	strengthening_enemies_dop = settings.get("strengthening_enemies_dop", 0)
	strengthening_money = settings.get("strengthening_money", 0)
	ResourceManager.current_money = int(settings.get("current_money", 0))
	list_wave_gift = settings.get("list_wave_gift", [])
	
	var game_settings = data.get("SettingsGame", {})
	ResourceManager.best_score = game_settings.get("best_score", 0)

## Загружает параметры уровня кампании
func _parse_levels() -> void:
	level_option = data.get("LevelOption", {}).get("level", [])

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
	data["Resources"]["money"] = ResourceManager.resources_money
	
	if not data.has("Turrets"):
		data["Turrets"] = {}
	for name in tower_data.keys():
		data["Turrets"][name] = tower_data[name]
	
	if not data.has("Settings"):
		data["Settings"] = {}
	data["Settings"]["strengthening_enemies"] = strengthening_enemies
	data["Settings"]["strengthening_enemies_dop"] = strengthening_enemies_dop
	data["Settings"]["strengthening_money"] = strengthening_money
	data["Settings"]["current_money"] = ResourceManager.current_money
	data["Settings"]["list_wave_gift"] = list_wave_gift
	
	if not data.has("SettingsGame"):
		data["SettingsGame"] = {}
	data["SettingsGame"]["best_score"] = ResourceManager.best_score
	
	if not data.has("LevelOption"):
		data["LevelOption"] = {}
	data["LevelOption"]["level"] = level_option

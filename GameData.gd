extends Node
"""type_attack: 0 обычная 1 - замедление 2 - перемещение 3 - по области 4 - приносит деньги"""
var menu_object
var strengthening_enemies
var strengthening_enemies_dop
var strengthening_money
var resources_money
var current_wave = 0
var current_game_score = 0
var current_money
const modifer_value = 1.0
const NUMBER_TURRET = 10
var spped_game = 0.0
var list_wave_gift
var list_open_menu_turrets = []
var config 
var best_score
var currrent_level = 0
var level_option
var data
const NUMBER_LEVEL = 3
const MONEY_BEGIN = [4000, 10400, 800]

##Нужно для отображения верного меню завершения игры
var FLAG_GAME_COMPANY = false 

static func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

var tower_data = {}
var enemy_data = {}

var wave_data = []
	
func _ready():
	var file = FileAccess.open("res://Files/resurse.json", FileAccess.READ)
	if file == null:
		printerr("⛔ Не удалось открыть файл resurse.json")
		return
	
	var content = file.get_as_text()
	var result = JSON.parse_string(content)
	
	if typeof(result) != TYPE_DICTIONARY:
		printerr("⛔ Неверный формат JSON данных")
		return
	
	data = result
	
	# 1. 🪙 Ресурсы
	resources_money = data.get("Resources", {}).get("money", 0)

	# 2. 🧱 Башни
	var turrets = data.get("Turrets", {})
	for name in turrets.keys():
		tower_data[name] = turrets[name]

	# 3. 👾 Враги
	var enemies = data.get("Enemies", {})
	for name in enemies.keys():
		enemy_data[name] = enemies[name]

	# 4. 🌊 Волны
	var wave = data.get("WaveData", {})
	for i in range(wave.size()):
		var key = "level_" + str(i)
		if wave.has(key):
			wave_data.append(wave[key])
		else:
			wave_data.append([])

	# 5. ⚙️ Настройки
	var settings = data.get("Settings", {})
	strengthening_enemies = settings.get("strengthening_enemies", 0)
	strengthening_enemies_dop = settings.get("strengthening_enemies_dop", 0)
	strengthening_money = settings.get("strengthening_money", 0)
	current_money = settings.get("current_money", 0)
	list_wave_gift = settings.get("list_wave_gift", [])

	# 6. 🖥Настройки игры
	var game_settings = data.get("SettingsGame", {})
	best_score = game_settings.get("best_score", 0)

	# 7. 📘 Уровни
	level_option = data.get("LevelOption", {}).get("level", [])
	
	
	for i in 100:
		wave_data[0].append([
			["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_5", 1.0],
			["Enemy_5", 1.5], ["Enemy_8", 2.5], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
			["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
			["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0],
			["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_4", 1.0], ["Enemy_5", 1.0],
			["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_4", 1.0], ["Enemy_3", 1.0], ["Enemy_2", 1.0],
			["Enemy_2", 0.7], ["Enemy_6", 0.8], ["Enemy_1", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
			["Enemy_4", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0], ["Enemy_3", 1.0], ["Enemy_4", 1.0],
			["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
			["Enemy_1", 1.0], ["Enemy_3", 1.0], ["Enemy_5", 1.0], ["Enemy_7", 1.0], ["Enemy_4", 1.0]])

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
		
func write_file():
	data.save("res://Files/resurse.json") 

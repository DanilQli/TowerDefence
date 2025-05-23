extends Node
var menu_object
var strengthening_enemies
var strengthening_enemies_dop
var strengthening_money
var resources_money
var current_wave = 0
var current_game_score = 0
var current_money
const modifer_value = 1.0
var spped_game = 0.0
var list_wave_gift
var list_open_menu_turrets = []
var config 
var best_score
var currrent_level = 0
var level_option
const NUMBER_LEVEL = 2
const MONEY_BEGIN = [400, 10400, 800]

##Нужно для отображения верного меню завершения игры
var FLAG_GAME_COMPANY = false 

static func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

var tower_data = {}
var enemy_data = {}

var wave_data = []
	
func _ready():
	config = ConfigFile.new()
	config.load("res://Files/options.cfg")
	var dict = {}
	var list = []
	var section
	for i in range(6):
		dict = {}
		list = []
		section = "Turret_" + str(i + 1) + "T1"
		if i != 5:
			if i in [0, 1, 2]:
				list = config.get_value(section, "damage")
				dict["damage"] = list
			elif i == 3:
				list = config.get_value(section, "intensivity")
				dict["intensivity"] = list
				list = config.get_value(section, "duration")
				dict["duration"] = list
			elif i == 4:
				list = config.get_value(section, "distance")
				dict["distance"] = list
			list = config.get_value(section, "rof")
			dict["rof"] = list
			list = config.get_value(section, "range")
			dict["range"] = list
		else:
			list = config.get_value(section, "speed")
			dict["speed"] = list
			list = config.get_value(section, "income")
			dict["income"] = list
		list = config.get_value(section, "upgrade_for")
		dict["upgrade for"] = list
		list = config.get_value(section, "cost")
		dict["cost"] = list
		list = config.get_value(section, "type_explosion")
		dict["type explosion"] = list
		list = config.get_value(section, "type_attack")
		dict["type attack"] = list
		list = config.get_value(section, "have")
		dict["have"] = list
		list = config.get_value(section, "activity")
		dict["activity"] = list
		list = config.get_value(section, "prise")
		dict["prise"] = list
		tower_data[section] = dict
	for i in range(8):
		dict = {}
		list = []
		section = "Enemy_" + str(i + 1)
		list = config.get_value(section, "speed")
		dict["speed"] = list
		list = config.get_value(section, "money_death")
		dict["money death"] = list
		list = config.get_value(section, "hp")
		dict["hp"] = list
		enemy_data[section] = dict
	#0 - уровень песочницы
	for i in range(NUMBER_LEVEL):
		wave_data.append(config.get_value("wave_data", "level_" + str(i)))
	strengthening_enemies = config.get_value("settings", "strengthening_enemies")
	strengthening_enemies_dop = config.get_value("settings", "strengthening_enemies_dop")
	strengthening_money = config.get_value("settings", "strengthening_money")
	current_money = config.get_value("settings", "current_money")
	list_wave_gift = config.get_value("settings", "list_wave_gift")
	best_score = config.get_value("settings_game", "best_score")
	resources_money = config.get_value("Resources", "money")
	level_option = config.get_value("level_option", "level")

	#for i in 100:
		#wave_data.append([
			#["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_5", 1.0],
			#["Enemy_5", 1.5], ["Enemy_8", 2.5], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
			#["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
			#["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0],
			#["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_4", 1.0], ["Enemy_5", 1.0],
			#["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_4", 1.0], ["Enemy_3", 1.0], ["Enemy_2", 1.0],
			#["Enemy_2", 0.7], ["Enemy_6", 0.8], ["Enemy_1", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
			#["Enemy_4", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0], ["Enemy_3", 1.0], ["Enemy_4", 1.0],
			#["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
			#["Enemy_1", 1.0], ["Enemy_3", 1.0], ["Enemy_5", 1.0], ["Enemy_7", 1.0], ["Enemy_4", 1.0]])

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
		
func write_file():
	config.save("res://Files/options.cfg") 

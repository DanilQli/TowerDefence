extends Node
var strengthening_enemies
var strengthening_enemies_dop
var strengthening_money
var current_wave = 0
var current_game_score = 0
var current_money
const modifer_value = 1.0
var spped_game = 1.0
var list_wave_gift
var list_open_menu_turrets = []
var config 
var best_score

static func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

var tower_data = {}
var enemy_data = {}

var wave_data = [
	[
		["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.5],
		["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3], 
		["Enemy_2", 0.5], ["Enemy_1", 0.2], ["Enemy_1", 0.6], ["Enemy_1", 0.5], ["Enemy_1", 0.3], 
		["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.5], ["Enemy_1", 0.3], ["Enemy_1", 0.2]],
	[
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9],
		["Enemy_1", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.6], 
		["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.6], 
		["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.9], 
		["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.6], 
		["Enemy_4", 0.3]],
	[
		["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_1", 0.5], ["Enemy_3", 0.3], ["Enemy_2", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], 
		["Enemy_3", 0.6], ["Enemy_1", 0.3], ["Enemy_2", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.3],
		["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_1", 0.9], ["Enemy_3", 0.3], ["Enemy_2", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.4]],
	[
		["Enemy_2", 0.2], ["Enemy_4", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_1", 0.9], ["Enemy_1", 0.3], ["Enemy_3", 0.1], ["Enemy_1", 0.15], ["Enemy_1", 0.35],
		["Enemy_4", 0.3], ["Enemy_1", 0.9], ["Enemy_4", 0.3], ["Enemy_1", 0.2], ["Enemy_1", 0.1],
		["Enemy_1", 0.6], ["Enemy_2", 0.3], ["Enemy_2", 0.3], ["Enemy_2", 0.9], ["Enemy_2", 0.3],
		["Enemy_3", 0.3], ["Enemy_3", 0.2], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3]],
	[
		["Enemy_4", 0.2], ["Enemy_4", 0.9], ["Enemy_4", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.3],
		["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_1", 0.2], ["Enemy_4", 0.9], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3],
		["Enemy_1", 0.8], ["Enemy_1", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]],
	[
		["Enemy_5", 0.9], ["Enemy_5", 0.4], ["Enemy_5", 0.1], ["Enemy_5", 0.9], ["Enemy_4", 0.1],
		["Enemy_1", 0.3], ["Enemy_1", 0.9], ["Enemy_1", 0.2], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_4", 0.2], ["Enemy_5", 0.3], ["Enemy_5", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3],
		["Enemy_2", 0.9], ["Enemy_1", 0.2], ["Enemy_3", 0.1], ["Enemy_5", 0.9], ["Enemy_3", 0.3],
		["Enemy_1", 0.8], ["Enemy_4", 0.3], ["Enemy_5", 0.1], ["Enemy_1", 0.3], ["Enemy_4", 0.3]],
	[
		["Enemy_4", 0.1], ["Enemy_4", 0.3], ["Enemy_4", 0.25], ["Enemy_1", 0.2], ["Enemy_1", 0.6],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_4", 0.9], ["Enemy_5", 0.3], ["Enemy_5", 0.4], ["Enemy_3", 0.3], ["Enemy_1", 0.9],
		["Enemy_2", 0.2], ["Enemy_1", 0.9], ["Enemy_3", 0.1], ["Enemy_5", 0.3], ["Enemy_3", 0.3],
		["Enemy_1", 0.2], ["Enemy_4", 0.3], ["Enemy_5", 0.1], ["Enemy_1", 0.9], ["Enemy_4", 0.3]],
	[
		["Enemy_6", 0.5], ["Enemy_6", 0.5], ["Enemy_6", 0.5], ["Enemy_6", 0.5], ["Enemy_6", 0.5],
		["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.4], ["Enemy_5", 0.3], ["Enemy_1", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_4", 0.9], ["Enemy_5", 0.3], ["Enemy_5", 0.4], ["Enemy_3", 0.3], ["Enemy_1", 0.3],
		["Enemy_2", 0.2], ["Enemy_1", 0.2], ["Enemy_3", 0.1], ["Enemy_5", 0.9], ["Enemy_3", 0.3],
		["Enemy_1", 0.2], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_4", 0.3]],
	[
		["Enemy_6", 0.3], ["Enemy_6", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.8], ["Enemy_5", 0.3], ["Enemy_3", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_6", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.8], ["Enemy_2", 0.3],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_3", 0.3],
		["Enemy_2", 0.3], ["Enemy_6", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_4", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.1], ["Enemy_3", 0.3], ["Enemy_4", 0.3],
		["Enemy_6", 0.2], ["Enemy_6", 0.2], ["Enemy_6", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.3],
		["Enemy_1", 0.2], ["Enemy_4", 0.3], ["Enemy_5", 0.1], ["Enemy_1", 0.3], ["Enemy_4", 0.3]],
	[
		["Enemy_5", 0.2], ["Enemy_5", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.2], ["Enemy_5", 0.3],
		["Enemy_1", 0.8], ["Enemy_5", 0.3], ["Enemy_1", 0.4], ["Enemy_5", 0.3], ["Enemy_5", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_7", 0.4], ["Enemy_7", 0.3], ["Enemy_7", 0.4], ["Enemy_7", 0.3], ["Enemy_7", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_3", 0.3],
		["Enemy_2", 0.3], ["Enemy_6", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_4", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.1], ["Enemy_3", 0.3], ["Enemy_4", 0.3],
		["Enemy_6", 0.2], ["Enemy_1", 0.2], ["Enemy_6", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.3],
		["Enemy_1", 0.2], ["Enemy_4", 0.3], ["Enemy_5", 0.1], ["Enemy_1", 0.3], ["Enemy_4", 0.3]],
	[
		["Enemy_7", 0.2], ["Enemy_5", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.2], ["Enemy_5", 0.3],
		["Enemy_1", 0.8], ["Enemy_5", 0.3], ["Enemy_1", 0.4], ["Enemy_5", 0.3], ["Enemy_5", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_7", 0.4], ["Enemy_7", 0.3], ["Enemy_7", 0.4], ["Enemy_7", 0.3], ["Enemy_7", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_3", 0.3],
		["Enemy_2", 0.3], ["Enemy_6", 0.4], ["Enemy_3", 0.1], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_4", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.1], ["Enemy_3", 0.3], ["Enemy_4", 0.3],
		["Enemy_1", 0.2], ["Enemy_7", 0.2], ["Enemy_7", 0.1], ["Enemy_7", 0.3], ["Enemy_7", 0.3],
		["Enemy_3", 0.2], ["Enemy_4", 0.3], ["Enemy_5", 0.1], ["Enemy_1", 0.3], ["Enemy_7", 0.3]],
	[
		["Enemy_1", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.2], ["Enemy_1", 0.2],
		["Enemy_1", 0.8], ["Enemy_5", 0.3], ["Enemy_4", 0.4], ["Enemy_3", 0.3], ["Enemy_6", 0.3],
		["Enemy_6", 0.3], ["Enemy_6", 0.4], ["Enemy_6", 0.5], ["Enemy_6", 0.3], ["Enemy_6", 0.3],
		["Enemy_6", 0.9], ["Enemy_6", 0.9], ["Enemy_8", 0.4], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_2", 0.3], ["Enemy_1", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_1", 0.3],
		["Enemy_3", 0.2], ["Enemy_3", 0.3], ["Enemy_5", 0.4], ["Enemy_5", 0.3], ["Enemy_3", 0.3],
		["Enemy_2", 0.3], ["Enemy_6", 0.4], ["Enemy_3", 0.9], ["Enemy_1", 0.3], ["Enemy_2", 0.3],
		["Enemy_4", 0.1], ["Enemy_5", 0.3], ["Enemy_5", 0.9], ["Enemy_3", 0.3], ["Enemy_4", 0.3],
		["Enemy_1", 0.2], ["Enemy_7", 0.2], ["Enemy_7", 0.9], ["Enemy_7", 0.3], ["Enemy_7", 0.9],
		["Enemy_3", 0.2], ["Enemy_4", 0.3], ["Enemy_5", 0.9], ["Enemy_1", 0.3], ["Enemy_7", 0.3]],
	[
		["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_5", 1.0],
		["Enemy_5", 1.5], ["Enemy_8", 2.5], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
		["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
		["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0],
		["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_4", 1.0], ["Enemy_5", 1.0],
		["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_4", 1.0], ["Enemy_3", 1.0], ["Enemy_2", 1.0],
		["Enemy_2", 0.7], ["Enemy_6", 0.8], ["Enemy_1", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
		["Enemy_4", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0], ["Enemy_3", 1.0], ["Enemy_4", 1.0],
		["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
		["Enemy_1", 1.0], ["Enemy_3", 1.0], ["Enemy_5", 1.0], ["Enemy_7", 1.0], ["Enemy_4", 1.0]]]

func _ready():
	config = ConfigFile.new()
	config.load("res://Files/options.cfg")
	var dict = {}
	var list = []
	var section
	for i in range(5):
		dict = {}
		list = []
		section = "Turret_" + str(i + 1) + "T1"
		if i not in [3, 4]:
			list = config.get_value(section, "damage")
			dict["damage"] = list
		elif i == 3:
			list = config.get_value(section, "intensivity")
			dict["intensivity"] = list
			list = config.get_value(section, "duration")
			dict["duration"] = list
		else:
			list = config.get_value(section, "distance")
			dict["distance"] = list
		list = config.get_value(section, "rof")
		dict["rof"] = list
		list = config.get_value(section, "range")
		dict["range"] = list
		list = config.get_value(section, "upgrade_for")
		dict["upgrade for"] = list
		list = config.get_value(section, "cost")
		dict["cost"] = list
		list = config.get_value(section, "type_explosion")
		dict["type explosion"] = list
		list = config.get_value(section, "type_attack")
		dict["type attack"] = list
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
		
	strengthening_enemies = config.get_value("settings", "strengthening_enemies")
	strengthening_enemies_dop = config.get_value("settings", "strengthening_enemies_dop")
	strengthening_money = config.get_value("settings", "strengthening_money")
	current_money = config.get_value("settings", "current_money")
	list_wave_gift = config.get_value("settings", "list_wave_gift")
	best_score = config.get_value("settings_game", "best_score")
	
	for i in 100:
		wave_data.append([
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

func write_file():
	config.save("res://Files/options.cfg") 

extends Node

var strengthening_enemies = 0.24
var strengthening_enemies_dop = 0.115
var strengthening_money = 0.35
var current_wave = 0
var current_money = 10000

var list_open_menu_turrets = []

var tower_data = {
	"Turret_1T1": {
		"damage": [45, 75, 120, 195, 315, 510, 825, 1335, 2165, 39],
		"rof": [1.0, 0.95, 0.9, 0.84, 0.78, 0.71, 0.64, 0.55, 0.45, 0.35],
		"range": [245, 247, 250, 253, 257, 262, 268, 275, 283, 292],
		"upgrade for": [50, 75, 125, 200, 325, 525, 850, 1375, 2225, 3600],
		"cost": 100,
		"type explosion": 0,
		"type attack": 0,
		"category": "Missile1"},
	"Turret_2T1": {
		"damage": [100, 170, 270, 440, 710, 1050, 1760, 2810, 4570, 7380],
		"rof": [1.5, 1.45, 1.39, 1.33, 1.25, 1.13, 1.05, 0.95, 0.83, 0.7],
		"range": [270, 275, 280, 285, 290, 300, 310, 325, 340, 360],
		"upgrade for": [100, 150, 250, 400, 650, 1050, 1700, 2750, 4450, 7200],
		"cost": 200,
		"type explosion": 0,
		"type attack": 0,
		"category": "Missile3"},
	"Turret_3T1": {
		"damage": [150, 250, 400, 650, 1050, 1700, 2750, 4450, 7200, 11650],
		"rof": [1.0, 0.95, 0.9, 0.84, 0.78, 0.71, 0.64, 0.55, 0.45, 0.35],
		"range": [245, 250, 255, 260, 270, 280, 295, 310, 325, 345],
		"upgrade for": [200, 300, 500, 800, 1300, 2100, 3400, 5500, 8900, 14400],
		"cost": 400,
		"type explosion": 1,
		"type attack": 0,
		"category": "Missile2"},
	"Turret_4T1": {
		"intensivity": [0.05, 0.06, 0.08, 0.1, 0.13, 0.16, 0.2, 0.24, 0.28, 0.32],
		"duration": [30, 31, 32, 33, 34, 35, 37, 39, 41, 43],
		"rof": [1.5, 1.48, 1.45, 1.42, 1.38, 1.34, 1.3, 1.25, 1.2, 1.15],
		"range": [250, 260, 270, 285, 300, 320, 340, 365, 390, 420],
		"upgrade for": [300, 450, 750, 1200, 1950, 3150, 5100, 8250, 13350, 21600],
		"cost": 600,
		"type explosion": 0,
		"type attack": 1,
		"category": "Missile2"},
	"Turret_5T1": {
		"distance": [500, 700, 1000, 1300, 1600, 1900, 2200, 2600, 3000, 3400],
		"rof": [4.5, 4.4, 4.25, 4.1, 3.9, 3.7, 3.45, 3.2, 2.9, 2.6],
		"range": [270, 280, 290, 305, 320, 340, 360, 385, 410, 440],
		"upgrade for": [500, 750, 1250, 2000, 3250, 5250, 8500, 13750, 22250, 36000],
		"cost": 2000,
		"type explosion": 2,
		"type attack": 2,
		"category": "Missile2"}
	}

var enemy_data = {
	"Enemy_1": {
		"speed": 155,
		"money death": 10.5,
		"hp": 65},
	"Enemy_2": {
		"speed": 145,
		"money death": 11,
		"hp": 80},
	"Enemy_3": {
		"speed": 160,
		"money death": 11.5,
		"hp": 80},
	"Enemy_4": {
		"speed": 200,
		"money death": 12,
		"hp": 130},
	"Enemy_5": {
		"speed": 120,
		"money death": 13,
		"hp": 135},
	"Enemy_6": {
		"speed": 210,
		"money death": 13,
		"hp": 135},
	"Enemy_7": {
		"speed": 220,
		"money death": 13,
		"hp": 200},
	"Enemy_8": {
		"speed": 150,
		"money death": 15,
		"hp": 400},
	}

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

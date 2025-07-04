## Хранит глобальные значения и перечисления
extends Node

static func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
	
## Тип режима игры
enum GameMode {
	SANDBOX,
	CAMPAIGN
}

## Тип атаки башен
enum TowerType {
	GUN = 0,
	AREA = 1,       ## одиночная атака
	SLOW = 2,        ## замедление
	MOVEMENT = 3,      ## урон по области
	MONEY = 4,        ## генерация ресурсов
	POISON = 5        ## башня яда
}
## Редкость башен
enum Rarity {
	COMMON,    # Обычная
	RARE,      # Редкая
	EPIC,      # Эпическая
	LEGENDARY  # Легендарная
}
const LEVEL_OPEN_ABILITY = [7, 10]
const CHANCE_AGAIN_DAMAGE = 20
const PriseUnblockCard = {
	Rarity.COMMON: {
		prise_up_money = [500, 800, 500, 800, 500, 800, 500, 800, 500, 800],
		prise_up_card = [1, 3, 5, 10, 5, 10, 5, 10, 5, 10],
		abilit_prise = [1000, 500],
		open_card = 100,
		upgrade_for_session = [50.0, 75.0, 125.0, 200.0, 325.0, 525.0, 850.0,1375.0, 2225.0, 3600.0]
	},
	Rarity.RARE: {
		prise_up_money = [500, 800, 500, 800, 500, 800, 500, 800, 500, 800],
		prise_up_card = [0, 3, 5, 10, 5, 10, 5, 10, 5, 10],
		abilit_prise = [1000, 500],
		open_card = 100,
		upgrade_for_session = [50.0, 75.0, 125.0, 200.0, 325.0, 525.0, 850.0,1375.0, 2225.0, 3600.0]
	},
	Rarity.LEGENDARY: {
		prise_up_money = [500, 800, 500, 800, 500, 800, 500, 800, 500, 800],
		prise_up_card = [0, 3, 5, 10, 5, 10, 5, 10, 5, 10],
		abilit_prise = [1000, 500],
		open_card = 100,
		upgrade_for_session = [50.0, 75.0, 125.0, 200.0, 325.0, 525.0, 850.0,1375.0, 2225.0, 3600.0]
	}
}

const NUMBER_MAX_EFFECT_CARD: int = 4
const CHANCE_CRITICAL_DAMAGE: int = 5
const DATA_TOWER = {
	0: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			0: [30.0, 39.0, 50.7, 65.9, 85.7, 111.4, 144.8, 188.2, 244.7, 318.1],
			1: [36.0, 46.8, 60.8, 79.0, 102.7, 133.5, 173.6, 225.7, 293.4, 381.4],
			2: [43.2, 56.2, 73.1, 95.0, 123.5, 160.6, 208.8, 271.4, 352.8, 458.6],
			3: [51.8, 67.3, 87.5, 113.8, 147.9, 192.3, 250.0, 325.0, 422.5, 549.2],
			4: [62.2, 80.9, 105.2, 136.8, 177.8, 231.1, 300.4, 390.5, 507.7, 660.0],
			5: [74.6, 97.0, 126.1, 163.9, 213.1, 277.0, 360.1, 468.1, 608.5, 791.1],
			6: [91.0, 118.3, 153.8, 199.9, 259.9, 337.9, 439.3, 571.1, 742.4, 965.1],
			7: [109.3, 142.1, 184.7, 240.1, 312.1, 405.7, 527.4, 685.6, 891.3, 1158.7],
			8: [132.0, 171.6, 223.1, 290.0, 377.0, 490.1, 637.1, 828.2, 1076.7, 1399.7],
			9: [170.0, 221.0, 287.3, 373.5, 485.6, 631.3, 820.7, 1066.9, 1387.0, 1803.1]
		},
		parametr_2 = {
			0: [40.0, 52.0, 67.6, 87.9, 114.3, 148.6, 193.2, 251.2, 326.6, 424.6],
			1: [48.0, 62.4, 81.1, 105.4, 137.0, 178.1, 231.5, 300.9, 391.2, 508.6],
			2: [57.6, 74.9, 97.4, 126.6, 164.6, 214.0, 278.2, 361.7, 470.2, 611.3],
			3: [69.0, 89.7, 116.6, 151.6, 197.1, 256.2, 333.1, 433.0, 562.9, 731.8],
			4: [83.0, 107.9, 140.3, 182.4, 237.1, 308.2, 400.7, 520.9, 677.2, 880.4],
			5: [99.0, 128.7, 167.3, 217.5, 282.8, 367.6, 477.9, 621.3, 807.7, 1050.0],
			6: [119.0, 154.7, 201.1, 261.4, 339.8, 441.7, 574.2, 746.5, 970.5, 1261.7],
			7: [143.0, 185.9, 241.7, 314.2, 408.5, 531.1, 690.4, 897.5, 1166.8, 1516.8],
			8: [172.0, 223.6, 290.7, 377.9, 491.3, 638.7, 830.3, 1079.4, 1403.2, 1824.2],
			9: [206.4, 268.3, 348.8, 453.4, 589.4, 766.2, 996.1, 1294.9, 1683.4, 2188.4]
		},
		parametr_3 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_4 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_range = 4,
		text = ["KEY_DAMAGE", "KEY_DAMAGE_REDUCTION", "KEY_RELOAD", "KEY_RANGE"],
		data = ["damage", "damage_reduction", "rof", "range"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://Assets/Icons/damage_reduction.png", 
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = []
	},
	1: {
		type = Rarity.COMMON,
		type_attack = 1,
		type_explosion = 0,
		cost_in_session = 200,
		parametr_1 = {
			0: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			3: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			4: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			5: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			6: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			7: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			8: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			9: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		parametr_range = 3,
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE"],
		data = ["damage", "rof", "range"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = []
	},
	2: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 3,
		text = ["KEY_INTENSIVITY", "KEY_DURATION", "KEY_RELOAD", "KEY_RANGE"],
		data = ["intensivity", "duration", "rof", "range"],
		img = ["res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex",
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex", 
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = []
	},
	3: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 3,
		text = ["KEY_DISTANCE", "KEY_RELOAD", "KEY_RANGE"],
		data = ["distance", "rof", "range"],
		img = ["res://.godot/imported/distance.png-a3097e1cb8e56e338aba8f1c30601538.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = true,
		queue_free = [3]
	},
	4: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 4,
		text = ["KEY_INCOME", "KEY_RELOAD"],
		data = ["income", "rof"],
		img = ["res://Assets/Icons/intensivity.png",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex"],
		strateg = true,
		queue_free = [2, 3]
	},
	5: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 4,
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_DURATION", "KEY_TICK"],
		data = ["damage", "rof", "range", "duration", "tick"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",  
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex",
		"res://Assets/Icons/tick.png"],
		strateg = false,
		queue_free = []
	},
	6: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 4,
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_DURATION", "KEY_TICK"],
		data = ["damage", "rof", "range", "duration", "tick"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",  
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex",
		"res://Assets/Icons/tick.png"],
		strateg = false,
		queue_free = []
	},
	7: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 4,
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_DURATION", "KEY_TICK"],
		data = ["damage", "rof", "range", "duration", "tick"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",  
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex",
		"res://Assets/Icons/tick.png"],
		strateg = false,
		queue_free = []
	},
	8: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 4,
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_DURATION", "KEY_TICK"],
		data = ["damage", "rof", "range", "duration", "tick"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",  
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex",
		"res://Assets/Icons/tick.png"],
		strateg = false,
		queue_free = []
	},
	9: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_2 = {
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			2: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
		},
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_range = 4,
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_DURATION", "KEY_TICK"],
		data = ["damage", "rof", "range", "duration", "tick"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",  
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex",
		"res://Assets/Icons/tick.png"],
		strateg = false,
		queue_free = []
	},
}
## Количество турелей в игре
const NUMBER_TURRET: int = 10
## Количество максимального уровня турелей в игре
const NUMBER_LVL_TURRET: int = 10
## Общее количество уровней
const NUMBER_LEVEL: int = 3
## Начальное количество денег/ресурсов на каждом уровне
const MONEY_BEGIN: Array = [400000, 10400, 800]
## Модификатор наград (например для подарков)
const MODIFIER_VALUE: float = 1.0
## Количество максимального уровня турелей путём улучшения карт
const NUMBER_LVL_TURRET_CARD: int = 9
## Количество боссов врагов
const NUMBER_BOSS_ENEMY: int = 1

const ENEMY_BOSS = {
	0: {
		hp = 1000,
		speed = 80,
		money_death = 20.0
		}
}
const TURRET_1_ABILITY_1: float = 0.03

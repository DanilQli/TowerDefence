## Хранит глобальные значения и перечисления
extends Node

static func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
	
## Тип режима игры
enum GameMode {
	SANDBOX,
	CAMPAIGN
}
const DATA_ENEMY = {
	0: {
		hp = 65,
		speed = 155,
		money_death = 10.5
		},
	1: {
		hp = 80,
		speed = 145,
		money_death = 11
		},
	2: {
		hp = 80,
		speed = 160,
		money_death = 11.5
		},
	3: {
		hp = 130,
		speed = 200,
		money_death = 12
		},
	4: {
		hp = 135,
		speed = 120,
		money_death = 13
		},
	5: {
		hp = 135,
		speed = 210,
		money_death = 13
		},
	6: {
		hp = 200,
		speed = 220,
		money_death = 13
		},
	7: {
		hp = 400,
		speed = 150,
		money_death = 15.0
		},
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
		name_label = ["", "", "с", "ед"],
		text = ["KEY_DAMAGE", "KEY_DAMAGE_REDUCTION", "KEY_RELOAD", "KEY_RANGE"],
		data = ["damage", "damage_reduction", "rof", "range"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://Assets/Icons/damage_reduction.png", 
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = [4, 5]
	},
	1: {
		type = Rarity.COMMON,
		type_attack = 1,
		type_explosion = 0,
		cost_in_session = 200,
		parametr_1 = {
			0: [45.0, 58.5, 76.0, 98.8, 128.4, 166.9, 217.0, 282.1, 366.7, 476.7],
			1: [57.1, 74.2, 96.5, 125.5, 163.2, 212.2, 275.9, 358.7, 466.3, 606.2],
			2: [72.6, 94.4, 122.7, 159.5, 207.3, 269.5, 350.4, 455.5, 592.1, 769.7],
			3: [92.2, 119.9, 155.9, 202.7, 263.5, 342.6, 445.4, 579.0, 752.7, 978.5],
			4: [117.1, 152.2, 197.9, 257.3, 334.5, 434.9, 565.4, 735.0, 955.5, 1242.2],
			5: [148.7, 193.3, 251.3, 326.7, 424.7, 552.1, 717.7, 933.0, 1212.9, 1576.8],
			6: [188.8, 245.4, 319.0, 414.7, 539.1, 700.8, 911.0, 1184.3, 1539.6, 2001.5],
			7: [239.8, 311.7, 405.2, 526.8, 684.8, 890.2, 1157.3, 1504.5, 1955.9, 2542.7],
			8: [304.5, 395.9, 514.7, 669.1, 869.8, 1130.7, 1469.9, 1910.9, 2484.2, 3229.5],
			9: [386.8, 502.8, 653.6, 849.7, 1104.6, 1436.0, 1866.8, 2426.8, 3154.8, 4101.2]
		},
		parametr_2 = [1.05, 1.02, 0.99, 0.96, 0.93, 0.9, 0.82, 0.79, 0.75, 0.7],
		parametr_3 = [245.0, 248.0, 251.0, 254.0, 257.0, 262.0, 268.0, 275.0, 282.0, 290.0],
		parametr_4 = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
		parametr_range = 3,
		name_label = ["", "ед", "с", "с"],
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_TARGET"],
		data = ["damage", "rof", "range", "target"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",
		"res://Assets/Icons/target.png"],
		strateg = false,
		queue_free = [4, 5]
	},
	2: {
		type = Rarity.COMMON,
		type_attack = 0,
		type_explosion = 0,
		cost_in_session = 100,
		parametr_1 = {
			0: [50.0, 65.0, 84.5, 109.9, 142.9, 185.8, 241.5, 313.9, 408.1, 530.5],
			1: [63.5, 82.5, 107.2, 139.4, 181.2, 235.6, 306.3, 398.2, 517.7, 673.0],
			2: [80.6, 104.8, 136.2, 177.1, 230.2, 299.3, 389.1, 505.8, 657.5, 854.8],
			3: [102.4, 133.1, 173.0, 224.9, 292.4, 380.1, 494.1, 642.3, 835.0, 1085.5],
			4: [130.1, 169.1, 219.8, 285.7, 371.4, 482.8, 627.6, 815.9, 1060.7, 1378.9],
			5: [165.2, 214.8, 279.2, 363.0, 471.9, 613.5, 797.6, 1036.9, 1348.0, 1752.4],
			6: [209.8, 272.7, 354.5, 460.9, 599.2, 779.0, 1012.7, 1316.5, 1711.5, 2225.0],
			7: [266.4, 346.3, 450.2, 585.3, 760.9, 989.2, 1286.0, 1671.8, 2173.3, 2825.3],
			8: [338.4, 439.9, 571.9, 743.5, 966.6, 1256.6, 1633.6, 2123.7, 2760.8, 3589.0],
			9: [429.7, 558.6, 726.2, 944.1, 1227.3, 1595.5, 2074.2, 2696.5, 3505.5, 4557.2]
		},
		parametr_2 = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.75, 0.7],
		parametr_3 = {
			0: [2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5],
			1: [2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9],
			2: [3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3],
			3: [3.7, 3.7, 3.7, 3.7, 3.7, 3.7, 3.7, 3.7, 3.7, 3.7],
			4: [4.1, 4.1, 4.1, 4.1, 4.1, 4.1, 4.1, 4.1, 4.1, 4.1],
			5: [4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5],
			6: [4.9, 4.9, 4.9, 4.9, 4.9, 4.9, 4.9, 4.9, 4.9, 4.9],
			7: [5.3, 5.3, 5.3, 5.3, 5.3, 5.3, 5.3, 5.3, 5.3, 5.3],
			8: [5.7, 5.7, 5.7, 5.7, 5.7, 5.7, 5.7, 5.7, 5.7, 5.7],
			9: [6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1]
		},
		parametr_4 = {
			0: [1.1, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1],
			1: [1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3], 
			2: [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5], 
			3: [1.7, 1.7, 1.7, 1.7, 1.7, 1.7, 1.7, 1.7, 1.7, 1.7], 
			4: [1.9, 1.9, 1.9, 1.9, 1.9, 1.9, 1.9, 1.9, 1.9, 1.9], 
			5: [2.1, 2.1, 2.1, 2.1, 2.1, 2.1, 2.1, 2.1, 2.1, 2.1], 
			6: [2.3, 2.3, 2.3, 2.3, 2.3, 2.3, 2.3, 2.3, 2.3, 2.3], 
			7: [2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5], 
			8: [2.7, 2.7, 2.7, 2.7, 2.7, 2.7, 2.7, 2.7, 2.7, 2.7], 
			9: [2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9, 2.9]
		},
		parametr_5 = [500, 505, 510, 520, 530, 535, 540, 545, 550, 555],
		parametr_6 = [230.0, 234.0, 238.0, 242.0, 246.0, 250.0, 254.0, 258.0, 262.0, 266.0],
		parametr_range = 6,
		name_label = ["", "с", "с", "с", "%", "ед"],
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_DURATION_PHASE_1", "KEY_DURATION_PHASE_2", "KEY_UP_ATTACK_SPEED", "KEY_RANGE"],
		data = ["damage", "rof", "duration_1", "duration_2", "up_attack_speed", "range"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex",
		"res://Assets/Icons/hourglass.png",
		"res://Assets/Icons/hourglass.png",
		"res://Assets/Icons/damage_reduction.png",
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
			0: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0],
			1: [45.0, 72.0, 115.0, 184.0, 295.0, 475.0, 765.0, 1238.0, 2006.0, 3250.0]
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
		parametr_range = 3,
		text = ["KEY_DISTANCE", "KEY_RELOAD", "KEY_RANGE"],
		data = ["distance", "rof", "range"],
		img = ["res://.godot/imported/distance.png-a3097e1cb8e56e338aba8f1c30601538.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = true,
		queue_free = [3]
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
		text = ["KEY_INCOME", "KEY_RELOAD"],
		data = ["income", "rof"],
		img = ["res://Assets/Icons/intensivity.png",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex"],
		strateg = true,
		queue_free = [2, 3]
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

const DATA_ENEMY_BOSS = {
	0: {
		hp = 100000,
		speed = 80,
		money_death = 20.0
		}
}
const TURRET_1_ABILITY_1: float = 0.03

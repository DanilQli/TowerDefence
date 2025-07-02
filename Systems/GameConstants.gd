## Хранит глобальные значения и перечисления
extends Node

## Тип режима игры
enum GameMode {
	SANDBOX,
	CAMPAIGN
}

## Тип атаки башен
enum TowerType {
	GUN = 0,      ## одиночная атака
	SLOW = 1,        ## замедление
	MOVEMENT = 2,    ## толкание/перемещение
	AREA = 3,        ## урон по области
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
		prise_up_card = [0, 3, 5, 10, 5, 10, 5, 10, 5, 10],
		abilit_prise = [1000, 500]
	},
	Rarity.RARE: {
		prise_up_money = [500, 800, 500, 800, 500, 800, 500, 800, 500, 800],
		prise_up_card = [0, 3, 5, 10, 5, 10, 5, 10, 5, 10],
		abilit_prise = [1000, 500]
	},
	Rarity.LEGENDARY: {
		prise_up_money = [500, 800, 500, 800, 500, 800, 500, 800, 500, 800],
		prise_up_card = [0, 3, 5, 10, 5, 10, 5, 10, 5, 10],
		abilit_prise = [1000, 500]
	}
}
## Редкость башен по их индексу
const CardsParity = {
	0: Rarity.COMMON,
	1: Rarity.COMMON,
	2: Rarity.COMMON,
	3: Rarity.RARE,
	4: Rarity.RARE,
	5: Rarity.RARE,
	6: Rarity.EPIC,
	7: Rarity.EPIC,
	8: Rarity.EPIC,
	9: Rarity.LEGENDARY,
	10: Rarity.LEGENDARY,
	11: Rarity.LEGENDARY
}
const NUMBER_MAX_EFFECT_CARD: int = 5
const CHANCE_CRITICAL_DAMAGE = 5
const NameParameters = {
	0: {
		text = ["KEY_DAMAGE", "KEY_DAMAGE_REDUCTION", "KEY_RELOAD", "KEY_RANGE"],
		data = ["damage", "damage_reduction", "rof", "range"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://Assets/Icons/damage_reduction.png", 
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = [3]
	},
	1: {
		text = ["KEY_INTENSIVITY", "KEY_DURATION", "KEY_RELOAD", "KEY_RANGE"],
		data = ["intensivity", "duration", "rof", "range"],
		img = ["res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex",
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex", 
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = []
	},
	2: {
		text = ["KEY_DISTANCE", "KEY_RELOAD", "KEY_RANGE"],
		data = ["distance", "rof", "range"],
		img = ["res://.godot/imported/distance.png-a3097e1cb8e56e338aba8f1c30601538.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = true,
		queue_free = [3]
	},
	3: {
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE"],
		data = ["damage", "rof", "range"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex"],
		strateg = false,
		queue_free = [3]
	},
	4: {
		text = ["KEY_INCOME", "KEY_RELOAD"],
		data = ["income", "rof"],
		img = ["res://Assets/Icons/intensivity.png",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex"],
		strateg = true,
		queue_free = [2, 3]
	},
	5: {
		text = ["KEY_DAMAGE", "KEY_RELOAD", "KEY_RANGE", "KEY_DURATION", "KEY_TICK"],
		data = ["damage", "rof", "range", "duration", "tick"],
		img = ["res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex",
		"res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex", 
		"res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex",  
		"res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex",
		"res://Assets/Icons/tick.png"],
		strateg = false,
		queue_free = []
	}
}

## Требуемое количество карт для улучшения уровня
const CARDS_PER_LEVEL = {
	Rarity.COMMON: [2, 4, 8, 16, 32, 64, 128, 256, 512],      # Для обычных
	Rarity.RARE: [2, 4, 6, 12, 24, 48, 96, 192, 384],         # Для редких
	Rarity.EPIC: [2, 3, 5, 10, 20, 40, 80, 160, 320],        # Для эпических
	Rarity.LEGENDARY: [1, 2, 4, 8, 16, 32, 64, 128, 256]     # Для легендарных
}
## Требуемое количество монет для улучшения уровня
const CARDS_MONEY_LEVEL = {
	Rarity.COMMON: [2, 4, 8, 16, 32, 64, 128, 256, 512],      # Для обычных
	Rarity.RARE: [2, 4, 6, 12, 24, 48, 96, 192, 384],         # Для редких
	Rarity.EPIC: [2, 3, 5, 10, 20, 40, 80, 160, 320],        # Для эпических
	Rarity.LEGENDARY: [1, 2, 4, 8, 16, 32, 64, 128, 256]     # Для легендарных
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
const NUMBER_LVL_TURRET_CARD: int = 10

## Хранит глобальные значения и перечисления
extends Node

## Тип режима игры
enum GameMode {
	SANDBOX,
	CAMPAIGN
}

## Тип атаки башен
enum TowerType {
	NORMAL = 0,      ## одиночная атака
	SLOW = 1,        ## замедление
	MOVEMENT = 2,    ## толкание/перемещение
	AREA = 3,        ## урон по области
	MONEY = 4,        ## генерация ресурсов
	POISON = 5        ## башня яда
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

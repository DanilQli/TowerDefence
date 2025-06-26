## Класс для хранения и управления данными башни
class_name TowerData
extends Resource

## Тип башни
var type: String
## Тип атаки башни
var type_attack: int
## Тип взрыва/эффекта
var type_explosion: int
## Массив значений урона для каждого уровня
var damage: Array[float]
## Массив значений радиуса действия для каждого уровня
var range: Array[float]
## Массив значений скорости атаки для каждого уровня
var rof: Array[float]
## Массив значений интенсивности эффекта для каждого уровня
var intensivity: Array[float]
## Массив значений длительности эффекта для каждого уровня
var duration: Array[float]
## Массив значений дистанции для каждого уровня
var distance: Array[float]
## Массив значений скорости для каждого уровня
var speed: Array[float]
## Массив значений дохода для каждого уровня
var income: Array[float]
## Массив стоимости улучшений для каждого уровня
var upgrade_costs: Array[int]
## Флаг наличия башни у игрока
var have: bool = false
## Флаг активности башни
var activity: bool = false

## Инициализация данных башни из словаря
func _init(data: Dictionary) -> void:
	type = data.get("type", "")
	type_attack = data.get("type_attack", 0)
	type_explosion = data.get("type_explosion", 0)
	damage = data.get("damage", [])
	range = data.get("range", [])
	rof = data.get("rof", [])
	intensivity = data.get("intensivity", [])
	duration = data.get("duration", [])
	distance = data.get("distance", [])
	speed = data.get("speed", [])
	income = data.get("income", [])
	upgrade_costs = data.get("upgrade_for", [])
	have = data.get("have", false)
	activity = data.get("activity", false)

## Получение текущих характеристик башни для указанного уровня
func get_current_stats(level: int) -> Dictionary:
	return {
		"damage": damage[level] if damage.size() > level else 0.0,
		"range": range[level] if range.size() > level else 0.0,
		"rof": rof[level] if rof.size() > level else 0.0,
		"intensivity": intensivity[level] if intensivity.size() > level else 0.0,
		"duration": duration[level] if duration.size() > level else 0.0,
		"distance": distance[level] if distance.size() > level else 0.0,
		"speed": speed[level] if speed.size() > level else 0.0,
		"income": income[level] if income.size() > level else 0.0
	}

## Получение стоимости улучшения для указанного уровня
func get_upgrade_cost(level: int) -> int:
	return upgrade_costs[level] if upgrade_costs.size() > level else 0

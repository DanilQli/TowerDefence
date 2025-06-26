## Башня для генерации денег, не участвует в бою
extends TowerBase
class_name MoneyTower

## Инициализация башни, устанавливает тип как MONEY
func _ready() -> void:
	type_attack = GameConstants.TowerType.MONEY
	super._ready()

## Переопределяет физический процесс, так как башня не атакует
func _physics_process(_delta: float) -> void:
	pass

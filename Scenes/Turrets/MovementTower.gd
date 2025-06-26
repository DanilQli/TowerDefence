## Башня для перемещения врагов
extends TowerBase
class_name MovementTower

## Инициализация башни, устанавливает тип как MOVEMENT
func _ready() -> void:
	type_attack = GameConstants.TowerType.MOVEMENT
	super._ready()

## Применяет эффект перемещения к выбранному врагу
func _apply_damage() -> void:
	enemy.on_hit(duration, type, type_explosion, type_attack, current_lvl)

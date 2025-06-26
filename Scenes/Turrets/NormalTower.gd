## Обычная атакующая башня, наносит прямой урон одной цели
extends TowerBase
class_name NormalTower

## Сигнал изменения нанесенного урона
signal damage_inflicted_changed(value: float)

## Инициализация башни, устанавливает тип как NORMAL
func _ready() -> void:
	type_attack = GameConstants.TowerType.NORMAL
	super._ready()

## Наносит урон одной цели и увеличивает счетчик нанесенного урона
func _apply_damage() -> void:
	inflicted += damage
	enemy.on_hit(damage, type, type_explosion, type_attack, current_lvl)
	emit_signal("damage_inflicted_changed", inflicted)

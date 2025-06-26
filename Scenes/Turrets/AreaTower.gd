## Башня с уроном по области, наносит урон всем врагам в радиусе действия
extends TowerBase
class_name AreaTower

## Инициализация башни, устанавливает тип атаки как AREA
func _ready() -> void:
	type_attack = GameConstants.TowerType.AREA
	super._ready()

## Наносит урон всем врагам в радиусе действия
func _apply_damage() -> void:
	for target in enemy_array:
		target.on_hit(damage, type, type_explosion, type_attack, current_lvl)

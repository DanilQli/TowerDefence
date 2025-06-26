## Башня замедления, снижает скорость врагов
extends TowerBase
class_name SlowTower

## Инициализация башни, устанавливает тип как SLOW
func _ready() -> void:
	type_attack = GameConstants.TowerType.SLOW
	super._ready()

## Применяет эффект замедления ко всем врагам в радиусе
func fire() -> void:
	is_ready = false
	fire_missile2()
	
	for target in enemy_array:
		target.on_hit(intensivity, type, type_explosion, type_attack, current_lvl)
	
	await get_tree().create_timer(rof).timeout
	is_ready = true

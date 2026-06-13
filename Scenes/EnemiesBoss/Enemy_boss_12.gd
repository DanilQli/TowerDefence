extends Enemy_boss
class_name Enemy_boss_12

func on_hit(damage, type_explosion, type_attack, tower, parametrs=false) -> void:
	if type_attack == GameConstants.TowerType.AREA:
		super.on_hit(damage / 4, type_explosion, type_attack, tower, parametrs)
	if type_attack == GameConstants.TowerType.SLOW:
		super.on_hit(-damage, type_explosion, type_attack, tower, parametrs)
	else:
		super.on_hit(damage, type_explosion, type_attack, tower, parametrs)

extends Enemy_boss
class_name Enemy_boss_7

func on_hit(damage, type_explosion, type_attack, towers, parametrs=false):
	super.on_hit(damage, type_explosion, type_attack, towers, parametrs)
	if towers and type_attack in [0, 1]:
		if towers.multiplier_damage_enemy > 0.7:
			towers.multiplier_damage_enemy -= 0.001

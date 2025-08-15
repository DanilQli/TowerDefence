extends Enemy_boss
class_name Enemy_boss_2
const BLOCK: float = 0.9

func on_hit(damage, type_explosion, type_attack, tower, parametrs=false) -> void:
	damage *= BLOCK
	super.on_hit(damage, type_explosion, type_attack, tower, parametrs)

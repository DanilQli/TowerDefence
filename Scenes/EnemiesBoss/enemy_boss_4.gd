extends Enemy_boss
class_name Enemy_boss_4

const rof: int = 5

func fire() -> void:
	is_ready = false
	spawn_enemy()
	await get_tree().create_timer(rof).timeout
	is_ready = true
	
func spawn_enemy():
	"""Создаёт 3-5 врагов"""

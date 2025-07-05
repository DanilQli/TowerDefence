extends Enemy_boss
class_name Enemy_boss_1

const rof: int = 3
const duration: int = 5
const number_block : int = 3

func fire() -> void:
	is_ready = false
	emit_signal("stone", number_block, duration) 
	await get_tree().create_timer(rof).timeout
	is_ready = true

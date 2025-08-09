extends Enemy_boss
class_name Enemy_boss_4

const rof: int = 5
var rng = RandomNumberGenerator.new()
var wave: Array
var wave_num: int

func fire() -> void:
	is_ready = false
	spawn_enemy()
	await get_tree().create_timer(rof).timeout
	is_ready = true
	
func spawn_enemy():
	"""Создаёт 3-5 врагов"""
	wave_num = rng.randi_range(3, 5)
	wave = []
	for i in range(0, wave_num):
		wave.append(["Enemy_" + str(rng.randi_range(1, GameConstants.NUMBER_ENEMY)), 0])
	emit_signal("signal_spawn_enemies", wave, self.progress - 30)

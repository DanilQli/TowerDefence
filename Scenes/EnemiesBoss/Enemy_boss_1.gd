# Scenes/EnemiesBoss/Enemy_boss_1.gd
extends Enemy_boss
class_name Enemy_boss_1

const rof: int = 3
const duration: int = 5
const number_block : int = 3

func fire() -> void:
	if is_spectator_enemy: return # Зрительский босс не стреляет сам
	
	is_ready = false
	# Вместо emit_signal используем прямую логику поиска башен в текущем контейнере
	_apply_stone_effect()
	await get_tree().create_timer(rof).timeout
	if is_instance_valid(self):
		is_ready = true

func _apply_stone_effect():
	# Ищем контейнер башен, в котором находится этот босс
	# Босс -> Path -> Map -> PlayerContainer (в идеале)
	var map = find_parent("Map")
	if not map: return
	
	var turret_layer = map.get_node("Turret")
	if not turret_layer: return
	
	var available_turrets = []
	for t in turret_layer.get_children():
		if is_instance_valid(t) and t is TowerBase and not t.block_damage:
			available_turrets.append(t)
			
	if available_turrets.is_empty(): return
	
	var num = number_block
	while num > 0 and not available_turrets.is_empty():
		var idx = randi() % available_turrets.size()
		available_turrets[idx].stone_effect_start(duration)
		available_turrets.remove_at(idx)
		num -= 1

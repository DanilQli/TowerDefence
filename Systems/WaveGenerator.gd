# Systems/WaveGenerator.gd
## Генерирует стартовые/тестовые волны при инициализации
extends Node
const WAVE_DURATION = 20.0  # длительность волны в секундах
var rng = RandomNumberGenerator.new()
func calculate_wave_max_hp(wave_number: int) -> float:
	# Базовое здоровье первой волны (нужно подобрать)
	var base_wave_hp = 10000.0
	
	# Множитель увеличения здоровья
	var hp_multiplier = wave_number * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * wave_number))
	
	return base_wave_hp * hp_multiplier

func generate_wave(wave_number: int) -> Array:
	var wave = []
	var total_hp = calculate_wave_max_hp(wave_number)
	var remaining_time = WAVE_DURATION
	var min_spawn_delay = 0.1  # минимальное время между врагами
	
	# --- ДОБАВЛЕНИЕ БОССА В ПЕСОЧНИЦЕ ---
	var boss_to_spawn = -1
	boss_to_spawn = rng.randi_range(1, 13)
	# ------------------------------------
	
	while remaining_time > 0:
		# Выбираем случайного врага
		var enemy_id = _select_enemy_for_wave(wave_number)
		
		# Рассчитываем его реальное здоровье с учетом множителя волны
		var hp_multiplier = wave_number * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * wave_number))
		var enemy_hp = GameConstants.DATA_ENEMY[enemy_id].hp * hp_multiplier
		
		# Рассчитываем время до следующего врага
		var spawn_delay = _calculate_spawn_delay(remaining_time, min_spawn_delay)
		
		wave.append(["Enemy_" + str(enemy_id + 1), spawn_delay])
		
		total_hp -= enemy_hp
		remaining_time -= spawn_delay
		
	# Если нужно заспавнить босса, добавляем его В КОНЕЦ волны
	if boss_to_spawn != -1:
		# Задержка 2 секунды перед боссом, чтобы дать игроку передышку
		wave.append(["BOSS_" + str(boss_to_spawn), 2.0])
		
	return wave

func _select_enemy_for_wave(wave_number: int) -> int:
	# Определяем, какие враги доступны для текущей волны
	var available_enemies = []
	
	var max_enemy_id = 7
	
	for i in range(max_enemy_id + 1):
		# Добавляем врага с весом (вероятностью появления)
		# Более сильные враги имеют меньший вес
		var weight = 1.0 - (i / (max_enemy_id + 1.0))
		for w in range(int(weight * 10)):  # умножаем на 10 для целых чисел
			available_enemies.append(i)
	
	return available_enemies[randi() % available_enemies.size()]

func _calculate_spawn_delay(remaining_time: float, min_delay: float) -> float:
	# Если осталось меньше минимальной задержки
	if remaining_time < min_delay:
		return remaining_time
		
	# Максимальная задержка 1 секунда
	var max_delay = 1.0
	
	# Если оставшееся время меньше максимальной задержки
	if remaining_time < max_delay:
		max_delay = remaining_time
		
	# Возвращаем случайное время между min_delay и max_delay
	return MathUtils.round_to_dec(randf_range(min_delay, max_delay), 1)
	
## Метод генерации базового набора волн в DataManager.wave_data[0]
func generate_default_waves(out_wave_data):
	var result = []
	for i in range(500):
		result.append(generate_wave(i + 1))
	out_wave_data.level_0 = result
	return out_wave_data

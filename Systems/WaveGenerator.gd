## Генерирует стартовые/тестовые волны при инициализации
extends Node

## Метод генерации базового набора волн в DataManager.wave_data[0]
func generate_default_waves(out_wave_data: Array):
	var result = []
	for i in range(200):
		result.append([
			["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_2", 1.0], ["Enemy_5", 1.0],
			["Enemy_5", 1.5], ["Enemy_8", 2.5], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
			["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
			["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0], ["Enemy_7", 1.0],
			["Enemy_2", 1.0], ["Enemy_1", 1.0], ["Enemy_5", 1.0], ["Enemy_4", 1.0], ["Enemy_5", 1.0],
			["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_4", 1.0], ["Enemy_3", 1.0], ["Enemy_2", 1.0],
			["Enemy_2", 0.7], ["Enemy_6", 0.8], ["Enemy_1", 1.0], ["Enemy_1", 1.0], ["Enemy_2", 1.0],
			["Enemy_4", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0], ["Enemy_3", 1.0], ["Enemy_4", 1.0],
			["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_6", 1.0], ["Enemy_5", 1.0], ["Enemy_5", 1.0],
			["Enemy_1", 1.0], ["Enemy_3", 1.0], ["Enemy_5", 1.0], ["Enemy_7", 1.0], ["Enemy_4", 1.0],
		])
	out_wave_data.resize(1)
	out_wave_data[0] = result
	return out_wave_data

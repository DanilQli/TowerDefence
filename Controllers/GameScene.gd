extends Node2D

@onready var map_node = load("res://Scenes/Maps/map_%d.tscn" % GameSession.current_level).instantiate()

# Ссылки на контроллеры
var build_controller
var wave_controller
var gift_controller
var ui_controller
var game_end_controller
var health_controller

func _ready():
	for i in range(len(ResourceManager.list_turret)):
		ResourceManager.list_turret[i] = []
	map_node.name = "Map"
	add_child(map_node)

	# Динамически создаем контроллеры
	build_controller = _create_controller("res://Controllers/BuildController.gd")
	wave_controller = _create_controller("res://Controllers/WaveController.gd")
	gift_controller = _create_controller("res://Controllers/GiftController.gd")
	ui_controller = _create_controller("res://Controllers/UIController.gd")
	game_end_controller = _create_controller("res://Controllers/GameEndController.gd")
	health_controller = _create_controller("res://Controllers/HealthController.gd")

	build_controller.initialize(self)
	wave_controller.initialize(self)
	gift_controller.initialize(self)
	ui_controller.initialize(self)
	game_end_controller.initialize(self)
	health_controller.initialize(self)
	GameManager.get_road_coords(self)

	get_tree().paused = false

func _process(delta):
	if build_controller.build_mode:
		build_controller.update_tower_preview()
	if GameSession.speed_game > 0.0:
		var is_last_wave = GameSession.current_wave >= DataManager.data_wave["level_" + str(GameSession.current_level)].size()
		var enemies_remaining = map_node.get_node("Path").get_child_count()

		if is_last_wave and (enemies_remaining == 0 or GameSession.base_health == 0):
			game_end_controller.end_game_company()

func _create_controller(script_path: String) -> Node:
	var script = load(script_path)
	var controller = Node.new()
	controller.set_script(script)
	add_child(controller)
	return controller

func on_base_damage(damage: int):
	health_controller.on_base_damage(damage)

func on_stone(number_block: int, duration: int):
	var tur = []
	var available_turrets = []
	# Сначала соберем все башни без эффекта
	for i in range(len(ResourceManager.list_turret)):
		if len(ResourceManager.list_turret[i]) != 0:
			for j in range(len(ResourceManager.list_turret[i])):
				var turret = ResourceManager.list_turret[i][j]
				if not turret.get_node("NinePatchRect").visible:
					available_turrets.append(turret)

	# Если нет доступных башен без эффекта, выходим
	if available_turrets.size() == 0:
		return

	# Выбираем случайные башни из доступных
	while number_block > 0 and available_turrets.size() > 0:
		var random_index = randi_range(0, available_turrets.size() - 1)
		tur.append(available_turrets[random_index])
		available_turrets.remove_at(random_index)
		number_block -= 1
	for i in range(len(tur)):
		tur[i].stone_effect_start(duration)

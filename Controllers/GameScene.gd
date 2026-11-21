extends Node2D

@onready var map_node

# Ссылки на контроллеры
var build_controller
var wave_controller
var gift_controller
var ui_controller
var game_end_controller
var health_controller
var campaign_pause_menu: CanvasLayer
var _path_root: Node = null
var _stats_panel = null

func _ready():
	GameSession.reset_battle_runtime_state()
	TasksManager.begin_battle()
	if GameSession.game_mode in [GameConstants.GameMode.CAMPAIGN, GameConstants.GameMode.SANDBOX]:
		AudioManager.start_battle_music("music_battle")
	# Install before loading the map/controllers, so input remains available even
	# if a later controller cannot finish initialising.
	if GameSession.game_mode in [GameConstants.GameMode.CAMPAIGN, GameConstants.GameMode.SANDBOX]:
		campaign_pause_menu = preload("res://Controllers/CampaignPauseMenu.gd").new()
		add_child(campaign_pause_menu)
		campaign_pause_menu.initialize(self)
	map_node = load("res://Scenes/Maps/map_%d.tscn" % randi_range(1, 9)).instantiate()
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
	game_end_controller.name = "GameEndController"
	health_controller = _create_controller("res://Controllers/HealthController.gd")

	build_controller.initialize(self)
	wave_controller.initialize(self)
	gift_controller.initialize(self)
	ui_controller.initialize(self)
	game_end_controller.initialize(self)
	health_controller.initialize(self)

	GameManager.get_road_coords(self)

	get_tree().paused = false
	
	InputManager.game_scene = self
	_path_root = map_node.get_node_or_null("Path")
	_stats_panel = get_node_or_null("UI/StatsPanel")
	if _stats_panel:
		_stats_panel.game_scene = self

func _process(_delta):
	if build_controller.build_mode:
		build_controller.update_tower_preview()
	if GameSession.game_mode == GameConstants.GameMode.CAMPAIGN and GameSession.speed_game > 0.0:
		var total_waves: int = wave_controller.wave_data_all.size()
		var is_last_wave: bool = total_waves > 0 and GameSession.current_wave >= total_waves
		if is_last_wave and wave_controller.active_spawn_sequences == 0 and is_instance_valid(_path_root):
			var has_alive_enemy: bool = false
			for path in _path_root.get_children():
				for enemy in path.get_children():
					if not enemy.is_queued_for_deletion():
						has_alive_enemy = true
						break
				if has_alive_enemy:
					break
			if not has_alive_enemy:
				game_end_controller.end_game_company()
	if is_instance_valid(_stats_panel) and _stats_panel.visible:
		_stats_panel.update_stats()

func is_campaign_pause_menu_open() -> bool:
	return is_instance_valid(campaign_pause_menu) and campaign_pause_menu.visible

func _create_controller(script_path: String) -> Node:
	var script = load(script_path)
	var controller = Node.new()
	controller.set_script(script)
	add_child(controller)
	return controller

func on_base_damage(damage: int):
	health_controller.on_base_damage(damage)

func on_signal_spawn_enemies(wave: Array, enemy_progress: float):
	ui_controller.main_scene.wave_controller.spawn_enemies(wave, enemy_progress)
	
func on_stone(number_block: int, duration: int):
	var tur = []
	var available_turrets = []
	# Сначала соберем все башни без эффекта
	for i in range(len(ResourceManager.list_turret)):
		if len(ResourceManager.list_turret[i]) != 0:
			for j in range(len(ResourceManager.list_turret[i])):
				var turret = ResourceManager.list_turret[i][j]
				if not is_instance_valid(turret) or turret.is_opponent or turret.is_protected_by_link:
					continue
				if turret is MoneyTower or turret is LinkTower:
					continue
				var rect = turret.get_node_or_null("NinePatchRect")
				if rect and not rect.visible:
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
		if is_instance_valid(tur[i]):
			tur[i].stone_effect_start(duration)

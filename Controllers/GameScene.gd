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

	get_tree().paused = false

func _process(delta):
	if build_controller.build_mode:
		build_controller.update_tower_preview()
	if GameSession.speed_game > 0.0:
		var is_last_wave = GameSession.current_wave >= DataManager.wave_data[GameSession.current_level].size()
		var enemies_remaining = map_node.get_node("Path").get_child_count()

		if is_last_wave and (enemies_remaining == 0 or GameSession.base_health == 0):
			print(GameSession.base_health)
			game_end_controller.end_game_company()

func _create_controller(script_path: String) -> Node:
	var script = load(script_path)
	var controller = Node.new()
	controller.set_script(script)
	add_child(controller)
	return controller

func on_base_damage(damage: int):
	health_controller.on_base_damage(damage)

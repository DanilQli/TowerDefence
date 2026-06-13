# Controllers/HealthController.gd
## HealthController
extends Node

var main_scene
var hp_label: Label = null

func initialize(scene):
	main_scene = scene
	# Используем безопасный поиск узла
	if main_scene.has_node("UI/HUD/InfoBar/H2/HP"):
		hp_label = main_scene.get_node("UI/HUD/InfoBar/H2/HP")
	else:
		# Пытаемся найти внутри контейнера, если путь отличается
		hp_label = main_scene.find_child("HP", true, false)

func update_health(base_health: int):
	if is_instance_valid(hp_label):
		hp_label.text = str(base_health)
	
func on_base_damage(damage: int):
	GameSession.spend_base_health(damage)

	if GameSession.base_health < 1:
		update_health(0)

		if GameSession.game_mode != GameConstants.GameMode.CAMPAIGN:
			main_scene.game_end_controller.end_game()
		else:
			main_scene.game_end_controller.end_game_company()
	else:
		update_health(GameSession.base_health)

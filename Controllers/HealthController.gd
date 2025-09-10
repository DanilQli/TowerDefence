extends Node

var main_scene
@onready var hp_label: Label = null

func initialize(scene):
	main_scene = scene
	hp_label = main_scene.get_node("UI/HUD/InfoBar/H2/HP")

func update_health(base_health: int):
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

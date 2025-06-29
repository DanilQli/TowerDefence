## Управляет глобальным состоянием игры: старт, пауза, завершение
extends Node

signal game_started
signal game_paused
signal game_over

## Запускает новую игру с выбранным уровнем кампании
func start_game(level: int) -> void:
	GameSession.current_level = level
	GameSession.current_wave = 0
	ResourceManager.current_money_in_game_session = GameConstants.MONEY_BEGIN[level]
	emit_signal("game_started")
	Logger.log(Logger.LogLevel.INFO, "Game started", {"level": level})

## Ставит игру на паузу
func pause_game() -> void:
	get_tree().paused = true
	emit_signal("game_paused")
	Logger.log(Logger.LogLevel.INFO, "Game paused")

## Завершает текущую сессию игры
func end_game() -> void:
	emit_signal("game_over")
	Logger.log(Logger.LogLevel.INFO, "Game over", {
		"score": ResourceManager.current_score,
		"wave": GameSession.current_wave
	})

## Позволяет вернуться в главное меню
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

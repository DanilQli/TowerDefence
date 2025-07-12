## Хранит временные (runtime) данные конкретной игровой сессии
extends Node

signal money_in_game_session_changed()

## Волна и уровень
var current_wave: int = 0
var current_level: int = 0

## Тип режима игры
var game_mode: GameConstants.GameMode = GameConstants.GameMode.SANDBOX

## Скорость игры (1.0 или 4.0 и т.п.)
var speed_game: float = 1.0

## Текущее золото игрока
var current_money_in_game_session: float

## Очки за сессию
var current_game_score: int = 0

## Здоровье базы
var base_health: int = 10

## Увеличивает очки игрока
func add_game_score(value: int) -> void:
	current_game_score += value

## Прибавляет деньги игроку
func add_money(value: float) -> void:
	current_money_in_game_session += value
	current_money_in_game_session = GameConstants.round_to_dec(current_money_in_game_session, 1)
	emit_signal("money_in_game_session_changed")

## Отнимает деньги игрока
func spend_money(value: float) -> void:
	current_money_in_game_session -= value
	current_money_in_game_session = GameConstants.round_to_dec(current_money_in_game_session, 1)
	emit_signal("money_in_game_session_changed")

## Уменьшает здоровье базы
func spend_base_health(value: int) -> void:
	base_health -= value

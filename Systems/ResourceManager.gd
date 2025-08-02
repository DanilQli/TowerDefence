## Управляет текущими ресурсами игрока (золото, очки, лучший результат)
extends Node

## Сигнал об изменении денег
signal money_changed()
## Сигнал об изменении очков
signal score_changed()
## Текущие деньги в игровой сессии
var current_money: int = 0
## Лучший результат из сохранения
var best_score: int = 0
## Текущий результат (очки) в сессии
var current_score: int = 0
## Построенные башни по id башни
var list_turret: Array = [[], [], [], [], [], [], [], [], [], []]
## Модификация скорости от 3 боса
var speed_modifer: int = 1
## Список активных 
var list_active_enemy: Array = []

## Добавить золото в игровую сессию
func add_money(value: int) -> void:
	current_money += value
	emit_signal("money_changed")

## Списать золото с баланса игрока
func spend_money(value: int) -> bool:
	current_money -= value
	emit_signal("money_changed")
	return true
	
## Установить текущие очки игрока и обновить рекорд
func update_score(value: int) -> void:
	current_score = value
	if current_score > best_score:
		best_score = current_score
	emit_signal("score_changed")

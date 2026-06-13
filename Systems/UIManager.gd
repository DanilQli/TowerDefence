## Отвечает за интерфейс башен и открытые меню
extends Node

## Ссылка на текущее окно меню (например: магазин, настройки, выбор режима)
var menu_object: Node

## Список открытых меню башен
var list_open_menu_turrets: Array[Node] = []

## Добавить в список открытую башню (если ещё не добавлена)
func add_open_menu_turret(turret: Node) -> void:
	if is_instance_valid(turret) and not turret in list_open_menu_turrets:
		list_open_menu_turrets.append(turret)

## Убрать башню из списка открытых
func remove_open_menu_turret(turret: Node) -> void:
	list_open_menu_turrets.erase(turret)

## Проверить, открыто ли меню башни
func is_turret_menu_open(turret: Node) -> bool:
	return turret in list_open_menu_turrets

## Скрыть и очистить все открытые меню
func clear_open_menus() -> void:
	for menu in list_open_menu_turrets:
		if is_instance_valid(menu):
			menu.hide()
	list_open_menu_turrets.clear()

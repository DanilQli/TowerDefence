## Класс управления пользовательским интерфейсом башни
extends Node
class_name TowerUI

## Ссылка на башню, которой принадлежит UI
var tower: TowerBase

func setup(tower_base: TowerBase) -> void:
	tower = tower_base
	_connect_signals()
	update_menu()
	update_menu_upgrade()
	
	# Подписываемся на изменение урона
	if tower.type_attack in [GameConstants.TowerType.GUN, GameConstants.TowerType.POISON]:
		tower.damage_inflicted_changed.connect(_update_inflicted_damage)

## Обновление меню башни
func update_menu() -> void:
	_update_combat_menu()
	
	# Обновляем отображение уровня
	tower.get_node("Menu/V/NameAndLvl/Lvl").text = tr("KEY_LVL") + " " + str(tower.current_lvl + 1) + "/" + str(tower.max_lvl + 1)
	
	# Если достигнут максимальный уровень
	if tower.current_lvl >= tower.max_lvl:
		set_max_level_ui()

## Подключение сигналов UI элементов
func _connect_signals() -> void:
	tower.get_node("MenuButton").pressed.connect(_on_menu_button_pressed)
	tower.get_node("Menu/V/HButton/Close").pressed.connect(hide_menu)

## Обработчик нажатия на кнопку меню
func _on_menu_button_pressed() -> void:
	_hide_other_menu_buttons()
	_check_upgrade_possibility()
	_update_inflicted_damage()
	_add_to_open_menus()
	_position_menu()
	tower.get_node("Menu").show()

## Скрытие кнопок меню других башен
func _hide_other_menu_buttons() -> void:
	for i in tower.get_parent().get_children():
		i.get_node("MenuButton").hide()

## Проверка возможности улучшения башни
func _check_upgrade_possibility() -> void:
	if GameSession.current_money_in_game_session >= GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[tower.id].type].upgrade_for_session[tower.current_lvl]:
		tower.get_node("Menu/V/HButton/Up").disabled = false

## Обновление отображения нанесенного урона
func _update_inflicted_damage() -> void:
	if tower.type_attack in [GameConstants.TowerType.GUN,  GameConstants.TowerType.AREA]:
		tower.get_node("Menu/V/4/HValue/Value").text = str(tower.inflicted)

## Добавление меню в список открытых
func _add_to_open_menus() -> void:
	UiManager.add_open_menu_turret(tower.get_node("Menu"))

## Позиционирование меню относительно башни
func _position_menu() -> void:
	var hud = tower.get_parent().get_parent().get_parent().get_node("UI/HUD")
	var menu = tower.get_node("Menu")
	
	if hud.size[0] - tower.position[0] < 400 and hud.size[1] - tower.position[1] < 300:
		menu.position = Vector2(-300, -330)  # Справо снизу
	elif hud.size[0] - tower.position[0] < 400 and tower.position[1] < 150:
		menu.position = Vector2(-300, 50)    # Справо сверху
	elif hud.size[0] - tower.position[0] < 400:
		menu.position = Vector2(-300, 0)     # Снизу
	elif hud.size[1] - tower.position[1] < 300:
		menu.position = Vector2(0, -330)     # Справо
	elif tower.position[1] < 150:
		menu.position = Vector2(0, 50)       # Сверху
	else:
		menu.position = Vector2(50, -200)    # По умолчанию

## Скрытие меню башни
func hide_menu() -> void:
	for i in tower.get_parent().get_children():
		i.get_node("MenuButton").show()
	
	while UiManager.list_open_menu_turrets.size() > 0:
		UiManager.list_open_menu_turrets[0].hide()
		UiManager.list_open_menu_turrets.pop_at(0)

## Обновление меню боевой башни
func _update_combat_menu() -> void:
	var menu = tower.get_node("Menu")
	for i in range(len(GameConstants.DATA_TOWER[tower.id].text)):
		if GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)] is Dictionary:
			menu.get_node("V/" + str(i) + "/HValue/Value").text = str(GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)][int(DataManager.tower_data[tower.type]["level"])][tower.current_lvl])
		else:
			menu.get_node("V/" + str(i) + "/HValue/Value").text = str(GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)][tower.current_lvl])

## Обновление информации об улучшении в меню
func update_menu_upgrade() -> void:
	if tower.current_lvl >= tower.max_lvl:
		_clear_upgrade_texts()
		return
		
	_update_combat_menu_upgrade()
	
	tower.get_node("Menu/V/HButton/Up/LabelValue").text = str(GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[tower.id].type].upgrade_for_session[tower.current_lvl])

## Очистка текстов улучшений при максимальном уровне
func _clear_upgrade_texts() -> void:
	var menu = tower.get_node("Menu")
	
	# Очищаем все тексты улучшений
	menu.get_node("V/0/HValue/Up").text = ""
	menu.get_node("V/1/HValue/Up").text = ""
	menu.get_node("V/2/HValue/Up").text = ""
	menu.get_node("V/3/HValue/Up").text = ""
	if menu.has_node("V/4"):
		menu.get_node("V/4/HValue/Up").text = ""
	
	# Очищаем стоимость улучшения
	menu.get_node("V/HButton/Up/LabelValue").text = ""
	
## Обновление информации об улучшении для боевой башни
func _update_combat_menu_upgrade() -> void:
	var menu = tower.get_node("Menu")
	var next_level = tower.current_lvl + 1
	var text
	for i in range(len(GameConstants.DATA_TOWER[tower.id].text)):
		if GameConstants.DATA_TOWER[tower.id].text[i] != "KEY_RELOAD":
			text = "+"
		else:
			text = ""
		if GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)] is Dictionary:
			text += str(GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)][int(DataManager.tower_data[tower.type]["level"])][next_level] - GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)][int(DataManager.tower_data[tower.type]["level"])][tower.current_lvl])
		else:
			text += str(GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)][next_level] - GameConstants.DATA_TOWER[tower.id]["parametr_" + str(i + 1)][tower.current_lvl])
		menu.get_node("V/" + str(i) + "/HValue/Up").text = text

## Установка UI для максимального уровня башни
func set_max_level_ui() -> void:
	var up_button = tower.get_node("Menu/V/HButton/Up")
	up_button.disabled = true
	up_button.get_node("TextureRect").visible = false
	up_button.get_node("LabelValue").visible = false
	up_button.get_node("LabelBut").text = tr("KEY_LVL_MAX")

func _exit_tree() -> void:
	if tower.damage_inflicted_changed.is_connected(_update_inflicted_damage):
		tower.damage_inflicted_changed.disconnect(_update_inflicted_damage)

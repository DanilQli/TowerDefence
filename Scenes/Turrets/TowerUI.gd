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
	if tower.type_attack == GameConstants.TowerType.NORMAL:
		tower.damage_inflicted_changed.connect(_on_damage_inflicted_changed)

## Обработчик изменения нанесенного урона
func _on_damage_inflicted_changed(value: float) -> void:
	# Обновляем значение только если меню открыто
	if tower.get_node("Menu").visible:
		tower.get_node("Menu/V/HInflicted/HValue/Value").text = str(value)
	
## Обновление меню башни
func update_menu() -> void:
	if tower.type_attack != GameConstants.TowerType.MONEY:
		_update_combat_menu()
	else:
		_update_money_menu()
	
	# Обновляем отображение уровня
	tower.get_node("Menu/V/NameAndLvl/Lvl").text = tr("KEY_LVL") + " " + str(tower.current_lvl + 1) + "/" + str(tower.max_lvl + 1)
	
	# Если достигнут максимальный уровень
	if tower.current_lvl >= tower.max_lvl:
		set_max_level_ui()

## Подключение сигналов UI элементов
func _connect_signals() -> void:
	tower.get_node("MenuButton").pressed.connect(_on_menu_button_pressed)
	tower.get_node("Menu/V/HButton/Close").pressed.connect(hide_menu)
	
	# Если башня денежная, удаляем ненужные элементы UI
	if tower.type_attack == GameConstants.TowerType.MONEY:
		tower.get_node("Menu/V/HRange").queue_free()
		tower.get_node("Menu/V/HStrateg").queue_free()
		tower.get_node("Menu").size[1] = 100

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
	if GameSession.current_money_in_game_session >= DataManager.tower_data[tower.type]["upgrade_for"][tower.current_lvl]:
		tower.get_node("Menu/V/HButton/Up").disabled = false

## Обновление отображения нанесенного урона
func _update_inflicted_damage() -> void:
	if tower.type_attack == GameConstants.TowerType.NORMAL:
		tower.get_node("Menu/V/HInflicted/HValue/Value").text = str(tower.inflicted)

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
	var tower_data = DataManager.tower_data[tower.type]
	
	if tower.type_attack in [GameConstants.TowerType.NORMAL, GameConstants.TowerType.AREA]:
		menu.get_node("V/HDamage/HValue/Value").text = str(tower_data["damage"][tower.current_lvl])
		menu.get_node("V/HReload/HValue/Value").text = str(tower_data["rof"][tower.current_lvl])
		menu.get_node("V/HRange/HValue/Value").text = str(tower_data["range"][tower.current_lvl])
	elif tower.type_attack == GameConstants.TowerType.SLOW:
		menu.get_node("V/HDamage/HValue/Value").text = str(tower_data["intensivity"][tower.current_lvl] * 100)
		menu.get_node("V/HReload/HValue/Value").text = str(tower_data["duration"][tower.current_lvl])
		menu.get_node("V/HRange/HValue/Value").text = str(tower_data["rof"][tower.current_lvl])
		menu.get_node("V/HInflicted/HValue/Value").text = str(tower_data["range"][tower.current_lvl])
	else:
		menu.get_node("V/HDamage/HValue/Value").text = str(tower_data["distance"][tower.current_lvl])
		menu.get_node("V/HReload/HValue/Value").text = str(tower_data["rof"][tower.current_lvl])
		menu.get_node("V/HRange/HValue/Value").text = str(tower_data["range"][tower.current_lvl])

## Обновление меню денежной башни
func _update_money_menu() -> void:
	var menu = tower.get_node("Menu")
	var tower_data = DataManager.tower_data[tower.type]
	
	menu.get_node("V/HDamage/HValue/Value").text = str(tower_data["speed"][tower.current_lvl])
	menu.get_node("V/HReload/HValue/Value").text = str(tower_data["income"][tower.current_lvl])

## Обновление информации об улучшении в меню
func update_menu_upgrade() -> void:
	if tower.current_lvl >= tower.max_lvl:
		_clear_upgrade_texts()
		return
		
	if tower.type_attack != GameConstants.TowerType.MONEY:
		_update_combat_menu_upgrade()
	else:
		_update_money_menu_upgrade()
	
	tower.get_node("Menu/V/HButton/Up/LabelValue").text = str(DataManager.tower_data[tower.type]["upgrade_for"][tower.current_lvl])

## Очистка текстов улучшений при максимальном уровне
func _clear_upgrade_texts() -> void:
	var menu = tower.get_node("Menu")
	
	# Очищаем все тексты улучшений
	menu.get_node("V/HDamage/HValue/Up").text = ""
	menu.get_node("V/HReload/HValue/Up").text = ""
	menu.get_node("V/HRange/HValue/Up").text = ""
	
	# Если есть дополнительное поле для некоторых типов башен
	if tower.type_attack == GameConstants.TowerType.SLOW:
		menu.get_node("V/HInflicted/HValue/Up").text = ""
	
	# Очищаем стоимость улучшения
	menu.get_node("V/HButton/Up/LabelValue").text = ""
	
## Обновление информации об улучшении для боевой башни
func _update_combat_menu_upgrade() -> void:
	var menu = tower.get_node("Menu")
	var tower_data = DataManager.tower_data[tower.type]
	var next_level = tower.current_lvl + 1
	
	if tower.type_attack in [GameConstants.TowerType.NORMAL, GameConstants.TowerType.AREA]:
		menu.get_node("V/HDamage/HValue/Up").text = "+" + str(tower_data["damage"][next_level] - tower_data["damage"][tower.current_lvl])
		menu.get_node("V/HReload/HValue/Up").text = str(tower_data["rof"][next_level] - tower_data["rof"][tower.current_lvl])
		menu.get_node("V/HRange/HValue/Up").text = "+" + str(tower_data["range"][next_level] - tower_data["range"][tower.current_lvl])
	elif tower.type_attack == GameConstants.TowerType.SLOW:
		menu.get_node("V/HDamage/HValue/Up").text = "+" + str(tower_data["intensivity"][next_level] - tower_data["intensivity"][tower.current_lvl])
		menu.get_node("V/HReload/HValue/Up").text = str(tower_data["duration"][next_level] - tower_data["duration"][tower.current_lvl])
		menu.get_node("V/HRange/HValue/Up").text = "+" + str(tower_data["rof"][next_level] - tower_data["rof"][tower.current_lvl])
	else:
		menu.get_node("V/HDamage/HValue/Up").text = "+" + str(tower_data["distance"][next_level] - tower_data["distance"][tower.current_lvl])
		menu.get_node("V/HReload/HValue/Up").text = str(tower_data["rof"][next_level] - tower_data["rof"][tower.current_lvl])
		menu.get_node("V/HRange/HValue/Up").text = "+" + str(tower_data["range"][next_level] - tower_data["range"][tower.current_lvl])

## Обновление информации об улучшении для денежной башни
func _update_money_menu_upgrade() -> void:
	var menu = tower.get_node("Menu")
	var tower_data = DataManager.tower_data[tower.type]
	var next_level = tower.current_lvl + 1
	
	menu.get_node("V/HDamage/HValue/Up").text = str(tower_data["speed"][next_level] - tower_data["speed"][tower.current_lvl])
	menu.get_node("V/HReload/HValue/Up").text = str(tower_data["income"][next_level] - tower_data["income"][tower.current_lvl])

## Установка UI для максимального уровня башни
func set_max_level_ui() -> void:
	var up_button = tower.get_node("Menu/V/HButton/Up")
	up_button.disabled = true
	up_button.get_node("TextureRect").visible = false
	up_button.get_node("LabelValue").visible = false
	up_button.get_node("LabelBut").text = tr("KEY_LVL_MAX")

func _exit_tree() -> void:
	if tower and tower.type_attack == GameConstants.TowerType.NORMAL:
		if tower.damage_inflicted_changed.is_connected(_on_damage_inflicted_changed):
			tower.damage_inflicted_changed.disconnect(_on_damage_inflicted_changed)

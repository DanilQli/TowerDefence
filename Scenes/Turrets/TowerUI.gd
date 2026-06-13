# Scenes/Turrets/TowerUI.gd
extends Node
class_name TowerUI

# Ссылка на башню-владельца
var tower: TowerBase
# Ссылка на узел меню башни
var menu

# Инициализация UI системы башни
func setup(tower_base: TowerBase) -> void:
	tower = tower_base
	menu = tower.get_node("Menu")
	_connect_signals()
	
	# Подписываемся на изменение денег для автоматического обновления кнопки апгрейда
	if not GameSession.money_in_game_session_changed.is_connected(_on_money_changed):
		GameSession.money_in_game_session_changed.connect(_on_money_changed)
	
	# Подписываемся на изменение урона для башен с этой статистикой
	if tower.type_attack in [GameConstants.TowerType.GUN, GameConstants.TowerType.POISON]:
		tower.damage_inflicted_changed.connect(_update_inflicted_damage)

# Обновление текста уровня и проверка максимального уровня
func update_menu() -> void:
	_update_info_menu()
	if menu:
		menu.get_node("V/NameAndLvl/Lvl").text = tr("KEY_LVL") + " " + str(tower.current_lvl + 1) + "/" + str(tower.max_lvl + 1)
		if tower.current_lvl >= tower.max_lvl:
			set_max_level_ui()

# Подключение сигналов от кнопок меню
func _connect_signals() -> void:
	tower.get_node("MenuButton").pressed.connect(_on_menu_button_pressed)
	tower.get_node("Menu/V/HButton/Close").pressed.connect(hide_menu)

# Обработчик нажатия на кнопку открытия меню башни
func _on_menu_button_pressed() -> void:
	# ИСПРАВЛЕНО: Сначала закрываем все старые меню
	_close_all_open_menus()
	
	# Обновляем состояние UI
	_check_upgrade_possibility()
	_update_inflicted_damage()
	_add_to_open_menus()
	_position_menu()
	_update_info_menu()
	
	# Показываем меню
	tower.get_node("Menu").show()

# Закрытие всех ранее открытых меню башен
func _close_all_open_menus() -> void:
	# Копируем список, чтобы избежать модификации во время итерации
	var menus_copy = UiManager.list_open_menu_turrets.duplicate()
	
	# Скрываем все меню
	for old_menu in menus_copy:
		if is_instance_valid(old_menu):
			old_menu.hide()
	
	# Очищаем список открытых меню
	UiManager.list_open_menu_turrets.clear()

# Обновление отображаемых характеристик башни в меню
func _update_info_menu():
	if menu:
		for i in range(len(GameConstants.DATA_TOWER[tower.id].text)):
			# Защита от выхода за границы массива UI элементов
			if i >= len(menu.list_node): 
				break
			
			var param_key = "parametr_" + str(i + 1)
			var tower_data = GameConstants.DATA_TOWER[tower.id]
			
			# Проверка наличия параметра
			if not tower_data.has(param_key): 
				continue
			
			var val_str = ""
			var raw_val = 0.0
			
			# Получаем значение из словаря уровней
			if tower_data[param_key] is Dictionary:
				var lvl_key = int(DataManager.tower_data[tower.type]["level"])
				if tower_data[param_key].has(lvl_key):
					var vals = tower_data[param_key][lvl_key]
					if vals is Array and tower.current_lvl < vals.size():
						raw_val = vals[tower.current_lvl]
					elif vals is float or vals is int:
						raw_val = vals
			# Получаем значение из массива уровней
			elif tower_data[param_key] is Array:
				if tower.current_lvl < tower_data[param_key].size():
					raw_val = tower_data[param_key][tower.current_lvl]
			
			# Применяем множители урона
			if GameConstants.DATA_TOWER[tower.id]["text"][i] == "KEY_DAMAGE":
				raw_val = raw_val * tower.multiplier_damage_all * tower.mastery_damage
			
			val_str = str(MathUtils.round_to_dec(raw_val, 2))
			menu.list_node[i].get_node("HValue/Value").text = val_str

# Проверка доступности кнопки улучшения на основе текущих денег
func _check_upgrade_possibility() -> void:
	if not is_instance_valid(tower): 
		return
	if tower.current_lvl >= tower.max_lvl: 
		return

	var up_button = tower.get_node_or_null("Menu/V/HButton/Up")
	if not is_instance_valid(up_button): 
		return

	# Вычисляем стоимость улучшения
	var upgrade_cost = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[tower.id].type].upgrade_for_session[tower.current_lvl]
	
	# Применяем скидку мастерства
	if DataManager.data["Turrets"].has(tower.turret_id):
		if DataManager.data["Turrets"][tower.turret_id].mastery_lvl >= 6:
			upgrade_cost = MathUtils.round_to_dec(upgrade_cost * tower.mastery_cost_upgrade, 1)
	
	# Разблокируем или блокируем кнопку
	if GameSession.current_money_in_game_session >= upgrade_cost:
		up_button.disabled = false
	else:
		up_button.disabled = true

# Обработчик изменения денег игрока
func _on_money_changed() -> void:
	# Обновляем кнопку апгрейда только если меню открыто
	if is_instance_valid(menu) and menu.visible:
		_check_upgrade_possibility()

# Обновление отображения нанесенного урона
func _update_inflicted_damage(value: float = 0.0) -> void:
	if tower.type_attack in [GameConstants.TowerType.GUN, GameConstants.TowerType.AREA]:
		if menu and menu.has_node("V/6/HValue/Value"):
			menu.get_node("V/6/HValue/Value").text = str(int(tower.inflicted))

# Добавление меню в глобальный список открытых меню
func _add_to_open_menus() -> void:
	if is_instance_valid(menu):
		UiManager.add_open_menu_turret(menu)

# Позиционирование меню на экране с учетом границ HUD
func _position_menu() -> void:
	var hud = tower.get_parent().get_parent().get_parent().get_node("UI/HUD")
	
	# Проверяем положение башни относительно краев экрана
	if hud.size[0] - tower.position[0] < 400 and hud.size[1] - tower.position[1] < 300:
		menu.position = Vector2(-300, -330)
	elif hud.size[0] - tower.position[0] < 400 and tower.position[1] < 150:
		menu.position = Vector2(-300, 50)
	elif hud.size[0] - tower.position[0] < 400:
		menu.position = Vector2(-300, 0)
	elif hud.size[1] - tower.position[1] < 300:
		menu.position = Vector2(0, -330)
	elif tower.position[1] < 150:
		menu.position = Vector2(0, 50)
	else:
		menu.position = Vector2(50, -200)

# Закрытие меню через кнопку Close
func hide_menu() -> void:
	# Скрываем и удаляем все открытые меню
	while UiManager.list_open_menu_turrets.size() > 0:
		UiManager.list_open_menu_turrets[0].hide()
		UiManager.list_open_menu_turrets.pop_at(0)

# Обновление информации об улучшении в меню
func update_menu_upgrade() -> void:
	if tower.current_lvl >= tower.max_lvl:
		_clear_upgrade_texts()
		return
	
	_update_combat_menu_upgrade()
	
	# Вычисляем и отображаем стоимость улучшения
	var upgrade_cost = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[tower.id].type].upgrade_for_session[tower.current_lvl]
	if DataManager.data["Turrets"][tower.turret_id].mastery_lvl >= 6:
		upgrade_cost = MathUtils.round_to_dec(upgrade_cost * tower.mastery_cost_upgrade, 1)
	tower.get_node("Menu/V/HButton/Up/LabelValue").text = str(upgrade_cost)

# Очистка текстов улучшения для максимального уровня
func _clear_upgrade_texts() -> void:
	for i in range(len(menu.list_node)):
		menu.list_node[i].get_node("HValue/NameUp").text = ""
		menu.list_node[i].get_node("HValue/Up").text = ""
	menu.get_node("V/HButton/Up/LabelValue").text = ""

# Обновление отображения изменений характеристик при улучшении
func _update_combat_menu_upgrade() -> void:
	if not is_instance_valid(menu):
		return
	
	var next_level = tower.current_lvl + 1
	var text
	
	for i in range(len(GameConstants.DATA_TOWER[tower.id].text)):
		if i >= len(menu.list_node): 
			break
		
		# Определяем знак изменения (минус для перезарядки, плюс для остального)
		if GameConstants.DATA_TOWER[tower.id].text[i] != "KEY_RELOAD": 
			text = "+"
		else: 
			text = ""
		
		var diff = 0.0
		var param_key = "parametr_" + str(i + 1)
		var t_data = GameConstants.DATA_TOWER[tower.id]
		
		# Вычисляем разницу для словаря уровней
		if t_data[param_key] is Dictionary:
			var lvl_key = int(DataManager.tower_data[tower.type]["level"])
			if t_data[param_key].has(lvl_key):
				var vals = t_data[param_key][lvl_key]
				if next_level < vals.size():
					diff = vals[next_level] - vals[tower.current_lvl]
		# Вычисляем разницу для массива уровней
		elif t_data[param_key] is Array:
			if next_level < t_data[param_key].size():
				diff = t_data[param_key][next_level] - t_data[param_key][tower.current_lvl]
		
		text += str(MathUtils.round_to_dec(diff, 2))
		menu.list_node[i].get_node("HValue/Up").text = text
		menu.list_node[i].get_node("HValue/NameUp").text = str(GameConstants.DATA_TOWER[tower.id].name_label[i])

# Установка UI для максимального уровня башни
func set_max_level_ui() -> void:
	var up_button = tower.get_node("Menu/V/HButton/Up")
	up_button.disabled = true
	up_button.get_node("TextureRect").visible = false
	up_button.get_node("LabelValue").visible = false
	up_button.get_node("LabelBut").text = tr("KEY_LVL_MAX")

# Отписка от сигналов при удалении узла
func _exit_tree() -> void:
	# Отписываемся от сигнала изменения денег
	if GameSession.money_in_game_session_changed.is_connected(_on_money_changed):
		GameSession.money_in_game_session_changed.disconnect(_on_money_changed)
	
	# Отписываемся от сигнала урона
	if tower.damage_inflicted_changed.is_connected(_update_inflicted_damage):
		tower.damage_inflicted_changed.disconnect(_update_inflicted_damage)

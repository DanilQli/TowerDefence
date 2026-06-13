# Scenes/SupportScenes/DeckTab.gd
extends Control

@onready var active_deck_grid = %ActiveDeckGrid
@onready var found_container = %FoundContainer
@onready var not_found_container = %NotFoundContainer
@onready var not_found_separator = %NotFoundSeparator
@onready var not_found_label = %NotFoundSeparator/Label

var selected_slot_index = -1 # 0-3, индекс слота, который хотим поменять

func initialize():
	_refresh()

func _refresh():
	# 1. Очистка контейнеров
	for c in active_deck_grid.get_children(): c.queue_free()
	for c in found_container.get_children(): c.queue_free()
	for c in not_found_container.get_children(): c.queue_free()
	
	var found_count = 0
	var total_count = len(DataManager.tower_data)
	
	# Собираем список ID активных башен (нужен для слотов и замены)
	var active_tower_indices = [] # Хранит индексы (0, 1, 2...)
	for i in range(total_count):
		var tid = "Turret_" + str(i + 1) + "T1"
		if DataManager.tower_data[tid]["activity"]:
			active_tower_indices.append(i)
	
	# 2. Заполняем коллекцию (Найденные и Не найденные)
	for i in range(total_count):
		var tower_id = "Turret_" + str(i + 1) + "T1"
		var data = DataManager.tower_data[tower_id]
		
		if data["have"]:
			found_count += 1
			# Создаем карту в секции "Найденные"
			_create_card_ui(i, data, found_container, true)
		else:
			# Создаем карту в секции "Не найденные"
			_create_card_ui(i, data, not_found_container, false)
			
	# 3. Заполняем слоты активной колоды (всегда 4)
	for i in range(4):
		var tower_idx = -1
		if i < active_tower_indices.size():
			tower_idx = active_tower_indices[i]
		
		var slot = _create_active_slot(i, tower_idx)
		active_deck_grid.add_child(slot)
		
	# 4. Обновляем разделитель
	var missing_count = total_count - found_count
	not_found_label.text = "НЕ НАЙДЕНО: " + str(missing_count) + "/" + str(total_count)
	not_found_separator.visible = (missing_count > 0)

# --- Создание слота активной колоды ---
func _create_active_slot(slot_index, tower_idx):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 160)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if tower_idx != -1:
		btn.icon = load("res://Assets/Props/towerDefense_tile_turret_" + str(tower_idx + 1) + ".png")
	else:
		btn.text = "ПУСТО"
		
	btn.pressed.connect(_on_slot_pressed.bind(slot_index))
	
	# Подсветка выбранного слота
	if slot_index == selected_slot_index:
		btn.modulate = Color(1.5, 1.5, 1.5) # Яркий
		btn.self_modulate = Color(0.5, 1.0, 0.5) # Зеленоватый оттенок
	else:
		btn.modulate = Color.WHITE
		btn.self_modulate = Color.WHITE
		
	return btn

# --- Создание карточки в коллекции (как в магазине) ---
func _create_card_ui(index, data, parent_container, is_found):
	# Используем тот же префаб, что и в магазине
	var panel = load("res://Scenes/Mobile/turret_max_choose.tscn").instantiate()
	panel.custom_minimum_size = Vector2(320, 550)
	parent_container.add_child(panel)
	
	# Настраиваем визуально
	var icon = panel.get_node("VBoxContainer/TextureRect/TextureRect")
	var label = panel.get_node("VBoxContainer/Label")
	var lvl = panel.get_node("VBoxContainer/Lvl")
	
	var card_of_container = panel.get_node("VBoxContainer/CardOf") 
	var card_bar = panel.get_node("VBoxContainer/CardOf/CardOf")
	var card_text_label = panel.get_node("VBoxContainer/CardOf/CardOf/Label") 
	
	# Шрифты
	label.add_theme_font_size_override("font_size", 36)
	lvl.add_theme_font_size_override("font_size", 32)
	if card_text_label: card_text_label.add_theme_font_size_override("font_size", 24)

	icon.texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(index + 1) + ".png")
	label.text = tr("KEY_NAME_TURRET_" + str(index + 1))
	
	if is_found:
		var level = int(data["level"])
		lvl.text = tr("KEY_LVL") + " " + str(level + 1)
		
		# Показываем и настраиваем прогресс
		if card_of_container:
			card_of_container.visible = true
			if level >= GameConstants.NUMBER_LVL_TURRET_CARD:
				if card_text_label: card_text_label.text = tr("KEY_MAX_LVL")
				card_bar.value = 100
				card_bar.max_value = 100
			else:
				var needed = TowerCards.get_cards_needed(index)
				var current = int(data["cards"])
				card_bar.max_value = needed
				card_bar.value = current
				# ВОТ ЗДЕСЬ ПРИСВАИВАЕМ ТЕКСТ
				if card_text_label: card_text_label.text = str(current) + "/" + str(needed)
		
		# Логика клика (если это кнопка)
		if panel is Button:
			# Очищаем старые подключения (если setup() что-то делал)
			if panel.pressed.is_connected(panel.turret_menu_open):
				panel.pressed.disconnect(panel.turret_menu_open)
			
			panel.pressed.connect(_on_card_clicked.bind(index, data))
			
			# Подсветка, если карта уже в колоде
			if data["activity"]:
				panel.modulate = Color(0.6, 0.6, 0.6) # Затемняем, типа занята
				# Или можно сделать рамку, если есть
			else:
				panel.modulate = Color.WHITE
	else:
		# Не найдено
		lvl.text = tr("KEY_NOT_FOUND")
		if card_of_container: card_of_container.visible = false
		panel.modulate = Color(0.4, 0.4, 0.4) # Сильно затемняем
		if panel is Button: panel.disabled = true

# --- Обработка нажатия на слот ---
func _on_slot_pressed(index):
	if selected_slot_index == index:
		selected_slot_index = -1 # Отмена выбора
	else:
		selected_slot_index = index # Выбор слота
	
	_refresh() # Перерисовываем, чтобы обновить подсветку слота

# --- Обработка нажатия на карту ---
func _on_card_clicked(index, data):
	# 1. Если выбран слот для замены -> МЕНЯЕМ
	if selected_slot_index != -1:
		# Нельзя выбрать ту, которая уже активна (она уже в колоде)
		if data["activity"]:
			# Можно сделать звук ошибки или анимацию
			print("Эта карта уже в колоде!")
			return
			
		_swap_card(index)
		return

	# 2. Если слот НЕ выбран -> ОТКРЫВАЕМ МЕНЮ ПРОКАЧКИ
	# Используем TurretMenuShop (как в магазине)
	var menu = load("res://Scenes/SupportScenes/turret_menu_shop.tscn").instantiate()
	var main_menu = find_parent("MenuMobile")
	if main_menu:
		main_menu.add_child(menu)
	else:
		add_child(menu)
	menu.setup(data, index)

# --- Логика замены карт ---
func _swap_card(new_index):
	# ID новой башни
	var new_id = "Turret_" + str(new_index + 1) + "T1"
	
	# Находим список активных башен по порядку
	var active_keys = []
	for i in range(len(DataManager.tower_data)):
		var tid = "Turret_" + str(i + 1) + "T1"
		if DataManager.tower_data[tid]["activity"]:
			active_keys.append(tid)
	
	# Если слот указывает на существующую башню -> выключаем её
	if selected_slot_index < active_keys.size():
		var old_id = active_keys[selected_slot_index]
		DataManager.tower_data[old_id]["activity"] = false
	
	# Включаем новую
	DataManager.tower_data[new_id]["activity"] = true
	
	# Сохраняем
	DataManager.write_file()
	
	# Сбрасываем выбор и обновляем UI
	selected_slot_index = -1
	_refresh()

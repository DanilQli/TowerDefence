# Scenes/SupportScenes/GloryTab.gd
extends Control

@onready var progress_bar = $VBoxContainer/Header/ProgressBar
@onready var progress_label = $VBoxContainer/Header/ProgressBar/Label
@onready var level_label = $VBoxContainer/Header/LevelIcon/Label
@onready var rewards_container = $VBoxContainer/ScrollContainer/VBoxContainer

func _ready() -> void:
	_update_ui()

func _update_ui():
	# Обновляем хедер
	progress_bar.max_value = GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level]
	progress_bar.value = DataManager.glory_progress
	
	var max_xp = GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level]
	progress_label.text = str(DataManager.glory_progress) + "/" + str(max_xp)
	level_label.text = str(DataManager.glory_level)
	
	# Очистка контейнера наград
	for child in rewards_container.get_children():
		child.queue_free()

	# Заполнение списка наград (сверху вниз, от последнего уровня к первому)
	for i in range(len(GameConstants.NUMBER_EXPERIENCE_GLORY) - 1, -1, -1):
		var keys = GameConstants.ID_GIFT_GLORY[i].keys()
		# Используем существующий префаб награды
		var hb = load("res://Scenes/SupportScenes/container_reward.tscn").instantiate()
		
		# Настройка визуалов
		hb.get_node("Control/Romb/Label").text = str(i)
		hb.get_node("Panel2/Button/Panel/TextureRect").texture = DataManager.TYPE_ITEMS[keys[0]][2]
		hb.get_node("Panel1/Button/Panel/TextureRect").texture = DataManager.TYPE_ITEMS[keys[1]][2]
		
		# Текст награды (если это не сундук/крит/деньги с иконкой, а что-то штучное)
		if not keys[1] in [2, 3, 4, 5, 6, 7, 8, 9]:
			hb.get_node("Panel1/Button/Panel/Label").text = str(GameConstants.ID_GIFT_GLORY[i][keys[1]])
		if not keys[0] in [2, 3, 4, 5, 6, 7, 8, 9]:
			hb.get_node("Panel2/Button/Panel/Label").text = str(GameConstants.ID_GIFT_GLORY[i][keys[0]])
			
		# Логика прогрессбара уровня
		var current_lvl_progress = 0.0
		if i > DataManager.glory_level + 1:
			current_lvl_progress = 0.0
		elif i > DataManager.glory_level:
			# Если это следующий уровень, но мы уже прошли половину пути к нему?
			# В оригинале логика была странной, упрощаем:
			# Если i > текущего, прогресс 0
			current_lvl_progress = 0.0
		elif i == DataManager.glory_level:
			# Текущий уровень. Считаем процент заполнения
			var percent = float(DataManager.glory_progress) / float(max_xp) * 100.0
			current_lvl_progress = percent
			
			# Разблокировка наград текущего уровня
			# Левая сторона (Бесплатная)
			hb.get_node("Panel2/Button/Panel/Lock").visible = false
			if not DataManager.glory_rewards_level_get[i][0]:
				hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(keys, i, 0))
				hb.get_node("Panel2/Button/Panel/ColorRect").visible = true
			
			# Правая сторона (VIP)
			if DataManager.glory_vip:
				hb.get_node("Panel1/Button/Panel/Lock").visible = false
				if not DataManager.glory_rewards_level_get[i][1]:
					hb.get_node("Panel1/Button").pressed.connect(open_rewards_glory.bind(keys, i, 1))
					hb.get_node("Panel1/Button/Panel/ColorRect").visible = true
		else:
			# Уровень пройден полностью
			current_lvl_progress = 100.0
			
			# Награды пройденных уровней тоже должны быть доступны, если не забрали
			hb.get_node("Panel2/Button/Panel/Lock").visible = false
			if not DataManager.glory_rewards_level_get[i][0]:
				hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(keys, i, 0))
				hb.get_node("Panel2/Button/Panel/ColorRect").visible = true
				
			if DataManager.glory_vip:
				hb.get_node("Panel1/Button/Panel/Lock").visible = false
				if not DataManager.glory_rewards_level_get[i][1]:
					hb.get_node("Panel1/Button").pressed.connect(open_rewards_glory.bind(keys, i, 1))
					hb.get_node("Panel1/Button/Panel/ColorRect").visible = true
			
		hb.get_node("Control/ProgressBar").value = current_lvl_progress
		rewards_container.add_child(hb)

func open_rewards_glory(keysa, index, vip_index):
	var keys = keysa[vip_index]
	
	# Помечаем как полученное
	DataManager.glory_rewards_level_get[index][vip_index] = 1
	DataManager.data["PathOfGlory"]["rewards_level_get"] = DataManager.glory_rewards_level_get
	
	var box_card = false
	# Проверка: если это сундук (ID 2-9)
	if keys in [2, 3, 4, 5, 6, 7, 8, 9]:
		box_card = GameConstants.get_random_card_pairs(GameConstants.ID_GIFT_GLORY[index][keys])
		DataManager.TYPE_ITEMS[keys][0].call(box_card)
	else:
		# Обычная награда (золото, крит)
		DataManager.TYPE_ITEMS[keys][0].call(GameConstants.ID_GIFT_GLORY[index][keys])
	
	DataManager.write_file()
	
	# Обновляем топ бар (деньги/крит)
	var main_menu = find_parent("MenuMobile")
	if main_menu and main_menu.has_method("_update_top_bar"):
		main_menu._update_top_bar()
	
	if box_card:
		# Показываем открытие сундука
		var choose_buy = load("res://Scenes/SupportScenes/buy_box_open.tscn").instantiate()
		choose_buy.setup(box_card, DataManager.TYPE_ITEMS[keys][2], DataManager.TYPE_ITEMS[keys][4])
		# Добавляем в MainMenu, чтобы перекрыть всё
		if main_menu: main_menu.add_child(choose_buy)
		else: add_child(choose_buy)
	
	# Обновляем UI вкладки (убираем подсветку полученной награды)
	_update_ui()

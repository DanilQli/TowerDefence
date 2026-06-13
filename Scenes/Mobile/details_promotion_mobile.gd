# Scenes/SupportScenes/details_promotion_mobile.gd
extends Control

func setup(id) -> void:
	$Panel/Close.pressed.connect(close)
	
	var lvl = int(DataManager.promotion_progress_level[id])
	var progress = int(DataManager.promotion_progress[id])
	var max_lvl = GameConstants.NUMBER_MINI_PROMOTION
	
	$Panel/VBoxContainer/Header/HBoxContainer/Label2.text = str(lvl)
	$Panel/VBoxContainer/Header/HBoxContainer/Label4.text = str(max_lvl)
	$Panel/VBoxContainer/Header/TextureProgressBar.max_value = max_lvl
	$Panel/VBoxContainer/Header/TextureProgressBar.value = lvl
	
	var container = $Panel/VBoxContainer/ScrollContainer/ItemsContainer
	
	# Создаем элементы списка
	var k = 0
	var flag = false
	
	for i in range(max_lvl):
		# Используем тот же префаб, но увеличим его размер
		var item = load("res://Scenes/SupportScenes/details_promotion_panel.tscn").instantiate()
		item.custom_minimum_size = Vector2(0, 400) # Большой размер
		container.add_child(item)
		
		# Заполнение данными (логика из старого скрипта)
		item.get_node("VBoxContainer/VBoxContainer/Label").text = tr("KEY_PROMOTION_DESC_" + str(id + 1)) + " " + str(GameConstants.NUMBER_LEVEL_PROMOTION[id][k])
		item.get_node("VBoxContainer/VBoxContainer/HBoxContainer/NinePatchRect").texture = load("res://Assets/Icons/medal_" + str(id + 1) + ".png")
		item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer/Label").text = str(GameConstants.NUMBER_EXPERIENCE_PROMOTION[id][k])
		
		if k < lvl:
			# Пройдено
			item.get_node("ColorRect").visible = false
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2").visible = false # Скрываем прогресс
			
			if len(str(DataManager.promotion_progress_level_data_end[id][k])) < 4:
				# Можно забрать награду
				if not flag:
					item.pressed.connect(open_promotion.bind(id, k))
					flag = true
				item.get_node("ColorRect2").visible = true
			else:
				# Уже забрано
				var date_label = Label.new()
				date_label.text = tr("KEY_COMPLETED") + " " + str(DataManager.promotion_progress_level_data_end[id][k])
				item.get_node("VBoxContainer").add_child(date_label)
				
		elif k == lvl:
			# Текущий
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label2").text = str(progress)
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label4").text = str(int(GameConstants.NUMBER_LEVEL_PROMOTION[id][k]))
		else:
			# Закрыто
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label1").text = ""
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label2").text = ""
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label3").text = ""
			item.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label4").text = ""
			
		k += 1

func close():
	if UiManager.menu_object:
		UiManager.menu_object.visible = true
	self.queue_free()

func open_promotion(id, k):
	var now = Time.get_datetime_dict_from_system()
	var date_str = "%04d-%02d-%02d" % [now.year, now.month, now.day]
	DataManager.promotion_stars += GameConstants.NUMBER_EXPERIENCE_PROMOTION[id][k]
	DataManager.promotion_progress_level_data_end[id][k] = date_str
	DataManager.write_file()
	
	# Перезагрузка UI без релоада сцены
	var container = $Panel/VBoxContainer/ScrollContainer/ItemsContainer
	for c in container.get_children(): c.queue_free()
	setup(id)

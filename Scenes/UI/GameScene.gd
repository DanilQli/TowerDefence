extends Node2D

signal game_finished

var map_node

var build_mode = false
var build_valid = false
var build_location
var build_type
var build_tile
var enemies_in_wave = 0
var wave_data_all = DataManager.wave_data[GameSession.current_level]
var wave_data = wave_data_all[GameSession.current_wave]
var node_mouse_entered
var type_attack
var list_gift
var list_random
var list_sprite_box
var have_open_present = false
var list_activity_turret = []

func _ready():
	GameSession.money_in_game_session_changed.connect(_on_money_changed)
	GameSession.current_money_in_game_session = GameConstants.MONEY_BEGIN[GameSession.current_level]
	# Загрузка и добавление карты
	map_node = load("res://Scenes/Maps/map_" + str(GameSession.current_level) + ".tscn").instantiate()
	get_node(".").add_child(map_node)

	# Проверка активных башен
	for i in range(GameConstants.NUMBER_TURRET):
		if DataManager.tower_data["Turret_" + str(i + 1) + "T1"]["activity"] == true:
			list_activity_turret.append(i + 1)
	for i in range(len(list_activity_turret)):
		self.get_node("UI/HUD/BuldBar/Tower_" + str(i + 1) + "/Icon").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(list_activity_turret[i]) + ".png")
		self.get_node("UI/HUD/BuldBar/Tower_" + str(i + 1)).pressed.connect(initiate_build_mode.bind("Turret_" + str(list_activity_turret[i])))
		self.get_node("UI/HUD/BuldBar/Tower_" + str(i + 1)).mouse_entered.connect(title_show.bind(str(i + 1),str(list_activity_turret[i])))
		self.get_node("UI/HUD/BuldBar/Tower_" + str(i + 1)).mouse_exited.connect(title_hide)
	_on_money_changed()

func _process(delta):
	if build_mode:
		update_tower_preview()
	if GameSession.speed_game != 0.0 and GameSession.current_wave >= len(wave_data_all) and (get_node("Map1/Path").get_child_count() == 0 or GameSession.base_health == 0):
		##Конечные волны только в компании
		end_game_company()

func _unhandled_input(event):
	if event.is_action_released("ui_cancel") and build_mode == true: 
		cancel_build_mode()
	if event.is_action_released("ui_accept") and build_mode == true:
		verify_and_build()
		cancel_build_mode()
		
##
## Wave Functions
##
func start_next_wave():
	wave_data = retrieve_wave_data()
	await get_tree().create_timer(0.2).timeout
	spawn_enemies(wave_data)
	
func retrieve_wave_data():
	wave_data = wave_data_all[GameSession.current_wave]
	if GameSession.current_wave in DataManager.list_wave_gift and not have_open_present:
		have_open_present = true
		get_tree().paused = true
		var box_gift = load("res://Scenes/SupportScenes/buf.tscn").instantiate()
		get_node("UI").add_child(box_gift)
		generate_gift()
		box_gift.get_node("Panel/V/H/Box1").pressed.connect(gift_open.bind(0, box_gift))
		box_gift.get_node("Panel/V/H/Box2").pressed.connect(gift_open.bind(1, box_gift))
		box_gift.get_node("Panel/V/H/Box3").pressed.connect(gift_open.bind(2, box_gift))
	GameSession.current_wave += 1
	enemies_in_wave = wave_data.size()
	return wave_data

func generate_gift():
	list_gift = []
	list_sprite_box = []
	var t
	Engine.set_time_scale(1.0)
	for i in range(3):
		var sprite_box = randi() % [0, 1, 2, 3].size() + 1
		list_sprite_box.append(sprite_box)
		get_node("UI/Buf/Panel/V/H/Box" + str(i + 1) + "/AnimationPlayer").play("stay_" + str(sprite_box))
		t = randi() % [0, 1, 2, 3].size()
		while t in list_gift:
			t = randi() % [0, 1, 2, 3].size()
		list_gift.append(t)
		get_node("UI/Buf/Panel/V/H/Box" + str(i + 1) + "/Label").text = tr("KEY_UP_" + str(t))
	list_random = []
	for i in list_gift:
		if i in [0, 1, 2]:
			list_random.append(randi_range(0, 2))
		elif i == 3:
			list_random.append(randi_range(1, 2))
		elif i == 4:
			list_random.append(randi_range(1, 3))

func gift_open(ind, box_gift):
	box_gift.get_node("Panel/V/H/Box1").pressed.disconnect(gift_open.bind(0, box_gift))
	box_gift.get_node("Panel/V/H/Box2").pressed.disconnect(gift_open.bind(0, box_gift))
	box_gift.get_node("Panel/V/H/Box3").pressed.disconnect(gift_open.bind(0, box_gift))
	for i in range(3):
		get_node("UI/Buf/Panel/V/H/Box" + str(i + 1) + "/AnimationPlayer").play("open_" + str(list_sprite_box[i]))
		var modifer = get_node("UI/Buf/Panel/V/HBox/Modifer" + str(i + 1))
		modifer.visible = true
		var icon
		if list_random[i] == 0:
			icon = "res://Assets/Icons/damage.png"
		elif list_random[i] == 1:
			icon = "res://Assets/Icons/reload.png"
		elif list_random[i] == 2:
			icon = "res://Assets/Icons/range.png"
		elif list_random[i] == 3:
			icon = "res://Assets/Icons/distance.png"
		modifer.get_node("TextureRect").texture = load(icon)
		modifer.get_node("Name").text = tr("KEY_UP_UP_" + str(list_random[i]))
		var inde
		if list_random[i] == 1:
			inde = " - "
		else:
			inde = " + "
		modifer.get_node("Up").text = inde + str(GameConstants.modifer_value) + " %"
	"""Модификация данных в GameData"""
	var up = 1 + GameConstants.modifer_value / 100
	if list_random[ind] == 0:
		for i in range(len(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"])):
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"][i] *= up
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"][i] = DataManager.round_to_dec(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"][i], 3)
		for i in map_node.get_node("Turret").get_children():
			if DataManager.tower_data[i.type].has("damage"):
				i.damage = DataManager.tower_data[i.type]["damage"][i.current_lvl]
	elif list_random[ind] == 1:
		for i in range(len(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"])):
			up = 1 - GameConstants.modifer_value / 100
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"][i] *= up
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"][i] = DataManager.round_to_dec(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"][i], 3)
		for i in map_node.get_node("Turret").get_children():
			i.rof = DataManager.tower_data[i.type]["rof"][i.current_lvl]
	elif list_random[ind] == 2:
		for i in range(len(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"])):
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"][i] *= up
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"][i] = DataManager.round_to_dec(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"][i], 3)
		for i in map_node.get_node("Turret").get_children():
			i.range = DataManager.tower_data[i.type]["range"][i.current_lvl]
	elif list_random[ind] == 3:
		for i in range(len(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"])):
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"][i] *= up
			DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"][i] = DataManager.round_to_dec(DataManager.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"][i], 3)
		"""Дистанцию писать не нужно, она используется из словаря в on_hit из enemy"""
	await get_tree().create_timer(1.5).timeout
	for i in range(3):
		if i != ind:
			get_node("UI/Buf/Panel/V/H/Box" + str(i + 1)).queue_free()
			get_node("UI/Buf/Panel/V/HBox/Modifer" + str(i + 1)).queue_free()
	get_node("UI/Buf/Panel/V/Play").visible = true
	get_node("UI/Buf/Panel/V/Play").pressed.connect(continue_game)

func continue_game():
	get_node("UI/Buf").queue_free()
	have_open_present = false
	get_tree().paused = false
	Engine.set_time_scale(GameSession.speed_game)

func spawn_enemies(wave_data):
	get_node("UI/HUD/InfoBar/H3/WaveValue").text = str(GameSession.current_wave)
	for i in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + i[0] + ".tscn").instantiate()
		new_enemy.names = i[0]
		new_enemy.hp = DataManager.enemy_data[new_enemy.names]["hp"]
		new_enemy.current_speed = DataManager.enemy_data[new_enemy.names]["speed"]
		new_enemy.speed = DataManager.enemy_data[new_enemy.names]["speed"]
		new_enemy.duration_speed_mod = 0
		new_enemy.base_damage.connect(on_base_damage)
		map_node.get_node("Path/" + str(randi_range(0, map_node.get_node("Path").get_child_count() - 1))).add_child(new_enemy,true) 
		await get_tree().create_timer(i[1]).timeout
	if GameSession.current_wave + 1 < len(wave_data_all):
		await get_tree().create_timer(5).timeout
		start_next_wave()
		
##
## Building Functions
##
func initiate_build_mode(tower_type):
	for i in map_node.get_node("Turret").get_children():
		i.get_node("MenuButton").show()
	if build_mode:
		cancel_build_mode()
	while len(UiManager.list_open_menu_turrets) > 0:
		UiManager.list_open_menu_turrets[0].hide()
		UiManager.list_open_menu_turrets.pop_at(0)
	if GameSession.current_money_in_game_session >= DataManager.tower_data[tower_type + "T1"]["cost"]:
		get_node("UI").remove_child(get_node("UI/TowerPreview"))
		build_type = tower_type + "T1"
		build_mode = true
		get_node("UI").set_tower_preview(build_type, get_global_mouse_position())
	
func update_tower_preview():
	var mouse_position = get_global_mouse_position()
	var current_tile = map_node.get_node("TowerExlusion").local_to_map(mouse_position)
	var tile_position = map_node.get_node("TowerExlusion").map_to_local(current_tile)
	if map_node.get_node("TowerExlusion").get_cell_source_id(current_tile) == -1:  
		get_node("UI").update_tower_preview(tile_position, "008000")
		build_valid = true
		build_location = tile_position
		build_tile = current_tile
	else:
		get_node("UI").update_tower_preview(tile_position, "ff0000") 
		build_valid = false
		
func cancel_build_mode():
	build_mode = false
	build_valid = false
	var v = get_node("UI/TowerPreview")
	if is_instance_valid(v):
		v.free()
	
func verify_and_build():
	if build_valid:
		var turret = TurretFactory.create_turret(build_type, build_location)
		if not turret:
			printerr("❌ Не удалось создать башню: ", build_type)
			return

		turret.set_name(build_type + "_1")
		map_node.get_node("Turret").add_child(turret)
		map_node.get_node("TowerExlusion").set_cell(build_tile, 0, Vector2i(0,4))

		GameSession.spend_money(DataManager.tower_data[build_type]["cost"])
		_on_money_changed()

func _on_money_changed():
	get_node("UI/HUD/InfoBar/H/Money").text = str(GameSession.current_money_in_game_session)
	for i in range(len(list_activity_turret)):
		self.get_node("UI/HUD/BuldBar/Tower_" + str(i + 1) + "/Color/Cost").text = str(DataManager.tower_data["Turret_" + str(list_activity_turret[i]) + "T1"]["cost"])
		if GameSession.current_money_in_game_session < DataManager.tower_data["Turret_" + str(list_activity_turret[i]) + "T1"]["cost"]:
			get_node("UI/HUD/BuldBar/Tower_" + str(i + 1) + "/Color").color = ("ff0000")
		else:
			get_node("UI/HUD/BuldBar/Tower_" + str(i + 1) + "/Color").color = ("008000")
	
func on_base_damage(damage):
	GameSession.spend_base_health(damage)
	if GameSession.base_health < 1:
		get_node("UI").update_health(0)
		if GameSession.game_mode != GameConstants.GameMode.CAMPAIGN:
			end_game()
		else:
			end_game_company()
	else:
		get_node("UI").update_health(GameSession.base_health)

func end_game_company():
	get_tree().paused = true
	var end = load("res://Scenes/SupportScenes/end_game_company.tscn").instantiate()
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_1/Label").text = tr("KEY_CONTINUE")
	var money_dop = 0
	if GameSession.base_health >= 9:
		end.get_node("Panel/MarginContainer/VBoxContainer/Label").text = tr("KEY_WIN")
		if not DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(GameSession.current_game_score / 10) / 3)
			end.get_node("Panel/MarginContainer/VBoxContainer/HBoxStar/Label2").text = str(money_dop)
	elif GameSession.base_health > 7:
		end.get_node("Panel/MarginContainer/VBoxContainer/Label").text = tr("KEY_WIN")
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect3").queue_free()
		if not DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(GameSession.current_game_score / 10) / 3.1)
			end.get_node("Panel/MarginContainer/VBoxContainer/HBoxStar/Label2").text = str(money_dop)
	elif GameSession.base_health > 5:
		end.get_node("Panel/MarginContainer/VBoxContainer/Label").text = tr("KEY_WIN")
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect2").queue_free()
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect3").queue_free()
		if not DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(GameSession.current_game_score / 10) / 3.2)
			end.get_node("Panel/MarginContainer/VBoxContainer/HBoxStar/Label2").text = str(money_dop)
	else:
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect1").queue_free()
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect2").queue_free()
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect3").queue_free()
		if DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(GameSession.current_game_score / 10) / 4)
			end.get_node("Panel/MarginContainer/VBoxContainer/HBoxStar/Label2").text = str(money_dop)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScore/Label2").text = str(GameSession.current_game_score)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxCoin/Label2").text = str(int(GameSession.current_game_score / 10))
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScoreBest/Label2").text = str(ResourceManager.best_score)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_1").pressed.connect(restart)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_2").pressed.connect(exit_menu)
	get_node("UI").add_child(end)
	if GameSession.current_game_score > ResourceManager.best_score:
		ResourceManager.best_score = GameSession.current_game_score
		DataManager.data["settings_game"]["best_score"] = ResourceManager.best_score
		ResourceManager.resources_money += int(GameSession.current_game_score / 10) + money_dop
		DataManager.data["Resources"]["money"] = ResourceManager.resources_money
		if not DataManager.level_option[GameSession.current_level - 1]:
			DataManager.level_option[GameSession.current_level - 1] = true
			DataManager.data["level_option"]["level"] = DataManager.level_option
		DataManager.write_file()
	GameSession.current_game_score = 0
	
func end_game():
	get_tree().paused = true
	var end = load("res://Scenes/SupportScenes/EndGame.tscn").instantiate()
	if GameSession.current_game_score > ResourceManager.best_score:
		ResourceManager.best_score = GameSession.current_game_score
		DataManager.data["SettingsGame"]["best_score"] = ResourceManager.best_score
		ResourceManager.resources_money += int(GameSession.current_game_score / 10)
		DataManager.data["Resources"]["money"] = ResourceManager.resources_money
		DataManager.write_file()
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScore/Label2").text = str(GameSession.current_game_score)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxCoin/Label2").text = str(int(GameSession.current_game_score / 10))
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScoreBest/Label2").text = str(ResourceManager.best_score)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_1").pressed.connect(restart)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_2").pressed.connect(exit_menu)
	get_node("UI").add_child(end)
	GameSession.current_game_score = 0
		
func exit_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func restart():
	GameSession.current_wave = 0
	GameSession.current_money_in_game_session = GameConstants.MONEY_BEGIN[GameSession.current_level]
	UiManager.list_open_menu_turrets = []
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")
	
func title_show(id_UI, id):
	type_attack = int(DataManager.tower_data["Turret_" + id + "T1"]["type_attack"])
	node_mouse_entered = load("res://Scenes/SupportScenes/TurretMenu.tscn").instantiate()
	node_mouse_entered.position = Vector2i(get_node("UI/HUD/BuldBar/Tower_" + id_UI).position[0] + 100, get_node("UI/HUD/BuldBar/Tower_" + id_UI).position[1] + 50)
	if type_attack != 4:
		if type_attack in [0, 3]:
			node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["damage"][0])
			node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["rof"][0])
			node_mouse_entered.get_node("V/HRange/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["range"][0])
			node_mouse_entered.get_node("V/HInflicted").queue_free()
			node_mouse_entered.size = Vector2i(node_mouse_entered.size[0], node_mouse_entered.size[1] - 30)
		elif type_attack == 1:
			node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["intensivity"][0] * 100)
			node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["duration"][0])
			node_mouse_entered.get_node("V/HRange/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["rof"][0])
			node_mouse_entered.get_node("V/HInflicted/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["range"][0])
		else:
			node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["distance"][0])
			node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["rof"][0])
			node_mouse_entered.get_node("V/HRange/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["range"][0])
			node_mouse_entered.get_node("V/HInflicted").queue_free()
			node_mouse_entered.size = Vector2i(node_mouse_entered.size[0], node_mouse_entered.size[1] - 30)
	else:
		node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["speed"][0])
		node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"]["income"][0])
		node_mouse_entered.get_node("V/HRange").queue_free()
		node_mouse_entered.get_node("V/HInflicted").queue_free()
	node_mouse_entered.get_node("V/HDamage/HValue/Up").queue_free()
	node_mouse_entered.get_node("V/HReload/HValue/Up").queue_free()
	node_mouse_entered.get_node("V/HRange/HValue/Up").queue_free()
	get_node(".").add_child(node_mouse_entered)

func title_hide():
	node_mouse_entered.queue_free()

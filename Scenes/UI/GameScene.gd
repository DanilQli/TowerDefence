extends Node2D

signal game_finished

var map_node

var build_mode = false
var build_valid = false
var build_location
var build_type
var build_tile
var enemies_in_wave = 0
var base_health = 100
var wave_data = GameData.wave_data[GameData.current_wave]
var node_mouse_entered
var type_attack
var list_gift
var list_random
var list_sprite_box
var have_open_present = false


func _ready():
	map_node = get_node("Map_1")
	self.get_node("UI/HUD/BuldBar/Tower_1").pressed.connect(initiate_build_mode.bind("Turret_1"))
	self.get_node("UI/HUD/BuldBar/Tower_2").pressed.connect(initiate_build_mode.bind("Turret_2"))
	self.get_node("UI/HUD/BuldBar/Tower_3").pressed.connect(initiate_build_mode.bind("Turret_3"))
	self.get_node("UI/HUD/BuldBar/Tower_4").pressed.connect(initiate_build_mode.bind("Turret_4"))
	self.get_node("UI/HUD/BuldBar/Tower_5").pressed.connect(initiate_build_mode.bind("Turret_5"))
#	[get_node("UI/HUD/BuldBar/Tower_1"), get_node("UI/HUD/BuldBar/Tower_2"), get_node("UI/HUD/BuldBar/Tower_3")]
#	var t = get_node("UI/HUD/BuldBar/Tower_1")
#	t.pressed.connect(initiate_build_mode(t.get_name()))
	self.get_node("UI/HUD/BuldBar/Tower_1").mouse_entered.connect(title_show.bind("1"))
	self.get_node("UI/HUD/BuldBar/Tower_1").mouse_exited.connect(title_hide)
	self.get_node("UI/HUD/BuldBar/Tower_2").mouse_entered.connect(title_show.bind("2"))
	self.get_node("UI/HUD/BuldBar/Tower_2").mouse_exited.connect(title_hide)
	self.get_node("UI/HUD/BuldBar/Tower_3").mouse_entered.connect(title_show.bind("3"))
	self.get_node("UI/HUD/BuldBar/Tower_3").mouse_exited.connect(title_hide)
	self.get_node("UI/HUD/BuldBar/Tower_4").mouse_entered.connect(title_show.bind("4"))
	self.get_node("UI/HUD/BuldBar/Tower_4").mouse_exited.connect(title_hide)
	self.get_node("UI/HUD/BuldBar/Tower_5").mouse_entered.connect(title_show.bind("5"))
	self.get_node("UI/HUD/BuldBar/Tower_5").mouse_exited.connect(title_hide)
	base_money()

	
func _process(delta):
	if build_mode:
		update_tower_preview()

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
	wave_data = GameData.wave_data[GameData.current_wave]
	if GameData.current_wave in GameData.list_wave_gift and not have_open_present:
		have_open_present = true
		var box_gift = load("res://Scenes/SupportScenes/buf.tscn").instantiate()
		get_node("UI").add_child(box_gift)
		generate_gift()
		box_gift.get_node("Panel/V/H/Box1").pressed.connect(gift_open.bind(0))
		box_gift.get_node("Panel/V/H/Box2").pressed.connect(gift_open.bind(1))
		box_gift.get_node("Panel/V/H/Box3").pressed.connect(gift_open.bind(2))
	GameData.current_wave += 1
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

func gift_open(ind):
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
		modifer.get_node("Up").text = inde + str(GameData.modifer_value) + " %"
	"""Модификация данных в GameData"""
	var up = 1 + GameData.modifer_value / 100
	if list_random[ind] == 0:
		for i in range(len(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"])):
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"][i] *= up
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"][i] = GameData.round_to_dec(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["damage"][i], 3)
		for i in map_node.get_node("Turret").get_children():
			i.damage = GameData.tower_data[i.type]["damage"][i.current_lvl]
	elif list_random[ind] == 1:
		for i in range(len(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"])):
			up = 1 - GameData.modifer_value / 100
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"][i] *= up
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"][i] = GameData.round_to_dec(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["rof"][i], 3)
		for i in map_node.get_node("Turret").get_children():
			i.rof = GameData.tower_data[i.type]["rof"][i.current_lvl]
	elif list_random[ind] == 2:
		for i in range(len(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"])):
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"][i] *= up
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"][i] = GameData.round_to_dec(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["range"][i], 3)
		for i in map_node.get_node("Turret").get_children():
			i.range = GameData.tower_data[i.type]["range"][i.current_lvl]
	elif list_random[ind] == 3:
		for i in range(len(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"])):
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"][i] *= up
			GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"][i] = GameData.round_to_dec(GameData.tower_data["Turret_" + str(list_gift[ind] + 1) + "T1"]["distance"][i], 3)
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
	Engine.set_time_scale(GameData.spped_game)

func spawn_enemies(wave_data):
	get_node("UI/HUD/InfoBar/H3/WaveValue").text = str(GameData.current_wave)
	for i in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + i[0] + ".tscn").instantiate()
		new_enemy.names = i[0]
		new_enemy.hp = GameData.enemy_data[new_enemy.names]["hp"]
		new_enemy.current_speed = GameData.enemy_data[new_enemy.names]["speed"]
		new_enemy.speed = GameData.enemy_data[new_enemy.names]["speed"]
		new_enemy.duration_speed_mod = 0
		new_enemy.base_damage.connect(on_base_damage)
		map_node.get_node("Path").add_child(new_enemy,true) 
		await get_tree().create_timer(i[1]).timeout
	if GameData.current_wave + 1 < len(GameData.wave_data):
		await get_tree().create_timer(5).timeout
		start_next_wave()
##
## Building Functions
##
func initiate_build_mode(tower_type):
	for i in get_node("Map_1/Turret").get_children():
		i.get_node("MenuButton").show()
	if build_mode:
		cancel_build_mode()
	while len(GameData.list_open_menu_turrets) > 0:
		GameData.list_open_menu_turrets[0].hide()
		GameData.list_open_menu_turrets.pop_at(0)
	if GameData.current_money >= GameData.tower_data[tower_type + "T1"]["cost"]:
		get_node("UI").remove_child(get_node("UI/TowerPreview"))
		build_type = tower_type + "T1"
		build_mode = true
		get_node("UI").set_tower_preview(build_type, get_global_mouse_position())
	
func update_tower_preview():
	var mouse_position = get_global_mouse_position()
	var current_tile = map_node.get_node("TowerExlusion").local_to_map(mouse_position)
	var tile_position = map_node.get_node("TowerExlusion").map_to_local(current_tile)
	if map_node.get_node("TowerExlusion").get_cell_source_id(0, current_tile) == -1:  
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
		## Test to verify player has enough cash
		var new_tower = load("res://Scenes/Turrets/" + build_type + ".tscn").instantiate()
		new_tower.position = build_location
		new_tower.type = build_type
		new_tower.inflicted = 0
		new_tower.current_lvl = 0
		new_tower.type_explosion = GameData.tower_data[build_type]["type explosion"]
		new_tower.type_attack = GameData.tower_data[build_type]["type attack"]
		if new_tower.type_attack == 0:
			new_tower.damage = GameData.tower_data[build_type]["damage"][new_tower.current_lvl]
		elif new_tower.type_attack == 1:
			new_tower.damage = 0
			new_tower.intensivity = GameData.tower_data[build_type]["intensivity"][new_tower.current_lvl]
			new_tower.duration = GameData.tower_data[build_type]["duration"][new_tower.current_lvl]
		else:
			new_tower.damage = 0
		new_tower.rof = GameData.tower_data[build_type]["rof"][new_tower.current_lvl]
		new_tower.range = GameData.tower_data[build_type]["range"][new_tower.current_lvl]
		new_tower.strategy = 0
		new_tower.category = GameData.tower_data[build_type]["category"]
		new_tower.max_lvl = GameData.tower_data["Turret_1T1"]["damage"].size() - 1
		new_tower.built = true
		new_tower.set_name(build_type + "_1")
		map_node.get_node("Turret").add_child(new_tower, true)
		map_node.get_node("TowerExlusion").set_cell(0, build_tile, 0, Vector2i(0,4))
		GameData.current_money -= GameData.tower_data[build_type]["cost"]
		base_money()

func base_money():
	get_node("UI/HUD/InfoBar/H/Money").text = str(GameData.current_money)
	get_node("UI/HUD/BuldBar/Tower_1/Color/Cost").text = str(GameData.tower_data["Turret_1T1"]["cost"])
	get_node("UI/HUD/BuldBar/Tower_2/Color/Cost").text = str(GameData.tower_data["Turret_2T1"]["cost"])
	get_node("UI/HUD/BuldBar/Tower_3/Color/Cost").text = str(GameData.tower_data["Turret_3T1"]["cost"])
	get_node("UI/HUD/BuldBar/Tower_4/Color/Cost").text = str(GameData.tower_data["Turret_4T1"]["cost"])
	get_node("UI/HUD/BuldBar/Tower_5/Color/Cost").text = str(GameData.tower_data["Turret_5T1"]["cost"])
	if GameData.current_money < GameData.tower_data["Turret_1T1"]["cost"]:
		get_node("UI/HUD/BuldBar/Tower_1/Color").color = ("ff0000")
	else:
		get_node("UI/HUD/BuldBar/Tower_1/Color").color = ("008000")
	if GameData.current_money < GameData.tower_data["Turret_2T1"]["cost"]:
		get_node("UI/HUD/BuldBar/Tower_2/Color").color = ("ff0000")
	else:
		get_node("UI/HUD/BuldBar/Tower_2/Color").color = ("008000")
	if GameData.current_money < GameData.tower_data["Turret_3T1"]["cost"]:
		get_node("UI/HUD/BuldBar/Tower_3/Color").color = ("ff0000")
	else:
		get_node("UI/HUD/BuldBar/Tower_3/Color").color = ("008000")
	if GameData.current_money < GameData.tower_data["Turret_4T1"]["cost"]:
		get_node("UI/HUD/BuldBar/Tower_4/Color").color = ("ff0000")
	else:
		get_node("UI/HUD/BuldBar/Tower_4/Color").color = ("008000")
	if GameData.current_money < GameData.tower_data["Turret_5T1"]["cost"]:
		get_node("UI/HUD/BuldBar/Tower_5/Color").color = ("ff0000")
	else:
		get_node("UI/HUD/BuldBar/Tower_5/Color").color = ("008000")
	
func on_base_damage(damage):
	base_health -= damage
	if base_health < 1:
		
		var end = load("res://Scenes/SupportScenes/EndGame.tscn").instantiate()
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_1").pressed.connect(restart)
		end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_2").pressed.connect(exit)
		get_node("UI").add_child(end)
	else:
		get_node("UI").update_health(base_health)

func exit():
	get_tree().quit()

func restart():
	GameData.current_wave = 0
	GameData.current_money = 400
	GameData.list_open_menu_turrets = []
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")
	
func title_show(id):
	type_attack = GameData.tower_data["Turret_" + id + "T1"]["type attack"]
	node_mouse_entered = load("res://Scenes/SupportScenes/TurretMenu.tscn").instantiate()
	node_mouse_entered.position = Vector2i(get_node("UI/HUD/BuldBar/Tower_" + id).position[0] + 100, get_node("UI/HUD/BuldBar/Tower_" + id).position[1] + 50)
	if type_attack == 0:
		node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["damage"][0])
		node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["rof"][0])
		node_mouse_entered.get_node("V/HRange/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["range"][0])
		node_mouse_entered.get_node("V/HInflicted").queue_free()
		node_mouse_entered.size = Vector2i(node_mouse_entered.size[0], node_mouse_entered.size[1] - 30)
	elif type_attack == 1:
		node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["intensivity"][0] * 100)
		node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["duration"][0])
		node_mouse_entered.get_node("V/HRange/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["rof"][0])
		node_mouse_entered.get_node("V/HInflicted/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["range"][0])
	else:
		node_mouse_entered.get_node("V/HDamage/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["distance"][0])
		node_mouse_entered.get_node("V/HReload/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["rof"][0])
		node_mouse_entered.get_node("V/HRange/HValue/Value").text = str(GameData.tower_data["Turret_" + id + "T1"]["range"][0])
		node_mouse_entered.get_node("V/HInflicted").queue_free()
		node_mouse_entered.size = Vector2i(node_mouse_entered.size[0], node_mouse_entered.size[1] - 30)
	node_mouse_entered.get_node("V/HDamage/HValue/Up").queue_free()
	node_mouse_entered.get_node("V/HReload/HValue/Up").queue_free()
	node_mouse_entered.get_node("V/HRange/HValue/Up").queue_free()
	get_node(".").add_child(node_mouse_entered)

func title_hide():
	node_mouse_entered.queue_free()

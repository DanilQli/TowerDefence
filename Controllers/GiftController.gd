extends Node

var main_scene
var list_gift: Array = []
var list_random: Array = []
var list_sprite_box: Array = []
var have_open_present: bool = false

func initialize(scene):
	main_scene = scene

func launch_gift_box():
	have_open_present = true
	get_tree().paused = true

	var box_gift = load("res://Scenes/SupportScenes/buf.tscn").instantiate()
	main_scene.get_node("UI").add_child(box_gift)
	generate_gift()

	box_gift.get_node("Panel/V/H/Box1").pressed.connect(gift_open.bind(0, box_gift))
	box_gift.get_node("Panel/V/H/Box2").pressed.connect(gift_open.bind(1, box_gift))
	box_gift.get_node("Panel/V/H/Box3").pressed.connect(gift_open.bind(2, box_gift))

func generate_gift():
	list_gift = []
	list_sprite_box = []
	list_random = []

	for i in range(3):
		var sprite_box = randi() % 4 + 1
		list_sprite_box.append(sprite_box)

		var box_path = "UI/Buf/Panel/V/H/Box" + str(i + 1)
		main_scene.get_node(box_path + "/AnimationPlayer").play("stay_" + str(sprite_box))

		var t = randi() % 4
		while t in list_gift:
			t = randi() % 4

		list_gift.append(t)
		main_scene.get_node(box_path + "/Label").text = tr("KEY_UP_" + str(t))

	for i in list_gift:
		if i == 0 or i == 1 or i == 2:
			list_random.append(randi_range(0, 2))
		elif i == 3:
			list_random.append(randi_range(1, 2))
		elif i == 4:
			list_random.append(randi_range(1, 3))

func gift_open(index: int, box_gift: Node):
	for i in range(3):
		box_gift.get_node("Panel/V/H/Box" + str(i + 1)).pressed.disconnect(gift_open.bind(i, box_gift))

	for i in range(3):
		var anim_path = "Panel/V/H/Box" + str(i + 1) + "/AnimationPlayer"
		box_gift.get_node(anim_path).play("open_" + str(list_sprite_box[i]))

		var mod_path = "Panel/V/HBox/Modifer" + str(i + 1)
		var modifier = box_gift.get_node(mod_path)
		modifier.visible = true

		var icon_path = ""
		if list_random[i] == 0:
			icon_path = "res://Assets/Icons/damage.png"
		elif list_random[i] == 1:
			icon_path = "res://Assets/Icons/reload.png"
		elif list_random[i] == 2:
			icon_path = "res://Assets/Icons/range.png"
		elif list_random[i] == 3:
			icon_path = "res://Assets/Icons/distance.png"

		modifier.get_node("TextureRect").texture = load(icon_path)
		modifier.get_node("Name").text = tr("KEY_UP_UP_" + str(list_random[i]))

		var is_reload = list_random[i] == 1
		var label_sign = " - "
		if not is_reload:
			label_sign = " + "

		modifier.get_node("Up").text = label_sign + str(GameConstants.MODIFIER_VALUE) + " %"

	var up = 1 + GameConstants.MODIFIER_VALUE / 100
	var id = list_gift[index] + 1
	var turret_id = "Turret_" + str(id) + "T1"

	var type = list_random[index]
	if type == 0:
		for i in range(DataManager.tower_data[turret_id]["damage"].size()):
			DataManager.tower_data[turret_id]["damage"][i] *= up
			DataManager.tower_data[turret_id]["damage"][i] = MathUtils.round_to_dec(DataManager.tower_data[turret_id]["damage"][i], 3)
		for turret in main_scene.map_node.get_node("Turret").get_children():
			if turret.type == turret_id:
				turret.damage = DataManager.tower_data[turret.type]["damage"][turret.current_lvl]

	elif type == 1:
		up = 1 - GameConstants.MODIFIER_VALUE / 100
		for i in range(DataManager.tower_data[turret_id]["rof"].size()):
			DataManager.tower_data[turret_id]["rof"][i] *= up
			DataManager.tower_data[turret_id]["rof"][i] = MathUtils.round_to_dec(DataManager.tower_data[turret_id]["rof"][i], 3)
		for turret in main_scene.map_node.get_node("Turret").get_children():
			if turret.type == turret_id:
				turret.rof = DataManager.tower_data[turret.type]["rof"][turret.current_lvl]

	elif type == 2:
		for i in range(DataManager.tower_data[turret_id]["range"].size()):
			DataManager.tower_data[turret_id]["range"][i] *= up
			DataManager.tower_data[turret_id]["range"][i] = MathUtils.round_to_dec(DataManager.tower_data[turret_id]["range"][i], 3)
		for turret in main_scene.map_node.get_node("Turret").get_children():
			if turret.type == turret_id:
				turret.range = DataManager.tower_data[turret.type]["range"][turret.current_lvl]

	elif type == 3:
		for i in range(DataManager.tower_data[turret_id]["distance"].size()):
			DataManager.tower_data[turret_id]["distance"][i] *= up
			DataManager.tower_data[turret_id]["distance"][i] = MathUtils.round_to_dec(DataManager.tower_data[turret_id]["distance"][i], 3)

	await get_tree().create_timer(1.5).timeout

	for i in range(3):
		if i != index:
			box_gift.get_node("Panel/V/H/Box" + str(i + 1)).queue_free()
			box_gift.get_node("Panel/V/HBox/Modifer" + str(i + 1)).queue_free()

	box_gift.get_node("Panel/V/Play").visible = true
	box_gift.get_node("Panel/V/Play").pressed.connect(continue_game)

func continue_game():
	main_scene.get_node("UI/Buf").queue_free()
	have_open_present = false
	get_tree().paused = false
	Engine.set_time_scale(GameSession.speed_game)

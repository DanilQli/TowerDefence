extends Node

var main_scene
var list_gift: Array = []
var list_random: Array = []
var list_sprite_box: Array = []
var have_open_present: bool = false

func initialize(scene):
	main_scene = scene

func _style_box_pedestal(box_node: Control, hovered: bool, winner: bool = false) -> void:
	var pedestal := box_node.get_node_or_null("PedestalBg") as Panel
	if not pedestal:
		return
	var st := StyleBoxFlat.new()
	if winner:
		st.bg_color = Color(0.11, 0.14, 0.08, 0.98)
		st.border_color = Color(1.0, 0.84, 0.24, 1.0)
	elif hovered:
		st.bg_color = Color(0.095, 0.135, 0.225, 0.98)
		st.border_color = Color(1.0, 0.80, 0.28, 0.98)
	else:
		st.bg_color = Color(0.063, 0.09, 0.157, 0.96)
		st.border_color = Color(0.72, 0.56, 0.22, 0.85)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 3
	st.set_corner_radius_all(16)
	st.shadow_color = Color(0, 0, 0, 0.48)
	st.shadow_size = 10 if (hovered or winner) else 8
	st.shadow_offset = Vector2(0, 4)
	pedestal.add_theme_stylebox_override("panel", st)

func _on_box_hover(box_node: Control, entered: bool) -> void:
	if not is_instance_valid(box_node) or box_node.has_meta("opened"):
		return
	_style_box_pedestal(box_node, entered, false)
	var tw: Tween = box_node.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(box_node, "scale", Vector2(1.045, 1.045) if entered else Vector2.ONE, 0.12)

func _style_modifier_card(mod_node: Panel, perk_type: int, is_winner: bool) -> void:
	var accent := Color(0.96, 0.42, 0.36, 0.95) # 0 = damage
	if perk_type == 1:
		accent = Color(0.32, 0.80, 1.0, 0.95) # 1 = reload
	elif perk_type == 2:
		accent = Color(0.34, 0.92, 0.58, 0.95) # 2 = range
	elif perk_type == 3:
		accent = Color(0.76, 0.52, 1.0, 0.95) # 3 = distance

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.085, 0.125, 0.215, 0.99) if is_winner else Color(0.055, 0.082, 0.145, 0.94)
	st.border_color = Color(1.0, 0.84, 0.26, 1.0) if is_winner else accent
	st.border_width_left = 2
	st.border_width_top = 3
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.set_corner_radius_all(16)
	st.shadow_color = Color(0, 0, 0, 0.52)
	st.shadow_size = 14 if is_winner else 8
	st.shadow_offset = Vector2(0, 4)
	mod_node.add_theme_stylebox_override("panel", st)

	var halo := mod_node.get_node_or_null("IconHalo") as Panel
	if halo:
		var hst := StyleBoxFlat.new()
		hst.bg_color = Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.22, 0.92)
		hst.border_color = Color(accent.r, accent.g, accent.b, 0.72)
		hst.set_border_width_all(1)
		hst.set_corner_radius_all(40)
		halo.add_theme_stylebox_override("panel", hst)

func launch_gift_box():
	have_open_present = true
	get_tree().paused = true

	var box_gift: Control = load("res://Scenes/SupportScenes/buf.tscn").instantiate() as Control
	main_scene.get_node("UI").add_child(box_gift)
	generate_gift()

	var panel := box_gift.get_node_or_null("Panel") as Control
	if panel:
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate.a = 0.0
		var tw: Tween = box_gift.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, 0.16)

	for idx in range(3):
		var b := box_gift.get_node("Panel/V/H/Box" + str(idx + 1)) as Control
		b.pressed.connect(gift_open.bind(idx, box_gift))
		b.mouse_entered.connect(_on_box_hover.bind(b, true))
		b.mouse_exited.connect(_on_box_hover.bind(b, false))

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
		var btn := box_gift.get_node("Panel/V/H/Box" + str(i + 1)) as Control
		btn.set_meta("opened", true)
		if btn.pressed.is_connected(gift_open.bind(i, box_gift)):
			btn.pressed.disconnect(gift_open.bind(i, box_gift))

	for i in range(3):
		var box_node := box_gift.get_node("Panel/V/H/Box" + str(i + 1)) as Control
		var anim_path = "Panel/V/H/Box" + str(i + 1) + "/AnimationPlayer"
		box_gift.get_node(anim_path).play("open_" + str(list_sprite_box[i]))

		var mod_path = "Panel/V/HBox/Modifer" + str(i + 1)
		var modifier := box_gift.get_node(mod_path) as Panel
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
		var label_sign = " - " if is_reload else " + "
		modifier.get_node("Up").text = label_sign + str(GameConstants.MODIFIER_VALUE) + " %"

		var is_winner: bool = (i == index)
		_style_modifier_card(modifier, list_random[i], is_winner)
		_style_box_pedestal(box_node, false, is_winner)

		modifier.scale = Vector2(0.78, 0.78)
		modifier.modulate = Color(1, 1, 1, 0.0)
		var target_mod := Color(1, 1, 1, 1) if is_winner else Color(0.68, 0.72, 0.82, 0.82)
		var target_scale := Vector2(1.04, 1.04) if is_winner else Vector2(0.95, 0.95)
		box_node.modulate = Color(1, 1, 1, 1) if is_winner else Color(0.68, 0.72, 0.82, 0.82)

		var mtw: Tween = box_gift.create_tween()
		mtw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		mtw.set_parallel(true)
		mtw.tween_property(modifier, "scale", target_scale, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		mtw.tween_property(modifier, "modulate", target_mod, 0.18)

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
	if not is_instance_valid(box_gift):
		return

	for i in range(3):
		if i != index:
			box_gift.get_node("Panel/V/H/Box" + str(i + 1)).queue_free()
			box_gift.get_node("Panel/V/HBox/Modifer" + str(i + 1)).queue_free()

	var play_btn := box_gift.get_node("Panel/V/Play") as Button
	play_btn.visible = true
	play_btn.pressed.connect(continue_game)

func continue_game():
	main_scene.get_node("UI/Buf").queue_free()
	have_open_present = false
	get_tree().paused = false
	Engine.set_time_scale(GameSession.speed_game)

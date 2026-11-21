extends Node

const DESKTOP_BUF_SCENE: PackedScene = preload("res://Scenes/SupportScenes/buf.tscn")
const MOBILE_BUF_SCENE: PackedScene = preload("res://Scenes/Mobile/buf_mobile.tscn")
const CHEST_POOL: Array[int] = [1, 3, 4, 5, 6, 7]
const MODIFIER_ICONS: Dictionary = {
	0: preload("res://Assets/Icons/damage.png"),
	1: preload("res://Assets/Icons/reload.png"),
	2: preload("res://Assets/Icons/range.png"),
	3: preload("res://Assets/Icons/distance.png")
}

var main_scene
var list_gift: Array = []
var list_random: Array = []
var list_sprite_box: Array = []
var have_open_present: bool = false

const STAT_KEYS_BY_MODIFIER := {
	0: "damage",
	1: "rof",
	2: "range",
	3: "distance"
}

func initialize(scene) -> void:
	main_scene = scene

func _on_box_hover(box_node: Control, entered: bool) -> void:
	if not is_instance_valid(box_node) or box_node.has_meta("opened"):
		return
	if box_node.has_method("set_hovered_state"):
		box_node.call("set_hovered_state", entered)

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

func _tower_buff_title(tower_idx: int) -> String:
	if tower_idx >= 0 and tower_idx <= 4:
		return tr("KEY_UP_" + str(tower_idx))
	return tr("KEY_NAME_TURRET_" + str(tower_idx + 1))

func _pick_buffable_towers() -> Array[int]:
	var equipped: Array[int] = []
	for tid in [0, 1, 2, 3, 4, 6, 7, 8, 9, 10]:
		var key: String = "Turret_" + str(tid + 1) + "T1"
		if DataManager.tower_data.has(key) and AudioManager.to_bool(DataManager.tower_data[key].get("activity", false)):
			equipped.append(tid)
	equipped.shuffle()

	var picked: Array[int] = []
	for tid in equipped:
		if picked.size() >= 3:
			break
		picked.append(tid)

	var fallback: Array[int] = [0, 1, 2, 3, 4]
	fallback.shuffle()
	for tid in fallback:
		if picked.size() >= 3:
			break
		if not (tid in picked):
			picked.append(tid)
	return picked

func _roll_modifier_for_tower(tower_idx: int) -> int:
	if tower_idx == 3:
		return randi_range(1, 2) # Замедление: перезарядка / радиус
	if tower_idx == 4:
		return randi_range(1, 3) # Хронопетля: перезарядка / радиус / дистанция
	return randi_range(0, 2) # Все боевые башни: урон / перезарядка / радиус

func launch_gift_box(cleared_wave: int = 0) -> void:
	if have_open_present or not is_instance_valid(main_scene):
		return
	var ui_root: Node = main_scene.get_node_or_null("UI")
	if not is_instance_valid(ui_root):
		return

	have_open_present = true
	get_tree().paused = true
	AudioManager.play_sfx("gift_appear")

	var is_mobile: bool = OS.get_name() in ["Android", "iOS"]
	var scene_to_use: PackedScene = MOBILE_BUF_SCENE if is_mobile else DESKTOP_BUF_SCENE
	var box_gift: Control = scene_to_use.instantiate() as Control
	ui_root.add_child(box_gift)

	var header_lbl := box_gift.get_node_or_null("Panel/Label") as Label
	if header_lbl:
		var wave_num: int = cleared_wave if cleared_wave > 0 else int(GameSession.current_wave)
		if wave_num > 0:
			var is_ru: bool = TranslationServer.get_locale().begins_with("ru")
			var wave_tag: String = ("Волна %d пройдена" % wave_num) if is_ru else ("Wave %d Cleared" % wave_num)
			header_lbl.text = tr("KEY_CHOOSE_REWARD") + "  ·  " + wave_tag
		else:
			header_lbl.text = tr("KEY_CHOOSE_REWARD")

	generate_gift(box_gift, is_mobile)

	var panel := box_gift.get_node_or_null("Panel") as Control
	if panel:
		var vp_size: Vector2 = box_gift.get_viewport_rect().size
		var target_scale := Vector2.ONE
		var base_w: float = 920.0 if is_mobile else 760.0
		if vp_size.x > 0.0 and vp_size.x < base_w + 40.0:
			var fit: float = clampf((vp_size.x - 32.0) / base_w, 0.65, 1.0)
			target_scale = Vector2(fit, fit)
		panel.pivot_offset = panel.size * 0.5
		panel.scale = target_scale * 0.90
		panel.modulate.a = 0.0
		var tw: Tween = box_gift.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", target_scale, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, 0.18)

	for idx in range(3):
		var b := box_gift.get_node("Panel/V/H/Box" + str(idx + 1)) as BaseButton
		b.pressed.connect(gift_open.bind(idx, box_gift))
		b.mouse_entered.connect(_on_box_hover.bind(b, true))
		b.mouse_exited.connect(_on_box_hover.bind(b, false))

func generate_gift(box_gift: Node, is_mobile: bool = false) -> void:
	list_gift = []
	list_sprite_box = []
	list_random = []

	var variants: Array[int] = CHEST_POOL.duplicate()
	variants.shuffle()
	var towers: Array[int] = _pick_buffable_towers()

	for i in range(3):
		var chest_variant: int = variants[i]
		list_sprite_box.append(chest_variant)

		var t: int = towers[i]
		list_gift.append(t)
		list_random.append(_roll_modifier_for_tower(t))

		var box_node: Control = box_gift.get_node("Panel/V/H/Box" + str(i + 1)) as Control
		if is_mobile and box_node:
			box_node.custom_minimum_size = Vector2(256, 206)
			box_node.pivot_offset = box_node.custom_minimum_size * 0.5
			var lbl := box_node.get_node_or_null("Label") as Label
			if lbl:
				lbl.add_theme_font_size_override("font_size", 19)
		if box_node and box_node.has_method("configure_chest"):
			box_node.call("configure_chest", chest_variant, i, _tower_buff_title(t))

func gift_open(index: int, box_gift: Node) -> void:
	if not is_instance_valid(box_gift) or box_gift.has_meta("gift_opened"):
		return
	box_gift.set_meta("gift_opened", true)
	AudioManager.play_sfx("chest_open")
	AudioManager.play_sfx("gift_pick")

	for i in range(3):
		var btn := box_gift.get_node("Panel/V/H/Box" + str(i + 1)) as BaseButton
		btn.set_meta("opened", true)
		btn.disabled = true

	for i in range(3):
		var box_node := box_gift.get_node("Panel/V/H/Box" + str(i + 1)) as Control
		var is_winner: bool = (i == index)
		if box_node and box_node.has_method("play_open"):
			box_node.call("play_open", is_winner)

		var mod_path: String = "Panel/V/HBox/Modifer" + str(i + 1)
		var modifier := box_gift.get_node(mod_path) as Panel
		modifier.visible = true

		var mod_kind: int = int(list_random[i])
		modifier.get_node("TextureRect").texture = MODIFIER_ICONS.get(mod_kind)
		modifier.get_node("Name").text = tr("KEY_UP_UP_" + str(mod_kind))

		var is_reload: bool = (mod_kind == 1)
		var label_sign: String = " - " if is_reload else " + "
		modifier.get_node("Up").text = label_sign + str(GameConstants.MODIFIER_VALUE) + " %"

		_style_modifier_card(modifier, mod_kind, is_winner)

		modifier.scale = Vector2(0.76, 0.76)
		modifier.modulate = Color(1, 1, 1, 0.0)
		var target_mod: Color = Color(1, 1, 1, 1) if is_winner else Color(0.68, 0.72, 0.82, 0.80)
		var target_scale: Vector2 = Vector2(1.05, 1.05) if is_winner else Vector2(0.94, 0.94)
		box_node.modulate = Color(1, 1, 1, 1) if is_winner else Color(0.68, 0.72, 0.82, 0.78)

		var mtw: Tween = box_gift.create_tween()
		mtw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		mtw.tween_interval(0.10)
		mtw.tween_property(modifier, "scale", target_scale, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		mtw.parallel().tween_property(modifier, "modulate", target_mod, 0.18)

	var mod_type: int = int(list_random[index])
	var stat_key: String = str(STAT_KEYS_BY_MODIFIER.get(mod_type, ""))
	var factor: float = (1.0 - GameConstants.MODIFIER_VALUE / 100.0) if mod_type == 1 else (1.0 + GameConstants.MODIFIER_VALUE / 100.0)
	var id: int = int(list_gift[index]) + 1
	var turret_id: String = "Turret_" + str(id) + "T1"

	if not stat_key.is_empty():
		GameSession.record_gift_buff(turret_id, stat_key, factor)
		if is_instance_valid(main_scene) and is_instance_valid(main_scene.map_node):
			var turret_layer: Node = main_scene.map_node.get_node_or_null("Turret")
			if is_instance_valid(turret_layer):
				for turret in turret_layer.get_children():
					if is_instance_valid(turret) and turret is TowerBase and turret.type == turret_id:
						turret.apply_level_and_gift_stats()
						if is_instance_valid(turret.ui_system):
							turret.ui_system.update_menu()
							turret.ui_system.update_menu_upgrade()

	await get_tree().create_timer(1.35, true, false, true).timeout
	if not is_instance_valid(box_gift):
		return

	var fade_tw: Tween = box_gift.create_tween()
	fade_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tw.set_parallel(true)
	for i in range(3):
		if i != index:
			var b_node: Control = box_gift.get_node_or_null("Panel/V/H/Box" + str(i + 1)) as Control
			var m_node: Control = box_gift.get_node_or_null("Panel/V/HBox/Modifer" + str(i + 1)) as Control
			if is_instance_valid(b_node):
				fade_tw.tween_property(b_node, "modulate:a", 0.0, 0.18)
				fade_tw.tween_property(b_node, "scale", Vector2(0.86, 0.86), 0.18)
			if is_instance_valid(m_node):
				fade_tw.tween_property(m_node, "modulate:a", 0.0, 0.18)
				fade_tw.tween_property(m_node, "scale", Vector2(0.86, 0.86), 0.18)
	await fade_tw.finished
	if not is_instance_valid(box_gift):
		return

	for i in range(3):
		if i != index:
			var b_node: Node = box_gift.get_node_or_null("Panel/V/H/Box" + str(i + 1))
			var m_node: Node = box_gift.get_node_or_null("Panel/V/HBox/Modifer" + str(i + 1))
			if is_instance_valid(b_node):
				b_node.queue_free()
			if is_instance_valid(m_node):
				m_node.queue_free()

	var play_btn := box_gift.get_node("Panel/V/Play") as Button
	play_btn.visible = true
	if not play_btn.pressed.is_connected(continue_game):
		play_btn.pressed.connect(continue_game)

func continue_game() -> void:
	if is_instance_valid(main_scene) and main_scene.has_node("UI/Buf"):
		main_scene.get_node("UI/Buf").queue_free()
	have_open_present = false
	get_tree().paused = false
	var spd: float = GameSession.speed_game if GameSession.speed_game > 0.0 else 1.0
	Engine.set_time_scale(spd)

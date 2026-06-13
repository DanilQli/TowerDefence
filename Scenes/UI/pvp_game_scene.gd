# Scenes/UI/pvp_game_scene.gd
extends Node2D

@onready var my_container = $CanvasLayer/HBoxContainer/Player1Container
@onready var opponent_container = $CanvasLayer/HBoxContainer/Player2Container
@onready var canvas_layer = $CanvasLayer

var pvp_manager: Node
var waves_started := false
var game_start_time = 0

func _ready():
	pvp_manager = NetworkManager 
	print("PVP SCENE READY. PvPSession ID: ", PvPSession.player_id)
	
	my_container.set_as_player(NetworkManager)
	opponent_container.set_as_spectator()
	
	if not NetworkManager.game_state_updated.is_connected(_on_game_state_updated):
		NetworkManager.game_state_updated.connect(_on_game_state_updated)
	if not NetworkManager.game_started.is_connected(_on_game_started):
		NetworkManager.game_started.connect(_on_game_started)
	if not NetworkManager.game_finished.is_connected(_on_game_finished):
		NetworkManager.game_finished.connect(_on_game_finished)
	
	NetworkManager.set_ready()

func _on_game_started(wave_data: Array):
	if waves_started: return
	waves_started = true
	game_start_time = Time.get_ticks_msec()
	if canvas_layer.has_node("StatusPanel"):
		canvas_layer.get_node("StatusPanel").queue_free()
	my_container.start_game(wave_data)
	opponent_container.start_game(wave_data)

func _on_game_state_updated(state: Dictionary):
	if state.has("winner") and state.winner:
		_on_game_finished(state.winner)
		return
	var opponent_data = {}
	if PvPSession.player_index == 0: opponent_data = state.get("p2_state", {})
	else: opponent_data = state.get("p1_state", {})
	if state.get("type") == "opponent_state": opponent_data = state
	if not opponent_data.is_empty():
		opponent_container.sync_opponent_state(opponent_data)

func _on_game_finished(winner_id: String):
	if get_tree().paused: return
	get_tree().paused = true
	var my_id = str(PvPSession.player_id)
	var win_id = str(winner_id)
	var is_win = (my_id == win_id)
	_show_end_game_screen(is_win)

func _show_end_game_screen(is_win: bool):
	var panel = Panel.new()
	panel.name = "EndGameOverlay"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.z_index = 100 
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.95)
	panel.add_theme_stylebox_override("panel", style)
	
	canvas_layer.add_child(panel)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(1200, 1200)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)
	
	# Заголовок
	var label = Label.new()
	label.text = "ПОБЕДА!" if is_win else "ПОРАЖЕНИЕ"
	label.add_theme_font_size_override("font_size", 144)
	label.add_theme_color_override("font_color", Color.GREEN if is_win else Color.RED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Контейнер для статистики (одна колонка - Башни)
	var stats_container = VBoxContainer.new()
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_container)
	
	var stats_title = Label.new()
	stats_title.text = "Статистика башен (MVP):"
	stats_title.add_theme_font_size_override("font_size", 56)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(stats_title)
	
	var towers_stats = _get_towers_damage_stats()
	var max_dmg = 1.0
	var total_dmg = 0.0
	for t in towers_stats: 
		total_dmg += t.damage
		if float(t.damage) > max_dmg: max_dmg = float(t.damage)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_container.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)
	
	# Заголовки таблицы
	var header = HBoxContainer.new()
	list_vbox.add_child(header)
	_add_header_label(header, "Башня", 200)
	_add_header_label(header, "%", 80)
	_add_header_label(header, "Урон", 150)
	
	towers_stats.sort_custom(func(a, b): return a.damage > b.damage)
	
	for i in range(towers_stats.size()):
		var t = towers_stats[i]
		if t.damage <= 0: continue
		
		var row = HBoxContainer.new()
		list_vbox.add_child(row)
		
		var name_lbl = Label.new()
		name_lbl.text = t.name
		name_lbl.custom_minimum_size = Vector2(200, 0)
		name_lbl.clip_text = true
		row.add_child(name_lbl)
		
		var percent = 0.0
		if total_dmg > 0: percent = (t.damage / total_dmg) * 100.0
		var perc_lbl = Label.new()
		perc_lbl.text = "%.1f%%" % percent
		perc_lbl.custom_minimum_size = Vector2(80, 0)
		perc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(perc_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = _format_number(int(t.damage))
		val_lbl.custom_minimum_size = Vector2(150, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_lbl)
		
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(100, 20)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.max_value = max_dmg
		bar.value = t.damage
		
		# Цвета для ТОП-3
		var style_box = StyleBoxFlat.new()
		style_box.set_corner_radius_all(4)
		if i == 0: style_box.bg_color = Color.GOLD
		elif i == 1: style_box.bg_color = Color.SILVER
		elif i == 2: style_box.bg_color = Color(0.8, 0.5, 0.2)
		else: style_box.bg_color = Color.GRAY
		bar.add_theme_stylebox_override("fill", style_box)
		row.add_child(bar)

	# Кнопка в меню
	var btn_menu = Button.new()
	btn_menu.text = "В ГЛАВНОЕ МЕНЮ"
	btn_menu.custom_minimum_size = Vector2(300, 60)
	btn_menu.add_theme_font_size_override("font_size", 48)
	btn_menu.process_mode = Node.PROCESS_MODE_ALWAYS 
	btn_menu.pressed.connect(_on_exit_pressed)
	vbox.add_child(btn_menu)

func _add_header_label(parent, text, width):
	var l = Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(width, 0)
	l.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	parent.add_child(l)

func _get_towers_damage_stats() -> Array:
	var stats = []
	var damage_history = my_container.tower_damage_history
	
	for key in damage_history.keys():
		var parts = key.split("_")
		if parts.size() > 1:
			var id_part = parts[1].split("T")[0]
			var id = int(id_part)
			var t_name = tr("KEY_NAME_TURRET_" + str(id))
			stats.append({"name": t_name, "damage": damage_history[key]})
		
	return stats

func _format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0: res = " " + res
		res = s[i] + res
		count += 1
	return res

func _on_exit_pressed():
	get_tree().paused = false 
	PvPSession.room_id = ""
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		get_tree().change_scene_to_file("res://Scenes/Mobile/Menu_mobile.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func _show_status_message(text: String):
	if not canvas_layer.has_node("StatusPanel"):
		var l = Label.new()
		l.name = "StatusPanel"
		l.set_anchors_preset(Control.PRESET_CENTER)
		l.add_theme_font_size_override("font_size", 80)
		l.add_theme_color_override("font_shadow_color", Color.BLACK)
		canvas_layer.add_child(l)
	canvas_layer.get_node("StatusPanel").text = text

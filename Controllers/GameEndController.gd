## GameEndController
extends Node

const END_GAME_COMPANY_SCENE: PackedScene = preload("res://Scenes/SupportScenes/end_game_company.tscn")
const END_GAME_SCENE: PackedScene = preload("res://Scenes/SupportScenes/EndGame.tscn")
const BUY_BOX_OPEN_SCENE: PackedScene = preload("res://Scenes/SupportScenes/buy_box_open.tscn")

var main_scene
var stars_earned := 0
var _pending_card_counts: Array = []
var _pending_chest_item_id: int = GameConstants.BATTLE_CHEST_ITEM_ID
var end
var game_ended := false

func initialize(scene):
	main_scene = scene

func _apply_end_theme_and_anim(modal: Control, is_win: bool, star_count: int = -1) -> void:
	var panel := modal.get_node_or_null("Panel") as Panel
	var title := modal.get_node_or_null("Panel/MarginContainer/VBoxContainer/Label") as Label
	var divider := modal.get_node_or_null("Panel/MarginContainer/VBoxContainer/Divider") as ColorRect

	if title:
		title.text = tr("KEY_WIN") if is_win else tr("KEY_END")
		title.add_theme_color_override(
			"font_color",
			Color(1.0, 0.87, 0.34, 1.0) if is_win else Color(1.0, 0.44, 0.48, 1.0)
		)

	if divider:
		divider.color = Color(0.95, 0.74, 0.22, 0.34) if is_win else Color(0.92, 0.32, 0.38, 0.34)

	if panel:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.055, 0.078, 0.137, 0.97) if is_win else Color(0.085, 0.055, 0.095, 0.97)
		st.border_width_left = 2
		st.border_width_top = 3
		st.border_width_right = 2
		st.border_width_bottom = 2
		st.border_color = Color(0.95, 0.74, 0.22, 0.94) if is_win else Color(0.92, 0.32, 0.38, 0.92)
		st.set_corner_radius_all(22)
		st.shadow_color = Color(0, 0, 0, 0.62)
		st.shadow_size = 24
		st.shadow_offset = Vector2(0, 8)
		panel.add_theme_stylebox_override("panel", st)

		panel.scale = Vector2(0.90, 0.90)
		panel.modulate.a = 0.0
		var tw: Tween = modal.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, 0.18)

	if star_count >= 0:
		var star_box: Node = modal.get_node_or_null("Panel/MarginContainer/VBoxContainer/HBoxContainer2")
		if star_box:
			for idx in range(1, 4):
				var star_node := star_box.get_node_or_null("NinePatchRect" + str(idx)) as Control
				if not star_node:
					continue
				if idx <= star_count:
					star_node.modulate = Color(1.0, 1.0, 1.0, 0.0)
					star_node.scale = Vector2(0.25, 0.25)
					var star_pitch: float = 1.0 + float(idx - 1) * 0.08
					var stw: Tween = modal.create_tween()
					stw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
					stw.tween_interval(0.14 + float(idx - 1) * 0.12)
					stw.tween_callback(func() -> void: AudioManager.play_sfx("campaign_star", star_pitch))
					stw.tween_property(star_node, "modulate:a", 1.0, 0.10)
					stw.parallel().tween_property(star_node, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				else:
					star_node.modulate = Color(0.20, 0.25, 0.36, 0.42)
					star_node.scale = Vector2(0.88, 0.88)

func end_game_company():
	if game_ended:
		return
	game_ended = true
	TasksManager.count_end_game_company += 1
	tasks()
	get_tree().paused = true

	end = END_GAME_COMPANY_SCENE.instantiate()

	var panel_root = "Panel/MarginContainer/VBoxContainer"
	var score: int = int(GameSession.current_game_score)
	var health: int = int(GameSession.base_health)
	var level_num: int = maxi(1, int(GameSession.current_level))
	DataManager.ensure_campaign_capacity(maxi(GameConstants.CAMPAIGN_TOTAL_LEVELS, level_num))
	var prev_max_stars: int = DataManager.get_level_max_stars(level_num)
	var was_completed: bool = bool(DataManager.level_option[level_num - 1])
	var is_win: bool = health > 0

	if health >= 9:
		stars_earned = 3
	elif health >= 6:
		stars_earned = 2
	elif health >= 1:
		stars_earned = 1
	else:
		stars_earned = 0

	var gold_info: Dictionary = GameConstants.get_campaign_gold_reward(level_num, stars_earned, prev_max_stars, score, is_win)
	var base_gold: int = int(gold_info.get("base_gold", 0))
	var money_dop: int = int(gold_info.get("star_bonus", 0))
	var total_money: int = int(gold_info.get("total_gold", base_gold + money_dop))

	_pending_card_counts = GameConstants.get_campaign_card_rewards(level_num, stars_earned, is_win and not was_completed)
	_pending_chest_item_id = GameConstants.get_campaign_chest_item_id(level_num, stars_earned)

	if score > ResourceManager.best_score:
		ResourceManager.best_score = score
		DataManager.data["SettingsGame"]["best_score"] = score

	end.get_node(panel_root + "/HBoxStar/Label2").text = MathUtils.format_int(money_dop)
	end.get_node(panel_root + "/HBoxScore/Label2").text = MathUtils.format_int(score)
	end.get_node(panel_root + "/HBoxCoin/Label2").text = MathUtils.format_int(base_gold)
	end.get_node(panel_root + "/HBoxScoreBest/Label2").text = MathUtils.format_int(int(ResourceManager.best_score))

	end.get_node(panel_root + "/HBoxContainer/TextureButton_1").pressed.connect(restart)
	end.get_node(panel_root + "/HBoxContainer/TextureButton_2").pressed.connect(exit_menu)

	main_scene.get_node("UI").add_child(end)
	AudioManager.on_battle_finished(is_win)
	_apply_end_theme_and_anim(end, is_win, stars_earned)

	DataManager.add_data_money(total_money)
	DataManager.data["Resources"]["money"] = DataManager.data_money
	var diamonds_earned := 0
	if is_win:
		if not was_completed:
			diamonds_earned = DataManager.grant_campaign_diamonds(level_num)
		DataManager.record_campaign_level_result(level_num, stars_earned)
	DataManager.write_file()
	if diamonds_earned > 0:
		var gem_label := Label.new()
		gem_label.name = "DiamondReward"
		gem_label.text = "💎 " + (tr("KEY_CAMPAIGN_DIAMOND_REWARD") % diamonds_earned)
		gem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gem_label.add_theme_font_size_override("font_size", 18)
		gem_label.add_theme_color_override("font_color", Color(0.46, 0.90, 1.0, 1.0))
		var gem_st := StyleBoxFlat.new()
		gem_st.bg_color = Color(0.05, 0.14, 0.24, 0.92)
		gem_st.border_color = Color(0.32, 0.78, 0.98, 0.80)
		gem_st.set_border_width_all(1)
		gem_st.set_corner_radius_all(10)
		gem_st.content_margin_top = 6
		gem_st.content_margin_bottom = 6
		gem_label.add_theme_stylebox_override("normal", gem_st)
		end.get_node(panel_root).add_child(gem_label)
		end.get_node(panel_root).move_child(gem_label, 3)

	GameSession.current_game_score = 0

func end_game():
	if GameSession.game_mode in [GameConstants.GameMode.PVP, GameConstants.GameMode.PVP_AI]:
		return
	if game_ended:
		return
	game_ended = true
	tasks()
	get_tree().paused = true
	end = END_GAME_SCENE.instantiate()

	var score: int = int(GameSession.current_game_score)
	if score > ResourceManager.best_score:
		ResourceManager.best_score = score
		DataManager.data["SettingsGame"]["best_score"] = score

	var is_win: bool = GameSession.base_health > 0
	var waves_cleared: int = GameConstants.get_sandbox_waves_cleared(int(GameSession.current_wave), is_win)
	var earned_coins: int = int(score / 10.0) + GameConstants.get_sandbox_bonus_gold(waves_cleared)
	_pending_card_counts = GameConstants.get_sandbox_card_rewards(waves_cleared)
	_pending_chest_item_id = GameConstants.get_sandbox_chest_item_id(waves_cleared)

	DataManager.add_data_money(earned_coins)
	DataManager.data["Resources"]["money"] = DataManager.data_money
	DataManager.write_file()

	stars_earned = 0 if not is_win else 1
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScore/Label2").text = MathUtils.format_int(score)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxCoin/Label2").text = MathUtils.format_int(earned_coins)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScoreBest/Label2").text = MathUtils.format_int(int(ResourceManager.best_score))

	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_1").pressed.connect(restart)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_2").pressed.connect(exit_menu)

	main_scene.get_node("UI").add_child(end)
	AudioManager.on_battle_finished(is_win)
	_apply_end_theme_and_anim(end, is_win, -1)

	GameSession.current_game_score = 0

func tasks():
	TasksManager.finish_battle(GameSession.base_health > 0)
	TasksManager.win_several_times.pop_at(0)
	if GameSession.base_health == 1:
		TasksManager.record_task(11)
		TasksManager.win_one_hp_count += 1
		TasksManager.win_several_times.append(1)
	elif GameSession.base_health <= 0:
		TasksManager.win_several_times.append(0)
	else:
		TasksManager.record_task(11)
		TasksManager.win_several_times.append(1)
	TasksManager.count_end_game += 1
	DataManager.write_mastery()
	TasksManager.check_tasks_in_game_session()

func _count_built_player_towers() -> int:
	var count := 0
	for bucket in ResourceManager.list_turret:
		if bucket is Array:
			for t in bucket:
				if is_instance_valid(t) and not AudioManager.to_bool(t.get("is_opponent")):
					count += 1
	return count

func _execute_restart() -> void:
	GameSession.reset_battle_runtime_state()
	GameSession.current_wave = 0
	GameSession.current_game_score = 0
	GameSession.current_money_in_game_session = GameConstants.get_campaign_starting_money(GameSession.current_level) if GameSession.game_mode == GameConstants.GameMode.CAMPAIGN else 500.0
	GameSession.base_health = 10
	GameSession.speed_game = GameConstants.SPEED_NORMAL_GAME_SESSION
	Engine.set_time_scale(GameConstants.SPEED_NORMAL_GAME_SESSION)
	UiManager.list_open_menu_turrets = []
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")

func restart():
	open_chest_pressed(_execute_restart)

func exit_menu():
	open_chest_pressed()

func open_chest_pressed(after_open: Callable = Callable()):
	if is_instance_valid(end):
		end.queue_free()
	var card_counts: Array = _pending_card_counts if not _pending_card_counts.is_empty() else GameConstants.POST_BATTLE_REWARDS.get(stars_earned, [1, 0, 0, 0])
	var box_card = GameConstants.get_random_card_pairs(card_counts)
	var i = 0
	while i < box_card.size():
		if box_card[i][1] == 0:
			box_card.remove_at(i)
		else:
			i += 1
	var chest_item_id: int = _pending_chest_item_id if DataManager.TYPE_ITEMS.has(_pending_chest_item_id) else GameConstants.BATTLE_CHEST_ITEM_ID
	DataManager.TYPE_ITEMS[chest_item_id][0].call(box_card)
	DataManager.write_file()
	var choose_buy = BUY_BOX_OPEN_SCENE.instantiate()
	choose_buy.setup(box_card, DataManager.TYPE_ITEMS[chest_item_id][2], DataManager.TYPE_ITEMS[chest_item_id][4], not after_open.is_valid(), after_open)
	_sync_profile_after_battle()
	get_tree().current_scene.get_node("UI").add_child(choose_buy)

func _sync_profile_after_battle() -> void:
	print("[GameEnd] 📝 Синхронизация профиля с Firebase...")

	var firebase = get_node_or_null("/root/Firebase")
	var firestore = firebase.get_node_or_null("Firestore") if firebase else null

	if not firestore:
		print("[GameEnd] ❌ Firestore не доступен")
		return

	if not AuthService or not AuthService.is_authenticated:
		print("[GameEnd] ❌ Пользователь не авторизован")
		return

	var uid = AuthService.get_current_uid()
	var collection = firestore.collection("users")

	var profile_data = {
		"uid": uid,
		"nickname": AuthService.get_current_nickname(),
		"friend_code": AuthService.get_friend_code(),
		"avatar_id": ProfileManager.profile_data.get("avatar_id", 1),
		"is_registered": AuthService.is_user_registered(),
		"gold": ProfileManager.profile_data.get("gold", 500),
		"level": ProfileManager.profile_data.get("level", 1),
		"clan_id": ProfileManager.profile_data.get("clan_id", null),
		"current_deck": ProfileManager.profile_data.get("current_deck", [0, 1, 2, 3]),
		"titles": ProfileManager.profile_data.get("titles", []),
		"stats": {
			"pvp_wins": ProfileManager.get_stat("pvp_wins"),
			"pvp_losses": ProfileManager.get_stat("pvp_losses"),
			"best_wave": GameSession.current_wave,
			"total_damage": TasksManager.battle_damage,
			"total_kills": GameSession.session_enemies_killed,
			"towers_built": _count_built_player_towers()
		},
		"created_at": ProfileManager.profile_data.get("created_at", FirebaseHelper.get_timestamp()),
		"last_online": FirebaseHelper.get_timestamp(),
		"last_gift_sent": ProfileManager.profile_data.get("last_gift_sent", {}),
		"claimed_gift_ids": ProfileManager.profile_data.get("claimed_gift_ids", [])
	}

	var result = await collection.set_doc(uid, profile_data)

	if result:
		print("[GameEnd] ✅ Профиль сохранён в Firebase")
	else:
		print("[GameEnd] ⚠️ Профиль сохранён (без подтверждения)")

	FirebaseHelper.save_offline_profile_data(profile_data)
	OfflineManager.cache_profile(profile_data)

extends Node

var main_scene
var hp_label: Label = null
signal ai_health_changed(new_hp: int)

# Controllers\HealthController.gd (ИЗМЕНИТЬ initialize)
func initialize(scene):
	main_scene = scene
	
	# ← ПРОВЕРКА: В PvP_AI режиме логика HP в player_container!
	if GameSession.game_mode == GameConstants.GameMode.PVP_AI:
		print("[HealthController] Режим PvP_AI - логика HP в PlayerContainer")
		set_process(false) # Отключаем обработку
		return
	
	# Для других режимов - находим HP лейбл
	if main_scene.has_node("UI/HUD/InfoBar/H2/HP"):
		hp_label = main_scene.get_node("UI/HUD/InfoBar/H2/HP")
	else:
		hp_label = main_scene.find_child("HP", true, false)


func update_health(base_health: int):
	if is_instance_valid(hp_label):
		hp_label.text = str(base_health)

func on_base_damage(damage: int):
		# ← В PvP_AI это не должно вызываться!
	if GameSession.game_mode == GameConstants.GameMode.PVP_AI:
		print("[HealthController] ⚠️ Вызван on_base_damage в PvP_AI режиме - игнорируем")
		return
	var container = main_scene
	
	# ← ПРОВЕРЯЕМ ЭТО AI ИЛИ ИГРОК
	var is_ai_container = container.has_meta("is_ai_player") and container.get_meta("is_ai_player")
	
	if is_ai_container:
		# AI КОНТЕЙНЕР: обновляем ТОЛЬКО meta, НЕ GameSession
		var ai_hp = container.get_meta("ai_hp") if container.has_meta("ai_hp") else 100
		ai_hp -= damage
		if ai_hp < 0: ai_hp = 0
		
		container.set_meta("ai_hp", ai_hp)
		emit_signal("ai_health_changed", ai_hp)
		
		# Обновляем лейбл HP
		update_health(ai_hp)
		
		# ← НЕ показываем деньги AI в UI, только в логах
		var ai_money = container.get_meta("ai_money") if container.has_meta("ai_money") else 500
		print("[HealthController] 💰 AI деньги: ", ai_money, " | HP: ", ai_hp)
		
		if ai_hp <= 0:
			print("[HealthController] ❌ AI проиграл!")
	else:
		# ИГРОК КОНТЕЙНЕР: обновляем GameSession
		GameSession.spend_base_health(damage)
		
		update_health(GameSession.base_health)
		
		# ← Игрок видит свои деньги в UI
		if main_scene.has_node("UI/HUD/InfoBar/H/Money"):
			main_scene.get_node("UI/HUD/InfoBar/H/Money").text = str(int(GameSession.current_money_in_game_session))
		
		if GameSession.base_health <= 0:
			print("[HealthController] ❌ Игрок проиграл!")
			
			if GameSession.game_mode != GameConstants.GameMode.CAMPAIGN:
				main_scene.game_end_controller.end_game()
			else:
				main_scene.game_end_controller.end_game_company()

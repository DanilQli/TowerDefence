# Scenes/SupportScenes/shop_tab.gd
extends Control

@onready var grid_container = $ScrollContainer/HFlowContainer

func _ready():
	_setup_turrets()

func _setup_turrets() -> void:
	if not grid_container: return
	for child in grid_container.get_children(): child.queue_free()
		
	for i in range(len(DataManager.tower_data)):
		var data = DataManager.tower_data["Turret_" + str(i + 1) + "T1"]
		
		# --- ИНСТАНЦИРУЕМ КАРТОЧКУ ---
		var panel = load("res://Scenes/Mobile/turret_max_choose.tscn").instantiate()
		panel.custom_minimum_size = Vector2(320, 550)
		grid_container.add_child(panel)
		panel.setup(data, i)
		
		# --- ПОЛУЧАЕМ ССЫЛКИ ---
		var card_of_container = panel.get_node("VBoxContainer/CardOf") 
		var card_bar = panel.get_node("VBoxContainer/CardOf/CardOf")
		var card_label = panel.get_node("VBoxContainer/CardOf/CardOf/Label")

		# --- ЛОГИКА ---
		if not data["have"]:
			# НЕ КУПЛЕНО
			card_of_container.visible = false 
			
		else:
			# КУПЛЕНО
			card_of_container.visible = true
			var level = int(data["level"])
			
			if level >= GameConstants.NUMBER_LVL_TURRET_CARD:
				# МАКС. УРОВЕНЬ
				card_label.text = tr("KEY_MAX_LVL")
				card_bar.value = 100
				card_bar.max_value = 100
			else:
				# МОЖНО КАЧАТЬ
				var needed = TowerCards.get_cards_needed(i)
				var current = int(data["cards"])
				
				# Настройка бара
				card_bar.max_value = needed
				card_bar.value = current
				card_label.text = str(current) + " / " + str(needed)
				
func _set_btn_style(btn, color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	# Для disabled тоже нужен стиль, иначе будет дефолтный
	var style_d = style.duplicate()
	style_d.bg_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", style_d)

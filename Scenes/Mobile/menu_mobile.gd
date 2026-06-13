# Scenes/UI/MenuMobile.gd
extends Control

# Вкладки
@onready var tab_battle = %TabBattle
@onready var tab_shop = %TabShop
@onready var tab_deck = %TabDeck
@onready var tab_glory = %TabGlory
@onready var tab_promo = %TabPromo

# Кнопки
@onready var btn_nav_shop = %BtnNavShop
@onready var btn_nav_deck = %BtnNavDeck
@onready var btn_nav_battle = %BtnNavBattle
@onready var btn_nav_glory = %BtnNavGlory
@onready var btn_nav_promo = %BtnNavPromo

# UI
@onready var money_label = %MoneyLabel
@onready var crit_label = %CritLabel
@onready var btn_fight = %BtnFight
@onready var btn_mode = %BtnMode
@onready var btn_tasks = %BtnTasks
@onready var btn_gift = %BtnGift
@onready var btn_settings = %BtnSettings
@onready var map_node = %MapCard

func _ready():
	TranslationServer.set_locale(DataManager.data.get("SettingsGame", {}).get("language", "en"))
	_update_top_bar()
	
	var parent_size = self.size 
	var map_base_size = Vector2(1090, 2100) 
	
	# Считаем скейл отдельно для X и Y (игнорируем соотношение!)
	var scale_x = parent_size.x / map_base_size.x
	var scale_y = parent_size.y / map_base_size.y
	
	map_node.scale = Vector2(scale_x, scale_y)
	
	# Центрировать не нужно, она займет всё место от (0,0)
	map_node.position = Vector2(0, 0)
	
	# Подключаем сигналы
	if not btn_nav_shop.pressed.is_connected(_on_tab_selected):
		btn_nav_shop.pressed.connect(_on_tab_selected.bind(tab_shop))
		btn_nav_deck.pressed.connect(_on_tab_selected.bind(tab_deck))
		btn_nav_battle.pressed.connect(_on_tab_selected.bind(tab_battle))
		btn_nav_glory.pressed.connect(_on_tab_selected.bind(tab_glory))
		btn_nav_promo.pressed.connect(_on_tab_selected.bind(tab_promo))
	
	btn_fight.pressed.connect(_on_fight_pressed)
	btn_mode.pressed.connect(_on_mode_pressed)
	btn_tasks.pressed.connect(_on_tasks_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	
	# Старт с вкладки БОЙ
	_on_tab_selected(tab_battle)
	
	update_mode_button(GameSession.selected_mode)
	
	UiManager.menu_object = self 

func _update_top_bar():
	if money_label: money_label.text = str(DataManager.data_money)
	if crit_label: crit_label.text = str(DataManager.critical_damage)

func _on_tab_selected(tab_node: Control):
	
	# Скрываем все
	tab_battle.visible = false
	tab_shop.visible = false
	tab_deck.visible = false
	tab_glory.visible = false
	tab_promo.visible = false
	
	# Показываем нужную
	tab_node.visible = true
	
	# Обновляем данные вкладки
	if tab_node.has_method("_setup_turrets"): # Shop
		tab_node._setup_turrets()
	elif tab_node.has_method("initialize"): # Deck
		tab_node.initialize()
	elif tab_node.has_method("_update_ui"): # Glory & Promo
		tab_node._update_ui()
		
	_update_top_bar()

func _setup_navigation_icons():
	# Загружаем иконки (убедись, что файлы существуют!)
	_set_btn_icon(btn_nav_shop, "res://Assets/Icons/Menu/nav_shop.png")
	_set_btn_icon(btn_nav_deck, "res://Assets/Icons/Menu/nav_deck.png")
	_set_btn_icon(btn_nav_battle, "res://Assets/Icons/Menu/nav_battle.png")
	_set_btn_icon(btn_nav_glory, "res://Assets/Icons/Menu/nav_glory.png")
	_set_btn_icon(btn_nav_promo, "res://Assets/Icons/Menu/nav_promo.png")

func _set_btn_icon(btn, path):
	if btn.has_node("Icon") and FileAccess.file_exists(path):
		btn.get_node("Icon").texture = load(path)

func update_mode_button(mode_index):
	var text = "PvP"
	if mode_index == 1: text = "КАМПАНИЯ"
	elif mode_index == 2: text = "ПЕСОЧНИЦА"
	%BtnMode.text = "РЕЖИМ: " + text

func _on_mode_pressed():
	var mode_select = load("res://Scenes/Mobile/choose_game_mode_mobile.tscn").instantiate()
	add_child(mode_select)

func _on_fight_pressed():
	# Запускаем выбранный режим
	match GameSession.selected_mode:
		1: # Кампания
			get_tree().change_scene_to_file("res://Scenes/UI/company_world.tscn")
		2: # Песочница
			GameSession.current_level = 0
			GameSession.current_wave = 0
			GameSession.game_mode = GameConstants.GameMode.SANDBOX
			get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")
		3: # PvP
			# Логика поиска игры (можно вынести в отдельный метод)
			var search_screen = load("res://Scenes/SupportScenes/search_pvp.tscn").instantiate()
			add_child(search_screen)
			NetworkManager.start_search()


func _on_tasks_pressed():
	var tasks = load("res://Scenes/SupportScenes/daily_tasks.tscn").instantiate()
	add_child(tasks)

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MenuSettings.tscn")

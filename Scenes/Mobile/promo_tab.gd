# Scenes/SupportScenes/promo_tab.gd
extends Control

@onready var lvl_label = $VBoxContainer/Header/LevelInfo/VBox/Lvl
@onready var stars_label = $VBoxContainer/Header/LevelInfo/VBox/Stars
@onready var progress_bar = $VBoxContainer/Header/ProgressBar
@onready var achievements_container = $VBoxContainer/ScrollContainer/HFlowContainer

func _ready() -> void:
	check_promotion_level()
	_update_ui()

func _update_ui():
	# Обновляем инфо
	stars_label.text = str(DataManager.promotion_stars) + " / " + str(GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level])
	lvl_label.text = tr("KEY_LVL") + " " + str(DataManager.promotion_level + 1)
	progress_bar.max_value = GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]
	progress_bar.value = DataManager.promotion_stars
	
	# Очистка
	for child in achievements_container.get_children():
		child.queue_free()
		
	var all = 0
	for i in range(GameConstants.NUMBER_PROMOTION):
		var ob = load("res://Scenes/SupportScenes/panel_promotion.tscn").instantiate()
		
		# --- УВЕЛИЧИВАЕМ РАЗМЕР ЭЛЕМЕНТА ---
		ob.custom_minimum_size = Vector2(320, 380)
		
		# Увеличиваем шрифты внутри
		if ob.has_node("VBoxContainer/Label"):
			ob.get_node("VBoxContainer/Label").add_theme_font_size_override("font_size", 24)
		if ob.has_node("HBoxContainer2/Label1"):
			ob.get_node("HBoxContainer2/Label1").add_theme_font_size_override("font_size", 24)
			ob.get_node("HBoxContainer2/Label2").add_theme_font_size_override("font_size", 24)
			ob.get_node("HBoxContainer2/Label3").add_theme_font_size_override("font_size", 24)
		# -----------------------------------
		
		ob.setup(i)
		achievements_container.add_child(ob)
		all += int(DataManager.promotion_progress_level[i])

func check_promotion_level():
	while DataManager.promotion_level < len(GameConstants.NEED_PROMOTION_STAR_LEVEL) and DataManager.promotion_stars >= GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]:
		DataManager.promotion_stars -= GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]
		DataManager.promotion_level += 1
		DataManager.write_file()

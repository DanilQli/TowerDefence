extends Control

@onready var dropExpansion = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton
@onready var dropLanguage = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton2
var expansion = ["1024*546", "1280*720", "1600*900", "1920*1080"]
var language = ["en", "ru"]

func _ready():
	add_items()
	
func add_items():
	dropExpansion.add_item(expansion[0])
	dropExpansion.add_item(expansion[1])
	dropExpansion.add_item(expansion[2])
	dropExpansion.add_item(expansion[3])
	dropExpansion.select(int(GameData.config.get_value("settings_game", "current_width_height")))
	dropLanguage.select(int(GameData.config.get_value("settings_game", "current_language")))

func _on_option_button_item_selected(index):
	var currentSelectedExpansion = index
	var expansions = expansion[index].split("*")
	DisplayServer.window_set_size(Vector2i(int(expansions[0]),int(expansions[1])))
	GameData.config.set_value("settings_game", "current_width_height", str(index))
	GameData.config.set_value("settings_game", "width", int(expansions[0]))
	GameData.config.set_value("settings_game", "height", int(expansions[1]))
	GameData.write_file()

func _on_option_button_2_item_selected(index):
	var currentSelectedLanguage = index
	TranslationServer.set_locale(language[index])
	GameData.config.set_value("settings_game", "current_language", str(index))
	GameData.config.set_value("settings_game", "language", language[index])
	GameData.write_file()

func _on_button_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func _on_button_reset_pressed():
	GameData.config.set_value("settings_game", "current_width_height", 2)
	var expansions = expansion[2].split("*")
	GameData.config.set_value("settings_game", "width", int(expansions[0]))
	GameData.config.set_value("settings_game", "height", int(expansions[1]))
	GameData.config.set_value("settings_game", "current_language", 1)
	GameData.config.set_value("settings_game", "language", language[1])
	TranslationServer.set_locale(language[1])
	GameData.write_file()
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

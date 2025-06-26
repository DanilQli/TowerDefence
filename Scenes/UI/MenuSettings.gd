extends Control

@onready var dropExpansion = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton
@onready var dropLanguage = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton2

const expansion = ["1024*546", "1280*720", "1600*900", "1920*1080"]
const language = ["en", "ru"]

func _ready() -> void:
	add_items()

func add_items() -> void:
	for resolution in expansion:
		dropExpansion.add_item(resolution)
	
	dropExpansion.select(int(DataManager.data.get("SettingsGame", {}).get("current_width_height", "2")))
	dropLanguage.select(int(DataManager.data.get("SettingsGame", {}).get("current_language", "1")))

func _on_option_button_item_selected(index: int) -> void:
	var expansions = expansion[index].split("*")
	var width = int(expansions[0])
	var height = int(expansions[1])
	
	DisplayServer.window_set_size(Vector2i(width, height))
		
	DataManager.data["SettingsGame"]["current_width_height"] = str(index)
	DataManager.data["SettingsGame"]["width"] = width
	DataManager.data["SettingsGame"]["height"] = height
	DataManager.write_file()

func _on_option_button_2_item_selected(index: int) -> void:
	TranslationServer.set_locale(language[index])
		
	DataManager.data["SettingsGame"]["current_language"] = str(index)
	DataManager.data["SettingsGame"]["language"] = language[index]
	DataManager.write_file()

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func _on_button_reset_pressed() -> void:
	
	# Установка разрешения по умолчанию (1600*900)
	var default_resolution_index = 2
	var default_expansions = expansion[default_resolution_index].split("*")
	
	DataManager.data["SettingsGame"]["current_width_height"] = default_resolution_index
	DataManager.data["SettingsGame"]["width"] = int(default_expansions[0])
	DataManager.data["SettingsGame"]["height"] = int(default_expansions[1])
	
	# Установка языка по умолчанию (русский)
	var default_language_index = 1
	DataManager.data["SettingsGame"]["current_language"] = default_language_index
	DataManager.data["SettingsGame"]["language"] = language[default_language_index]
	TranslationServer.set_locale(language[default_language_index])
	
	DataManager.write_file()
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

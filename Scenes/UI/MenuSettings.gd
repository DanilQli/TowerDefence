extends Control

@onready var dropExpansion = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton
@onready var dropLanguage = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton2
var options = GlobalFiles.read("options")
var expansion = ["1024*546", "1280*720", "1600*900", "1920*1080"]
var language = ["en", "ru"]

func _ready():
	add_items()
	
func add_items():
	dropExpansion.add_item(expansion[0])
	dropExpansion.add_item(expansion[1])
	dropExpansion.add_item(expansion[2])
	dropExpansion.add_item(expansion[3])
	dropExpansion.select(int(options[1][0]))
	dropLanguage.select(int(options[1][2]))

func _on_option_button_item_selected(index):
	var currentSelectedExpansion = index
	var expansions = expansion[index].split("*")
	DisplayServer.window_set_size(Vector2i(int(expansions[0]),int(expansions[1])))
	options[1][0] = str(index)
	options[1][1] = expansion[index]
	GlobalFiles.write("options", options)

func _on_option_button_2_item_selected(index):
	var currentSelectedLanguage = index
	TranslationServer.set_locale(language[index])
	options[1][2] = str(index)
	options[1][3] = language[index]
	GlobalFiles.write("options", options)


func _on_button_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func _on_button_reset_pressed():
	options[1][0] = "3"
	options[1][1] = expansion[2]
	options[1][2] = "1"
	options[1][3] = language[1]
	var expansions = expansion[2].split("*")
	TranslationServer.set_locale(options[1][3])
	DisplayServer.window_set_size(Vector2i(int(expansion[0]),int(expansion[1])))
	GlobalFiles.write("options", options)
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

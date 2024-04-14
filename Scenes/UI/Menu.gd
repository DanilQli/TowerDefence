extends Control

var language_codes = ["ru", "en"]

func _ready():
	var options = GlobalFiles.read("options")
	var expansion = options[1][1].split("*")
	TranslationServer.set_locale(options[1][3])
	DisplayServer.window_set_size(Vector2i(int(expansion[0]),int(expansion[1])))
	load_main_menu()

func _on_texture_button_1_pressed():
	get_tree().change_scene_to_file("res://Scenes/GameScene.tscn")

func _on_texture_button_3_pressed():
	get_tree().change_scene_to_file("res://Scenes/MenuSettings.tscn")


func _on_texture_button_4_pressed():
	get_tree().quit()

func load_main_menu():
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/TextureButton_1").pressed.connect(on_new_game_pressed) 
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/TextureButton_4").pressed.connect(on_quit_pressed)
	
func on_new_game_pressed():
	self.queue_free()
	var game_scene = load("res://Scenes/GameScene.tscn").instantiate()
	game_scene.game_finished.connect(unload_game)
	add_child(game_scene)
	
func on_quit_pressed():
	get_tree().quit()
	
func unload_game(result):
	get_node("GameScene" ).queue_free( )
	var main_menu = load("res://Scenes/Menu.tscn").instantiate()
	add_child(main_menu)
	load_main_menu()

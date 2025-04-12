extends CanvasLayer

@onready var hp_label = get_node("HUD/InfoBar/H2/HP") 


func set_tower_preview(tower_type, mouse_position): 
	var drag_tower = load("res://Scenes/Turrets/" + tower_type + ".tscn").instantiate()
	drag_tower.set_name("DragTower")
	var control = Control.new()
	control.add_child(drag_tower, true)
	var range_texture = Sprite2D.new()
	var scaling
	if GameData.tower_data[tower_type]["type attack"] != 4:
		scaling = GameData.tower_data[tower_type]["range"][0] / 600.0
	else:
		scaling = 0.1
	range_texture.scale = Vector2(scaling, scaling)
	var texture = load("res://Assets/Props/range_overlay.png")
	range_texture.texture = texture
	range_texture.set_modulate(Color("ad54ff3c"))
	range_texture.set_name("Sprite")
	control.add_child(range_texture, true)
	control.set_position(mouse_position)
	control.set_position(mouse_position)
	control.set_name("TowerPreview")
	add_child(control, true)
	move_child(get_node("TowerPreview"), 0)
	
func update_tower_preview(new_position, color):
	get_node("TowerPreview").set_position(new_position)
	if get_node("TowerPreview/DragTower").modulate != Color(color):
		get_node("TowerPreview/DragTower").modulate = Color(color)
		get_node("TowerPreview/Sprite").modulate = Color(color)

func update_health(base_health):
	hp_label.text = str(base_health)
	
##Game Control functions ##
func _on_pause_play_pressed():
	if get_parent().build_mode:
		get_parent().cancel_build_mode()
	if GameData.current_wave == 0:
		get_parent().start_next_wave()
	elif get_tree().is_paused():
		GameData.spped_game = 1.0
		get_tree().paused = false
	else:
		get_tree().paused = true
		GameData.spped_game = 0.0
	
func _on_speed_up_pressed():
	if GameData.current_wave == 0:
		get_parent().start_next_wave()
	if GameData.spped_game == 4.0:
		GameData.spped_game = 1.0
		Engine.set_time_scale(GameData.spped_game)
	else:
		GameData.spped_game = 4.0
		Engine.set_time_scale(GameData.spped_game)

extends Node

var main_scene
var build_mode := false
var build_valid := false
var build_location
var build_type
var build_tile

func initialize(scene):
	main_scene = scene

func initiate_build_mode(tower_type: String, tower_index: int):
	while UiManager.list_open_menu_turrets.size() > 0:
		var menu = UiManager.list_open_menu_turrets.pop_at(0)
		menu.queue_free()

	if build_mode:
		cancel_build_mode()

	var build_name = tower_type + "T1"
	var cost = GameConstants.DATA_TOWER[int(tower_type.split("_")[1]) - 1].cost_in_session
	if DataManager.data["Turrets"][DataManager.keys[tower_index - 1]].mastery_lvl >= 2:
		cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)

	if GameSession.current_money_in_game_session >= cost:
		# 4. Установка режима постройки
		build_type = build_name
		build_mode = true
		set_tower_preview(build_type, main_scene.get_global_mouse_position())
		
func update_tower_preview_ui(new_position: Vector2, color: String):
	if not main_scene.get_node("UI").has_node("TowerPreview"):
		return # ничего не делать, если preview удалён

	var tower_preview = main_scene.get_node("UI/TowerPreview")
	tower_preview.position = new_position

	var drag_tower = tower_preview.get_node("DragTower")
	var sprite = tower_preview.get_node("Sprite")

	var new_color = Color(color)
	if drag_tower.modulate != new_color:
		drag_tower.modulate = new_color
		sprite.modulate = new_color

func set_tower_preview(tower_type: String, mouse_position: Vector2):
	var drag_tower = load("res://Scenes/Turrets/%s.tscn" % tower_type).instantiate()
	drag_tower.name = "DragTower"
	var control = Control.new()

	control.add_child(drag_tower, true)

	var range_texture = Sprite2D.new()
	var scaling: float
	if GameConstants.DATA_TOWER[int(tower_type.substr(0, tower_type.length() - 2).split("_")[1]) - 1].type_attack != 4:
		scaling = GameConstants.DATA_TOWER[int(tower_type.substr(0, tower_type.length() - 2).split("_")[1]) - 1]["parametr_" + str(GameConstants.DATA_TOWER[int(tower_type.substr(0, tower_type.length() - 2).split("_")[1]) - 1].parametr_range)][0] / 600.0
	else:
		scaling = 0.1

	range_texture.scale = Vector2(scaling, scaling)
	range_texture.texture = load("res://Assets/Props/range_overlay.png")
	range_texture.modulate = Color("ad54ff3c")
	range_texture.name = "Sprite"
	control.add_child(range_texture, true)

	control.position = mouse_position
	control.name = "TowerPreview"

	main_scene.get_node("UI").add_child(control, true)
	main_scene.get_node("UI").move_child(control, 0)

func cancel_build_mode():
	build_mode = false
	build_valid = false

	var ui_node = main_scene.get_node("UI")
	if ui_node.has_node("TowerPreview"):
		ui_node.get_node("TowerPreview").queue_free()

func verify_and_build():
	if build_valid:
		var turret = TurretFactory.create_turret(build_type, build_location)
		if not turret:
			printerr("❌ Не удалось создать башню: ", build_type)
			return

		var turret_layer = main_scene.map_node.get_node("Turret")
		turret_layer.add_child(turret)

		turret.position = build_location
		turret.name = build_type + "_1"
		turret.built = true
		turret._ready()
		turret.get_node("Menu").setup(turret.id)
		
		main_scene.map_node.get_node("TowerExlusion").set_cell(build_tile, 0, Vector2i(0, 4))
		var excl = main_scene.map_node.get_node("TowerExlusion")
		excl.set_cell(build_tile, 0, Vector2i(0, 4))

		# Чистим клетку, когда башня удаляется (без лямбд)
		turret.tree_exited.connect(turret._on_turret_tree_exited.bind(main_scene.map_node.get_node("TowerExlusion"), build_tile))
		turret.ui_system.update_menu()
		turret.ui_system.update_menu_upgrade()
		var cost = GameConstants.DATA_TOWER[int(build_type.left(build_type.length() - 2).split("_")[1]) - 1].cost_in_session
		if DataManager.data["Turrets"][DataManager.keys[int(build_type.left(build_type.length() - 2).split("_")[1])  - 1]].mastery_lvl >= 2:
			cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)
		GameSession.spend_money(cost)
		main_scene.ui_controller._on_money_changed()

func update_tower_preview():
	var mouse_position = main_scene.get_global_mouse_position()
	var tilemap = main_scene.map_node.get_node("TowerExlusion")
	var current_tile = tilemap.local_to_map(mouse_position)
	var tile_position = tilemap.map_to_local(current_tile)

	if tilemap.get_cell_source_id(current_tile) == -1:
		update_tower_preview_ui(tile_position, "008000")
		build_valid = true
		build_location = tile_position
		build_tile = current_tile
	else:
		update_tower_preview_ui(tile_position, "ff0000")
		build_valid = false

func _unhandled_input(event):
	if build_mode:
		if event.is_action_released("ui_accept"):
			verify_and_build()
			cancel_build_mode()
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()

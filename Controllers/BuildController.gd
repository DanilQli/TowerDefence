extends Node

var main_scene
var build_mode := false
var native_drag_active := false
var build_valid := false
var build_location
var build_type
var build_tile

func initialize(scene):
	main_scene = scene

func initiate_build_mode(tower_type: String, tower_index: int) -> bool:
	while UiManager.list_open_menu_turrets.size() > 0:
		var menu = UiManager.list_open_menu_turrets.pop_at(0)
		if has_node(menu):
			menu.queue_free()

	if build_mode:
		cancel_build_mode()

	var build_name = tower_type + "T1"
	var cost = GameConstants.DATA_TOWER[int(tower_type.split("_")[1]) - 1].cost_in_session
	if DataManager.data["Turrets"][DataManager.keys[tower_index - 1]].mastery_lvl >= 3:
		cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)

	if GameSession.current_money_in_game_session < cost:
		return false
	build_type = build_name
	build_mode = true
	if not set_tower_preview(build_type, main_scene.get_global_mouse_position()):
		build_mode = false
		return false
	return true
		
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

func set_tower_preview(tower_type: String, mouse_position: Vector2) -> bool:
	var scene = load("res://Scenes/Turrets/%s.tscn" % tower_type)
	if not scene:
		push_error("Не удалось загрузить превью башни: " + tower_type)
		return false
	var drag_tower = scene.instantiate()
	# TowerBase uses this ID to resolve the locally selected skin in _ready().
	drag_tower.turret_id = tower_type
	drag_tower.name = "DragTower"
	var control = Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	return true

func cancel_build_mode():
	build_mode = false
	build_valid = false
	native_drag_active = false

	var ui_node = main_scene.get_node("UI")
	if ui_node.has_node("TowerPreview"):
		var preview = ui_node.get_node("TowerPreview")
		# Remove it immediately; queue_free alone leaves the name occupied until
		# frame end, so a new preview could be renamed and become unfindable.
		ui_node.remove_child(preview)
		preview.queue_free()

func verify_and_build():
	if build_valid:
		var tower_index = int(build_type.left(build_type.length() - 2).split("_")[1]) - 1
		var required_cost = GameConstants.DATA_TOWER[tower_index].cost_in_session
		if DataManager.data["Turrets"][DataManager.keys[tower_index]].mastery_lvl >= 3:
			required_cost = MathUtils.round_to_dec(required_cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)
		if GameSession.current_money_in_game_session < required_cost:
			return
		var turret = TurretFactory.create_turret(build_type, build_location)
		if not turret:
			printerr("❌ Не удалось создать башню: ", build_type)
			return

		var turret_layer = main_scene.map_node.get_node("Turret")
		turret.position = build_location
		turret.name = build_type + "_1"
		turret.built = true
		turret_layer.add_child(turret)
		TasksManager.record_build(tower_index)
		turret.get_node("Menu").setup(turret.id)
		
		var excl = main_scene.map_node.get_node("TowerExlusion")
		excl.set_cell(build_tile, 0, Vector2i(0, 4))

		# Чистим клетку, когда башня удаляется (без лямбд)
		turret.tree_exited.connect(turret._on_turret_tree_exited.bind(main_scene.map_node.get_node("TowerExlusion"), build_tile))
		turret.ui_system.update_menu()
		turret.ui_system.update_menu_upgrade()
		var cost = GameConstants.DATA_TOWER[int(build_type.left(build_type.length() - 2).split("_")[1]) - 1].cost_in_session
		if DataManager.data["Turrets"][DataManager.keys[int(build_type.left(build_type.length() - 2).split("_")[1])  - 1]].mastery_lvl >= 3:
			cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)
		GameSession.spend_money(cost)
		main_scene.ui_controller._on_money_changed()


func update_tower_preview():
	# Получаем позицию мыши в глобальных координатах экрана/мира
	var mouse_position = main_scene.get_global_mouse_position()
	
	# Нам нужно перевести это в локальные координаты тайловой карты, 
	# чтобы понять, над какой клеткой мы находимся.
	var tilemap = main_scene.map_node.get_node("TowerExlusion")
	
	# Переводим глобальную позицию мыши в локальную позицию тайлмапа
	var local_mouse_pos = tilemap.to_local(mouse_position)
	
	var current_tile = tilemap.local_to_map(local_mouse_pos)
	
	# Получаем центр тайла в локальных координатах
	var tile_position_local = tilemap.map_to_local(current_tile)
	
	# Переводим обратно в глобальные, чтобы отрисовать превью в правильном месте на экране
	var tile_position_global = tilemap.to_global(tile_position_local)

	var ground = main_scene.map_node.get_node_or_null("Ground")
	var ground_cell = ground.local_to_map(ground.to_local(tile_position_global)) if ground else current_tile
	if ground and ground.get_cell_source_id(ground_cell) != -1 and tilemap.get_cell_source_id(current_tile) == -1:
		update_tower_preview_ui(tile_position_global, "008000") # Используем глобальную
		build_valid = true
		build_location = tile_position_local # Строим в локальных (так как add_child к карте)
		build_tile = current_tile
	else:
		update_tower_preview_ui(tile_position_global, "ff0000")
		build_valid = false

func _input(event):
	if build_mode:
		# На телефоне и ПК: движение мыши/пальца обновляет превью
		if event is InputEventMouseMotion:
			update_tower_preview()
			
		# На ПК: Клик ЛКМ подтверждает (если не через Drag&Drop)
		if event.is_action_released("ui_accept") and not native_drag_active:
			verify_and_build()
			cancel_build_mode()
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()

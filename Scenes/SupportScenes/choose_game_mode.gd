extends Control
	
# Пути к сценам
const SCENE_PATH := "res://Scenes/Maps/map_0.tscn"
const OUTPUT_PATH := "res://Scenes/Maps/map_0.tscn"
const TILE_LAYER_PATH := "TowerExlusion"

# Terrain параметры
const TERRAIN_SET_ID := 0       # ID набора местности (TerrainSet)
const TERRAIN_ID_ROAD := 0      # ID местности "road" внутри набора

# Обычные tile ID
const TILE_ID_ATLAS_8_0 = [4, 8, 8]    # tile ID для значений 2, 3, 4 вручную

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Panel/MarginContainer/VBoxContainer/TextureButton_1").pressed.connect(choose_game_mode.bind(1))
	get_node("Panel/MarginContainer/VBoxContainer/TextureButton_2").pressed.connect(choose_game_mode.bind(2))
	get_node("Panel/MarginContainer/VBoxContainer/TextureButton_3").pressed.connect(choose_game_mode.bind(3))
	get_node("Panel/Close").pressed.connect(close)

func close():
	get_parent().get_node("MarginContainer2").visible = true
	get_node(".").queue_free()
	
func choose_game_mode(index):
	match index:
		1:
			get_tree().change_scene_to_file("res://Scenes/UI/company_world.tscn")
		2:
			GameData.currrent_level = 0
			GameData.current_wave = 0
			GameData.FLAG_GAME_COMPANY = false
			var url = "https://lobste.pythonanywhere.com/generate"
			var request = HTTPRequest.new()
			add_child(request)

			request.request(
				url,
				[],
				HTTPClient.METHOD_POST,
				""
			)
			request.connect("request_completed", Callable(self, "_on_request_completed"))
	
func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		return

	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())

	if err != OK:
		return

	var data = json.get_data()
	var map_data = data["map"]
	update_tilemap_with_map_data(map_data)

func update_tilemap_with_map_data(data: Array):
	var original_scene = load(SCENE_PATH)
	if not original_scene:
		return

	var scene_instance = original_scene.instantiate()

	var tilemap: TileMap = scene_instance.get_node(TILE_LAYER_PATH)
	if not tilemap:
		return

	# ⚠️ Убедимся, что TileSet поддерживает Terrain
	var tileset := tilemap.tile_set
	if tileset == null:
		return

	# Очистим всю карту
	tilemap.clear()

	# 📌 Шаг 1: Собираем точки для terrain ("дорожки")
	var terrain_points := []  # координаты Vector2i
	for i in range(len(data) + 2):
		tilemap.set_cell(0, Vector2i(0, i), 8, Vector2i(0, 0))
		tilemap.set_cell(0, Vector2i(len(data[0]) + 2, i), 4, Vector2i(0, 0))
	for i in range(len(data[0]) + 2):
		tilemap.set_cell(0, Vector2i(i, 0), 8, Vector2i(0, 0))
		tilemap.set_cell(0, Vector2i(i, len(data) + 2), 4, Vector2i(0, 0))
	for y in data.size():
		for x in data[y].size():
			var value = int(data[y][x])
			match value:
				1:
					terrain_points.append(Vector2i(x + 1, y + 1))  # только собираем пока
				2, 3, 4:
					# ставим обычный tile
					tilemap.set_cell(0, Vector2i(x + 1, y + 1), TILE_ID_ATLAS_8_0[value - 2], Vector2i(0, 0))
				_:
					pass
	var sorted_path = order_path(terrain_points.duplicate())
	
	if scene_instance.get_node("Path").curve:
		scene_instance.get_node("Path").curve.clear_points()
	var curve = Curve2D.new()
	curve.bake_interval = 20
	# Добавляем точки в кривую
	# Конвертируем координаты тайлов в мировые координаты
	for point in sorted_path:
		# Умножаем на размер тайла (предполагая, что размер тайла 64x64)
		var world_position = Vector2(point.x * 64 + 32, point.y * 64 + 32)
		curve.add_point(world_position)
	

	# Устанавливаем кривую для пути
	scene_instance.get_node("Path").curve = curve
	
	# 🏗️ Шаг 2: Автоматическая дорога
	tilemap.set_cells_terrain_connect(0, sorted_path, TERRAIN_SET_ID, TERRAIN_ID_ROAD, true)
	# 💾 Сохраняем сцену
	var packed = PackedScene.new()
	packed.pack(scene_instance)
	var result = ResourceSaver.save(packed, OUTPUT_PATH)
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")

# Упорядочивает список клеток так, чтобы идти от начала до конца (жадно по ближайшей)
func order_path(points: Array) -> Array:
	points.sort_custom(func(a, b): return a.x < b.x)
	points.insert(0, Vector2i(0, points[0][1]))
	points.insert(0, Vector2i(-1, points[0][1]))
	points.append(Vector2i(points[len(points) - 1][0] + 1, points[len(points) - 1][1]))
	points.append(Vector2i(points[len(points) - 1][0] + 1, points[len(points) - 1][1]))
	points.append(Vector2i(points[len(points) - 1][0] + 1, points[len(points) - 1][1]))
	
		# Результирующий упорядоченный путь
	var ordered_points := []
	
	# Множество использованных точек (чтобы не добавлять одну и ту же точку дважды)
	var used_points := {}
	
	# Начинаем с первой точки
	var current_point = points[0]
	ordered_points.append(current_point)
	used_points[current_point] = true
	
	# Пока не использованы все точки
	while ordered_points.size() < points.size():
		var next_point = null
		var min_distance = INF
		
		# Ищем ближайшую точку, которая еще не использована
		for point in points:
			if used_points.has(point):
				continue
			
			# Вычисляем расстояние до текущей точки
			var distance = (point - current_point).length_squared()
			
			# Если точка находится на расстоянии 1 (соседняя) и ближе, чем текущая минимальная
			if distance <= 1 and distance < min_distance:
				next_point = point
				min_distance = distance
		
		# Если следующая точка найдена, добавляем её
		if next_point != null:
			ordered_points.append(next_point)
			used_points[next_point] = true
			current_point = next_point
		else:
			# Если не удалось найти следующую точку, значит, путь не непрерывен
			print("Ошибка: путь не непрерывен!")
			var url = "https://lobste.pythonanywhere.com/generate"
			var request = HTTPRequest.new()
			add_child(request)

			request.request(
				url,
				[],
				HTTPClient.METHOD_POST,
				""
			)
			request.connect("request_completed", Callable(self, "_on_request_completed"))
			break
	
	return ordered_points

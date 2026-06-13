# Systems/GameManager.gd
## Управляет разметкой списка плиток дороги
extends Node

var main_scene
var target_terrain_names = ["Road1", "Road2", "Road3", "Road4"]
var target_terrain_set = 0
var LIST_COORDS_ROAD
var list_coords_road_use_index = []
var water_scene = preload("res://Scenes/SupportScenes/water_overlay.tscn")
var water_scene_t = preload("res://Scenes/SupportScenes/water_overlay_t.tscn")
var water_scene_p = preload("res://Scenes/SupportScenes/water_overlay_p.tscn")

func get_road_coords(scene):
	main_scene = scene
	# Проверяем наличие узла
	if main_scene.has_node("Map/TowerExlusion"):
		LIST_COORDS_ROAD = get_matching_tile_coords(main_scene.get_node("Map/TowerExlusion"))
	else:
		LIST_COORDS_ROAD = []
	
func get_matching_tile_coords(tilemaplayer: TileMapLayer) -> Array:
	var result = []
	if not is_instance_valid(tilemaplayer): return result
	
	var tileset = tilemaplayer.tile_set
	if not tileset: return result
	
	var cell_coords = []
	var cell_set = {}

	# Собираем все клетки дороги
	for cell in tilemaplayer.get_used_cells():
		var source_id = tilemaplayer.get_cell_source_id(cell)
		if source_id == -1: continue 
		
		# --- ФИКС КРИТИЧЕСКОЙ ОШИБКИ C++ ---
		# Проверяем, есть ли тайл в атласе перед запросом данных
		var atlas_coords = tilemaplayer.get_cell_atlas_coords(cell)
		var source = tileset.get_source(source_id)
		if source is TileSetAtlasSource:
			if not source.has_tile(atlas_coords):
				continue # Тайл есть в карте, но удален из атласа - пропускаем
		# -----------------------------------

		var tile_data = tilemaplayer.get_cell_tile_data(cell)
		if tile_data == null: continue 

		var terrain_id = tile_data.get_terrain()
		if terrain_id == -1:
			continue
		
		if target_terrain_set >= tileset.get_terrain_sets_count():
			continue
			
		var terrain_name = tileset.get_terrain_name(target_terrain_set, terrain_id)
		if terrain_name in target_terrain_names:
			cell_coords.append(cell)
			cell_set[cell] = true

	if cell_coords.is_empty():
		return []

	# Находим стартовую клетку
	var start_cell = null
	for cell in cell_coords:
		var neighbors = 0
		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			if cell_set.has(cell + offset):
				neighbors += 1
		if neighbors == 1:
			start_cell = cell
			break

	if start_cell == null and cell_coords.size() > 0:
		start_cell = cell_coords[0]

	if start_cell == null:
		return []

	# BFS обход
	var visited = {}
	var queue = [start_cell]
	visited[start_cell] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		result.append(tilemaplayer.map_to_local(current))
		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next = current + offset
			if cell_set.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)

	return result

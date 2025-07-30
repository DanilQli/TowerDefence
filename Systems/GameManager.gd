## Управляет разметкой списка плиток дороги
extends Node

var main_scene
var target_terrain_names = ["Road1", "Road2", "Road3", "Road4"]
var target_terrain_set = 0
var LIST_COORDS_ROAD
var list_coords_road_use_index = [] 

func get_road_coords(scene: Node2D):
	main_scene = scene
	LIST_COORDS_ROAD = get_matching_tile_coords(main_scene.get_node("Map/TowerExlusion"))

func get_matching_tile_coords(tilemaplayer: TileMapLayer) -> Array:
	var result = []
	var tileset = tilemaplayer.tile_set

	for cell in tilemaplayer.get_used_cells():
		var tile_data = tilemaplayer.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		var terrain_id = tile_data.get_terrain() # это int, индекс местности
		if terrain_id == -1:
			continue # -1 значит, что местность не назначена

		var terrain_name = tileset.get_terrain_name(target_terrain_set, terrain_id)
		if terrain_name in target_terrain_names:
			result.append(tilemaplayer.map_to_local(cell))

	return result

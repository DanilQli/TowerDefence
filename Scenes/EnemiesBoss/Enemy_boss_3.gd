# Scenes/EnemiesBoss/Enemy_boss_3.gd
extends Enemy_boss
class_name Enemy_boss_3
const SPEED_MODIFER: float = 1.2
var water_nodes = []

# Используем один и тот же файл, если второго нет
var tex_water = preload("res://Assets/Tilesheet/ME_Singles_Terrains_and_Fences_.png")

func _ready() -> void:
	ResourceManager.speed_modifer = SPEED_MODIFER
	super._ready()
	
	var map = find_parent("Map")
	if map:
		var coords = []
		if map.has_node("TowerExlusion"):
			coords = GameManager.get_matching_tile_coords(map.get_node("TowerExlusion"))
		
		if coords.size() > 0:
			call_deferred("generate_water_over_road", map, coords, GameManager.water_scene, GameManager.water_scene_t, GameManager.water_scene_p)

func _exit_tree() -> void:
	# Удаляем воду мгновенно при выходе из дерева
	for node in water_nodes:
		if is_instance_valid(node):
			node.queue_free()
	water_nodes.clear()
	
	if not is_spectator_enemy:
		ResourceManager.speed_modifer = 1

func on_destroy(tower_id=-1) -> void:
	super.on_destroy(tower_id)

func generate_water_over_road(parent: Node, coords: Array, water_scene: PackedScene, water_scene_t: PackedScene, water_scene_p: PackedScene):
	if not is_instance_valid(parent): return
		
	var cell_set = coords_to_set(coords)
	for pos in coords:
		if not is_instance_valid(self) or not is_inside_tree(): return 
		
		var water = null
		var name_prefix = "WaterOverlay"
		var is_complex = false
		
		var has_x = cell_set.has(Vector2(pos.x + 64, pos.y)) or cell_set.has(Vector2(pos.x - 64, pos.y))
		var has_y = cell_set.has(Vector2(pos.x, pos.y + 64)) or cell_set.has(Vector2(pos.x, pos.y - 64))
		var width = 32.0
		var height = 32.0
		
		if has_x and not has_y:
			width = 64.0; height = 32.0; water = water_scene.instantiate()
		elif has_y and not has_x:
			width = 32.0; height = 64.0; water = water_scene.instantiate()
		elif has_x and has_y:
			var has_y_u = cell_set.has(Vector2(pos.x, pos.y + 64))
			var has_y_d = cell_set.has(Vector2(pos.x, pos.y - 64))
			var has_x_r = cell_set.has(Vector2(pos.x + 64, pos.y))
			var has_x_l = cell_set.has(Vector2(pos.x - 64, pos.y))
			
			if has_y_d and has_x_l and not has_x_r and not has_y_u:
				water = water_scene_p.instantiate(); name_prefix = "WaterOverlayP"; is_complex = true
			elif has_y_d and has_x_r and not has_x_l and not has_y_u:
				water = water_scene_p.instantiate(); water.rotation = PI / 2; name_prefix = "WaterOverlayP"; is_complex = true
			elif has_y_u and has_x_r and not has_x_l and not has_y_d:
				water = water_scene_p.instantiate(); water.rotation = PI; name_prefix = "WaterOverlayP"; is_complex = true
			elif has_y_u and has_x_l and not has_x_r and not has_y_d:
				water = water_scene_p.instantiate(); water.rotation = 3 * PI / 2; name_prefix = "WaterOverlayP"; is_complex = true
			elif has_y_d and has_x_r and has_x_l and not has_y_u:
				water = water_scene_t.instantiate(); name_prefix = "WaterOverlayT"; is_complex = true
			elif has_y_u and has_x_r and has_x_l and not has_y_d:
				water = water_scene_t.instantiate(); water.rotation = PI / 2; name_prefix = "WaterOverlayT"; is_complex = true
			elif has_y_u and has_x_r and has_y_d and not has_x_l:
				water = water_scene_t.instantiate(); water.rotation = PI / 2; name_prefix = "WaterOverlayT"; is_complex = true
			elif has_y_u and has_x_l and has_y_d and not has_x_r:
				water = water_scene_t.instantiate(); water.rotation = 3 * PI / 2; name_prefix = "WaterOverlayT"; is_complex = true
			else:
				water = water_scene.instantiate()

		if water == null: water = water_scene.instantiate()

		water.position = pos
		water.name = name_prefix + "_" + str(pos)
		water.add_to_group("boss_water")
		
		# --- ФИКС ТЕКСТУР ЧЕРЕЗ ПЕРЕМЕННУЮ ---
		if not is_complex and water is Sprite2D:
			if not water.texture:
				water.texture = tex_water
			
			if water.texture:
				water.scale.x = width / water.texture.get_width()
				water.scale.y = height / water.texture.get_height()
		
		elif is_complex:
			for child in water.get_children():
				if child is Sprite2D and not child.texture:
					child.texture = tex_water
		# -------------------------------------
		
		water_nodes.append(water)
		parent.add_child(water)
		
		if get_tree(): await get_tree().create_timer(0.02).timeout

func remove_with_delay(nodes: Array):
	# Этот метод оставлен для совместимости, но в _exit_tree мы удаляем напрямую
	for node in nodes:
		if is_instance_valid(node): node.queue_free()
	nodes.clear()

func coords_to_set(coords: Array):
	var s = {}
	for pos in coords: s[pos] = true
	return s

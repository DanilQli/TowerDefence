extends Enemy_boss
class_name Enemy_boss_3
const SPEED_MODIFER: float = 1.2
var water_nodes = []

func _ready() -> void:
	ResourceManager.speed_modifer = SPEED_MODIFER
	super._ready()
	generate_water_over_road(GameManager.main_scene, GameManager.LIST_COORDS_ROAD, GameManager.water_scene, GameManager.water_scene_t, GameManager.water_scene_p)

func on_destroy() -> void:
	remove_with_delay(water_nodes)
	ResourceManager.speed_modifer = 1
	super.on_destroy()

func generate_water_over_road(parent: Node, coords: Array, water_scene: PackedScene, water_scene_t: PackedScene, water_scene_p: PackedScene):
	var cell_set = coords_to_set(coords) # Для быстрого поиска
	for pos in coords:
		var water = water_scene.instantiate()
		water.position = pos

		# Проверяем наличие соседей по X и Y
		var has_x = cell_set.has(Vector2(pos.x + 64, pos.y)) or cell_set.has(Vector2(pos.x - 64, pos.y))
		var has_y = cell_set.has(Vector2(pos.x, pos.y + 64)) or cell_set.has(Vector2(pos.x, pos.y - 64))

		var width = 32.0
		var height = 32.0
		if has_x and not has_y:
			width = 64.0
			height = 32.0
		elif has_y and not has_x:
			width = 32.0
			height = 64.0
		elif has_x and has_y:
			var has_y_u = cell_set.has(Vector2(pos.x, pos.y + 64))
			var has_y_d = cell_set.has(Vector2(pos.x, pos.y - 64))
			var has_x_r = cell_set.has(Vector2(pos.x + 64, pos.y))
			var has_x_l = cell_set.has(Vector2(pos.x - 64, pos.y))
			if has_y_d and has_x_l and not has_x_r and not has_y_u:
				# слево-вверх
				var water_h = water_scene_p.instantiate()
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
			elif has_y_d and has_x_r and not has_x_l and not has_y_u:
				# справо-вверх
				var water_h = water_scene_p.instantiate()
				water_h.rotation = PI / 2
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
			elif has_y_u and has_x_r and not has_x_l and not has_y_d:
				# справо-вниз
				var water_h = water_scene_p.instantiate()
				water_h.rotation = PI
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
			elif has_y_u and has_x_l and not has_x_r and not has_y_d:
				# слево-вниз
				var water_h = water_scene_p.instantiate()
				water_h.rotation = 3 * PI / 2
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
			elif has_y_d and has_x_r and has_x_l and not has_y_u:
				# T повернут вверх
				var water_h = water_scene_t.instantiate()
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
				continue
			elif has_y_u and has_x_r and has_x_l and not has_y_d:
				# T повернут вниз
				var water_h = water_scene_t.instantiate()
				water_h.rotation = PI / 2
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
				continue
			elif has_y_u and has_x_r and has_y_d and not has_x_l:
				# T повернут вправо
				var water_h = water_scene_t.instantiate()
				water_h.rotation = PI / 2
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
				continue
			elif has_y_u and has_x_l and has_y_d and not has_x_r:
				# T повернут влево
				var water_h = water_scene_t.instantiate()
				water_h.rotation = 3 * PI / 2
				water_h.position = pos
				parent.add_child(water_h)
				water_nodes.append(water_h)
				continue
		water.scale.x = width / water.texture.get_width()
		water.scale.y = height / water.texture.get_height()
		water_nodes.append(water)
		parent.add_child(water)
		await get_tree().create_timer(0.05).timeout
	
func remove_with_delay(water_nodes: Array):
	for node in water_nodes:
		if is_instance_valid(node):
			node.queue_free()

# Вспомогательная функция для быстрого поиска
func coords_to_set(coords: Array):
	var s = {}
	for pos in coords:
		s[pos] = true
	return s
		

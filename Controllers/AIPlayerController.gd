# Controllers/AIPlayerController.gd
# Контроллер ИИ для Desktop-версии (работает через внешний ai_server.exe в AIManager).
extends Node
class_name AIPlayerController

signal action_decided(action: Dictionary)


var container: Node = null
var is_active: bool = false
var last_action_time: float = 0.0
var min_action_interval: float = 0.5
var request_in_flight: bool = false

var ai_deck: Array[int] = []
var ai_card_levels: Dictionary = {}
var ai_abilities: Dictionary = {}
var ai_spell_id: String = ""
var ai_spell_level: int = 0
var ai_core_energy: float = SpellCatalog.CORE_ENERGY_INITIAL
var ai_spell_cd: float = 0.0
var _ai_spell_scan_accum: float = 0.0

var _static_grid: Array = []
var _static_grid_ready: bool = false

var max_damage_val: float = 0.0
var max_damage_tower_id: int = -1

func setup(player_container: Node) -> void:
	container = player_container
	_static_grid.clear()
	_static_grid_ready = false
	_sync_player_deck_and_levels()
	ai_spell_id = GameSession.get_battle_spell_id() if GameSession != null else ""
	ai_spell_level = GameSession.get_battle_spell_level(ai_spell_id) if not ai_spell_id.is_empty() else 0
	ai_core_energy = SpellCatalog.CORE_ENERGY_INITIAL
	ai_spell_cd = 0.0
	if is_instance_valid(container) and is_instance_valid(container.map_node):
		container.map_node.set_meta("spell_energy_receiver", weakref(self))
	_ensure_static_grid()
	is_active = true
	print("[AI Player] Контроллер активирован | Колода игрока: ", ai_deck, " | Уровни карт: ", ai_card_levels)

func on_enemy_killed_for_energy(is_boss: bool) -> void:
	if ai_spell_id.is_empty():
		return
	var gain: float = SpellCatalog.CORE_ENERGY_KILL_BOSS if is_boss else SpellCatalog.CORE_ENERGY_KILL_ENEMY
	add_core_energy(gain)

func add_core_energy(amount: float) -> void:
	if ai_spell_id.is_empty() or amount <= 0.0:
		return
	ai_core_energy = clampf(ai_core_energy + amount, 0.0, SpellCatalog.CORE_ENERGY_MAX)

func _sync_player_deck_and_levels() -> void:
	ai_deck.clear()
	ai_card_levels.clear()
	ai_abilities.clear()

	# 1. Точная активная колода игрока в том же порядке слотов (0..3)
	if is_instance_valid(container) and container.get("ui_controller") != null:
		var ui_ctrl: Node = container.ui_controller
		if "list_activity_turret" in ui_ctrl:
			for raw_id in ui_ctrl.list_activity_turret:
				var tid: int = int(raw_id)
				if GameConstants.DATA_TOWER.has(tid) and tid not in ai_deck:
					ai_deck.append(tid)

	if ai_deck.is_empty():
		for tid in GameSession.get_battle_deck_ids():
			ai_deck.append(tid)

	if ai_deck.is_empty():
		ai_deck = [0, 1, 2, 3]

	# 2. Точные уровни карт и открытые способности для всех башен (в Зеркальных — турнирный стандарт)
	for i in range(GameConstants.DATA_TOWER.size()):
		var tkey: String = "Turret_" + str(i + 1) + "T1"
		var td: Dictionary = GameSession.get_battle_tower_data(tkey)
		var clvl: int = clampi(int(td.get("level", 0)), 0, 9)
		ai_card_levels[i] = clvl
		var raw_ab: Variant = td.get("ability", [false, false, false])
		if raw_ab is Array and (raw_ab as Array).size() >= 3:
			ai_abilities[i] = [bool((raw_ab as Array)[0]), bool((raw_ab as Array)[1]), bool((raw_ab as Array)[2])]
		else:
			ai_abilities[i] = [
				(clvl + 1) >= int(GameConstants.LEVEL_OPEN_ABILITY[0]),
				(clvl + 1) >= int(GameConstants.LEVEL_OPEN_ABILITY[1]),
				(clvl + 1) >= int(GameConstants.LEVEL_OPEN_ABILITY[2]),
			]

func _process(_delta: float) -> void:
	if not is_active or not is_instance_valid(container):
		return
	if get_tree() and get_tree().paused:
		return
	if _get_ai_base_hp() <= 0:
		stop()
		return

	_tick_ai_spell(_delta)
	if request_in_flight:
		return

	var current_time: float = float(Time.get_ticks_msec()) / 1000.0
	if (current_time - last_action_time) >= min_action_interval:
		var wave_active: bool = _is_wave_active()
		var has_money: bool = _get_current_money() >= 50.0
		if wave_active or has_money:
			_request_ai_decision()

func _tick_ai_spell(delta: float) -> void:
	if ai_spell_id.is_empty() or not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return
	if int(GameSession.current_wave) >= 1:
		ai_core_energy = minf(SpellCatalog.CORE_ENERGY_MAX, ai_core_energy + SpellCatalog.CORE_ENERGY_PASSIVE_PER_SEC * delta)
		if ai_spell_cd > 0.0:
			ai_spell_cd = maxf(0.0, ai_spell_cd - delta)
	_ai_spell_scan_accum += delta
	if _ai_spell_scan_accum < 0.55:
		return
	_ai_spell_scan_accum = 0.0
	var cost: int = SpellCatalog.get_energy_cost(ai_spell_id)
	if ai_spell_cd > 0.01 or ai_core_energy + 0.001 < float(cost):
		return
	var rad: float = SpellCatalog.get_radius_at_level(ai_spell_id, ai_spell_level)
	var target_pt: Vector2 = SpellBattleController.find_best_ai_spell_target(ai_spell_id, container.map_node, rad)
	if target_pt.x >= 0.0:
		ai_core_energy = maxf(0.0, ai_core_energy - float(cost))
		ai_spell_cd = SpellCatalog.get_cooldown_at_level(ai_spell_id, ai_spell_level)
		var w_num: int = maxi(1, int(GameSession.current_wave))
		SpellBattleController.execute_spell_on_map(ai_spell_id, container.map_node, target_pt, ai_spell_level, w_num, false, container)

func _is_wave_active() -> bool:
	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return false
	if container.wave_controller and int(container.wave_controller.active_spawn_sequences) > 0:
		return true
	var path_node: Node = container.map_node.find_child("Path", true, false)
	if not path_node:
		return false
	for path in path_node.get_children():
		for ch in path.get_children():
			if is_instance_valid(ch) and not ch.is_queued_for_deletion() and ("hp" in ch) and float(ch.hp) > 0.0:
				return true
	return false

func _request_ai_decision() -> void:
	last_action_time = float(Time.get_ticks_msec()) / 1000.0
	var state: Dictionary = _collect_game_state()
	request_in_flight = true
	var action: Dictionary = await AIManager.predict(state)
	request_in_flight = false

	if not is_active or not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(container):
		return
	if get_tree() and get_tree().paused:
		return
	if action.has("error"):
		return

	_execute_action(action)
	emit_signal("action_decided", action)

func _get_local_road_coords() -> Array:
	if not is_instance_valid(container):
		return []
	var road_arr: Array = container.local_road_coords if ("local_road_coords" in container and container.local_road_coords is Array) else []
	if road_arr.is_empty() and is_instance_valid(container.map_node):
		var excl: TileMapLayer = container.map_node.get_node_or_null("TowerExlusion") as TileMapLayer
		if excl:
			road_arr = GameManager.get_matching_tile_coords(excl)
			container.local_road_coords = road_arr
	return road_arr

func _ensure_static_grid() -> Array:
	if _static_grid_ready and _static_grid.size() == 12:
		return _static_grid

	var grid: Array = []
	for _x in range(12):
		var row: Array = []
		row.resize(14)
		row.fill(0)
		grid.append(row)

	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return grid

	var road_coords: Array = _get_local_road_coords()
	var tilemap: TileMapLayer = container.map_node.get_node_or_null("TowerExlusion") as TileMapLayer
	var built_cells: Dictionary = {}
	var turret_layer: Node = container.map_node.find_child("Turret", true, false)
	if turret_layer:
		for turret in turret_layer.get_children():
			if is_instance_valid(turret):
				var tx: int = int(floor(turret.position.x / 64.0))
				var ty: int = int(floor(turret.position.y / 64.0))
				built_cells[Vector2i(tx, ty)] = true

	if tilemap:
		for x in range(12):
			for y in range(14):
				var cell: Vector2i = Vector2i(x, y)
				if tilemap.get_cell_source_id(cell) != -1 and not built_cells.has(cell):
					grid[x][y] = 2

	for coord in road_coords:
		if coord is Vector2:
			var rx: int = int(floor((coord as Vector2).x / 64.0))
			var ry: int = int(floor((coord as Vector2).y / 64.0))
			if rx >= 0 and rx < 12 and ry >= 0 and ry < 14:
				grid[rx][ry] = 1

	if not road_coords.is_empty():
		_static_grid = grid
		_static_grid_ready = true
	return grid

func _collect_game_state() -> Dictionary:
	if ai_deck.is_empty():
		_sync_player_deck_and_levels()

	var deck_copy: Array = []
	for tid in ai_deck:
		deck_copy.append(int(tid))

	var money: float = _get_current_money()
	var wave_num: int = maxi(1, int(GameSession.current_wave))
	if container.wave_controller and int(container.wave_controller.local_wave) > 0:
		wave_num = int(container.wave_controller.local_wave)

	var towers_arr: Array = _get_all_towers()
	var enemies_arr: Array = _get_all_enemies()
	var total_dps: float = 0.0
	for t in towers_arr:
		if t is Dictionary:
			total_dps += float((t as Dictionary).get("dps", 0.0))
	var total_ehp: float = 0.0
	for e in enemies_arr:
		if e is Dictionary:
			total_ehp += float((e as Dictionary).get("hp", 0.0))

	return {
		"grid": _ensure_static_grid(),
		"towers": towers_arr,
		"enemies": enemies_arr,
		"path": _get_local_road_coords(),
		"deck": deck_copy,
		"card_levels": ai_card_levels,
		"money": money,
		"wave": wave_num,
		"base_hp": _get_ai_base_hp(),
		"wave_active": _is_wave_active(),
		"total_dps": total_dps,
		"total_enemy_hp": total_ehp,
	}

func _get_current_money() -> float:
	if not is_instance_valid(container):
		return 500.0
	if not container.has_meta("ai_money"):
		container.set_meta("ai_money", 500.0)
		return 500.0
	return float(container.get_meta("ai_money"))

func _get_ai_base_hp() -> int:
	if not is_instance_valid(container):
		return 100
	if container.has_meta("ai_hp"):
		return int(container.get_meta("ai_hp"))
	container.set_meta("ai_hp", 100)
	return 100

func _get_all_towers() -> Array:
	var towers: Array = []
	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return towers
	var turret_layer: Node = container.map_node.find_child("Turret", true, false)
	if not turret_layer:
		return towers

	max_damage_val = 0.0
	max_damage_tower_id = -1

	for turret in turret_layer.get_children():
		if is_instance_valid(turret) and not turret.is_queued_for_deletion() and not AudioManager.to_bool(turret.get("is_phantom_clone")):
			var damage: float = float(turret.damage) if ("damage" in turret) else 0.0
			var rof: float = float(turret.rof) if ("rof" in turret) else 1.0
			if int(turret.id) in [12, 15] and ("tick_rate" in turret):
				rof = maxf(0.08, float(turret.tick_rate))
			var range_val: float = float(turret.range) if ("range" in turret) else 0.0
			var dps: float = (damage / rof) if rof > 0.0 else 0.0
			if int(turret.id) == 16:
				dps *= 1.26
			elif int(turret.id) == 19:
				var cycle_t: float = maxf(0.5, float(turret.get("archive_cycle")) if ("archive_cycle" in turret) else 2.0)
				var cap_m: float = float(turret.get("echo_cap_mult")) if ("echo_cap_mult" in turret) else 8.0
				dps += (damage * minf(cap_m * 0.35, 3.5)) / cycle_t

			var grid_x: int = int(floor(turret.position.x / 64.0))
			var grid_y: int = int(floor(turret.position.y / 64.0))

			towers.append({
				"grid_x": grid_x,
				"grid_y": grid_y,
				"type_id": int(turret.id),
				"lvl": int(turret.current_lvl),
				"dps": dps,
				"range": range_val,
				"role": 0.0,
			})

			if float(turret.inflicted) > max_damage_val:
				max_damage_val = float(turret.inflicted)
				max_damage_tower_id = int(turret.id)

	return towers

func _get_all_enemies() -> Array:
	var enemies_data: Array = []
	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return enemies_data
	var map_node_2d: Node2D = container.map_node as Node2D
	var path_node: Node = container.map_node.find_child("Path", true, false)
	if not path_node:
		return enemies_data

	for path in path_node.get_children():
		for enemy in path.get_children():
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and ("hp" in enemy):
				var hp_val: float = float(enemy.hp)
				if hp_val <= 0.0:
					continue
				if not enemy.has_meta("network_id"):
					enemy.set_meta("network_id", str(enemy.get_instance_id()) + "_" + str(randi()))
				var max_h: float = float(enemy.base_hp) if ("base_hp" in enemy) else hp_val
				# КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: передаём локальные координаты внутри Map (0..768, 0..896),
				# а не global_position правого контейнера (960..1920), чтобы сетка 12x14 видела всех врагов!
				var local_pos: Vector2 = Vector2.ZERO
				if map_node_2d != null and enemy is Node2D:
					local_pos = map_node_2d.to_local((enemy as Node2D).global_position)
				elif "position" in enemy:
					local_pos = enemy.position
				enemies_data.append({
					"position": local_pos,
					"hp": hp_val,
					"max_hp": max_h,
				})

	return enemies_data

func _get_build_cost(tower_id: int) -> float:
	var cost: float = float(GameConstants.DATA_TOWER[tower_id].cost_in_session)
	var tkey: String = "Turret_" + str(tower_id + 1) + "T1"
	if tower_id == 5:
		var map_ref: Node = container.map_node if is_instance_valid(container) else null
		return MoneyTower.get_bank_build_cost_for_session(cost, map_ref, true, GameSession.get_battle_tower_data(tkey), GameSession.get_battle_mastery_lvl(tkey))
	if tower_id == 11:
		return LinkTower.get_link_build_cost_for_session(cost, GameSession.get_battle_tower_data(tkey), GameSession.get_battle_mastery_lvl(tkey))
	if tower_id == 14:
		return MimicTower.get_mimic_build_cost_for_session(cost, GameSession.get_battle_tower_data(tkey), GameSession.get_battle_mastery_lvl(tkey))
	if GameSession.get_battle_mastery_lvl(tkey) >= 3:
		cost = MathUtils.round_to_dec(cost * (1.0 - float(GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0])), 1)
	return cost

func _get_upgrade_cost(turret: TowerBase) -> float:
	var cost: float = float(GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[turret.id].type].upgrade_for_session[turret.current_lvl])
	if GameSession.get_battle_mastery_lvl(turret.turret_id) >= 7:
		cost = MathUtils.round_to_dec(cost * turret.mastery_cost_upgrade, 1)
	return cost

func _execute_action(action: Dictionary) -> void:
	var action_type: int = int(action.get("action_type", 0))
	var tower_slot: int = int(action.get("tower_idx", 0))
	var grid_x: int = int(action.get("grid_x", -1))
	var grid_y: int = int(action.get("grid_y", -1))

	if ai_deck.is_empty():
		_sync_player_deck_and_levels()

	match action_type:
		0: # Idle
			pass
		1: # Build
			if tower_slot < 0 or tower_slot >= ai_deck.size():
				return
			var tower_id: int = ai_deck[tower_slot]
			var cost: float = _get_build_cost(tower_id)
			if _get_current_money() < cost:
				return
			if tower_id == 14:
				var smart_cell: Vector2i = _find_smart_mimic_cell(grid_x, grid_y)
				grid_x = smart_cell.x
				grid_y = smart_cell.y
			elif tower_id == 15:
				var flame_cell: Vector2i = _find_smart_flamethrower_cell(grid_x, grid_y)
				grid_x = flame_cell.x
				grid_y = flame_cell.y
			elif tower_id == 16:
				var sniper_cell: Vector2i = _find_smart_sniper_cell(grid_x, grid_y)
				grid_x = sniper_cell.x
				grid_y = sniper_cell.y
			if not _is_cell_free(grid_x, grid_y):
				return
			_build_tower(tower_id, grid_x, grid_y)
		2: # Upgrade
			var turret: TowerBase = _get_tower_at(grid_x, grid_y)
			if turret == null or turret.is_phantom_clone or turret.current_lvl >= turret.max_lvl:
				return
			var upgrade_cost: float = _get_upgrade_cost(turret)
			if _get_current_money() < upgrade_cost:
				return
			_upgrade_tower(grid_x, grid_y)

func _get_tower_at(grid_x: int, grid_y: int) -> TowerBase:
	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return null
	var turret_layer: Node = container.map_node.find_child("Turret", true, false)
	if not turret_layer:
		return null
	var target_pos: Vector2 = Vector2(float(grid_x * 64 + 32), float(grid_y * 64 + 32))
	for turret in turret_layer.get_children():
		if is_instance_valid(turret) and not turret.is_queued_for_deletion() and turret is TowerBase:
			if (turret as TowerBase).position.distance_to(target_pos) < 32.0:
				return turret as TowerBase
	return null

func _is_cell_free(grid_x: int, grid_y: int) -> bool:
	if grid_x < 0 or grid_x >= 12 or grid_y < 0 or grid_y >= 14:
		return false
	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return false

	var tilemap: TileMapLayer = container.map_node.get_node_or_null("TowerExlusion") as TileMapLayer
	if tilemap and tilemap.get_cell_source_id(Vector2i(grid_x, grid_y)) != -1:
		return false

	for coord in _get_local_road_coords():
		if coord is Vector2:
			if int(floor((coord as Vector2).x / 64.0)) == grid_x and int(floor((coord as Vector2).y / 64.0)) == grid_y:
				return false

	return _get_tower_at(grid_x, grid_y) == null

func _build_tower(tower_id: int, grid_x: int, grid_y: int) -> void:
	if not _is_cell_free(grid_x, grid_y):
		return
	var tower_name: String = "Turret_" + str(tower_id + 1) + "T1"
	var cost: float = _get_build_cost(tower_id)
	var current_money: float = _get_current_money()
	if current_money < cost:
		return

	var turret_layer: Node = container.map_node.get_node_or_null("Turret")
	var tilemap: TileMapLayer = container.map_node.get_node_or_null("TowerExlusion") as TileMapLayer
	if not turret_layer:
		return

	var cell: Vector2i = Vector2i(grid_x, grid_y)
	var pos: Vector2 = tilemap.map_to_local(cell) if tilemap else Vector2(float(grid_x * 64 + 32), float(grid_y * 64 + 32))
	var turret: TowerBase = TurretFactory.create_turret(tower_name, pos)
	if not turret:
		return

	var card_lvl: int = int(ai_card_levels.get(tower_id, 0))
	var card_ab: Array = (ai_abilities.get(tower_id, [false, false, false]) as Array).duplicate()
	turret.position = pos
	turret.name = "%s_AI_%d_%d" % [tower_name, grid_x, grid_y]
	turret.built = true
	turret.is_opponent = false
	turret.ai_card_level = card_lvl
	turret.ability = card_ab
	var raw_ai_choices: Variant = GameSession.get_battle_tower_data(tower_name).get("ability_choices", {})
	if raw_ai_choices is Dictionary:
		turret.set_meta("ability_choices_ui", (raw_ai_choices as Dictionary).duplicate(true))
	turret.set_meta("build_cost_paid", cost)
	if tower_id == 5 and MoneyTower.is_seed_capital_selected_in_data(GameSession.get_battle_tower_data("Turret_6T1")):
		MoneyTower.mark_seed_capital_used(container.map_node, true)
	turret_layer.add_child(turret)

	# Применяем точный уровень карты игрока (без подарков сессии игрока)
	turret.apply_level_and_gift_stats()

	if tilemap:
		turret.set_meta("bound_excl_cell", cell)
		tilemap.set_cell(cell, 0, Vector2i(0, 4))
		turret.tree_exited.connect(turret._on_turret_tree_exited.bind(tilemap, cell))

	container.set_meta("ai_money", maxf(0.0, current_money - cost))
	print("[AI Player] Башня построена: ", tower_name, " (card_lvl=", card_lvl + 1, ") на (", grid_x, ",", grid_y, ") | денег: ", current_money - cost)

func _upgrade_tower(grid_x: int, grid_y: int) -> void:
	var turret: TowerBase = _get_tower_at(grid_x, grid_y)
	if turret == null or turret.is_phantom_clone or turret.current_lvl >= turret.max_lvl:
		return

	var cost: float = _get_upgrade_cost(turret)
	var current_money: float = _get_current_money()
	if current_money < cost:
		return

	turret.current_lvl += 1
	if turret.upgrade_system:
		turret.upgrade_system.apply_upgrade_effects()
		turret.upgrade_system.upgrades.emit()
	else:
		turret.apply_level_and_gift_stats()
	container.set_meta("ai_money", maxf(0.0, current_money - cost))
	print("[AI Player] Улучшена башня на (", grid_x, ",", grid_y, ") до уровня ", turret.current_lvl + 1, " | денег: ", current_money - cost)

func stop() -> void:
	is_active = false
	print("[AI Player] Контроллер остановлен")

func _find_smart_mimic_cell(fallback_x: int, fallback_y: int) -> Vector2i:
	if not is_instance_valid(container) or not is_instance_valid(container.map_node):
		return Vector2i(fallback_x, fallback_y)
	var turret_layer: Node = container.map_node.find_child("Turret", true, false)
	if not turret_layer:
		return Vector2i(fallback_x, fallback_y)
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var best_cell := Vector2i(fallback_x, fallback_y)
	var best_val: float = -1.0
	for child in turret_layer.get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion() or not (child is TowerBase):
			continue
		var t := child as TowerBase
		if not t.built or t.is_phantom_clone or t.id in [5, 11, 14] or t.is_mimic_copy:
			continue
		var tc: Vector2i = t.get_grid_cell_coords()
		var base_cost: float = float(GameConstants.DATA_TOWER[t.id].cost_in_session) if GameConstants.DATA_TOWER.has(t.id) else 80.0
		var val: float = base_cost + float(t.current_lvl) * 65.0
		for d in dirs:
			var cand: Vector2i = tc + d
			if _is_cell_free(cand.x, cand.y):
				var road_bonus: float = 0.0
				var cpos := Vector2(float(cand.x * 64 + 32), float(cand.y * 64 + 32))
				for rc in _get_local_road_coords():
					if rc is Vector2 and cpos.distance_to(rc as Vector2) <= 135.0:
						road_bonus += 8.0
				if (road_bonus > 0.0 or t.id == 10) and (val + road_bonus) > best_val:
					best_val = val + road_bonus
					best_cell = cand
	return best_cell

func _find_smart_flamethrower_cell(fallback_x: int, fallback_y: int) -> Vector2i:
	var road_coords: Array = _get_local_road_coords()
	if road_coords.is_empty():
		return Vector2i(fallback_x, fallback_y)
	# Если исходная клетка уже стоит вплотную к дороге (<= 88 px до минимум 2 сегментов) — оставляем её
	if _is_cell_free(fallback_x, fallback_y):
		var fb_pos := Vector2(float(fallback_x * 64 + 32), float(fallback_y * 64 + 32))
		var fb_hits: int = 0
		for rc in road_coords:
			if rc is Vector2 and fb_pos.distance_to(rc as Vector2) <= 88.0:
				fb_hits += 1
		if fb_hits >= 2:
			return Vector2i(fallback_x, fallback_y)

	var best_cell := Vector2i(fallback_x, fallback_y)
	var best_score: float = -1.0
	for gx in range(12):
		for gy in range(14):
			if not _is_cell_free(gx, gy):
				continue
			var cpos := Vector2(float(gx * 64 + 32), float(gy * 64 + 32))
			var score: float = 0.0
			for rc in road_coords:
				if rc is Vector2:
					var d: float = cpos.distance_to(rc as Vector2)
					if d <= 90.0:
						score += 12.0 + (90.0 - d) * 0.15
			if score > best_score:
				best_score = score
				best_cell = Vector2i(gx, gy)
	return best_cell

func _find_smart_sniper_cell(fallback_x: int, fallback_y: int) -> Vector2i:
	var road_coords: Array = _get_local_road_coords()
	if road_coords.is_empty():
		return Vector2i(fallback_x, fallback_y)
	# Снайпер — башня второй линии (бонус до +20% за дальнюю половину радиуса 95..190px):
	# сохраняем ближние клетки первой линии под сплэш/огнемёт, выбирая тыловые/боковые клетки с максимальным покрытием.
	if _is_cell_free(fallback_x, fallback_y):
		var fb_pos := Vector2(float(fallback_x * 64 + 32), float(fallback_y * 64 + 32))
		var fb_min_d: float = 99999.0
		var fb_far_hits: int = 0
		for rc in road_coords:
			if rc is Vector2:
				var d: float = fb_pos.distance_to(rc as Vector2)
				fb_min_d = minf(fb_min_d, d)
				if d >= 95.0 and d <= 190.0:
					fb_far_hits += 1
		if fb_min_d >= 84.0 and fb_far_hits >= 3:
			return Vector2i(fallback_x, fallback_y)

	var best_cell := Vector2i(fallback_x, fallback_y)
	var best_score: float = -1.0
	for gx in range(12):
		for gy in range(14):
			if not _is_cell_free(gx, gy):
				continue
			var cpos := Vector2(float(gx * 64 + 32), float(gy * 64 + 32))
			var min_d: float = 99999.0
			var near_hits: int = 0
			var far_hits: int = 0
			for rc in road_coords:
				if rc is Vector2:
					var d: float = cpos.distance_to(rc as Vector2)
					min_d = minf(min_d, d)
					if d <= 95.0:
						near_hits += 1
					elif d <= 192.0:
						far_hits += 1
			if near_hits + far_hits == 0:
				continue
			var score: float = float(far_hits) * 14.0 + float(near_hits) * 6.0
			if min_d >= 86.0 and min_d <= 185.0:
				score *= 1.38
			elif min_d < 72.0:
				score *= 0.72
			if score > best_score:
				best_score = score
				best_cell = Vector2i(gx, gy)
	return best_cell


extends TowerBase
class_name MinotaurTower

var damage: float = 0.0
var interval: float = 0.0
var trap_damage: float = 0.0
var trap_damage_end: float = 0.0
var critical_damage_all
var one_attack: bool = false

func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
	upgrade_system.upgrades.connect(mode)
	mode()

func mode() -> void:
	trap_damage_end = trap_damage
	if self.ability[0]:
		var up = 0
		for i in range(len(ResourceManager.list_turret[7])):
			up += ResourceManager.list_turret[7][i].current_lvl + 1
		for i in range(len(ResourceManager.list_turret[7])):
			ResourceManager.list_turret[7][i].trap_damage_end += MathUtils.round_to_dec(trap_damage / 100.0 * (GameConstants.TURRET_8_ABILITY_0[1] + up * GameConstants.TURRET_8_ABILITY_0[2]), 2)
			ResourceManager.list_turret[7][i].get_node("Turret").modulate = Color(1, 0.5, 0.5)
			ResourceManager.list_turret[7][i].get_node("Panel").visible = true
			ResourceManager.list_turret[7][i].get_node("Panel/Label").text = str(up)
		var awaiting = GameConstants.TURRET_8_ABILITY_0[0]
		if self.ability[1]:
			awaiting += up
			if awaiting > GameConstants.TURRET_8_ABILITY_1:
				awaiting = GameConstants.TURRET_8_ABILITY_1
		await get_tree().create_timer(awaiting).timeout
		for i in range(len(ResourceManager.list_turret[7])):
			ResourceManager.list_turret[7][i].trap_damage_end = trap_damage
			ResourceManager.list_turret[7][i].get_node("Turret").modulate = Color(1, 1, 1)
			ResourceManager.list_turret[7][i].get_node("Panel").visible = false
	
func fire() -> void:
	if not block_damage:
		if not one_attack:
			one_attack = true
			_apply_damage_obstacle()
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer((multiplier_rof_enemy * rof)).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		critical_damage_all = critical_damage()
		func_add_deal_damage(critical_damage_all)
		inflicted += critical_damage_all
		enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN, self)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		return (damage * multiplier_damage_enemy) + (DataManager.critical_damage * (damage * multiplier_damage_enemy)) / 100
	else:
		return (damage * multiplier_damage_enemy)

func _apply_damage_obstacle() -> void:
	if len(GameManager.list_coords_road_use_index) < len(GameManager.LIST_COORDS_ROAD):
		var road_obstacle = load("res://Scenes/SupportScenes/road_obstacle.tscn").instantiate()
		var pos = GameManager.LIST_COORDS_ROAD[randi_range(0, len(GameManager.LIST_COORDS_ROAD) - 1)]
		while pos in GameManager.list_coords_road_use_index:
			pos = GameManager.LIST_COORDS_ROAD[randi_range(0, len(GameManager.LIST_COORDS_ROAD) - 1)]
		GameManager.list_coords_road_use_index.append(pos)
		road_obstacle.damage = trap_damage_end
		road_obstacle.position = pos
		var map_node = get_tree().current_scene.find_child("Map", true, false)
		map_node.add_child(road_obstacle)
	await get_tree().create_timer(interval).timeout
	_apply_damage_obstacle()

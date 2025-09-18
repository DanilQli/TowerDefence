# TowerBase.gd
extends Node2D
class_name TowerBase

# --- СИГНАЛЫ ---
signal money_in_game_session_changed()
signal damage_inflicted_changed(value: float)
signal tower_fired(tower: TowerBase)
signal tower_crit(tower: TowerBase)

# --- ОСНОВНЫЕ ПАРАМЕТРЫ ---
var type: String
var id: int
var type_attack: int
var type_explosion: int

var enemy_array: Array[Node] = []
var enemy: Node = null
var built: bool = false
var is_ready: bool = true
var inflicted: float = 0

# --- БОЕВЫЕ ХАРАКТЕРИСТИКИ ---
var range: float
var rof: float
var current_lvl: int
var max_lvl: int
var ability: Array = []
var block_damage: bool = false
var multiplier_damage_enemy: float = 0.0
var multiplier_damage_link: float = 0.0
var multiplier_damage_all: float = 1.0
var multiplier_rof_enemy: float = 0.0
var multiplier_rof_link: float = 1.0
var multiplier_rof_all: float = 1.0

# --- СТРАТЕГИЯ И PvP ---
var strategy: int = 0 # First/Last/Random
var is_opponent := false

# --- ПАРАМЕТРЫ ДЛЯ LINKTOWER ---
var is_protected_by_link := false
var force_next_attack_crit := false

# --- ССЫЛКИ НА УЗЛЫ ---
@onready var ui_system: TowerUI
@onready var upgrade_system: TowerUpgradeSystem
@onready var stone_texture = preload("res://Assets/Effect/stone.png")
@onready var range_area: Area2D = $Range

# --- ИНИЦИАЛИЗАЦИЯ ---
func _ready() -> void:
	if built:
		ui_system = TowerUI.new()
		add_child(ui_system)
		ui_system.setup(self)

		upgrade_system = TowerUpgradeSystem.new()
		add_child(upgrade_system)
		upgrade_system.setup(self)
		
		_initialize()

func _initialize() -> void:
	range_area.body_entered.connect(_on_range_body_entered)
	range_area.body_exited.connect(_on_range_body_exited)
	var shape = range_area.get_node("CollisionShape2D")
	if shape and shape.shape is CircleShape2D:
		shape.shape.radius = 0.5 * range

# --- ЭФФЕКТЫ И ДЕБАФФЫ ---
func stone_effect_start(duration):
	if is_protected_by_link:
		print(name + " защищена от камня!")
		return
		
	block_damage = true
	get_node("NinePatchRect").texture = stone_texture
	get_node("NinePatchRect").visible = true
	await get_tree().create_timer(duration).timeout
	stone_effect_stop()

func stone_effect_stop():
	block_damage = false
	get_node("NinePatchRect").visible = false

# --- ИГРОВОЙ ЦИКЛ ---
func _physics_process(_delta: float) -> void:
	if not built or type_attack == -1: return # LinkTower не должна ничего делать здесь
	
	if enemy_array.is_empty():
		enemy = null
		return

	if not is_instance_valid(enemy):
		select_enemy()

	if is_instance_valid(enemy):
		var turret_sprite = get_node_or_null("Turret")
		if is_instance_valid(turret_sprite):
			var angle = turret_sprite.global_position.direction_to(enemy.global_position).angle()
			turret_sprite.rotation = angle
		
		if is_ready:
			fire()

# --- ВИРТУАЛЬНЫЕ МЕТОДЫ ---
func fire() -> void:
	multiplier_damage_all = 1 + multiplier_damage_enemy + multiplier_damage_link
	multiplier_rof_all = (1.0 + multiplier_rof_enemy) / multiplier_rof_link

func _apply_damage() -> void:
	pass

# --- УПРАВЛЕНИЕ ВРАГАМИ ---
func _on_range_body_entered(body: Node) -> void:
	var parent = body.get_parent()
	if parent and parent.has_method("on_hit") and not enemy_array.has(parent):
		enemy_array.append(parent)

func _on_range_body_exited(body: Node) -> void:
	var parent = body.get_parent()
	if enemy_array.has(parent):
		enemy_array.erase(parent)
	if enemy == parent:
		enemy = null
		select_enemy()

func select_enemy() -> void:
	enemy_array = enemy_array.filter(func(e): return is_instance_valid(e))
	if enemy_array.is_empty():
		enemy = null
		return

	# ИСПРАВЛЕНО: Ручной поиск вместо max_by/min_by
	var best_target: Node = null
	match strategy:
		0: # First (самый дальний по пути)
			var max_progress = -1.0
			for e in enemy_array:
				if e.progress > max_progress:
					max_progress = e.progress
					best_target = e
		1: # Last (самый близкий к базе)
			var min_progress = INF
			for e in enemy_array:
				if e.progress < min_progress:
					min_progress = e.progress
					best_target = e
		2: # Random
			if not enemy_array.is_empty():
				best_target = enemy_array.pick_random()

	enemy = best_target

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---
func func_add_deal_damage(damage):
	TasksManager.deal_damage += damage
	DataManager.mastery_damage_tower_session[id] += damage

func set_opponent_tower(value: bool):
	is_opponent = value
	if has_node("MenuButton"):
		get_node("MenuButton").disabled = true

func is_opponent_tower() -> bool:
	return is_opponent

func _on_turret_tree_exited(excl, cell: Vector2i) -> void:
	excl.erase_cell(cell)

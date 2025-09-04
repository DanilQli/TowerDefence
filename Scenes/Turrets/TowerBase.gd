extends Node2D
class_name TowerBase

signal money_in_game_session_changed()
signal damage_inflicted_changed(value: float)

var type: String
var id: int
var type_attack: int
var type_explosion: int

var enemy_array: Array = []
var enemy: Node = null
var built: bool = false
var is_ready: bool = true
var inflicted: float = 0

var range: float
var rof: float
var current_lvl: int
var max_lvl: int
var ability: Array = []
var block_damage: bool = false
var multiplier_damage_enemy: float = 1.0 # множитель урона (использует босс 7)
var multiplier_rof_enemy: float = 1.0 # множитель урона (использует босс 8)

var strategy: int = 0 # First/Last/Random

@onready var ui_system: TowerUI
@onready var upgrade_system: TowerUpgradeSystem
@onready var stone_texture = preload("res://Assets/Effect/stone.png")

@onready var range_area: Area2D = $Range

func _initialize() -> void:
	range_area.connect("body_entered", Callable(self, "_on_range_body_entered"))
	range_area.connect("body_exited", Callable(self, "_on_range_body_exited"))
	var shape = range_area.get_node("CollisionShape2D")
	if shape and shape.shape is CircleShape2D:
		shape.shape.radius = 0.5 * range
		
func _ready() -> void:
	if built:
		ui_system = TowerUI.new()
		add_child(ui_system)
		ui_system.setup(self)

		upgrade_system = TowerUpgradeSystem.new()
		add_child(upgrade_system)
		upgrade_system.setup(self)

		var range_node := get_node_or_null("Range")
		if range_node:
			range_node.body_entered.connect(_on_range_body_entered)
			range_node.body_exited.connect(_on_range_body_exited)
		_initialize()

# Применение эффекта босса
func stone_effect_start(duration):
	block_damage = true
	get_node("NinePatchRect").texture = stone_texture
	get_node("NinePatchRect").visible = true
	await get_tree().create_timer(duration).timeout
	stone_effect_stop()

func stone_effect_stop():
	block_damage = false
	get_node("NinePatchRect").visible = false
	
func _physics_process(_delta: float) -> void:
	if not built or enemy_array.is_empty():
		enemy = null
		return

	if enemy == null or not is_instance_valid(enemy):
		select_enemy()

	if enemy != null:
		var angle = get_node("Turret").global_position.direction_to(enemy.global_position).angle()
		get_node("Turret").rotation = angle
		
		if is_ready:
			fire()

func fire() -> void: pass

func _apply_damage() -> void: pass  # Virtual methods

func func_add_deal_damage(damage):
	TasksManager.deal_damage += damage
func _on_range_body_entered(body: Node) -> void:
	var parent = body.get_parent()
	if parent and parent.has_method("on_hit"):
		enemy_array.append(parent)

func _on_range_body_exited(body: Node) -> void:
	enemy_array.erase(body.get_parent())
	if enemy == body.get_parent():
		enemy = null
		select_enemy()

func select_enemy() -> void:
	enemy_array = enemy_array.filter(func(e): return is_instance_valid(e))
	if enemy_array.is_empty():
		enemy = null
		return

	var values = enemy_array.map(func(e): return e.progress)
	var target_index = 0

	match strategy:
		0: target_index = values.find(values.max()) # First
		1: target_index = values.find(values.min()) # Last
		2: target_index = randi_range(0, values.size() - 1)  # Random

	enemy = enemy_array[target_index]

func _on_turret_tree_exited(excl, cell: Vector2i) -> void:
	excl.erase_cell(cell)

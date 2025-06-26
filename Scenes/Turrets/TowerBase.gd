## Базовый класс для всех типов башен, содержит общую функциональность и характеристики
extends Node2D
class_name TowerBase

## Сигнал об изменении количества денег в игровой сессии
signal money_in_game_session_changed()

# Базовые свойства
## Тип башни
var type: String
## Тип атаки башни (обычная, замедление, перемещение и т.д.)
var type_attack: int
## Тип взрыва/эффекта
var type_explosion: int
## Массив врагов в зоне действия башни
var enemy_array: Array = []
## Флаг, указывающий построена ли башня
var built: bool = false
## Текущая цель башни
var enemy: Node
## Готовность башни к атаке
var is_ready: bool = true
## Общий нанесенный урон
var inflicted: float = 0

# Характеристики башни
## Интенсивность эффекта (для башни замедления)
var intensivity: float
## Длительность эффекта
var duration: float
## Радиус действия башни
var range: float
## Скорость атаки (Rate of Fire)
var rof: float
## Урон башни
var damage: float
## Доход башни (для денежной башни)
var income: float
## Скорость генерации денег
var speed: float
## Стратегия выбора целей
var strategy: int
## Радиус эффекта
var radius: float

# Уровни
## Текущий уровень башни
var current_lvl: int
## Максимальный уровень башни
var max_lvl: int

# Компоненты
## Система управления UI башни
@onready var ui_system: TowerUI
## Система улучшений башни
@onready var upgrade_system: TowerUpgradeSystem

## Инициализация башни при создании
func _ready() -> void:
	if built:
		# Создаем и добавляем UI систему
		ui_system = TowerUI.new()
		add_child(ui_system)
		ui_system.name = "TowerUI"
		
		# Создаем и добавляем систему улучшений
		upgrade_system = TowerUpgradeSystem.new()
		add_child(upgrade_system)
		upgrade_system.name = "TowerUpgradeSystem"
		
		var range_node = get_node("Range")
		if range_node:
			range_node.body_entered.connect(_on_range_body_entered)
			range_node.body_exited.connect(_on_range_body_exited)
		
		_initialize_tower()
		_initialize_systems()

## Инициализация систем башни
func _initialize_systems() -> void:
	ui_system = $TowerUI
	upgrade_system = $TowerUpgradeSystem
	
	if ui_system:
		ui_system.setup(self)
	if upgrade_system:
		upgrade_system.setup(self)

## Первоначальная настройка башни
func _initialize_tower() -> void:
	if type_attack == GameConstants.TowerType.MONEY:
		_setup_money_tower()
	else:
		_setup_combat_tower()

## Настройка денежной башни
func _setup_money_tower() -> void:
	get_node("Timer").wait_time = self.speed
	get_node("Timer").connect("timeout", update_money)
	get_node("AnimationPlayer").play("Fire")

## Настройка боевой башни
func _setup_combat_tower() -> void:
	self.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * self.range

## Обработка физического процесса башни
func _physics_process(_delta: float) -> void:
	if not built or type_attack == GameConstants.TowerType.MONEY:
		return
		
	if enemy_array.size() > 0:
		if enemy == null or not is_instance_valid(enemy):
			select_enemy()
		
		if enemy != null:
			if type_attack != GameConstants.TowerType.SLOW:
				turn()
			if is_ready:
				fire()
	else:
		enemy = null

## Поворот башни в сторону цели
func turn() -> void:
	if enemy != null and is_instance_valid(enemy):
		var angle = get_node("Turret").global_position.direction_to(enemy.global_position).angle()
		get_node("Turret").rotation = angle


## Выбор цели для атаки на основе стратегии
func select_enemy() -> void:
	# Очистка недействительных ссылок
	enemy_array = enemy_array.filter(func(e): return e != null and is_instance_valid(e))
	
	if enemy_array.size() == 0:
		enemy = null
		return
	
	var enemy_progress_array = []
	for e in enemy_array:
		enemy_progress_array.append(e.progress)
	
	var target_index = 0
	match strategy:
		0: # First
			var max_progress = enemy_progress_array.max()
			target_index = enemy_progress_array.find(max_progress)
		1: # Last
			var min_progress = enemy_progress_array.min()
			target_index = enemy_progress_array.find(min_progress)
		2: # Random
			target_index = randi() % enemy_array.size()
	
	enemy = enemy_array[target_index]

## Обработчик входа врага в зону действия башни
func _on_range_body_entered(body: Node) -> void:
	enemy_array.append(body.get_parent())
	if enemy == null:
		select_enemy()

## Обработчик выхода врага из зоны действия башни
func _on_range_body_exited(body: Node) -> void:
	enemy_array.erase(body.get_parent())
	if enemy == body.get_parent():
		enemy = null
		select_enemy()

## Выполнение атаки башни
func fire() -> void:
	if enemy == null:
		return
		
	is_ready = false
	
	match type_attack:
		GameConstants.TowerType.NORMAL, GameConstants.TowerType.MOVEMENT:
			fire_missile1()
		GameConstants.TowerType.SLOW:
			fire_missile2()
		GameConstants.TowerType.AREA:
			fire_missile1()
	
	_apply_damage()
	await get_tree().create_timer(rof).timeout
	is_ready = true

## Применение урона к цели
func _apply_damage() -> void:
		
	match type_attack:
		GameConstants.TowerType.NORMAL:
			inflicted += damage
			enemy.on_hit(damage, type, type_explosion, type_attack, current_lvl)
			emit_signal("damage_inflicted_changed", inflicted)  # Добавляем emit сигнала
		GameConstants.TowerType.SLOW, GameConstants.TowerType.AREA:
			for i in enemy_array:
				if i != null:
					i.on_hit(damage, type, type_explosion, type_attack, current_lvl)
		GameConstants.TowerType.MOVEMENT:
			enemy.on_hit(damage, type, type_explosion, type_attack, current_lvl)

## Запуск анимации атаки для обычных башен
func fire_missile1() -> void:
	get_node("AnimationPlayer").play("Fire")

## Запуск анимации атаки для башен с эффектами
func fire_missile2() -> void:
	var new_impact = preload("res://Scenes/SupportScenes/ProjecttileImpact_2.tscn").instantiate()
	new_impact.scale = Vector2(range / 50, range / 50)
	new_impact.speed_scale = 60.0 / duration
	add_child(new_impact)

## Обновление денег для денежной башни
func update_money() -> void:
	var sp = self.income if GameSession.speed_game == 0 else self.income * GameSession.speed_game
	
	if GameSession.speed_game == 1.0:
		get_node("Timer").wait_time = self.speed
	elif GameSession.speed_game == 4.0:
		get_node("Timer").wait_time = self.speed / GameSession.speed_game
		
	ResourceManager.add_money(sp)
	emit_signal("money_in_game_session_changed")

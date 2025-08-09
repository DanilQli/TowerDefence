extends PathFollow2D
class_name Enemy_boss

signal base_damage(damage)
signal money_in_game_session_changed()
signal stone(duration)
signal signal_spawn_enemies(wave, enemy_progress)
 
var damage = 3

var speed
var current_speed
var hp
var base_hp
var names
var new_impact
var duration_speed_mod
var poison_data = null
var poison_tick_timer = 0.0
# Так как урон от препятствия проверяется в _physics_process, то урон должен наносится лишь 3 раза в секунду
var hole_move = 19
var id
var is_ready: bool = true

var destroy = false

var projectile_impact_1 = preload("res://Scenes/SupportScenes/ProjecttileImpact_1.tscn")
var projectile_impact_3 = preload("res://Scenes/SupportScenes/ProjecttileImpact_3.tscn")
var projectile_impact_4 = preload("res://Scenes/SupportScenes/ProjecttileImpact_4.tscn")

@onready var health_bar = $HealthBar
@onready var impact_area = $Impact
@onready var poison_effect = $PoisonEffect
@onready var anim_player = $AnimationPlayer  # Анимационный плеер
@onready var sprite = $Sprite2D              # Спрайт противника

var previous_global_pos: Vector2 = Vector2.ZERO  # Предыдущая позиция
var move_threshold: float = 0.1                  # Минимальное движение для переключения анимации

func _ready():
	self.z_index = 1
	previous_global_pos = global_position  # Инициализируем начальную позицию
	self.hp += self.hp * GameSession.current_wave * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * GameSession.current_wave))
	self.base_hp = hp
	self.health_bar.max_value = base_hp
	self.health_bar.value = hp
	self.health_bar.top_level = true
	ResourceManager.list_active_enemy.append(self)
	
func _physics_process(delta):
	if self.progress_ratio > 0.98:
		emit_signal("base_damage", damage) 
		on_destroy()
	move(delta)
	process_poison(delta)
	if is_ready:
		fire()

func fire() -> void: 
	pass

func process_poison(delta: float) -> void:
	if poison_data == null:
		return
		
	poison_data.duration -= delta
	poison_tick_timer -= delta
	
	# Наносим урон по тику
	if poison_tick_timer <= 0:
		poison_tick_timer = poison_data.tick
		self.hp -= poison_data.damage
		self.health_bar.visible = true
		self.health_bar.value = hp
		
		if self.hp <= 0:
			destroy = true
			GameSession.add_game_score(int(float(GameConstants.DATA_ENEMY_BOSS[id].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.DATA_ENEMY_BOSS[id].money_death) + int(float(GameConstants.DATA_ENEMY_BOSS[id].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
			return
	
	# Проверяем окончание действия яда
	if poison_data.duration <= 0:
		poison_data = null
		# Останавливаем анимацию
		poison_effect.visible = false
		poison_effect.get_node("AnimationPlayer").stop()
		
func move(delta):
	var is_in_hole = false
	for hole in get_tree().get_nodes_in_group("holes"):
		if position.distance_to(hole.position) <= hole.radius:
			is_in_hole = hole
			break
	if is_in_hole:
		self.speed = self.current_speed * GameConstants.OBSTACLE_SLOW
		if hole_move % 20 == 0:
			on_hit(is_in_hole.damage / 3, -1, GameConstants.TowerType.GUN)
		hole_move += 1
	else:
		if self.duration_speed_mod <= 1:
			self.speed = self.current_speed
		hole_move = 19
		
	self.progress += self.speed * ResourceManager.speed_modifer * delta
	if self.duration_speed_mod > 0:
		self.duration_speed_mod -= 1
		if self.duration_speed_mod == 1:
			self.speed = self.current_speed
	self.health_bar.set_position(self.position - Vector2(30, 40))
	# Вычисляем вектор движения (разницу между текущей и предыдущей позицией)
	var current_global_pos = global_position
	var move_vector = current_global_pos - previous_global_pos
	previous_global_pos = current_global_pos  # Обновляем предыдущую позицию

	# Игнорируем микро-движения (например, при остановке)
	if move_vector.length() < move_threshold:
		return

	# Определяем направление и переключаем анимацию
	determine_direction(move_vector)

func determine_direction(move_vector: Vector2):
	# Сравниваем горизонтальное и вертикальное движение
	if abs(move_vector.x) > abs(move_vector.y):
		# Движение по горизонтали (влево/вправо)
		if move_vector.x > 0:
			anim_player.play("walk_right")
		else:
			anim_player.play("walk_left")
	else:
		# Движение по вертикали (вверх/вниз)
		if move_vector.y > 0:
			anim_player.play("walk_down")  # Вниз
		else:
			anim_player.play("walk_up")

func on_hit(damage, type_explosion, type_attack, parametrs=false):
	if type_attack in [0, 1]:
		impact(type_explosion, type_attack)
	if type_attack in [0, 1]:
		self.hp -= damage
		self.health_bar.visible = true
		self.health_bar.value = hp
		if self.hp <= 0 and not destroy:
			destroy = true
			GameSession.add_game_score(int(float(GameConstants.DATA_ENEMY_BOSS[id].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.DATA_ENEMY_BOSS[id].money_death) + int(float(GameConstants.DATA_ENEMY_BOSS[id].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
	elif type_attack == 2:
		self.speed *= (100 - damage) / 100.0
		if self.speed < 50:
			self.speed = 50
		self.duration_speed_mod = parametrs
	elif type_attack == 3:
		self.progress_ratio -= damage
		if self.progress_ratio < 0:
			self.progress_ratio = 0

func apply_poison(data: Dictionary) -> void:
	poison_data = {
		"damage": data.damage,
		"duration": data.duration,
		"tick": data.tick,
		"timer": 0.0
	}
	poison_tick_timer = 0.0
	# Запускаем анимацию
	poison_effect.visible = true
	poison_effect.get_node("AnimationPlayer").play("Poison")
	
func impact(type_explosion, type_attack):
	if type_explosion == 5:
		new_impact = projectile_impact_4.instantiate()
		new_impact.position = Vector2(impact_area.global_position.x, impact_area.global_position.y - 10)
		new_impact.z_index = 5
		get_tree().current_scene.add_child(new_impact)
	else:
		randomize()
		var x_pos = randi() % 31
		randomize()
		var y_pos = randi() % 31
		var impact_location = Vector2(x_pos, y_pos)
		if type_attack == 0 and type_explosion == 1:
			new_impact = projectile_impact_3.instantiate()
		else:
			new_impact = projectile_impact_1.instantiate()
		new_impact.position = impact_location
		impact_area.add_child(new_impact)

func on_destroy():
	if len(ResourceManager.list_turret[1]) > 0:
		if ResourceManager.list_turret[1][0].ability[0]:
			var ind = randi_range(0, len(ResourceManager.list_turret[1]) - 1)
			ResourceManager.list_turret[1][ind].ability_0 += 1
			ResourceManager.list_turret[1][ind].get_node("Panel").visible = true
			ResourceManager.list_turret[1][ind].get_node("Panel/Label").text = str(ResourceManager.list_turret[1][ind].ability_0)
	if len(ResourceManager.list_turret[5]) > 0 and ResourceManager.list_turret[5][0].ability[0]:
		GameSession.add_money(len(ResourceManager.list_turret[5]))
	ResourceManager.list_active_enemy.erase(self)
	queue_free()

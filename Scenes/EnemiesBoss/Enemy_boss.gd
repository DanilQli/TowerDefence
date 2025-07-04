extends PathFollow2D
class_name Enemy_boss

signal base_damage(damage)
signal money_in_game_session_changed()
var damage = 3

var speed
var current_speed
var hp
var names
var new_impact
var duration_speed_mod
var poison_data = null
var poison_tick_timer = 0.0

var projectile_impact_1 = preload("res://Scenes/SupportScenes/ProjecttileImpact_1.tscn")
var projectile_impact_3 = preload("res://Scenes/SupportScenes/ProjecttileImpact_3.tscn")
@onready var health_bar = $HealthBar
@onready var impact_area = $Impact
@onready var poison_effect = $PoisonEffect
@onready var anim_player = $AnimationPlayer  # Анимационный плеер
@onready var sprite = $Sprite2D              # Спрайт противника

var previous_global_pos: Vector2 = Vector2.ZERO  # Предыдущая позиция
var move_threshold: float = 0.1                  # Минимальное движение для переключения анимации

func _ready():
	previous_global_pos = global_position  # Инициализируем начальную позицию
	self.hp += self.hp * GameSession.current_wave * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * GameSession.current_wave))
	self.health_bar.max_value = hp
	self.health_bar.value = hp
	self.health_bar.top_level = true
	
func _physics_process(delta):
	if self.progress_ratio == 1.0:
		emit_signal("base_damage", self.damage) 
		on_destroy()
	move(delta)
	process_poison(delta)
	

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
			GameSession.add_game_score(int(float(DataManager.enemy_data[self.names]["money_death"]) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(DataManager.enemy_data[self.names]["money_death"]) + int(float(DataManager.enemy_data[self.names]["money_death"]) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
			return
	
	# Проверяем окончание действия яда
	if poison_data.duration <= 0:
		poison_data = null
		# Останавливаем анимацию
		poison_effect.visible = false
		poison_effect.get_node("AnimationPlayer").stop()
		
func move(delta):
	self.progress += self.speed * delta
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
			anim_player.play("walk_down")  # Вниз (в Godot Y растет вниз)
		else:
			anim_player.play("walk_up")


func on_hit(damage, type_turret, type_explosion, type_attack, level):
	if type_attack in [0, 2, 1]:
		impact(type_explosion, type_attack)
	if type_attack in [0, 1]:
		self.hp -= damage
		self.health_bar.visible = true
		self.health_bar.value = hp
		if self.hp <= 0:
			GameSession.add_game_score(int(float(GameConstants.ENEMY_BOSS[self.names].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.ENEMY_BOSS[self.names]["money_death"]) + int(float(GameConstants.ENEMY_BOSS[self.names].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
	elif type_attack == 3: 
		self.speed -= (self.speed * float(DataManager.tower_data[type_turret]["intensivity"][level]))
		if self.speed < 50:
			self.speed = 50
		self.duration_speed_mod = int(DataManager.tower_data[type_turret]["duration"][level])
	else:
		self.progress -= float(DataManager.tower_data[type_turret]["distance"][level])

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
	print(ResourceManager.list_turret)
	if len(ResourceManager.list_turret[1]) > 0:
		if ResourceManager.list_turret[1][0].ability[0]:
			var ind = randi_range(0, len(ResourceManager.list_turret[1]) - 1)
			ResourceManager.list_turret[1][ind].ability_0 += 1
			print("ResourceManager.list_turret[1][ind].ability_0")
			print(ResourceManager.list_turret[1][ind].ability_0)
			#ResourceManager.list_turret[1][ind].get_node("")
	self.queue_free()

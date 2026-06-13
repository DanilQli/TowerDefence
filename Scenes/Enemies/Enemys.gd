extends PathFollow2D
class_name Enemy

signal base_damage(damage)
signal money_in_game_session_changed()

var damage = 1
var is_spectator_enemy: bool = false 
# Целевая позиция с сервера (0.0 - 1.0)
var server_progress_ratio: float = -1.0

var speed: float = 100.0
var current_speed: float = 100.0
var hp: float = 10.0
var base_hp: float = 10.0
var id: int = 0
var names: String = ""
var new_impact
var duration_speed_mod = 0
var poison_data = null
var poison_tick_timer = 0.0
var speed_modifer = 1.0
var hole_move = 19

@onready var health_bar = self.get_node("HealthBar")
@onready var impact_area = self.get_node("Impact")
@onready var poison_effect = $PoisonEffect

var projectile_impact_1 = preload("res://Scenes/SupportScenes/ProjecttileImpact_1.tscn")
var projectile_impact_3 = preload("res://Scenes/SupportScenes/ProjecttileImpact_3.tscn")
var projectile_impact_4 = preload("res://Scenes/SupportScenes/ProjecttileImpact_4.tscn")

func _ready():
	add_to_group("enemies")
	self.z_index = 1
	self.loop = false 
	randomize() 
	
	if not is_spectator_enemy:
		self.hp += self.hp * GameSession.current_wave * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * GameSession.current_wave))
	
	self.base_hp = self.hp
	self.health_bar.max_value = base_hp
	self.health_bar.value = hp
	
	self.health_bar.top_level = true
	self.health_bar.global_position = global_position + Vector2(-30, -40)
	
	ResourceManager.list_active_enemy.append(self)

func _process(_delta):
	if is_instance_valid(health_bar):
		health_bar.global_position = global_position + Vector2(-30, -40)
		health_bar.rotation = 0

func _physics_process(delta):
	if not is_inside_tree(): return

	if self.progress_ratio >= 1.0:
		if not is_spectator_enemy:
			emit_signal("base_damage", self.damage)
		on_destroy()
		return

	move(delta)
	
	if not is_spectator_enemy:
		process_poison(delta)

func apply_poison(data: Dictionary) -> void:
	poison_data = {
		"damage": data.damage,
		"duration": data.duration,
		"tick": data.tick,
		"timer": 0.0
	}
	poison_tick_timer = 0.0
	if is_instance_valid(poison_effect):
		poison_effect.visible = true
		poison_effect.get_node("AnimationPlayer").play("Poison")

func process_poison(delta: float) -> void:
	if poison_data == null:
		return
		
	poison_data.duration -= delta
	poison_tick_timer -= delta
	
	if poison_tick_timer <= 0:
		poison_tick_timer = poison_data.tick
		self.hp -= poison_data.damage
		
		# --- ФИКС ОШИБКИ ---
		if is_instance_valid(health_bar):
			self.health_bar.visible = true
			self.health_bar.value = hp
		# -------------------
		
		if self.hp <= 0:
			GameSession.add_game_score(int(float(GameConstants.DATA_ENEMY[id].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.DATA_ENEMY[id].money_death) + int(float(GameConstants.DATA_ENEMY[id].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
			return
	
	if poison_data.duration <= 0:
		poison_data = null
		if is_instance_valid(poison_effect):
			poison_effect.visible = false
			poison_effect.get_node("AnimationPlayer").stop()

func on_hit(damage_val, type_explosion, type_attack, towers, parametrs=0):
	if is_spectator_enemy: return

	if type_attack in [0, 1]:
		if type_explosion >= 0:
			impact(type_explosion, type_attack)
			
	if type_attack in [0, 1]:
		self.hp -= damage_val
		
		# --- ФИКС ОШИБКИ ---
		if is_instance_valid(health_bar):
			self.health_bar.visible = true
			self.health_bar.value = hp
		# -------------------
		
		if self.hp <= 0:
			GameSession.add_game_score(int(float(GameConstants.DATA_ENEMY[id].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.DATA_ENEMY[id].money_death) + int(float(GameConstants.DATA_ENEMY[id].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			enemy_destroy_task()
			if towers:
				on_destroy(towers.id)
			else:
				on_destroy()
	
func move(delta):
	if is_spectator_enemy:
		if server_progress_ratio >= 0.0:
			self.progress_ratio = lerp(self.progress_ratio, server_progress_ratio, 10.0 * delta)
		return

	var move_speed = self.current_speed
	var is_in_hole = null
	
	# Проверка ям (holes)
	var holes = get_tree().get_nodes_in_group("holes")
	for hole in holes:
		if position.distance_to(hole.position) <= hole.radius:
			is_in_hole = hole
			break
			
	if is_in_hole:
		move_speed = self.current_speed * GameConstants.OBSTACLE_SLOW
		if hole_move % 20 == 0:
			on_hit(is_in_hole.damage / 3, -1, GameConstants.TowerType.GUN, null)
		hole_move += 1
	else:
		if self.duration_speed_mod <= 1:
			move_speed = self.current_speed
		hole_move = 19
		
	# --- УЛУЧШЕННАЯ ПРОВЕРКА ПОДБОРА СКОРОСТИ ---
	# Проверяем дистанцию каждый кадр, а не через физику Area2D
	if self.speed_modifer < 1.6:
		var speeds = get_tree().get_nodes_in_group("speed")
		for speed_obj in speeds:
			# Увеличили радиус подбора до 60 пикселей для надежности
			if position.distance_to(speed_obj.position) <= 60:
				self.speed_modifer += speed_obj.speed
				speed_obj.queue_free()
				break
	# --------------------------------------------
	
	self.progress += move_speed * ResourceManager.speed_modifer * self.speed_modifer * delta
	
	if self.duration_speed_mod > 0:
		self.duration_speed_mod -= 1
		if self.duration_speed_mod < 1:
			self.speed = self.current_speed

func impact(type_explosion, type_attack):
	if type_explosion == 5:
		new_impact = projectile_impact_4.instantiate()
		new_impact.position = Vector2(impact_area.global_position.x, impact_area.global_position.y - 10)
		new_impact.z_index = 5
		get_tree().current_scene.add_child(new_impact)
	else:
		var x_pos = randi() % 31
		var y_pos = randi() % 31
		var impact_location = Vector2(x_pos, y_pos)
		if type_attack == 0 and type_explosion == 1:
			new_impact = projectile_impact_3.instantiate()
		else:
			new_impact = projectile_impact_1.instantiate()
		new_impact.position = impact_location
		impact_area.add_child(new_impact)

func on_destroy(tower_id=-1):
	if ResourceManager.list_turret.size() > 5 and not ResourceManager.list_turret[5].is_empty():
		var t = ResourceManager.list_turret[5][0]
		if is_instance_valid(t) and t.ability.size() > 0 and t.ability[0]:
			GameSession.add_money(len(ResourceManager.list_turret[5]))
			
	if tower_id >= 0:
		DataManager.mastery_deal_tower_session[tower_id] += 1
		
	ResourceManager.list_active_enemy.erase(self)
	
	if is_instance_valid(health_bar):
		health_bar.queue_free()
	
	if not is_spectator_enemy:
		var container = find_parent("Player1Container")
		if not container: container = find_parent("Player2Container")
		if container and container.has_method("record_enemy_kill"):
			container.record_enemy_kill(self.names)
	
	call_deferred("queue_free")

func enemy_destroy_task():
	TasksManager.destroy_enemies += 1

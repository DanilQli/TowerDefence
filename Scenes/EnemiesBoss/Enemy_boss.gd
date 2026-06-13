extends PathFollow2D
class_name Enemy_boss

signal base_damage(damage)
signal money_in_game_session_changed()
signal stone(duration)
signal signal_spawn_enemies(wave, enemy_progress)
 
var damage = 1
var is_spectator_enemy: bool = false
# Целевая позиция с сервера (0.0 - 1.0)
var server_progress_ratio: float = -1.0

var speed: float = 80.0
var current_speed: float = 80.0
var hp: float = 1000.0
var base_hp: float = 1000.0
var names: String = ""
var new_impact
var duration_speed_mod = 0
var poison_data = null
var poison_tick_timer = 0.0
var speed_modifer = 1.0
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
@onready var anim_player = $AnimationPlayer 
@onready var sprite = $Sprite2D             

var previous_global_pos: Vector2 = Vector2.ZERO  
var move_threshold: float = 0.1                  

func _ready():
	add_to_group("enemies")
	self.z_index = 1
	self.loop = false 
	previous_global_pos = global_position 
	
	if not is_spectator_enemy:
		self.hp += self.hp * GameSession.current_wave * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * GameSession.current_wave))
	
	self.base_hp = self.hp
	self.health_bar.max_value = base_hp
	self.health_bar.value = hp
	
	self.health_bar.top_level = true
	self.health_bar.position = Vector2(-30, -50) 
	
	ResourceManager.list_active_enemy.append(self)

func _process(_delta):
	if is_instance_valid(health_bar):
		health_bar.global_position = global_position + Vector2(-30, -50)
		health_bar.rotation = 0

func _physics_process(delta):
	if not is_inside_tree(): return 

	if self.progress_ratio >= 1.0:
		if not is_spectator_enemy:
			emit_signal("base_damage", damage) 
		on_destroy()
		return

	move(delta)
	
	if not is_spectator_enemy:
		process_poison(delta)
		if is_ready:
			fire()

func move(delta):
	# --- ИСПРАВЛЕНИЕ: Логика для босса-зрителя использует progress_ratio ---
	if is_spectator_enemy:
		if server_progress_ratio >= 0.0:
			self.progress_ratio = lerp(self.progress_ratio, server_progress_ratio, 10.0 * delta)
		
		# Анимация движения (определяем направление)
		var current_global_pos = global_position
		var move_vector = current_global_pos - previous_global_pos
		previous_global_pos = current_global_pos
		if move_vector.length() >= move_threshold:
			determine_direction(move_vector)
		return
	# ----------------------------------------------------------------------

	var move_speed = self.current_speed
	var is_in_hole = false
	for hole in get_tree().get_nodes_in_group("holes"):
		if position.distance_to(hole.position) <= hole.radius:
			is_in_hole = true
			break
	if is_in_hole:
		move_speed = self.current_speed * GameConstants.OBSTACLE_SLOW
	
	self.progress += move_speed * ResourceManager.speed_modifer * self.speed_modifer * delta
	
	var current_global_pos = global_position
	var move_vector = current_global_pos - previous_global_pos
	previous_global_pos = current_global_pos
	if move_vector.length() >= move_threshold:
		determine_direction(move_vector)

func determine_direction(move_vector: Vector2):
	if not is_instance_valid(anim_player): return
	if abs(move_vector.x) > abs(move_vector.y):
		if move_vector.x > 0: anim_player.play("walk_right")
		else: anim_player.play("walk_left")
	else:
		if move_vector.y > 0: anim_player.play("walk_down")
		else: anim_player.play("walk_up")

func on_hit(damage_val, type_explosion, type_attack, towers, parametrs=false):
	if is_spectator_enemy: return
	if type_attack in [0, 1]:
		impact(type_explosion, type_attack)
	self.hp -= damage_val
	if is_instance_valid(health_bar):
			self.health_bar.visible = true
			self.health_bar.value = hp
	if self.hp <= 0 and not destroy:
		destroy = true
		on_destroy(towers.id if towers else -1)

func fire() -> void: 
	pass

func apply_poison(data: Dictionary) -> void:
	poison_data = {"damage": data.damage, "duration": data.duration, "tick": data.tick, "timer": 0.0}
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
		if is_instance_valid(health_bar):
			self.health_bar.visible = true
			self.health_bar.value = hp
		if self.hp <= 0:
			destroy = true
			on_destroy()

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
		if type_attack == 0 and type_explosion == 1: new_impact = projectile_impact_3.instantiate()
		else: new_impact = projectile_impact_1.instantiate()
		new_impact.position = impact_location
		impact_area.add_child(new_impact)

func on_destroy(tower_id=-1):
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

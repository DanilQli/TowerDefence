extends Node

const TOWER_LEVEL_ASSETS = preload("res://Scenes/Turrets/TowerLevelAssets.gd")
const SKIN_CATALOG = preload("res://Systems/SkinCatalog.gd")


# Run this scene with F6 (Run Current Scene), or use run_mortar_tests.sh.
# The tests intentionally use lightweight mock targets so combat results are deterministic.
class MockEnemy:
	extends Node2D
	var hp: float = 100000.0
	var hit_values: Array[float] = []
	var stun_duration: float = 0.0

	func on_hit(value: float, _type_explosion: int, _attack_type: int, _source: Node) -> void:
		hp -= value
		hit_values.append(value)

	func apply_spell_stun(duration: float) -> void:
		stun_duration = maxf(stun_duration, duration)


var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	call_deferred("_run_suite")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Mortar test failed: " + label)


func _run_suite() -> void:
	_test_project_menu_scene_loads()
	_test_factory_and_stats()
	_test_area_damage_and_stun()
	_test_boss_control()
	_test_fragment_ability()
	_test_assets_localization_and_progression()
	await _test_shell_flight_and_mastery()
	# Let queued towers and short-lived shell/impact sprites finish before teardown.
	await get_tree().create_timer(0.45).timeout
	await get_tree().process_frame
	if _failures == 0:
		print("MORTAR_TESTS PASS checks=%d" % _checks)
	else:
		push_error("MORTAR_TESTS FAIL checks=%d failures=%d" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_project_menu_scene_loads() -> void:
	var menu := load("res://Scenes/UI/Menu.tscn") as PackedScene
	_check(menu != null, "project main menu scene parses and loads")
	if menu != null:
		var instance := menu.instantiate()
		_check(instance is Control, "project main menu scene instantiates")
		instance.free()


func _new_mortar() -> MortarTower:
	var result := TurretFactory.create_turret("Turret_18T1", Vector2.ZERO)
	if result == null:
		return null
	add_child(result)
	result._initialize()
	return result as MortarTower


func _test_factory_and_stats() -> void:
	var mortar := _new_mortar()
	_check(mortar != null, "factory instantiates MortarTower")
	if mortar == null:
		return
	_check(mortar.id == 17 and mortar.turret_id == "Turret_18T1", "tower identity is ID 17")
	_check(
		(
			mortar.damage > 0.0
			and mortar.rof > 0.0
			and mortar.range > 0.0
			and mortar.blast_radius > 0.0
		),
		"all four catalog stats are applied"
	)
	_check(mortar.get_fx_style() == "mortar", "Mortar combat FX palette is selected")
	var animation_player := mortar.get_node("AnimationPlayer") as AnimationPlayer
	_check(
		(
			animation_player.has_animation("Fire")
			and animation_player.get_animation("Fire").get_track_count() > 0
		),
		"Fire recoil animation has an active track"
	)
	_check(
		mortar.get_node("Range/CollisionShape2D").shape is CircleShape2D,
		"range collision is a circle"
	)
	_check(
		is_equal_approx(
			(mortar.get_node("Range/CollisionShape2D").shape as CircleShape2D).radius,
			mortar.range * 0.5
		),
		"range shape tracks the catalog radius"
	)
	mortar.queue_free()


func _test_area_damage_and_stun() -> void:
	var mortar := _new_mortar()
	if mortar == null:
		return
	mortar.damage = 100.0
	mortar.blast_radius = 95.0
	mortar.multiplier_damage_all = 1.0
	mortar.mastery_damage = 1.0
	mortar.ability = [false, false]
	var center := MockEnemy.new()
	var outer := MockEnemy.new()
	var outside := MockEnemy.new()
	center.position = Vector2.ZERO
	outer.position = Vector2(76.0, 0.0)
	outside.position = Vector2(101.0, 0.0)
	add_child(center)
	add_child(outer)
	add_child(outside)
	mortar.enemy_array.append_array([center, outer, outside])
	mortar.force_next_attack_crit = true
	mortar._apply_main_blast(Vector2.ZERO)
	_check(
		center.hit_values.size() == 1 and center.hit_values[0] >= 100.0,
		"epicenter receives full base damage"
	)
	_check(
		outer.hit_values.size() == 1 and outer.hit_values[0] < center.hit_values[0],
		"outer blast ring receives reduced damage"
	)
	_check(outside.hit_values.is_empty(), "targets beyond blast radius are untouched")
	_check(center.stun_duration == 0.0, "stun ability is inactive when locked")
	_check(not mortar.has_stunning_fuse(), "Concussive Fuse reports locked state")
	mortar.ability = [true, false]
	_check(mortar.has_stunning_fuse(), "Concussive Fuse unlock flag is honored")
	mortar._apply_main_blast(Vector2.ZERO)
	_check(center.stun_duration >= 0.35, "Concussive Fuse stuns a center target")
	_check(outer.stun_duration == 0.0, "Concussive Fuse is limited to inner blast radius")
	mortar.queue_free()
	center.queue_free()
	outer.queue_free()
	outside.queue_free()


func _test_boss_control() -> void:
	var mortar := _new_mortar()
	if mortar == null:
		return
	mortar.ability = [true, false]
	var boss := Enemy_boss.new()
	mortar._apply_stun_or_boss_slow(boss)
	_check(
		is_equal_approx(boss.spell_slow_pct, 20.0),
		"boss receives 20 percent slow instead of a stun"
	)
	_check(is_equal_approx(boss.spell_slow_timer, 0.8), "boss slow duration is 0.8 seconds")
	boss.free()
	mortar.queue_free()


func _test_fragment_ability() -> void:
	var mortar := _new_mortar()
	if mortar == null:
		return
	mortar.damage = 100.0
	mortar.blast_radius = 95.0
	mortar.multiplier_damage_all = 1.0
	mortar.mastery_damage = 1.0
	mortar.ability = [false, true]
	_check(
		not mortar.has_stunning_fuse() and mortar.has_fragment_ability(),
		"second ability unlocks fragments without the stun fuse"
	)
	var fragment_targets: Array[MockEnemy] = []
	for i in range(3):
		var angle: float = -PI * 0.5 + TAU * float(i) / 3.0
		var target := MockEnemy.new()
		target.position = Vector2(cos(angle), sin(angle)) * mortar.blast_radius * 0.48
		add_child(target)
		fragment_targets.append(target)
		mortar.enemy_array.append(target)
	mortar._apply_fragments(Vector2.ZERO)
	for target in fragment_targets:
		_check(
			target.hit_values.size() == 1 and target.hit_values[0] >= 25.0,
			"each of the three fragments hits its nearby target"
		)
	mortar.queue_free()
	for target in fragment_targets:
		target.queue_free()


func _test_assets_localization_and_progression() -> void:
	var stages: Array = TOWER_LEVEL_ASSETS.get_stages().get("Turret_18T1", [])
	_check(stages.size() == 8, "eight default level-stage sprites are mapped")
	for texture in stages:
		_check(texture is Texture2D, "each default stage resource loads")
	for skin_id in ["skin_01", "skin_02", "skin_03"]:
		var art: Array = SKIN_CATALOG.get_skin("Turret_18T1", skin_id).get("art", [])
		_check(art.size() == 8, skin_id + " provides all eight stage sprites")
	var mastery_one: Dictionary = SKIN_CATALOG.mastery_skin("Turret_18T1", "xp1")
	var mastery_two: Dictionary = SKIN_CATALOG.mastery_skin("Turret_18T1", "xp2")
	_check(
		(
			mastery_one.get("name") == "KEY_SKIN_T18_XP1"
			and (mastery_one.get("art", []) as Array).size() == 8
		),
		"Mastery I skin loads all art stages"
	)
	_check(
		(
			mastery_two.get("name") == "KEY_SKIN_T18_XP2"
			and (mastery_two.get("art", []) as Array).size() == 8
		),
		"Mastery II skin loads all art stages"
	)
	_check(AudioManager.SFX_META.has("turret_mortar_launch"), "launch SFX is registered")
	_check(AudioManager.SFX_META.has("turret_mortar_impact"), "impact SFX is registered")
	_check(AudioManager.SFX_META.has("turret_mortar_shrapnel"), "fragment SFX is registered")
	for sfx_id in ["launch", "impact", "shrapnel"]:
		_check(
			FileAccess.file_exists("res://Audio/SFX/turret_mortar_%s.wav" % sfx_id),
			"Mortar %s audio file exists" % sfx_id
		)
	_check(
		GameConstants.DATA_TOWER.size() == 18 and GameConstants.DATA_TOWER.has(17),
		"tower catalog contains all 18 towers"
	)
	_check(GameConstants.NUMBER_PROMOTION == 43, "new Mortar promotion is counted")
	_check(
		GameConstants.NUMBER_LEVEL_PROMOTION.size() == 43, "promotion progress table includes ID 43"
	)
	_check(
		GameConstants.NUMBER_EXPERIENCE_PROMOTION.size() == 43, "promotion XP table includes ID 43"
	)
	_check(
		DataManager.mastery_mortar_shell_session.size() >= 18,
		"per-tower Mortar mastery session data is initialized"
	)
	_check(
		GameConstants.MORTAR_SHELLS_PER_MASTERY_XP == 150,
		"shell-to-Mastery XP conversion is centralized"
	)
	var saved_progress: int = int(DataManager.promotion_progress[42])
	var saved_level: int = int(DataManager.promotion_progress_level[42])
	var saved_dates: Array = DataManager.promotion_completion_dates[42].duplicate()
	var saved_battle_started: bool = TasksManager.battle_started
	var saved_battle_finished: bool = TasksManager.battle_finished
	var saved_task_dirty: bool = TasksManager.task_dirty
	TasksManager.battle_started = true
	TasksManager.battle_finished = false
	TasksManager.record_tower_achievement(42)
	_check(
		int(DataManager.promotion_progress[42]) == saved_progress + 1,
		"Mortar shell promotion records progress during a battle"
	)
	DataManager.promotion_progress[42] = saved_progress
	DataManager.promotion_progress_level[42] = saved_level
	DataManager.promotion_completion_dates[42] = saved_dates
	TasksManager.battle_started = saved_battle_started
	TasksManager.battle_finished = saved_battle_finished
	TasksManager.task_dirty = saved_task_dirty
	for icon_id in ["mortar_ability_stun", "mortar_ability_fragments", "mortar_radius", "medal_43"]:
		_check(
			ResourceLoader.exists("res://Assets/Icons/%s.png" % icon_id),
			"Mortar icon %s exists" % icon_id
		)
	var csv := FileAccess.get_file_as_string("res://lang/translation.csv")
	for key in [
		"KEY_NAME_TURRET_18",
		"KEY_MORTAR_RADIUS",
		"KEY_TURRET18_UP0_DESC",
		"KEY_TURRET18_UP1_DESC",
		"KEY_MASTERY_DESC_T18",
		"KEY_PROMOTION_NAME_43"
	]:
		_check(csv.contains(key + ","), "translation key %s exists" % key)


func _test_shell_flight_and_mastery() -> void:
	var mortar := _new_mortar()
	if mortar == null:
		return
	mortar.damage = 100.0
	mortar.blast_radius = 95.0
	mortar.rof = 0.12
	mortar.mastery_speed = 1.0
	mortar.ability = [false, false]
	var target := MockEnemy.new()
	add_child(target)
	mortar.enemy_array.append(target)
	mortar.enemy = target
	var initial_hits: int = target.hit_values.size()
	var initial_shells: int = int(DataManager.mastery_mortar_shell_session[mortar.id])
	mortar.fire()
	_check(
		(mortar.get_node("AnimationPlayer") as AnimationPlayer).is_playing(),
		"firing triggers the recoil animation"
	)
	await get_tree().create_timer(0.36).timeout
	_check(
		target.hit_values.size() > initial_hits, "launched shell completes its flight and impacts"
	)
	_check(
		int(DataManager.mastery_mortar_shell_session[mortar.id]) == initial_shells + 1,
		"fired shell advances Mortar mastery counter"
	)
	_check(mortar.is_ready, "fire cooldown completes and tower can fire again")
	mortar.queue_free()
	target.queue_free()

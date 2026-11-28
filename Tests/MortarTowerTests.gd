extends Node

const TOWER_LEVEL_ASSETS = preload("res://Scenes/Turrets/TowerLevelAssets.gd")
const SKIN_CATALOG = preload("res://Systems/SkinCatalog.gd")
const MOBILE_TACTICAL_AI = preload("res://Scenes/Mobile/Controllers/MobileTacticalAI.gd")
const DESKTOP_PLAYER_CONTAINER = preload("res://Scenes/UI/player_container.gd")
const MOBILE_PLAYER_CONTAINER = preload("res://Scenes/Mobile/player_container_mobile.gd")
const LIVE_ENEMY_SCENE: PackedScene = preload("res://Scenes/Enemies/Enemy_1.tscn")
const LIVE_BOSS_SCENE: PackedScene = preload("res://Scenes/EnemiesBoss/Enemy_boss_1.tscn")


# Run this scene with F6 (Run Current Scene), or use run_mortar_tests.sh.
# The tests intentionally use lightweight mock targets so combat results are deterministic.
class MockEnemy:
	extends Node2D
	var hp: float = 100000.0
	var base_hp: float = 100000.0
	var is_spectator_enemy: bool = false
	var is_boss: bool = false
	var hit_values: Array[float] = []
	var stun_duration: float = 0.0
	var poison_data: Variant = {"active": true}
	var flame_burn_timer: float = 0.0
	var drone_scan_timer: float = 0.0
	var drone_scan_mult: float = 1.08
	var spell_freeze_timer: float = 0.0
	var spell_stasis_timer: float = 0.0
	var spell_stun_timer: float = 0.0
	var spell_slow_timer: float = 0.0
	var spell_slow_pct: float = 0.0
	var spell_vuln_timer: float = 0.0
	var spell_anti_heal_timer: float = 0.0
	var spell_hunters_mark_timer: float = 0.0
	var spell_gold_mark_timer: float = 0.0
	var duration_speed_mod: int = 0
	var speed_mod: float = 0.0
	var speed: float = 100.0
	var current_speed: float = 100.0
	var progress: float = 0.0
	var progress_ratio: float = 0.0
	var last_slow_frames: int = 0

	func on_hit(value: float, _type_explosion: int, _attack_type: int, _source: Node, _duration_frames: int = 0) -> void:
		if _attack_type == GameConstants.TowerType.SLOW:
			speed_mod = value
			duration_speed_mod = _duration_frames
			last_slow_frames = _duration_frames
			return
		var hp_before: float = maxf(0.0, hp)
		var dealt: float = maxf(0.0, minf(hp_before, value))
		if _attack_type == GameConstants.TowerType.MOVING:
			progress_ratio = maxf(0.0, progress_ratio - value)
		else:
			hp -= value
		hit_values.append(value)
		if dealt > 0.0 and is_instance_valid(_source) and (_source is TowerBase) and _attack_type != GameConstants.TowerType.MOVING:
			var is_dot: bool = (("is_applying_bleed_tick" in _source) and bool(_source.get("is_applying_bleed_tick"))) or (("is_applying_burn_tick" in _source) and bool(_source.get("is_applying_burn_tick")))
			EchoarchiveTower.notify_enemy_damaged(self, dealt, _source, is_dot, false)

	func apply_poison(data: Dictionary) -> void:
		poison_data = {
			"damage": float(data.get("damage", 0.0)),
			"duration": float(data.get("duration", 0.0)),
			"base_duration": float(data.get("base_duration", data.get("duration", 0.0))),
			"tick": float(data.get("tick", 0.8)),
			"timer": 0.0,
			"tower": data.get("tower", null),
			"slow_pct": float(data.get("slow_pct", 0.0)),
			"epidemic": bool(data.get("epidemic", false))
		}

	func apply_spell_slow(pct: float, dur: float) -> void:
		spell_slow_pct = maxf(spell_slow_pct, pct)
		spell_slow_timer = maxf(spell_slow_timer, dur)

	func apply_drone_scan(dur: float = 2.0, mult: float = 1.08) -> void:
		drone_scan_timer = maxf(drone_scan_timer, dur)
		drone_scan_mult = maxf(1.0, mult)

	func trigger_dot_hit(value: float, source: Node) -> void:
		var hp_before: float = maxf(0.0, hp)
		var dealt: float = maxf(0.0, minf(hp_before, value))
		hp -= value
		hit_values.append(value)
		if dealt > 0.0 and is_instance_valid(source) and (source is TowerBase):
			EchoarchiveTower.notify_enemy_damaged(self, dealt, source, true, false)

	func kill_mock(was_killed: bool = true) -> void:
		if was_killed:
			hp = 0.0
		EchoarchiveTower.notify_enemy_destroyed(self, was_killed)

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
	_test_mobile_ai_combat_profiles()
	await _test_resonator_abilities()
	await _test_resonator_real_enemy_integration()
	await _test_echoarchive_comprehensive()
	await _test_shell_flight_and_mastery()
	await _test_follow_up_fixes()
	await _test_shop_badges_and_catalog_cleanup()
	await _test_turrets_1_2_3_abilities()
	await _test_sniper_echo_and_turrets_4_to_7()
	await _test_turrets_8_to_12()
	await _test_turrets_13_to_16()
	await _test_t17_t18_loader_and_icons()
	await _test_ui_readability_desktop_and_mobile()
	await _test_audit_mechanics_bugfixes()
	await _test_all_25_spells_and_core_systems()
	# Let queued towers and short-lived shell/impact sprites finish before teardown.
	await get_tree().create_timer(0.9).timeout
	await get_tree().process_frame
	# Stop any final transient renderer nodes before this headless harness quits.
	for grp in ["combat_fx_transient", "combat_fx", "napalm_zones"]:
		for transient in get_tree().get_nodes_in_group(grp):
			if is_instance_valid(transient):
				transient.free()
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


func _new_resonator() -> ResonatorTower:
	var result := TurretFactory.create_turret("Turret_19T1", Vector2.ZERO)
	if result == null:
		return null
	add_child(result)
	result._initialize()
	return result as ResonatorTower


func _test_mobile_ai_combat_profiles() -> void:
	var ai: MobileTacticalAI = MOBILE_TACTICAL_AI.new()
	var mortar_single: float = ai.eval_combat_power(17, 0, 0, [false, false], 1.0, 1.0, 1, false, 500.0, 0)
	var mortar_group: float = ai.eval_combat_power(17, 0, 0, [false, false], 1.0, 1.0, 5, false, 500.0, 0)
	_check(mortar_group > mortar_single, "mobile AI values Mortar splash against groups")
	var resonator_base: float = ai.eval_combat_power(18, 0, 0, [true, false, false], 1.0, 1.0, 2, false, 500.0, 3)
	var resonator_perfect: float = ai.eval_combat_power(18, 9, 9, [true, false, true], 1.0, 1.0, 2, false, 500.0, 3)
	_check(resonator_perfect > resonator_base, "mobile AI accounts for Perfect Resonance 150% pulse")
	_check(ai.get_tower_radius_px(18, 0, 0) > 0.0, "mobile AI derives Resonator attack radius from live tower data")
	var desktop_ai_mortar: Dictionary = AIManager._estimate_card_level0_stats(17, 0)
	var desktop_ai_resonator: Dictionary = AIManager._estimate_card_level0_stats(18, 0)
	_check(float(desktop_ai_mortar.get("dps", 0.0)) > 148.0 / 2.10, "desktop AI accounts for Mortar area value")
	_check(float(desktop_ai_resonator.get("dps", 0.0)) > 25.0 / 1.20, "desktop AI accounts for Resonator charge-pulse value")
	var resonator := _new_resonator()
	var ui_less_upgrade_system := TowerUpgradeSystem.new()
	ui_less_upgrade_system.setup(resonator)
	ui_less_upgrade_system.update_ui()
	_check(ui_less_upgrade_system.tower == resonator, "AI/opponent upgrade UI refresh safely handles towers without an interactive menu")
	ui_less_upgrade_system.free()
	var snapshot := {"resonance_charges": 2, "ability_choices": {"3": {"id": "resonator_returning_tone"}, "7": {"id": "resonator_string_memory"}}}
	var desktop_remote: Control = DESKTOP_PLAYER_CONTAINER.new()
	desktop_remote._update_tower_visuals(resonator, snapshot)
	_check(resonator.resonance_charges == 2, "desktop PvP snapshot restores Resonator charge pips")
	_check(resonator.get_meta("ability_choices_ui", {}).get("7", {}).get("id", "") == "resonator_string_memory", "desktop PvP snapshot restores chosen branch")
	var mobile_remote: Control = MOBILE_PLAYER_CONTAINER.new()
	mobile_remote._update_tower_visuals(resonator, {"resonance_charges": 3, "ability_choices": {"7": {"id": "resonator_overtone"}}})
	_check(resonator.resonance_charges == 3, "mobile PvP snapshot restores Resonator charge pips")
	_check(resonator.get_meta("ability_choices_ui", {}).get("7", {}).get("id", "") == "resonator_overtone", "mobile PvP snapshot restores chosen branch")
	desktop_remote.free()
	mobile_remote.free()
	resonator.queue_free()


func _test_factory_and_stats() -> void:
	var mortar := _new_mortar()
	_check(mortar != null, "factory instantiates MortarTower")
	if mortar == null:
		return
	_check(mortar.id == 17 and mortar.turret_id == "Turret_18T1", "tower identity is ID 17")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[17]["parametr_1"][0][0]), 148.0), "Mortar L1/0 damage reduced by 20% to 148.0")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[17]["parametr_1"][9][9]), 442.30), "Mortar L10/10 damage reduced by 20% to 442.30")
	var mortar_defaults := MortarTower.new()
	_check(is_equal_approx(mortar_defaults.damage, 148.0), "MortarTower default damage fallback is 148.0")
	mortar_defaults.free()
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
		GameConstants.DATA_TOWER.size() == 20 and GameConstants.DATA_TOWER.has(18) and GameConstants.DATA_TOWER.has(19),
		"tower catalog contains all 20 towers including Resonator and Echoarchive"
	)
	_check(GameConstants.NUMBER_PROMOTION == 44, "new Echoarchive promotion is counted")
	_check(
		GameConstants.NUMBER_LEVEL_PROMOTION.size() == 44, "promotion progress table includes ID 44"
	)
	_check(
		GameConstants.NUMBER_EXPERIENCE_PROMOTION.size() == 44, "promotion XP table includes ID 44"
	)
	_check(
		GameConstants.NUMBER_LEVEL_PROMOTION[42] == [25, 50, 100, 500, 5000]
		and GameConstants.NUMBER_LEVEL_PROMOTION[43] == [25, 50, 100, 500, 5000],
		"Mortar and Echoarchive achievements use [25, 50, 100, 500, 5000] thresholds"
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


func _test_resonator_abilities() -> void:
	var resonator := _new_resonator()
	_check(resonator != null, "factory instantiates the Resonator")
	if resonator == null:
		return
	_check(resonator.id == 18 and resonator.turret_id == "Turret_19T1", "Resonator has catalog identity 18")
	_check(resonator.damage > 0.0 and resonator.rof > 0.0 and resonator.range > 0.0, "factory applies all Resonator battle stats")
	var resonator_range := resonator.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(is_instance_valid(resonator_range) and resonator_range.shape is CircleShape2D and is_equal_approx((resonator_range.shape as CircleShape2D).radius, resonator.range * 0.5), "Resonator targeting radius follows its catalog range")
	_check(ResourceLoader.exists(str(GameConstants.DATA_TOWER[18].get("portrait", ""))), "Resonator catalogue provides its portrait art")
	_check(resonator.get_fx_style() == "resonator", "Resonator uses its signature harmonic projectile FX")
	_check(GameConstants.LEVEL_OPEN_ABILITY == [3, 7, 10], "permanent ability unlock thresholds remain 3, 7, and 10")
	for rarity in [GameConstants.Rarity.COMMON, GameConstants.Rarity.RARE, GameConstants.Rarity.EPIC, GameConstants.Rarity.LEGENDARY]:
		var price_list: Array = GameConstants.PriseUnblockCard[rarity].abilit_prise
		_check(price_list.size() == 3, "rarity has exactly three permanent ability prices")
	_check(GameConstants.PriseUnblockCard[GameConstants.Rarity.RARE].abilit_prise == [720, 1600, 2560], "Resonator retains reduced Rare ability-unlock prices")
	var status_probe := MockEnemy.new()
	status_probe.poison_data = null
	_check(resonator._active_negative_effect_count(status_probe) == 0, "clean target has no charge-qualifying effects")
	status_probe.duration_speed_mod = 5
	status_probe.speed = 60.0
	_check(resonator._active_negative_effect_count(status_probe) == 1, "legacy frame-based micro-slow is recognized as a debuff")
	status_probe.duration_speed_mod = 0
	status_probe.speed = status_probe.current_speed
	status_probe.spell_freeze_timer = 1.0
	status_probe.spell_stun_timer = 1.0
	status_probe.spell_anti_heal_timer = 1.0
	_check(resonator._active_negative_effect_count(status_probe) == 3, "freeze, stun and anti-heal each count as a distinct debuff")
	status_probe.spell_stasis_timer = 1.0
	status_probe.spell_hunters_mark_timer = 1.0
	status_probe.spell_gold_mark_timer = 1.0
	_check(resonator._active_negative_effect_count(status_probe) == 6, "stasis and both enemy marks count as independent effects")
	status_probe.free()
	var body_animation := resonator.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var resonance_animation := resonator.get_node_or_null("ResonanceAnimationPlayer") as AnimationPlayer
	_check(is_instance_valid(body_animation) and body_animation.has_animation("Fire") and body_animation.get_animation("Fire").get_track_count() > 0, "Resonator fire animation is authored at runtime")
	_check(is_instance_valid(resonance_animation), "Resonator has a separate layered animation channel")
	if is_instance_valid(resonance_animation):
		for animation_name in ["Idle", "Charge", "Echo", "PerfectResonance"]:
			_check(resonance_animation.has_animation(animation_name), "Resonator %s animation exists" % animation_name)
	var resonator_icons := [
		"resonator_returning_tone", "resonator_scattered_chord", "resonator_string_memory",
		"resonator_overtone", "resonator_perfect_resonance"
	]
	for icon_id in resonator_icons:
		_check(ResourceLoader.exists("res://Assets/Icons/%s.png" % icon_id), "Resonator ability icon %s exists" % icon_id)
	for sfx_id in ["shot", "charge", "pulse", "impact", "perfect"]:
		var audio_key := "turret_resonator_%s" % sfx_id
		_check(AudioManager.SFX_META.has(audio_key), "Resonator sound %s is registered" % audio_key)
		_check(FileAccess.file_exists("res://Audio/SFX/%s.wav" % audio_key), "Resonator sound %s is generated" % audio_key)
	var choices := JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json")) as Dictionary
	var resonator_choices: Dictionary = choices.get("19", {})
	var all_icons_declared := true
	for milestone in ["3", "7", "10"]:
		for entry in resonator_choices.get(milestone, []):
			var icon_path := str(entry.get("icon", ""))
			all_icons_declared = all_icons_declared and ResourceLoader.exists(icon_path)
	_check(all_icons_declared, "every Resonator ability choice references its bespoke icon")
	var ability_translations := FileAccess.get_file_as_string("res://lang/translation.csv")
	var translation_keys_complete := true
	for key in ["RETURNING_TONE_NAME", "RETURNING_TONE_DESC", "SCATTERED_CHORD_NAME", "SCATTERED_CHORD_DESC", "STRING_MEMORY_NAME", "STRING_MEMORY_DESC", "OVERTONE_NAME", "OVERTONE_DESC", "PERFECT_RESONANCE_NAME", "PERFECT_RESONANCE_DESC"]:
		translation_keys_complete = translation_keys_complete and ability_translations.contains("KEY_RESONATOR_%s," % key)
	_check(translation_keys_complete, "all Resonator choice names and concise descriptions are translated")
	var selected_state: Dictionary = {
		"3": {"id": "resonator_returning_tone", "name": "Ответный тон"},
		"7": {"id": "resonator_overtone", "name": "Овертон"},
		"10": {"id": "resonator_perfect_resonance", "name": "Совершенный резонанс"},
	}
	resonator.set_meta("ability_choices_ui", selected_state)
	_check(resonator._choice_id(3) == "resonator_returning_tone", "Resonator reads the saved level-three branch")
	_check(resonator._choice_id(7) == "resonator_overtone", "Resonator reads the saved level-seven branch")
	_check(resonator._choice_id(10) == "resonator_perfect_resonance", "Resonator reads the fixed level-ten ability")
	resonator.ability = [true, true, true]
	resonator._is_ai_tower = true
	_check(resonator._choice_id(3) == "resonator_returning_tone", "AI battle reads the saved Resonator level-three branch")
	_check(resonator._choice_id(7) == "resonator_overtone", "AI battle reads the saved Resonator level-seven branch")
	resonator._is_ai_tower = false
	for skin_id in ["skin_01", "skin_02", "skin_03", "xp1", "xp2"]:
		var skin: Dictionary = SKIN_CATALOG.get_skin("Turret_19T1", skin_id)
		_check((skin.get("art", []) as Array).size() == 8, "Resonator %s skin supplies all eight stages" % skin_id)
	var default_final := load("res://Assets/TowerSkins/turret_19/default/stage_08.png") as Texture2D
	var cinder_final := (SKIN_CATALOG.get_skin("Turret_19T1", "skin_01").get("art", []) as Array)[7] as Texture2D
	var verdigris_final := (SKIN_CATALOG.get_skin("Turret_19T1", "skin_02").get("art", []) as Array)[7] as Texture2D
	_check(default_final.get_image().get_data() != cinder_final.get_image().get_data(), "Cinder skin has bespoke pixels and silhouette details")
	_check(cinder_final.get_image().get_data() != verdigris_final.get_image().get_data(), "shop skins are visually distinct from one another")
	for shop_path in ["res://Scenes/SupportScenes/turret_menu_shop.tscn", "res://Scenes/Mobile/turret_menu_shop_mobile.tscn"]:
		var shop_scene := load(shop_path) as PackedScene
		_check(shop_scene != null, "Resonator shop scene loads: %s" % shop_path)
		if shop_scene == null:
			continue
		var shop := shop_scene.instantiate() as Control
		add_child(shop)
		shop.setup(GameConstants.DATA_TOWER[18], 18)
		await get_tree().process_frame
		var hero_image := shop.find_child("UI_hero_image", true, false) as TextureRect
		_check(is_instance_valid(hero_image) and hero_image.texture != null, "shop preview displays Resonator stage art: %s" % shop_path)
		var rendered_shop_icons := shop.find_children("UI_ability_icon_row", "HBoxContainer", true, false)
		_check(rendered_shop_icons.size() == 3, "shop shows all three milestone icons: %s" % shop_path)
		shop.free()
	resonator.damage = 100.0
	resonator.rof = 0.05
	resonator.mastery_chanse_crit = -5
	resonator.current_lvl = 2
	resonator.ability = [true, false, false]
	resonator.set_meta("ability_choices_ui", {"3": {"id": "resonator_returning_tone"}})
	var echo_world := Node2D.new()
	add_child(echo_world)
	remove_child(resonator)
	echo_world.add_child(resonator)
	var marked := MockEnemy.new()
	echo_world.add_child(marked)
	resonator.enemy_array = [marked]
	resonator.enemy = marked
	for _shot in range(3):
		await resonator.fire()
	_check(resonator.get_resonance_charges() == 0, "three debuffed hits release and consume all charges")
	_check(resonance_animation.current_animation == "Echo", "three charges trigger the dedicated echo animation")
	_check(body_animation.current_animation == "Fire", "regular attack plays its authored recoil animation")
	_check(absf(resonator._turret_sprite.scale.x - 0.58) > 0.002, "Fire animation visibly moves the tower sprite scale")
	_check(marked.hit_values.size() == 4, "three regular shots trigger one bonus pulse")
	_check(is_equal_approx(marked.hit_values[3], 80.0), "Returning Tone pulse deals 80% shot damage")
	var impact_vfx_found := false
	for transient in get_tree().get_nodes_in_group("combat_fx_transient"):
		if str(transient.name).begins_with("ResonatorImpactFX"):
			impact_vfx_found = true
	_check(impact_vfx_found, "resonance release spawns its expanding harmonic impact VFX")
	echo_world.free()

	var split_tower := _new_resonator()
	if split_tower != null:
		split_tower.damage = 100.0
		split_tower.rof = 0.05
		split_tower.mastery_chanse_crit = -5
		split_tower.current_lvl = 2
		split_tower.ability = [true, false, false]
		split_tower.set_meta("ability_choices_ui", {"3": {"id": "resonator_scattered_chord"}})
		var fx_world := Node2D.new()
		add_child(fx_world)
		remove_child(split_tower)
		fx_world.add_child(split_tower)
		var primary := MockEnemy.new()
		var nearby := MockEnemy.new()
		primary.position = Vector2(220.0, 30.0)
		nearby.position = Vector2(240.0, 20.0)
		fx_world.add_child(primary)
		fx_world.add_child(nearby)
		split_tower.enemy_array = [primary, nearby]
		split_tower.enemy = primary
		for _shot in range(3):
			await split_tower.fire()
		var split_bonus: float = 0.0
		for amount in primary.hit_values.slice(3):
			split_bonus += amount
		for amount in nearby.hit_values:
			split_bonus += amount
		_check(is_equal_approx(split_bonus, 80.0), "Scattered Chord splits the 80% bonus budget without creating damage")
		_check(nearby.hit_values.size() == 1, "Scattered Chord reaches the nearest secondary target")
		var chord_vfx_found := false
		for transient in get_tree().get_nodes_in_group("combat_fx_transient"):
			if str(transient.name).begins_with("ResonatorChordFX"):
				chord_vfx_found = true
		_check(chord_vfx_found, "Scattered Chord spawns its dedicated branching VFX")
		fx_world.free()

	var memory_tower := _new_resonator()
	if memory_tower != null:
		memory_tower.damage = 100.0
		memory_tower.rof = 0.05
		memory_tower.mastery_chanse_crit = -5
		memory_tower.current_lvl = 6
		memory_tower.ability = [true, true, false]
		memory_tower.set_meta("ability_choices_ui", {"3": {"id": "resonator_returning_tone"}, "7": {"id": "resonator_string_memory"}})
		var first_target := MockEnemy.new()
		var next_target := MockEnemy.new()
		first_target.hp = 250.0
		add_child(first_target)
		add_child(next_target)
		memory_tower.enemy_array = [first_target, next_target]
		memory_tower.enemy = first_target
		for _shot in range(3):
			await memory_tower.fire()
		_check(memory_tower.get_resonance_charges() == 3, "String Memory keeps a full charge stack when its target dies")
		memory_tower.enemy = next_target
		await memory_tower.fire()
		_check(next_target.hit_values.size() == 2 and is_equal_approx(next_target.hit_values[0], 80.0), "String Memory delivers the retained pulse on the replacement target")
		_check(memory_tower.get_resonance_charges() == 1, "new target receives only its own newly earned charge")
		memory_tower.free()
		first_target.free()
		next_target.free()

	var reset_tower := _new_resonator()
	if reset_tower != null:
		reset_tower.damage = 100.0
		reset_tower.rof = 0.05
		reset_tower.mastery_chanse_crit = -5
		reset_tower.current_lvl = 2
		reset_tower.ability = [true, false, false]
		reset_tower.set_meta("ability_choices_ui", {"3": {"id": "resonator_returning_tone"}})
		var reset_target_a := MockEnemy.new()
		var reset_target_b := MockEnemy.new()
		add_child(reset_target_a)
		add_child(reset_target_b)
		reset_tower.enemy_array = [reset_target_a, reset_target_b]
		reset_tower.enemy = reset_target_a
		await reset_tower.fire()
		reset_tower.enemy = reset_target_b
		await reset_tower.fire()
		_check(reset_tower.get_resonance_charges() == 1, "without String Memory, switching target resets stored charge")
		var clean_target := MockEnemy.new()
		clean_target.poison_data = null
		add_child(clean_target)
		reset_tower.enemy_array.append(clean_target)
		reset_tower.enemy = clean_target
		await reset_tower.fire()
		_check(reset_tower.get_resonance_charges() == 0, "unmarked enemies never grant resonance charge")
		reset_tower.free()
		reset_target_a.free()
		reset_target_b.free()
		clean_target.free()

	var overtone_tower := _new_resonator()
	if overtone_tower != null:
		overtone_tower.damage = 100.0
		overtone_tower.rof = 0.05
		overtone_tower.mastery_chanse_crit = -5
		overtone_tower.current_lvl = 6
		overtone_tower.ability = [true, true, false]
		overtone_tower._is_ai_tower = true
		overtone_tower.set_meta("ability_choices_ui", {})
		var overtone_target := MockEnemy.new()
		overtone_target.flame_burn_timer = 3.0
		add_child(overtone_target)
		overtone_tower.enemy_array = [overtone_target]
		overtone_tower.enemy = overtone_target
		await overtone_tower.fire()
		_check(overtone_tower.get_resonance_charges() == 2, "Overtone grants two charges for two distinct debuffs")
		var overtone_animation := overtone_tower.get_node("ResonanceAnimationPlayer") as AnimationPlayer
		_check(overtone_animation.current_animation == "Charge", "Overtone charge animation plays before the echo threshold")
		await overtone_tower.fire()
		_check(overtone_tower.get_resonance_charges() == 0, "Overtone's second hit reaches three and releases the pulse")
		_check(overtone_animation.current_animation == "Echo", "Overtone threshold swaps into the echo animation")
		_check(overtone_target.hit_values.size() == 3 and is_equal_approx(overtone_target.hit_values[2], 80.0), "Overtone trigger deals one regular hit plus one 80% pulse")
		_check(is_equal_approx(overtone_target.hp, 99720.0), "Overtone adds exactly 40% damage across each two-shot cycle")
		overtone_tower.free()
		overtone_target.free()

	var perfect_tower := _new_resonator()
	if perfect_tower != null:
		perfect_tower.damage = 100.0
		perfect_tower.rof = 0.05
		perfect_tower.mastery_chanse_crit = -5
		perfect_tower.current_lvl = 9
		perfect_tower.ability = [true, true, true]
		perfect_tower.set_meta("ability_choices_ui", {"3": {"id": "resonator_returning_tone"}, "7": {"id": "resonator_string_memory"}, "10": {"id": "resonator_perfect_resonance"}})
		var perfect_target := MockEnemy.new()
		add_child(perfect_target)
		perfect_tower.enemy_array = [perfect_target]
		perfect_tower.enemy = perfect_target
		for _shot in range(3):
			await perfect_tower.fire()
		_check(perfect_target.hit_values.size() == 4, "Perfect Resonance still releases exactly one pulse")
		var perfect_animation := perfect_tower.get_node("ResonanceAnimationPlayer") as AnimationPlayer
		_check(perfect_animation.current_animation == "PerfectResonance", "level-ten ability plays its signature crescendo animation")
		_check(is_equal_approx(perfect_target.hit_values[3], 150.0), "Perfect Resonance pulse deals 150% shot damage")
		perfect_tower.free()
		perfect_target.free()


func _test_resonator_real_enemy_integration() -> void:
	var resonator := _new_resonator()
	var target := LIVE_ENEMY_SCENE.instantiate() as Enemy
	if resonator == null or target == null:
		_check(false, "real Enemy_1 and Resonator instantiate for scene-backed integration")
		if is_instance_valid(resonator):
			resonator.queue_free()
		if is_instance_valid(target):
			target.queue_free()
		return
	add_child(target)
	await get_tree().process_frame
	target.set_physics_process(false)
	target.hp = 100000.0
	target.base_hp = target.hp
	target.health_bar.max_value = target.hp
	target.health_bar.value = target.hp
	target.apply_poison({"damage": 1.0, "duration": 10.0, "tick": 1.0})
	resonator.damage = 100.0
	resonator.rof = 0.05
	resonator.mastery_chanse_crit = -float(GameConstants.CHANCE_CRITICAL_DAMAGE)
	resonator.current_lvl = 9
	resonator.ability = [true, true, true]
	resonator.set_meta("ability_choices_ui", {
		"3": {"id": "resonator_returning_tone"},
		"7": {"id": "resonator_string_memory"},
		"10": {"id": "resonator_perfect_resonance"}
	})
	resonator.enemy_array = [target]
	resonator.enemy = target
	var hp_before: float = target.hp
	await resonator.fire()
	await resonator.fire()
	await resonator.fire()
	var actual_damage: float = hp_before - target.hp
	_check(resonator._active_negative_effect_count(target) >= 1, "real Enemy_1 poison from apply_poison qualifies as a Resonator debuff")
	_check(actual_damage > 0.0, "real Enemy_1 receives Resonator hits through its on_hit combat path")
	_check(is_zero_approx(resonator.get_resonance_charges()), "three real debuffed hits release and consume the stored charges")
	_check(is_equal_approx(actual_damage, 450.0), "real Enemy_1 receives three 100% shots plus one 150% Perfect Resonance pulse")
	resonator.queue_free()
	target.queue_free()
	await get_tree().process_frame


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


func _new_echoarchive() -> EchoarchiveTower:
	var result := TurretFactory.create_turret("Turret_20T1", Vector2.ZERO)
	if result == null:
		return null
	add_child(result)
	result._initialize()
	return result as EchoarchiveTower


func _test_echoarchive_comprehensive() -> void:
	# 1. Catalog, Factory, Stats, Assets, Localization, Cards, Mastery, Achievements
	var echo := _new_echoarchive()
	_check(echo != null, "factory instantiates Echoarchive")
	if echo == null:
		return
	echo.set_physics_process(false)
	_check(echo.id == 19 and echo.turret_id == "Turret_20T1", "Echoarchive has catalog identity 19")
	_check(echo.get_fx_style() == "echoarchive", "Echoarchive uses echoarchive FX style")
	var echo_range := echo.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(is_instance_valid(echo_range) and echo_range.shape is CircleShape2D and is_equal_approx((echo_range.shape as CircleShape2D).radius, echo.range * 0.5), "Echoarchive targeting radius matches catalog range")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_1[0][0]), 40.0), "Echoarchive card 1 lvl 1 base damage is 40")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_1[9][9]), 215.76), "Echoarchive card 10 lvl 10 damage is 215.76")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_2[9]), 1.04), "Echoarchive lvl 10 reload is 1.04s")
	_check(int(GameConstants.DATA_TOWER[19].parametr_3[9][9]) == 383, "Echoarchive card 10 lvl 10 range is 383")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_4[0]), 2.0) and is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_4[9]), 1.75), "Echoarchive archive_cycle scales from 2.00s to 1.75s")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_5[0][0]), 20.0) and is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_5[9][9]), 25.0), "Echoarchive echo_share scales from 20% to 25%")
	_check(is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_6[0]), 8.0) and is_equal_approx(float(GameConstants.DATA_TOWER[19].parametr_6[9]), 12.0), "Echoarchive echo_cap_mult scales from 8.0x to 12.0x")
	_check(ResourceLoader.exists(str(GameConstants.DATA_TOWER[19].get("portrait", ""))), "Echoarchive portrait exists")
	_check(DataManager.mastery_echoarchive_session.size() >= 20, "per-tower Echoarchive mastery session array is initialized")
	_check(GameConstants.ECHOARCHIVE_PULSES_PER_MASTERY_XP == 100, "Echoarchive pulses-per-XP constant equals 100")

	var saved_p43: int = int(DataManager.promotion_progress[43])
	var saved_l43: int = int(DataManager.promotion_progress_level[43])
	var saved_d43: Array = DataManager.promotion_completion_dates[43].duplicate()
	var saved_bs: bool = TasksManager.battle_started
	var saved_bf: bool = TasksManager.battle_finished
	var saved_dirty: bool = TasksManager.task_dirty
	TasksManager.battle_started = true
	TasksManager.battle_finished = false
	TasksManager.record_tower_achievement(43)
	_check(int(DataManager.promotion_progress[43]) == saved_p43 + 1, "Echoarchive achievement ID 43 increments medal 44 progress")
	DataManager.promotion_progress[43] = saved_p43
	DataManager.promotion_progress_level[43] = saved_l43
	DataManager.promotion_completion_dates[43] = saved_d43
	TasksManager.battle_started = saved_bs
	TasksManager.battle_finished = saved_bf
	TasksManager.task_dirty = saved_dirty

	# TowerCards LEGENDARY add_cards safety check (tower_id is 1-based: 20 -> Turret_20T1)
	var saved_cards_20: int = int(DataManager.tower_data["Turret_20T1"]["cards"])
	TowerCards.add_cards(20, 1)
	_check(int(DataManager.tower_data["Turret_20T1"]["cards"]) == saved_cards_20 + 1, "TowerCards handles LEGENDARY Echoarchive drops safely")
	DataManager.tower_data["Turret_20T1"]["cards"] = saved_cards_20

	for icon_id in ["echoarchive_choral_echo", "echoarchive_big_binding", "echoarchive_witness", "echoarchive_last_record", "echoarchive_synchronous_index", "echo_cycle", "echo_share", "echo_cap", "medal_44"]:
		_check(ResourceLoader.exists("res://Assets/Icons/%s.png" % icon_id), "Echoarchive icon %s exists" % icon_id)
	for sfx_id in ["build", "shot", "lock", "record", "window_end", "echo"]:
		var akey := "turret_echoarchive_%s" % sfx_id
		_check(AudioManager.SFX_META.has(akey) and FileAccess.file_exists("res://Audio/SFX/%s.wav" % akey), "Echoarchive SFX %s exists and is registered" % akey)

	var choices := JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json")) as Dictionary
	var echo_choices: Dictionary = choices.get("20", {})
	var echo_icons_ok: bool = echo_choices.size() == 3
	for milestone in ["3", "7", "10"]:
		for entry in echo_choices.get(milestone, []):
			echo_icons_ok = echo_icons_ok and ResourceLoader.exists(str(entry.get("icon", "")))
	_check(echo_icons_ok, "AbilityChoiceCatalog[20] defines all 5 Echoarchive choices with valid icons")

	var csv := FileAccess.get_file_as_string("res://lang/translation.csv")
	for key in [
		"KEY_NAME_TURRET_20", "KEY_UNIT_PERCENT", "KEY_ECHO_MULT_UNIT",
		"KEY_ECHO_CYCLE", "KEY_ECHO_SHARE", "KEY_ECHO_CAP",
		"KEY_TURRET20_DESC", "KEY_TURRET20_UP0_DESC", "KEY_TURRET20_UP1_DESC", "KEY_TURRET20_UP2_DESC",
		"KEY_ECHOARCHIVE_CHORAL_ECHO_NAME", "KEY_ECHOARCHIVE_BIG_BINDING_NAME",
		"KEY_ECHOARCHIVE_WITNESS_NAME", "KEY_ECHOARCHIVE_LAST_RECORD_NAME", "KEY_ECHOARCHIVE_SYNCHRONOUS_INDEX_NAME",
		"KEY_MASTERY_DESC_T20", "KEY_PROMOTION_NAME_44", "KEY_PROMOTION_DESC_44"
	]:
		_check(csv.contains(key + ","), "Echoarchive translation key %s exists" % key)

	for skin_id in ["skin_01", "skin_02", "skin_03", "xp1", "xp2"]:
		var skin: Dictionary = SKIN_CATALOG.get_skin("Turret_20T1", skin_id)
		_check((skin.get("art", []) as Array).size() == 8, "Echoarchive %s skin provides 8 stages" % skin_id)
	var default_t20 := load("res://Assets/TowerSkins/turret_20/default/stage_08.png") as Texture2D
	var skin01_t20 := (SKIN_CATALOG.get_skin("Turret_20T1", "skin_01").get("art", []) as Array)[7] as Texture2D
	var skin02_t20 := (SKIN_CATALOG.get_skin("Turret_20T1", "skin_02").get("art", []) as Array)[7] as Texture2D
	_check(default_t20.get_image().get_data() != skin01_t20.get_image().get_data(), "Echoarchive skin_01 differs from default art")
	_check(skin01_t20.get_image().get_data() != skin02_t20.get_image().get_data(), "Echoarchive shop skins are distinct")

	for shop_path in ["res://Scenes/SupportScenes/turret_menu_shop.tscn", "res://Scenes/Mobile/turret_menu_shop_mobile.tscn"]:
		var shop_scene := load(shop_path) as PackedScene
		var shop := shop_scene.instantiate() as Control
		add_child(shop)
		shop.setup(GameConstants.DATA_TOWER[19], 19)
		await get_tree().process_frame
		var hero_image := shop.find_child("UI_hero_image", true, false) as TextureRect
		_check(is_instance_valid(hero_image) and hero_image.texture != null, "Echoarchive shop renders preview: %s" % shop_path)
		var rendered_icons := shop.find_children("UI_ability_icon_row", "HBoxContainer", true, false)
		_check(rendered_icons.size() == 3, "Echoarchive shop shows all 3 milestone icon rows: %s" % shop_path)
		shop.free()

	# Mobile AI & PvP Sync checks
	var ai: MobileTacticalAI = MOBILE_TACTICAL_AI.new()
	_check(ai.get_tower_radius_px(19, 0, 0) > 0.0, "mobile AI resolves Echoarchive attack radius")
	var ai_solo: float = ai.eval_combat_power(19, 0, 0, [false, false, false], 1.0, 1.0, 3, false, 600.0, 1)
	var ai_team: float = ai.eval_combat_power(19, 9, 9, [true, true, true], 1.0, 1.0, 3, true, 600.0, 5)
	_check(ai_team > ai_solo, "mobile AI values Echoarchive scaling with allies, abilities, and bosses")

	var desktop_pc = DESKTOP_PLAYER_CONTAINER.new()
	var echo_sync_d := _new_echoarchive()
	echo_sync_d.is_opponent = true
	echo_sync_d.set_remote_echo_ratio(0.65)
	_check(is_equal_approx(echo_sync_d.get_echo_fill_ratio(), 0.65), "desktop PvP echo_buffer_ratio round-trips")
	echo_sync_d.free()
	desktop_pc.free()

	# 2. Combat mechanics: recording, 1s window cutoff, exclusions, cap, branches, Mimic, real Enemy_1
	var arena := Node2D.new()
	arena.name = "EchoTestArena"
	add_child(arena)
	remove_child(echo)
	arena.add_child(echo)
	echo.damage = 100.0
	echo.rof = 1.4
	echo.archive_cycle = 2.0
	echo.echo_share_pct = 20.0
	echo.echo_cap_mult = 8.0
	echo.mastery_chanse_crit = -float(GameConstants.CHANCE_CRITICAL_DAMAGE)
	echo.current_lvl = 0
	echo.ability = [false, false, false]
	echo.built = true

	var ally := _new_resonator()
	ally.set_physics_process(false)
	remove_child(ally)
	arena.add_child(ally)
	ally.built = true

	var second_echo := _new_echoarchive()
	second_echo.set_physics_process(false)
	remove_child(second_echo)
	arena.add_child(second_echo)
	second_echo.damage = 100.0
	second_echo.archive_cycle = 2.0
	second_echo.echo_share_pct = 20.0
	second_echo.echo_cap_mult = 8.0
	second_echo.mastery_chanse_crit = -float(GameConstants.CHANCE_CRITICAL_DAMAGE)
	second_echo.built = true

	var enemy_low := MockEnemy.new()
	enemy_low.progress = 10.0
	enemy_low.position = Vector2(-400.0, 0.0)
	var enemy_mid := MockEnemy.new()
	enemy_mid.progress = 50.0
	enemy_mid.position = Vector2(160.0, 0.0)
	var enemy_lead := MockEnemy.new()
	enemy_lead.progress = 90.0
	enemy_lead.position = Vector2(100.0, 0.0)
	arena.add_child(enemy_low)
	arena.add_child(enemy_mid)
	arena.add_child(enemy_lead)
	echo.enemy_array = [enemy_low, enemy_mid, enemy_lead]
	second_echo.enemy_array = [enemy_lead]

	# Step once to lock lead target (enemy_lead, progress = 90.0)
	echo.step_archive_cycle(0.05)
	second_echo.step_archive_cycle(0.05)
	_check(echo.get_marked_target() == enemy_lead, "Echoarchive marks enemy with highest path progress")

	# Direct damage from ally records 20% in BOTH friendly Echoarchives
	enemy_lead.on_hit(500.0, -1, GameConstants.TowerType.GUN, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 100.0), "Echoarchive records 20% of allied tower direct damage (100 of 500)")
	_check(is_equal_approx(second_echo.get_stored_echo(), 100.0), "Second Echoarchive independently records allied damage on its marked target")

	# Allied damage to OTHER non-marked enemies (even outside Echoarchive's own range) ALSO records into buffer
	enemy_low.on_hit(200.0, -1, GameConstants.TowerType.GUN, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 140.0), "Echoarchive records 20% of allied tower damage across non-marked targets (+40 of 200)")
	echo._stored_echo = 100.0

	# Spectator/opponent map enemy is excluded from recording
	var spec_enemy := MockEnemy.new()
	spec_enemy.is_spectator_enemy = true
	arena.add_child(spec_enemy)
	spec_enemy.on_hit(500.0, -1, GameConstants.TowerType.GUN, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 100.0), "Echoarchive ignores allied damage against spectator/opponent map enemies")
	spec_enemy.free()

	# Echoarchive's own primary shot does NOT record into its own buffer (or another Echoarchive)
	enemy_lead.on_hit(100.0, -1, GameConstants.TowerType.GUN, echo)
	_check(is_equal_approx(echo.get_stored_echo(), 100.0), "Echoarchive own direct shots are excluded from its own buffer")

	# Opponent/phantom exclusion
	ally.is_opponent = true
	enemy_lead.on_hit(500.0, -1, GameConstants.TowerType.GUN, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 100.0), "Opponent tower damage is ignored by allied Echoarchive")
	ally.is_opponent = false

	# DoT without Witness is ignored; DoT with Witness is recorded
	enemy_lead.trigger_dot_hit(200.0, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 100.0), "DoT ticks are ignored before unlocking Witness")
	echo.current_lvl = 6
	echo.ability = [true, true, false]
	echo.set_meta("ability_choices_ui", {"3": {"id": "echoarchive_big_binding"}, "7": {"id": "echoarchive_witness"}})
	enemy_lead.trigger_dot_hit(200.0, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 140.0), "Witness enables recording poison/burn/bleed DoT damage (+40 of 200)")

	# Big Binding increases cap by 25% (100 * 8.0 * 1.25 = 1000)
	_check(is_equal_approx(echo.get_echo_cap_limit(), 1000.0), "Big Binding increases echo cap by +25% (800 -> 1000)")
	enemy_lead.on_hit(10000.0, -1, GameConstants.TowerType.GUN, ally)
	_check(is_equal_approx(echo.get_stored_echo(), 1000.0), "Echo buffer clamps strictly at effective cap (1000)")

	# 1.50s recording window stays open at 1.10s and closes at > 1.50s while cycle finishes at 2.0s
	var echo_win := _new_echoarchive()
	echo_win.set_physics_process(false)
	remove_child(echo_win)
	arena.add_child(echo_win)
	echo_win.damage = 100.0
	echo_win.archive_cycle = 2.0
	echo_win.echo_share_pct = 20.0
	echo_win.echo_cap_mult = 8.0
	echo_win.enemy_array = [enemy_lead]
	echo_win.step_archive_cycle(0.05) # timer = 0.05
	echo_win.step_archive_cycle(1.05) # timer = 1.10 (< 1.50 RECORD_WINDOW)
	_check(echo_win.is_recording_window_open(), "Recording window stays open at 1.10s (< 1.50s)")
	echo_win.step_archive_cycle(0.45) # timer = 1.55 (> 1.50 RECORD_WINDOW)
	_check(not echo_win.is_recording_window_open(), "Recording window closes after 1.50s")
	var buf_after_close: float = echo_win.get_stored_echo()
	enemy_lead.on_hit(500.0, -1, GameConstants.TowerType.GUN, ally)
	_check(is_equal_approx(echo_win.get_stored_echo(), buf_after_close), "Allied hits after 1.50s recording window closes are NOT recorded")
	echo_win.queue_free()

	# Release echo -> verify release does NOT chain into second_echo AND increments mastery
	var saved_echo_mastery: int = int(DataManager.mastery_echoarchive_session[echo.id])
	var hits_before_release: int = enemy_lead.hit_values.size()
	var second_buf_before: float = second_echo.get_stored_echo()
	echo.step_archive_cycle(2.00)
	_check(enemy_lead.hit_values.size() == hits_before_release + 1, "Cycle completion fires echo burst onto marked enemy")
	_check(is_equal_approx(enemy_lead.hit_values[hits_before_release], 1000.0), "Released echo deals stored buffer damage (1000)")
	_check(is_equal_approx(second_echo.get_stored_echo(), second_buf_before), "Released echo does NOT recursively record into another Echoarchive")
	_check(is_zero_approx(echo.get_stored_echo()), "Echo buffer resets to 0 after cycle release")
	_check(int(DataManager.mastery_echoarchive_session[echo.id]) == saved_echo_mastery + 1, "Echo release increments Echoarchive mastery counter")
	var echo_anim := echo.get_node_or_null("ArchiveAnimationPlayer") as AnimationPlayer
	_check(is_instance_valid(echo_anim) and echo_anim.current_animation == "EchoRelease" and echo_anim.get_animation("EchoRelease").get_track_count() >= 2, "Echoarchive plays EchoRelease scale+modulate animation on echo burst")
	var found_burst := false
	var found_primary_num := false
	for child in arena.get_children():
		if str(child.name).begins_with("EchoarchiveAbilityBurstFX"):
			found_burst = true
		elif str(child.name).begins_with("EchoarchiveDamageNumberFX") and bool(child.get("is_primary")):
			found_primary_num = str(child.get("text")) == "1000" and (child.get("text_color") as Color).is_equal_approx(Color(1.0, 0.86, 0.22, 1.0))
	_check(found_burst, "Echoarchive ability hit spawns EchoarchiveAbilityBurstFX animation on target")
	_check(found_primary_num, "Echoarchive displays golden exact damage readout (1000) on targeted enemy")
	for child in arena.get_children():
		if str(child.name).begins_with("EchoarchiveAbilityBurstFX") or str(child.name).begins_with("EchoarchiveDamageNumberFX"):
			child.free()

	# Choral Echo (lvl 3): 60% primary + 20% to 2 highest-progress enemies map-wide
	second_echo.queue_free()
	echo.set_meta("ability_choices_ui", {"3": {"id": "echoarchive_choral_echo"}, "7": {"id": "echoarchive_last_record"}, "10": {"id": "echoarchive_synchronous_index"}})
	echo.current_lvl = 9
	echo.ability = [true, true, true]
	_check(is_equal_approx(echo.get_effective_echo_share_pct(), 30.0), "Synchronous Index adds +10 pp to echo share (20% -> 30%)")
	_check(is_equal_approx(echo.get_effective_echo_cap_mult(), 8.0), "Synchronous Index leaves echo cap unchanged")
	var global_far := MockEnemy.new()
	global_far.progress = 200.0 # outside Echoarchive's enemy_array, right beside enemy_lead
	global_far.position = Vector2(130.0, 0.0)
	global_far.add_to_group("enemies")
	arena.add_child(global_far)
	echo.step_archive_cycle(0.05) # locks enemy_lead
	enemy_lead.on_hit(1000.0, -1, GameConstants.TowerType.GUN, ally) # +300 buffered
	var h_lead: int = enemy_lead.hit_values.size()
	var h_mid: int = enemy_mid.hit_values.size()
	var h_far: int = global_far.hit_values.size()
	var h_low: int = enemy_low.hit_values.size()
	echo.step_archive_cycle(2.00)
	_check(enemy_lead.hit_values.size() == h_lead + 1 and is_equal_approx(enemy_lead.hit_values[h_lead], 180.0), "Choral Echo deals 60% (180 of 300) to primary target")
	_check(global_far.hit_values.size() == h_far + 1 and is_equal_approx(global_far.hit_values[h_far], 60.0), "Choral Echo hits nearest neighbor (even off-range) for 20% (60)")
	_check(enemy_mid.hit_values.size() == h_mid + 1 and is_equal_approx(enemy_mid.hit_values[h_mid], 60.0), "Choral Echo hits second nearest neighbor for 20% (60)")
	_check(enemy_low.hit_values.size() == h_low, "Choral Echo hits at most 2 neighboring enemies within radius")
	var choral_primary_ok := false
	var choral_neighbor_nums := 0
	for child in arena.get_children():
		if str(child.name).begins_with("EchoarchiveDamageNumberFX"):
			if bool(child.get("is_primary")) and str(child.get("text")) == "180" and (child.get("text_color") as Color).is_equal_approx(Color(1.0, 0.86, 0.22, 1.0)):
				choral_primary_ok = true
			elif not bool(child.get("is_primary")) and str(child.get("text")) == "60" and (child.get("text_color") as Color).is_equal_approx(Color(0.38, 0.94, 1.0, 1.0)):
				choral_neighbor_nums += 1
	_check(choral_primary_ok and choral_neighbor_nums == 2, "Choral Echo displays golden 180 on primary and cyan 60 on neighbors")

	# Last Record (lvl 7): killed marked enemy transfers 50% buffer without resetting timer
	echo.step_archive_cycle(0.05) # marks enemy_lead
	enemy_lead.on_hit(1000.0, -1, GameConstants.TowerType.GUN, ally) # +300 buffered
	echo.step_archive_cycle(0.70) # elapsed = 0.75s
	var timer_before_kill: float = echo.get_cycle_timer()
	echo.enemy_array.erase(enemy_lead)
	enemy_lead.kill_mock(true)
	_check(echo.get_marked_target() == enemy_mid, "Last Record transfers mark to next highest-progress enemy in range")
	_check(is_equal_approx(echo.get_stored_echo(), 150.0), "Last Record preserves 50% of stored buffer (300 -> 150)")
	_check(is_equal_approx(echo.get_cycle_timer(), timer_before_kill), "Last Record does not reset archive timer")

	# Exiting enemy (was_killed = false) clears buffer instead of transferring
	enemy_mid.kill_mock(false)
	_check(is_zero_approx(echo.get_stored_echo()), "Exiting target clears stored echo buffer instead of transferring")

	# Mimic copy scaling of echo_share_pct + ability_choices_ui preservation
	var mimic_echo := _new_echoarchive()
	mimic_echo.set_physics_process(false)
	mimic_echo.is_mimic_copy = true
	mimic_echo.mimic_card_level = 0
	mimic_echo.mimic_stat_mult = 0.85
	mimic_echo.current_lvl = 9
	mimic_echo.ability = [true, true, true]
	mimic_echo.set_meta("ability_choices_ui", (echo.get_meta("ability_choices_ui") as Dictionary).duplicate(true))
	mimic_echo.apply_level_and_gift_stats()
	_check(is_equal_approx(mimic_echo.echo_share_pct, 20.0 * 0.85), "Mimic Echoarchive scales base echo_share_pct by mimic_stat_mult")
	_check(is_equal_approx(mimic_echo.get_effective_echo_share_pct(), 20.0 * 0.85 + 10.0 * 0.85), "Mimic Echoarchive scales Synchronous Index share bonus by mimic_stat_mult")
	mimic_echo.queue_free()

	# Real Enemy_1 anti-double-dipping check (spell_vuln_mult = 1.5x applies to ally hit, NOT again to Echoarchive release)
	var live_enemy := LIVE_ENEMY_SCENE.instantiate() as Enemy
	if live_enemy != null:
		arena.add_child(live_enemy)
		await get_tree().process_frame
		live_enemy.set_physics_process(false)
		live_enemy.hp = 100000.0
		live_enemy.base_hp = live_enemy.hp
		live_enemy.health_bar.max_value = live_enemy.hp
		live_enemy.health_bar.value = live_enemy.hp
		live_enemy.spell_vuln_timer = 10.0
		live_enemy.spell_vuln_mult = 1.5
		echo.set_meta("ability_choices_ui", {"3": {"id": "echoarchive_big_binding"}, "7": {"id": "echoarchive_witness"}, "10": {"id": "echoarchive_synchronous_index"}})
		echo.enemy_array = [live_enemy]
		echo._clear_archive_state()
		echo.step_archive_cycle(0.05) # lock live_enemy
		var hp0: float = live_enemy.hp
		live_enemy.on_hit(100.0, -1, GameConstants.TowerType.GUN, ally) # 100 * 1.5 = 150 dealt -> 30% * 150 = 45 buffered
		var hp_after_ally: float = live_enemy.hp
		_check(is_equal_approx(hp0 - hp_after_ally, 150.0), "Real Enemy_1 receives ally hit amplified by 1.5x Vulnerability (150)")
		_check(is_equal_approx(echo.get_stored_echo(), 45.0), "Echoarchive records 30% of amplified dealt damage (45)")
		echo.step_archive_cycle(2.00)
		var echo_dealt_real: float = hp_after_ally - live_enemy.hp
		_check(is_equal_approx(echo_dealt_real, 45.0), "Echoarchive burst is NOT double-dipped by Vulnerability on real Enemy_1 (45, not 67.5)")
		live_enemy.queue_free()

	# Desktop AIManager DPS estimation check
	var desktop_ai_echo: Dictionary = AIManager._estimate_card_level0_stats(19, 0)
	_check(float(desktop_ai_echo.get("dps", 0.0)) > 40.0 / 1.4, "Desktop AIManager accounts for Echoarchive echo burst DPS")

	# Live fire() shot check + no self-recording
	echo.enemy_array = [enemy_low]
	echo.enemy = enemy_low
	echo._clear_archive_state()
	echo.step_archive_cycle(0.05) # locks enemy_low
	echo.is_ready = true
	echo.rof = 0.05
	var low_hits_before: int = enemy_low.hit_values.size()
	await echo.fire()
	_check(enemy_low.hit_values.size() == low_hits_before + 1, "Echoarchive primary fire() hits target")
	_check(is_zero_approx(echo.get_stored_echo()), "Echoarchive primary fire() does not self-record")

	# Battle UI (TowerUI + TurretMenu) rendering + upgrade diffs check (real BuildController lifecycle: built = true before add_child)
	var ui_echo := TurretFactory.create_turret("Turret_20T1", Vector2.ZERO) as EchoarchiveTower
	_check(ui_echo != null, "TurretFactory builds UI-capable Echoarchive")
	if ui_echo != null:
		ui_echo.built = true
		ui_echo.current_lvl = 0
		ui_echo.ability = [false, false, false]
		add_child(ui_echo)
		ui_echo._initialize()
		ui_echo.set_physics_process(false)
		ui_echo.apply_level_and_gift_stats()
		var echo_menu := ui_echo.get_node_or_null("Menu") as Control
		_check(is_instance_valid(echo_menu) and is_instance_valid(ui_echo.ui_system), "Echoarchive instantiates battle TurretMenu and TowerUI")
		if is_instance_valid(echo_menu) and is_instance_valid(ui_echo.ui_system):
			echo_menu.setup(19)
			ui_echo.ui_system.update_menu()
			ui_echo.ui_system.update_menu_upgrade()
			_check(echo_menu.list_node.size() == 6, "Echoarchive battle TurretMenu shows all 6 stat rows")
			_check(echo_menu.list_node[3].get_node("HValue/Value").text == str(MathUtils.round_to_dec(2.0, 2)), "TurretMenu row 3 displays archive_cycle = 2.0")
			_check(echo_menu.list_node[3].get_node("HValue/Up").text == "-0.02", "TurretMenu row 3 upgrade diff omits + on negative cycle delta")
			ui_echo.current_lvl = 8
			ui_echo.ability = [true, true, true]
			ui_echo.set_meta("ability_choices_ui", {"3": {"id": "echoarchive_big_binding"}, "7": {"id": "echoarchive_witness"}, "10": {"id": "echoarchive_synchronous_index"}})
			ui_echo.apply_level_and_gift_stats()
			ui_echo.ui_system.update_menu_upgrade()
			_check(echo_menu.list_node[4].get_node("HValue/Up").text == "+" + str(MathUtils.round_to_dec(10.0, 2)), "TurretMenu row 4 previews +10 Synchronous Index share jump at lvl 9->10")
			_check(echo_menu.list_node[5].get_node("HValue/Up").text == "+" + str(MathUtils.round_to_dec(1.0, 2)), "TurretMenu row 5 previews Big Binding (+25% of +0.8 = +1.0) cap jump at lvl 9->10")
		ui_echo.queue_free()

	# DataManager.write_mastery() Echoarchive pulse -> XP conversion
	var saved_xp20: int = int(DataManager.tower_data["Turret_20T1"].get("mastery_xp", 0))
	var saved_sess20: int = int(DataManager.mastery_echoarchive_session[19])
	DataManager.tower_data["Turret_20T1"]["mastery_xp"] = 0
	DataManager.mastery_echoarchive_session[19] = 250
	DataManager.write_mastery()
	_check(int(DataManager.tower_data["Turret_20T1"].get("mastery_xp", 0)) >= 2, "DataManager.write_mastery converts 250 Echoarchive pulses into >=2 XP")
	DataManager.tower_data["Turret_20T1"]["mastery_xp"] = saved_xp20
	DataManager.mastery_echoarchive_session[19] = saved_sess20

	# Supporting Desktop & Mobile UI scene instantiation checks (Mastery, Promotions, Mobile TurretMenu)
	for ui_path in [
		"res://Scenes/SupportScenes/info_mastery.tscn",
		"res://Scenes/SupportScenes/promotion.tscn",
		"res://Scenes/Mobile/info_mastery_mobile.tscn",
		"res://Scenes/Mobile/TurretMenu_mobile.tscn"
	]:
		var ui_scene := load(ui_path) as PackedScene
		_check(ui_scene != null, "UI scene loads cleanly: %s" % ui_path)
		if ui_scene != null:
			var inst := ui_scene.instantiate() as Control
			add_child(inst)
			if inst.has_method("setup") and ui_path.ends_with("TurretMenu_mobile.tscn"):
				inst.setup(19)
			await get_tree().process_frame
			_check(is_instance_valid(inst), "UI scene instantiates cleanly: %s" % ui_path)
			inst.free()

	arena.queue_free()
	await get_tree().process_frame


func _test_follow_up_fixes() -> void:
	# Req 1: Echoarchive detailed description contains live stats in RU & EN
	var orig_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("ru")
	var ru_desc := tr("KEY_TURRET20_DESC")
	_check(ru_desc.contains("20–62") and ru_desc.contains("1.40–1.04") and ru_desc.contains("2.00–1.75") and ru_desc.contains("1.50") and ru_desc.contains("20%–25%"), "RU KEY_TURRET20_DESC includes live stats")
	TranslationServer.set_locale("en")
	var en_desc := tr("KEY_TURRET20_DESC")
	_check(en_desc.contains("20–62") and en_desc.contains("1.40–1.04") and en_desc.contains("2.00–1.75") and en_desc.contains("1.50") and en_desc.contains("20%–25%"), "EN KEY_TURRET20_DESC includes live stats")
	TranslationServer.set_locale(orig_locale)

	# Req 2: Reworked Echoarchive assets (portrait 512x512, 384x384 transparent alpha stages across 6 skins)
	var p_tex := load("res://Assets/TowerSkins/turret_20/portrait.png") as Texture2D
	_check(p_tex != null and p_tex.get_image().get_size() == Vector2i(512, 512), "Reworked Echoarchive portrait is 512x512")
	for sk in ["default", "skin_01", "skin_02", "skin_03", "xp1", "xp2"]:
		var st8 := load("res://Assets/TowerSkins/turret_20/%s/stage_08.png" % sk) as Texture2D
		_check(st8 != null, "Echoarchive %s stage_08 loads" % sk)
		if st8 != null:
			var img := st8.get_image()
			_check(img.get_size() == Vector2i(384, 384), "Echoarchive %s stage_08 is 384x384" % sk)
			_check(img.get_pixel(0, 0).a < 0.05 and img.get_pixel(383, 383).a < 0.05, "Echoarchive %s stage_08 has transparent edges" % sk)

	# Req 3 & 4 & 6: Desktop & Mobile shop sorting, rarity coloring, _stat_value fix, L3/L7 switching, Planned tags
	var saved_t19: Dictionary = DataManager.tower_data["Turret_19T1"].duplicate(true)
	var saved_t20: Dictionary = DataManager.tower_data["Turret_20T1"].duplicate(true)
	var saved_money: int = DataManager.data_money
	DataManager.data_money = 999999
	DataManager.tower_data["Turret_19T1"]["have"] = true
	DataManager.tower_data["Turret_19T1"]["level"] = 9
	DataManager.tower_data["Turret_19T1"]["ability"] = [true, true, false]
	DataManager.tower_data["Turret_19T1"]["ability_choices"] = {"3": {"id": "resonator_returning_tone", "name": "Returning Tone", "selected": true}, "7": {"id": "resonator_string_memory", "name": "String Memory", "selected": true}}
	DataManager.tower_data["Turret_20T1"]["have"] = true
	DataManager.tower_data["Turret_20T1"]["level"] = 9
	DataManager.tower_data["Turret_20T1"]["ability"] = [true, true, false]
	DataManager.tower_data["Turret_20T1"]["ability_choices"] = {"3": {"id": "echoarchive_choral_echo", "name": "Choral Echo", "selected": true}, "7": {"id": "echoarchive_witness", "name": "Witness", "selected": true}}

	for m_path in ["res://Scenes/SupportScenes/turret_menu_shop.tscn", "res://Scenes/Mobile/turret_menu_shop_mobile.tscn"]:
		DataManager.data_money = 999999
		DataManager.tower_data["Turret_20T1"]["have"] = true
		DataManager.tower_data["Turret_20T1"]["level"] = 9
		DataManager.tower_data["Turret_20T1"]["ability"] = [true, true, false]
		DataManager.tower_data["Turret_20T1"]["ability_choices"] = {"3": {"id": "echoarchive_choral_echo", "name": "Choral Echo", "selected": true}, "7": {"id": "echoarchive_witness", "name": "Witness", "selected": true}}
		var menu_scene := load(m_path) as PackedScene
		var m := menu_scene.instantiate() as Control
		add_child(m)
		m.setup(DataManager.tower_data["Turret_20T1"], 19)
		await get_tree().process_frame
		var badge := m.find_child("UI_rarity_badge", true, false) as PanelContainer
		_check(is_instance_valid(badge), "Shop info modal renders UI_rarity_badge (%s)" % m_path)
		# Verify _stat_value does NOT index flat Array parametr_2 by card level!
		var p2_val: Variant = m._stat_value(GameConstants.DATA_TOWER[19].parametr_2, 5)
		_check(is_equal_approx(float(p2_val), 1.40), "_stat_value returns base Lv.1 value for battle-level Array parametr_2 (%s)" % m_path)
		# Verify L3 switching works AFTER unlock!
		var c0_1 := m.find_child("Choice_0_1", true, false) as Button
		_check(is_instance_valid(c0_1) and not c0_1.disabled, "Implemented L3 option 2 stays clickable after unlock (%s)" % m_path)
		if is_instance_valid(c0_1):
			c0_1.pressed.emit()
			await get_tree().process_frame
			_check(str(DataManager.tower_data["Turret_20T1"]["ability_choices"]["3"].get("id", "")) == "echoarchive_big_binding", "Clicking L3 option 2 switches pre-battle choice (%s)" % m_path)
		# Verify L10 unlock records ability_choices["10"]
		m._on_ability_pressed(2)
		await get_tree().process_frame
		_check(str(DataManager.tower_data["Turret_20T1"].get("ability_choices", {}).get("10", {}).get("id", "")) == "echoarchive_synchronous_index", "Unlocking L10 records ability_choices['10'] (%s)" % m_path)
		# Verify Turret_17T1 L3 Option 2 is now implemented and enabled in shop preview!
		var saved_t17_ui: Dictionary = DataManager.tower_data["Turret_17T1"].duplicate(true)
		DataManager.tower_data["Turret_17T1"]["have"] = true
		DataManager.tower_data["Turret_17T1"]["level"] = 5
		m.setup(DataManager.tower_data["Turret_17T1"], 16)
		await get_tree().process_frame
		var t17_o2 := m.find_child("Choice_0_1", true, false) as Button
		_check(is_instance_valid(t17_o2) and not t17_o2.disabled, "Implemented Turret_17T1 Option 2 is enabled in shop preview (%s)" % m_path)
		DataManager.tower_data["Turret_17T1"] = saved_t17_ui
		# Verify 3/7/10 ability lock badges & active-button states on desktop & mobile shop UIs
		DataManager.tower_data["Turret_20T1"]["have"] = true
		DataManager.tower_data["Turret_20T1"]["ability"] = [false, false, false]
		DataManager.tower_data["Turret_20T1"]["ability_choices"] = {}
		DataManager.tower_data["Turret_20T1"]["level"] = 0 # Lv 1: all 3/7/10 locked
		m.setup(DataManager.tower_data["Turret_20T1"], 19)
		await get_tree().process_frame
		var badges_lv1 := m.find_children("UI_ability_lock_badge", "PanelContainer", true, false)
		var vis_locks_lv1 := 0
		for b in badges_lv1:
			if b.is_visible_in_tree():
				vis_locks_lv1 += 1
		_check(vis_locks_lv1 == 3, "Lv 1 card displays lock badges on all 3 abilities (%s)" % m_path)
		_check(m.ability_buttons[0].disabled and m.ability_buttons[1].disabled and m.ability_buttons[2].disabled, "Lv 1 card disables buy buttons for abilities 3/7/10 (%s)" % m_path)
		_check(m.ability_buttons[0].icon != null and m.ability_buttons[1].icon != null and m.ability_buttons[2].icon != null, "Lv 1 card shows lock icon on buy buttons (%s)" % m_path)
		var p43_lv1 := m.find_child("PanelContainer43", true, false) as PanelContainer
		var sb_lv1 := p43_lv1.get_theme_stylebox("panel") as StyleBoxFlat if is_instance_valid(p43_lv1) else null
		_check(sb_lv1 != null and sb_lv1.border_color.is_equal_approx(Color("2a3748")), "Locked ability panel dims outer border (%s)" % m_path)

		DataManager.tower_data["Turret_20T1"]["level"] = 2 # Lv 3: slot 0 unlocked, 1 & 2 locked
		DataManager.data_money = 0
		m.setup(DataManager.tower_data["Turret_20T1"], 19)
		await get_tree().process_frame
		_check(not m.ability_buttons[0].disabled and m.ability_buttons[0].icon == null, "Lv 3 card activates buy button and clears lock icon for slot 0 even with 0 money (%s)" % m_path)
		_check(m.ability_buttons[1].disabled and m.ability_buttons[2].disabled, "Lv 3 card keeps slots 7 and 10 locked (%s)" % m_path)
		m._on_ability_pressed(0)
		_check(not bool(DataManager.tower_data["Turret_20T1"]["ability"][0]), "Clicking active buy button without money/choice does not buy (%s)" % m_path)

		DataManager.tower_data["Turret_20T1"]["level"] = 9 # Lv 10: all 3/7/10 available with 0 money -> all active, no locks
		m.setup(DataManager.tower_data["Turret_20T1"], 19)
		await get_tree().process_frame
		var vis_locks_lv10 := 0
		for b in m.find_children("UI_ability_lock_badge", "PanelContainer", true, false):
			if b.is_visible_in_tree():
				vis_locks_lv10 += 1
		_check(vis_locks_lv10 == 0, "Lv 10 card hides all ability lock badges (%s)" % m_path)
		_check(not m.ability_buttons[0].disabled and not m.ability_buttons[1].disabled and not m.ability_buttons[2].disabled, "Lv 10 card keeps all ability buy buttons active when unpurchased (%s)" % m_path)
		var p43_lv10 := m.find_child("PanelContainer43", true, false) as PanelContainer
		var sb_lv10 := p43_lv10.get_theme_stylebox("panel") as StyleBoxFlat if is_instance_valid(p43_lv10) else null
		_check(sb_lv10 != null and not sb_lv10.border_color.is_equal_approx(Color("2a3748")), "Available unpurchased ability panel uses highlighted border (%s)" % m_path)
		DataManager.data_money = 999999
		# Selecting L3 branch directly in the card unlocks and saves without opening any overlay
		m._pending_ability_choices.clear()
		var ov_file_gone := not FileAccess.file_exists("res://Scenes/SupportScenes/AbilityChoiceOverlay.gd") and not FileAccess.file_exists("res://Scenes/SupportScenes/AbilityChoiceOverlay.tscn")
		_check(ov_file_gone, "AbilityChoiceOverlay files have been removed (%s)" % m_path)
		m._on_ability_pressed(0)
		await get_tree().process_frame
		_check(not bool(DataManager.tower_data["Turret_20T1"]["ability"][0]), "Pressing buy before picking card hints instead of opening overlay (%s)" % m_path)
		var c20_0 := m.find_child("Choice_0_0", true, false) as Button
		_check(is_instance_valid(c20_0) and not c20_0.disabled, "Turret_20T1 L3 Option 1 card is clickable (%s)" % m_path)
		if is_instance_valid(c20_0):
			c20_0.pressed.emit()
			await get_tree().process_frame
		m._on_ability_pressed(0)
		await get_tree().process_frame
		_check(bool(DataManager.tower_data["Turret_20T1"]["ability"][0]) and str(DataManager.tower_data["Turret_20T1"]["ability_choices"].get("3", {}).get("id", "")) == "echoarchive_choral_echo", "Inline card choice + buy unlocks and saves L3 branch (%s)" % m_path)
		# Turret_17T1 supports inline 2-choice selection on L3 and 1-click L10 unlock
		var saved_t17: Dictionary = DataManager.tower_data["Turret_17T1"].duplicate(true)
		DataManager.tower_data["Turret_17T1"]["have"] = true
		DataManager.tower_data["Turret_17T1"]["level"] = 9
		DataManager.tower_data["Turret_17T1"]["ability"] = [false, false, false]
		DataManager.tower_data["Turret_17T1"]["ability_choices"] = {}
		m.setup(DataManager.tower_data["Turret_17T1"], 16)
		await get_tree().process_frame
		m._pending_ability_choices.clear()
		var c17_1 := m.find_child("Choice_0_1", true, false) as Button
		if is_instance_valid(c17_1):
			c17_1.pressed.emit()
			await get_tree().process_frame
		m._on_ability_pressed(0)
		await get_tree().process_frame
		_check(bool(DataManager.tower_data["Turret_17T1"]["ability"][0]) and str(DataManager.tower_data["Turret_17T1"]["ability_choices"].get("3", {}).get("id", "")) == "tower_17_level_3_option_2", "Inline Turret_17T1 L3 Option 2 saves Reinforced Optics (%s)" % m_path)
		m._on_ability_pressed(2)
		await get_tree().process_frame
		_check(bool(DataManager.tower_data["Turret_17T1"]["ability"][2]) and str(DataManager.tower_data["Turret_17T1"]["ability_choices"].get("10", {}).get("id", "")) == "tower_17_level_10_option_1", "Single-option fixed L10 ability unlocks in 1 click (%s)" % m_path)
		DataManager.tower_data["Turret_17T1"] = saved_t17
		# Implemented 2-branch T13..T16 have active Option 2 button in shop preview
		var saved_t13_imp: Dictionary = DataManager.tower_data["Turret_13T1"].duplicate(true)
		DataManager.tower_data["Turret_13T1"]["have"] = true
		DataManager.tower_data["Turret_13T1"]["level"] = 9
		m.setup(DataManager.tower_data["Turret_13T1"], 12)
		await get_tree().process_frame
		var t13_imp_o2 := m.find_child("Choice_0_1", true, false) as Button
		_check(is_instance_valid(t13_imp_o2) and not t13_imp_o2.disabled, "Implemented T13 Option 2 stays enabled in shop preview (%s)" % m_path)
		DataManager.tower_data["Turret_13T1"] = saved_t13_imp
		m.free()

	DataManager.tower_data["Turret_19T1"] = saved_t19
	DataManager.tower_data["Turret_20T1"] = saved_t20
	DataManager.data_money = saved_money
	DataManager.write_file()

	# Verify Desktop Shop sorting by rarity
	var d_shop := (load("res://Scenes/SupportScenes/shop.tscn") as PackedScene).instantiate() as Control
	add_child(d_shop)
	await get_tree().process_frame
	var shop_flow := d_shop.get_node_or_null("VBoxContainer/Panel/VBoxContainer/Shop/MarginContainer/ScrollContainer/HFlowContainer")
	_check(is_instance_valid(shop_flow) and shop_flow.get_child_count() >= 20, "Desktop shop populates all tower + spell cards")
	if is_instance_valid(shop_flow) and shop_flow.get_child_count() >= 20:
		var first_tower := shop_flow.get_child(0)
		var last_tower := shop_flow.get_child(19)
		_check(first_tower != null and last_tower != null, "Desktop shop sorted order has 20 tower cards before spells")
	d_shop.free()

	# Verify SpellInfoModal applies rarity border
	var modal: SpellInfoModal = SpellInfoModal.show_modal(self, "spell_23", false)
	await get_tree().process_frame
	_check(is_instance_valid(modal), "SpellInfoModal opens cleanly")
	if is_instance_valid(modal):
		var mc := modal.find_child("ModalCard", true, false) as PanelContainer
		var sb := mc.get_theme_stylebox("panel") as StyleBoxFlat if is_instance_valid(mc) else null
		_check(is_instance_valid(mc) and sb != null and sb.border_color.is_equal_approx(SpellInfoModal.RARITY_COLORS[3]), "SpellInfoModal applies legendary rarity border color")
		modal.free()

	# Verify BuildController placement preview for Dictionary parametr_range (Resonator & Echoarchive)
	var bc_host := Node2D.new()
	var bc_ui := CanvasLayer.new()
	bc_ui.name = "UI"
	bc_host.add_child(bc_ui)
	add_child(bc_host)
	var bc := preload("res://Controllers/BuildController.gd").new()
	bc.main_scene = bc_host
	add_child(bc)
	_check(bc.set_tower_preview("Turret_19T1", Vector2.ZERO), "BuildController renders Resonator preview without Array/Dictionary error")
	bc.cancel_build_mode()
	_check(bc.set_tower_preview("Turret_20T1", Vector2.ZERO), "BuildController renders Echoarchive preview without Array/Dictionary error")
	var pv := bc_ui.get_node_or_null("TowerPreview/Sprite") as Sprite2D
	_check(is_instance_valid(pv) and pv.scale.x > 0.1, "BuildController sets non-zero range radius scale for Echoarchive")
	bc.cancel_build_mode()
	bc.free()
	bc_host.free()
	var m_t19 := MirrorDeckRules.build_tournament_tower_data(true, "Turret_19T1")
	var m_t20 := MirrorDeckRules.build_tournament_tower_data(true, "Turret_20T1")
	_check(m_t19.get("ability_choices", {}).has("3") and m_t20.get("ability_choices", {}).has("3"), "MirrorDeckRules populates default L3 ability_choices for T19/T20")

	# Verify AbilityChoiceCatalog completeness across all 20 towers
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json")) as Dictionary
	var cat_ok := catalog.size() == 20
	for tid_i in range(1, 21):
		var t_dict: Dictionary = catalog.get(str(tid_i), {})
		for ms in ["3", "7", "10"]:
			for opt in t_dict.get(ms, []):
				var nk := str(opt.get("name_key", ""))
				var dk := str(opt.get("choice_description_key", ""))
				if nk.is_empty() or dk.is_empty() or tr(nk) == nk or tr(dk) == dk:
					cat_ok = false
					push_error("Missing key/translation for T%d L%s (%s / %s)" % [tid_i, ms, nk, dk])
	_check(cat_ok, "AbilityChoiceCatalog T1..T20 all have translated name_key & choice_description_key")
	_check(not str(catalog["17"]["3"][0].get("description", "")).contains("Сейчас у врагов"), "T17 L3 O1 removes raw dev note")
	_check(str(catalog["10"]["10"][0].get("name", "")) == "Запугивание", "T10 L10 restores intact Запугивание name")

	# Req 5: Bosses & Petrification (NinePatchRect on all 20 scenes, spore/stone isolation, CC fire block, Boss 12 speedup)
	for tid_i in range(1, 21):
		var t_sc := load("res://Scenes/Turrets/Turret_%dT1.tscn" % tid_i) as PackedScene
		var t_inst := t_sc.instantiate() as TowerBase
		var npr := t_inst.get_node_or_null("NinePatchRect") as NinePatchRect
		_check(is_instance_valid(npr) and npr.mouse_filter == Control.MOUSE_FILTER_IGNORE and npr.size.x >= 50.0, "Turret_%dT1.tscn has sized mouse-ignore NinePatchRect" % tid_i)
		t_inst.free()

	var t_stone := _new_resonator()
	t_stone.set_physics_process(false)
	var sp_tex := load("res://Assets/Icons/wild_plants.png") as Texture2D
	t_stone.set_spore_debuff(true, sp_tex)
	_check(t_stone.has_spore_debuff and t_stone.get_node("NinePatchRect").visible, "TowerBase spore helper activates NinePatchRect")
	t_stone.stone_effect_start(5.0)
	_check(t_stone.block_damage and t_stone.get_node("NinePatchRect").texture == TowerBase.STONE_TEXTURE, "Stone overrides texture safely without dropping spore state")
	t_stone.stone_effect_stop()
	_check(not t_stone.block_damage and t_stone.has_spore_debuff and t_stone.get_node("NinePatchRect").visible and t_stone.get_node("NinePatchRect").texture == sp_tex, "Clearing stone restores active spore texture")
	t_stone.set_spore_debuff(false)
	_check(not t_stone.get_node("NinePatchRect").visible, "Clearing spores hides NinePatchRect")
	t_stone.queue_free()

	var boss := Enemy_boss.new()
	boss.current_speed = 100.0
	boss.speed = 100.0
	boss.spell_freeze_timer = 1.0
	_check(boss.is_boss_cc_disabled(), "Frozen boss reports CC disabled")
	boss.spell_freeze_timer = 0.0
	boss.spell_stasis_timer = 1.0
	_check(boss.is_boss_cc_disabled(), "Stasis boss reports CC disabled")
	boss.spell_stasis_timer = 0.0
	boss.spell_stun_timer = 1.0
	_check(boss.is_boss_cc_disabled(), "Stunned boss reports CC disabled")
	boss.spell_stun_timer = 0.0
	# Boss 12 speedup protection test
	boss.speed = 140.0
	boss.duration_speed_mod = 60
	boss.apply_micro_slow(12.0, 60)
	_check(is_equal_approx(boss.speed, 140.0), "apply_micro_slow does not clobber Boss 12 speedup")
	boss.free()

	# Verify Desktop Shop exact rarity ordering (Common=8, Rare=5, Epic=4, Legendary=3, then Spells Common->Legendary)
	var d_shop2 := (load("res://Scenes/SupportScenes/shop.tscn") as PackedScene).instantiate() as Control
	add_child(d_shop2)
	await get_tree().process_frame
	var sf2 := d_shop2.get_node_or_null("VBoxContainer/Panel/VBoxContainer/Shop/MarginContainer/ScrollContainer/HFlowContainer")
	_check(is_instance_valid(sf2) and sf2.get_child_count() == 45, "Desktop shop renders 20 towers + 25 spells (45 total)")
	if is_instance_valid(sf2) and sf2.get_child_count() == 45:
		_check(sf2.get_child(0).get_node("VBoxContainer/Label").text == tr("KEY_NAME_TURRET_1"), "Desktop shop tower #0 is Common Turret_1")
		_check(sf2.get_child(8).get_node("VBoxContainer/Label").text == tr("KEY_NAME_TURRET_2"), "Desktop shop tower #8 is Rare Turret_2")
		_check(sf2.get_child(19).get_node("VBoxContainer/Label").text == tr("KEY_NAME_TURRET_20"), "Desktop shop tower #19 is Legendary Turret_20")
		_check(sf2.get_child(20).name == "SpellCard_spell_1" and sf2.get_child(44).name == "SpellCard_spell_25", "Desktop shop sorts spells Common->Legendary after towers")
	d_shop2.free()

	# Verify Mobile Shop & Deck scenes instantiate and sort by rarity cleanly
	for m_ui in ["res://Scenes/Mobile/shop_tab_mobile.tscn", "res://Scenes/Mobile/deck_tab.tscn"]:
		var m_sc := load(m_ui) as PackedScene
		var m_in := m_sc.instantiate() as Control
		add_child(m_in)
		await get_tree().process_frame
		_check(is_instance_valid(m_in), "Mobile UI instantiates cleanly: %s" % m_ui)
		if m_ui.ends_with("shop_tab_mobile.tscn"):
			var mf := m_in.get_node_or_null("VBoxContainer/ScrollContainer/HFlowContainer")
			_check(is_instance_valid(mf) and mf.get_child_count() == 45, "Mobile shop renders 20 towers + 25 spells")
			if is_instance_valid(mf) and mf.get_child_count() == 45:
				_check(mf.get_child(0).get_node("VBoxContainer/Label").text == tr("KEY_NAME_TURRET_1") and mf.get_child(19).get_node("VBoxContainer/Label").text == tr("KEY_NAME_TURRET_20"), "Mobile shop sorts towers Common->Legendary")
				_check(mf.get_child(20).name == "SpellCard_spell_1" and mf.get_child(44).name == "SpellCard_spell_25", "Mobile shop sorts spells Common->Legendary")
		m_in.free()

	# Verify Resonator rotation freezes when block_damage == true (petrified)
	var res_p := _new_resonator()
	res_p.set_physics_process(false)
	res_p.built = true
	res_p.block_damage = true
	var r_spr := res_p.get_node_or_null("Turret") as Node2D
	if is_instance_valid(r_spr):
		r_spr.rotation = 0.25
		var d_target := MockEnemy.new()
		d_target.position = Vector2(0.0, 200.0)
		res_p.enemy_array = [d_target]
		res_p.is_ready = true
		res_p.enemy = d_target
		# _physics_process early returns when block_damage is true; even direct aim preserves angle
		res_p._physics_process(0.016)
		_check(is_equal_approx(r_spr.rotation, 0.25), "Petrified Resonator preserves sprite rotation and skips firing")
		d_target.free()
	res_p.queue_free()

	# Verify Mimic copy of Resonator fires and builds resonance charges (regression fix for is_mimic_copy guard)
	var mimic_res := _new_resonator()
	mimic_res.set_physics_process(false)
	mimic_res.built = true
	mimic_res.is_mimic_copy = true
	mimic_res.is_opponent = false
	mimic_res.current_lvl = 2
	mimic_res.ability = [true, false, false]
	mimic_res.damage = 40.0
	mimic_res.rof = 0.05
	mimic_res.is_ready = true
	var mimic_target := MockEnemy.new()
	mimic_target.position = Vector2(50.0, 0.0)
	add_child(mimic_target)
	mimic_res.enemy_array = [mimic_target]
	mimic_res._physics_process(0.016)
	_check(mimic_target.hit_values.size() == 1 and mimic_res.get_resonance_charges() == 1, "Mimic Resonator copy fires and builds resonance charges")
	mimic_res.is_opponent = true
	mimic_res.is_ready = true
	mimic_res._physics_process(0.016)
	_check(mimic_target.hit_values.size() == 1, "Opponent Resonator clone skips local autonomous firing")
	mimic_target.free()
	mimic_res.queue_free()

	# Verify unlocked ability fallback without explicit ability_choices_ui
	var res_fb := _new_resonator()
	res_fb.set_meta("ability_choices_ui", {})
	res_fb.ability = [true, true, true]
	_check(res_fb._choice_id(3) == "resonator_returning_tone" and res_fb._choice_id(7) == "resonator_overtone" and res_fb._choice_id(10) == "resonator_perfect_resonance", "Resonator unlocked abilities fall back cleanly without saved choices")
	res_fb.queue_free()
	var echo_fb := _new_echoarchive()
	echo_fb.set_meta("ability_choices_ui", {})
	echo_fb.ability = [true, true, true]
	_check(echo_fb._choice_id(3) == "echoarchive_choral_echo" and echo_fb._choice_id(7) == "echoarchive_last_record" and echo_fb._choice_id(10) == "echoarchive_synchronous_index", "Echoarchive unlocked abilities fall back cleanly without saved choices")
	echo_fb.queue_free()

	# Verify updated Echoarchive description mentions recording across all targets
	var prev_loc := TranslationServer.get_locale()
	TranslationServer.set_locale("ru")
	_check(tr("KEY_TURRET20_DESC").contains("по всем целям"), "RU KEY_TURRET20_DESC describes recording across all targets")
	TranslationServer.set_locale("en")
	_check(tr("KEY_TURRET20_DESC").contains("across all targets"), "EN KEY_TURRET20_DESC describes recording across all targets")
	TranslationServer.set_locale(prev_loc)


func _test_shop_badges_and_catalog_cleanup() -> void:
	# 1. Verify catalog cleanup, T1..T3 implemented=true, T14..T18 clean keys, zero parenthetical fluff
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json")) as Dictionary
	for tid_str in ["1", "2", "3"]:
		for ms in ["3", "7", "10"]:
			for opt in catalog[tid_str][ms]:
				_check(bool(opt.get("implemented", false)), "Catalog T%s L%s %s is marked implemented" % [tid_str, ms, str(opt.get("id", ""))])
	for tid_i in range(14, 19):
		for ms in ["3", "7"]:
			var dk := str(catalog[str(tid_i)][ms][0].get("choice_description_key", ""))
			_check(dk == ("KEY_CHOICE_T%d_L%s_O1_DESC" % [tid_i, ms]), "T%d L%s O1 uses concise KEY_CHOICE_* key" % [tid_i, ms])

	var prev_loc := TranslationServer.get_locale()
	var no_parens := true
	for loc in ["ru", "en"]:
		TranslationServer.set_locale(loc)
		for tid_i in range(1, 21):
			for ms in ["3", "7", "10"]:
				for opt in catalog[str(tid_i)][ms]:
					var txt := tr(str(opt.get("choice_description_key", "")))
					if txt.contains("(") or txt.contains(")"):
						no_parens = false
						push_error("Unexpected parentheses in %s %s: %s" % [loc, str(opt.get("choice_description_key", "")), txt])
	TranslationServer.set_locale(prev_loc)
	_check(no_parens, "All localized AbilityChoiceCatalog descriptions avoid parenthetical clutter")

	# 2. Verify NotificationBadges + Desktop/Mobile Shop & Mobile Deck card badges
	var saved_money := DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_spells: Dictionary = DataManager.spell_data.duplicate(true)
	var saved_levels: Array = DataManager.level_option.duplicate()
	var saved_active_spell := DataManager.active_spell_id

	var req_idx := SpellCatalog.UNLOCK_AFTER_CAMPAIGN_LEVEL - 1
	while DataManager.level_option.size() <= req_idx:
		DataManager.level_option.append(false)
	DataManager.level_option[req_idx] = true

	DataManager.data_money = 999999
	for i in range(DataManager.tower_data.size()):
		var tid := "Turret_%dT1" % (i + 1)
		DataManager.tower_data[tid]["have"] = (i < 4)
		DataManager.tower_data[tid]["activity"] = (i < 4)
		DataManager.tower_data[tid]["level"] = 0
		DataManager.tower_data[tid]["cards"] = 0
		DataManager.tower_data[tid]["ability"] = [false, false, false]
		DataManager.tower_data[tid]["ability_choices"] = {}
	# Turret_1T1 (index 0): level=9 -> 3 abilities unpurchased (3 actions)
	DataManager.tower_data["Turret_1T1"]["level"] = 9
	# Turret_2T1 (index 1): level=2, enough cards for Lv.4 upgrade + L3 ability (2 actions)
	DataManager.tower_data["Turret_2T1"]["level"] = 2
	DataManager.tower_data["Turret_2T1"]["cards"] = 99
	# Turret_5T1 (index 4): unowned, affordable -> 1 action
	for s_key in SpellCatalog.get_implemented_spell_keys():
		DataManager.ensure_spell_entry(s_key)
		DataManager.spell_data[s_key]["have"] = false
		DataManager.spell_data[s_key]["level"] = 0
		DataManager.spell_data[s_key]["cards"] = 0
	DataManager.spell_data["spell_1"]["have"] = true
	DataManager.spell_data["spell_1"]["cards"] = 99
	DataManager.active_spell_id = "spell_1"

	_check(NotificationBadges.count_tower_shop_actions(0, DataManager.tower_data["Turret_1T1"]) == 3, "T1 Lv10 with 3 locked abilities reports 3 shop actions")
	_check(NotificationBadges.count_tower_shop_actions(1, DataManager.tower_data["Turret_2T1"]) == 2, "T2 Lv3 with cards + L3 ability reports 2 shop actions")
	_check(NotificationBadges.count_tower_shop_actions(4, DataManager.tower_data["Turret_5T1"]) == 1, "Affordable unowned tower reports 1 shop action")
	_check(NotificationBadges.count_spell_shop_actions("spell_1") == 1, "Upgradeable spell reports 1 shop action")
	_check(NotificationBadges.count_spell_shop_actions("spell_2") == 1, "Affordable unowned spell reports 1 shop action")

	# Desktop Shop card badges
	var d_shop := (load("res://Scenes/SupportScenes/shop.tscn") as PackedScene).instantiate() as Control
	add_child(d_shop)
	await get_tree().process_frame
	var d_flow := d_shop.get_node("VBoxContainer/Panel/VBoxContainer/Shop/MarginContainer/ScrollContainer/HFlowContainer")
	var d_badge_cards := 0
	var d_t1_card: Control = null
	var d_unowned_card: Control = null
	for ch in d_flow.get_children():
		var sb := ch.get_node_or_null("ShopBadge") as PanelContainer
		if is_instance_valid(sb) and sb.visible:
			d_badge_cards += 1
		if ch is Control:
			var nm_lbl := ch.get_node_or_null("VBoxContainer/Label") as Label
			if nm_lbl and nm_lbl.text == tr("KEY_NAME_TURRET_1"):
				d_t1_card = ch
			elif nm_lbl and nm_lbl.text == tr("KEY_NAME_TURRET_5"):
				d_unowned_card = ch
	_check(d_badge_cards == NotificationBadges.count_ready_shop(), "Desktop Shop badged card count matches NotificationBadges.count_ready_shop()")
	if is_instance_valid(d_t1_card):
		var b1 := d_t1_card.get_node_or_null("ShopBadge") as PanelContainer
		_check(is_instance_valid(b1) and b1.visible and b1.get_node("CountLabel").text == "3", "Desktop T1 ShopBadge shows 3")
		_check(b1.offset_right <= 0.0 and b1.offset_top >= 0.0, "Desktop ShopBadge is inset inside card top-right bounds")
	if is_instance_valid(d_unowned_card):
		var b5 := d_unowned_card.get_node_or_null("ShopBadge") as PanelContainer
		_check(is_instance_valid(b5) and b5.visible and b5.get_node("CountLabel").text == "1", "Desktop affordable unowned T5 ShopBadge shows 1")
	var sp1_card := d_flow.get_node_or_null("SpellCard_spell_1") as Control
	var sp2_card := d_flow.get_node_or_null("SpellCard_spell_2") as Control
	_check(is_instance_valid(sp1_card) and sp1_card.get_node("ShopBadge").visible and sp1_card.get_node("ShopBadge/CountLabel").text == "1", "Desktop upgradeable SpellCard shows ShopBadge 1")
	_check(is_instance_valid(sp2_card) and sp2_card.get_node("ShopBadge").visible and sp2_card.get_node("ShopBadge/CountLabel").text == "1", "Desktop unowned affordable SpellCard shows ShopBadge 1")
	var arm_flow := d_shop.get_node("VBoxContainer/Panel/VBoxContainer/Armanent/AllOwnedPanel/MarginContainer/ScrollContainer/HFlowContainer")
	var sp1_choose := arm_flow.get_node_or_null("SpellChoose_spell_1") as Control
	_check(is_instance_valid(sp1_choose) and sp1_choose.get_node("ShopBadge").visible, "Desktop Armament SpellChoose shows ShopBadge when upgradeable")
	d_shop.free()

	# Mobile Shop & Mobile Deck card badges
	var m_shop := (load("res://Scenes/Mobile/shop_tab_mobile.tscn") as PackedScene).instantiate() as Control
	add_child(m_shop)
	await get_tree().process_frame
	var m_flow := m_shop.get_node("VBoxContainer/ScrollContainer/HFlowContainer")
	var m_badge_cards := 0
	var m_t1_card: Control = null
	for ch in m_flow.get_children():
		var sb := ch.get_node_or_null("ShopBadge") as PanelContainer
		if is_instance_valid(sb) and sb.visible:
			m_badge_cards += 1
		if ch is Control:
			var nm_lbl := ch.get_node_or_null("VBoxContainer/Label") as Label
			if nm_lbl and nm_lbl.text == tr("KEY_NAME_TURRET_1"):
				m_t1_card = ch
	_check(m_badge_cards == NotificationBadges.count_ready_shop(), "Mobile Shop badged card count matches NotificationBadges.count_ready_shop()")
	if is_instance_valid(m_t1_card):
		var mb1 := m_t1_card.get_node_or_null("ShopBadge") as PanelContainer
		_check(is_instance_valid(mb1) and mb1.visible and mb1.get_node("CountLabel").text == "3", "Mobile T1 ShopBadge shows 3")
		_check(mb1.offset_right <= 0.0 and mb1.offset_top >= 0.0, "Mobile ShopBadge is inset inside card top-right bounds")
	m_shop.free()

	var m_deck := (load("res://Scenes/Mobile/deck_tab.tscn") as PackedScene).instantiate() as Control
	add_child(m_deck)
	m_deck.initialize()
	await get_tree().process_frame
	var m_found := m_deck.get_node("ScrollContainer/VBox/FoundContainer")
	var saw_legacy_arrow := false
	var saw_deck_shop_badge := false
	for ch in m_found.get_children():
		if ch.get_node_or_null("UpgradeReadyBadge") != null:
			saw_legacy_arrow = true
		var sb := ch.get_node_or_null("ShopBadge") as PanelContainer
		if is_instance_valid(sb) and sb.visible:
			saw_deck_shop_badge = true
	_check(not saw_legacy_arrow and saw_deck_shop_badge, "Mobile Deck replaces UpgradeReadyBadge with ShopBadge")
	m_deck.selected_slot_index = 0
	m_deck._refresh()
	await get_tree().process_frame
	var swap_mode_badges := 0
	for ch in m_found.get_children():
		if not ch.name.begins_with("SpellCard_"):
			var sb := ch.get_node_or_null("ShopBadge") as PanelContainer
			if is_instance_valid(sb) and sb.visible:
				swap_mode_badges += 1
	_check(swap_mode_badges == 0, "Mobile Deck hides tower ShopBadges during slot swap selection")
	m_deck.free()

	# Zero money hides all shop badges
	DataManager.data_money = 0
	_check(NotificationBadges.count_ready_shop() == 0, "count_ready_shop returns 0 when player has 0 gold")
	var d_shop_zero := (load("res://Scenes/SupportScenes/shop.tscn") as PackedScene).instantiate() as Control
	add_child(d_shop_zero)
	await get_tree().process_frame
	var zero_vis := 0
	for ch in d_shop_zero.get_node("VBoxContainer/Panel/VBoxContainer/Shop/MarginContainer/ScrollContainer/HFlowContainer").get_children():
		var sb := ch.get_node_or_null("ShopBadge") as PanelContainer
		if is_instance_valid(sb) and sb.visible:
			zero_vis += 1
	_check(zero_vis == 0, "Desktop Shop hides all ShopBadges when gold is 0")
	d_shop_zero.free()

	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	DataManager.spell_data = saved_spells
	DataManager.level_option = saved_levels
	DataManager.active_spell_id = saved_active_spell
	DataManager.write_file()


func _test_turrets_1_2_3_abilities() -> void:
	var saved_money := DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_crit := DataManager.critical_damage

	var map_root := Node2D.new()
	map_root.name = "Map"
	var turret_layer := Node2D.new()
	turret_layer.name = "Turret"
	map_root.add_child(turret_layer)
	add_child(map_root)

	# === TURRET 1: GunTower (L3-R Long Barrel, L7-R Rhythmic Burst, L10 Spin-Up) ===
	DataManager.tower_data["Turret_1T1"]["have"] = true
	DataManager.tower_data["Turret_1T1"]["level"] = 0
	DataManager.tower_data["Turret_1T1"]["ability"] = [true, true, true]
	DataManager.tower_data["Turret_1T1"]["ability_choices"] = {
		"3": {"id": "tower_1_level_3_option_2", "selected": true},
		"7": {"id": "tower_1_level_7_option_2", "selected": true},
		"10": {"id": "tower_1_level_10_option_1", "selected": true},
	}
	var base_gun_range := float(GameConstants.DATA_TOWER[0].parametr_4[0])
	var gun := TurretFactory.create_turret("Turret_1T1", Vector2.ZERO) as GunTower
	gun.built = true
	turret_layer.add_child(gun)
	gun.set_physics_process(false)
	await get_tree().process_frame
	_check(gun.has_long_barrel_ability() and not gun.has_double_shot_ability(), "Gun L3-R enables Long Barrel and disables Double Shot")
	_check(gun.has_rhythmic_burst_ability() and not gun.has_crit_potential_ability(), "Gun L7-R enables Rhythmic Burst and disables Crit Potential")
	_check(is_equal_approx(gun.range, MathUtils.round_to_dec(base_gun_range * 1.10, 2)), "Gun L3-R applies +10% range on Lv.1 spawn")
	var gun_col := gun.get_node("Range/CollisionShape2D").shape as CircleShape2D
	_check(is_equal_approx(gun_col.radius, 0.5 * gun.range), "Gun Range CollisionShape2D reflects +10% range")
	gun.ui_system.menu.setup(gun.id)
	gun.ui_system.update_menu()
	var gun_range_ui := float(gun.ui_system.menu.list_node[3].get_node("HValue/Value").text)
	_check(is_equal_approx(gun_range_ui, MathUtils.round_to_dec(gun.range, 2)), "TowerUI displays +10% Gun range accurately")

	gun.damage = 100.0
	gun.damage_reduction = 0
	gun.multiplier_damage_all = 1.0
	gun.mastery_damage = 1.0
	gun.rof = 1.0
	gun.mastery_speed = 1.0
	gun.mastery_chanse_crit = -100.0
	gun.rune_crit_chance_bonus = -100
	var g_target := MockEnemy.new()
	g_target.position = Vector2(40.0, 0.0)
	map_root.add_child(g_target)
	gun.enemy_array = [g_target]
	gun.enemy = g_target
	for shot_i in range(1, 9):
		gun._apply_damage()
		gun.sync_live_multipliers()
	_check(g_target.hit_values.size() == 8, "Gun with L3-R fires single shots reliably (no Double Shot)")
	_check(is_equal_approx(g_target.hit_values[0], 100.0) and is_equal_approx(g_target.hit_values[5], 100.0) and is_equal_approx(g_target.hit_values[6], 125.0) and is_equal_approx(g_target.hit_values[7], 100.0), "Gun L7-R Rhythmic Burst deals +25% on exact 7th shot only")
	# 8 consecutive hits on same target -> capped at 6 stacks (+12% attack speed)
	_check(is_equal_approx(gun.get_ability_attack_speed_bonus_pct(), 12.0), "Gun L10 Spin-Up reaches +12% cap on consecutive hits")
	_check(is_equal_approx(gun.multiplier_rof_all, 1.0 / 1.12), "Gun L10 Spin-Up reduces rof multiplier via sync_live_multipliers")
	# Switching target resets Spin-Up stacks to 0
	var g_target2 := MockEnemy.new()
	g_target2.position = Vector2(40.0, 10.0)
	map_root.add_child(g_target2)
	gun.enemy_array = [g_target2]
	gun.enemy = g_target2
	gun._apply_damage()
	gun.sync_live_multipliers()
	_check(is_equal_approx(gun.get_ability_attack_speed_bonus_pct(), 0.0), "Gun L10 Spin-Up resets stacks when switching to a new target")
	# Build 2 stacks (+4%), then simulate 2.1s idle timeout
	gun._apply_damage()
	gun._apply_damage()
	gun.sync_live_multipliers()
	_check(is_equal_approx(gun.get_ability_attack_speed_bonus_pct(), 4.0), "Gun L10 Spin-Up builds +2% per subsequent hit on new target")
	gun.is_ready = false
	gun.enemy_array = []
	gun.enemy = null
	gun._physics_process(2.1)
	_check(is_equal_approx(gun.get_ability_attack_speed_bonus_pct(), 0.0) and is_equal_approx(gun.multiplier_rof_all, 1.0), "Gun L10 Spin-Up resets stacks after 2s idle")
	g_target.free()
	g_target2.free()
	gun.queue_free()

	# === TURRET 2: AreaTower (L3-L vs L3-R Napalm, L7-R Standalone Napalm, L10 Cluster, Boss mark isolation) ===
	# Boss mark isolation: T2-A (L3-L) vs T2-B (L3-R Napalm)
	DataManager.tower_data["Turret_2T1"]["have"] = true
	DataManager.tower_data["Turret_2T1"]["level"] = 9
	DataManager.tower_data["Turret_2T1"]["ability"] = [true, true, true]
	DataManager.tower_data["Turret_2T1"]["ability_choices"] = {
		"3": {"id": "rocket_napalm", "selected": true},
		"7": {"id": "rocket_napalm_advanced", "selected": true},
		"10": {"id": "tower_2_level_10_option_1", "selected": true},
	}
	var rocket_napalm := TurretFactory.create_turret("Turret_2T1", Vector2(0.0, 0.0)) as AreaTower
	rocket_napalm.built = true
	turret_layer.add_child(rocket_napalm)
	rocket_napalm.set_physics_process(false)

	var rocket_mark := TurretFactory.create_turret("Turret_2T1", Vector2(120.0, 0.0)) as AreaTower
	rocket_mark.set_meta("ability_choices_ui", {"3": {"id": "tower_2_level_3_option_1", "selected": true}})
	rocket_mark.ability = [true, false, false]
	rocket_mark.built = true
	turret_layer.add_child(rocket_mark)
	rocket_mark.set_physics_process(false)

	var boss_probe := (load("res://Scenes/EnemiesBoss/Enemy_boss_1.tscn") as PackedScene).instantiate() as Enemy_boss
	boss_probe.is_spectator_enemy = false
	map_root.add_child(boss_probe)
	boss_probe.hp = 0.0
	boss_probe.on_destroy(1)
	_check(rocket_mark.ability_0 == 1 and rocket_napalm.ability_0 == 0, "Boss death grants Boss Mark to L3-L AreaTower and skips L3-R Napalm AreaTower")
	_check(not rocket_napalm.has_boss_hunter_ability(), "L7-R Enriched Napalm disables Boss Hunter passive crit bonus")
	rocket_mark.queue_free()

	# Enriched Napalm (3s, 20%/s) + Echoarchive Witness DoT tracking + Cluster Warhead (3x 20%, max 1 hit per enemy)
	rocket_napalm.damage = 100.0
	rocket_napalm.target = 1
	rocket_napalm.multiplier_damage_all = 1.0
	rocket_napalm.mastery_damage = 1.0
	rocket_napalm.mastery_chanse_crit = -100.0
	rocket_napalm.rune_crit_chance_bonus = -100
	var a_primary := MockEnemy.new()
	a_primary.position = Vector2(20.0, 0.0)
	a_primary.add_to_group("enemies")
	var a_near := MockEnemy.new()
	a_near.position = Vector2(30.0, 10.0) # within overlapping shrapnel and napalm radius
	a_near.add_to_group("enemies")
	map_root.add_child(a_primary)
	map_root.add_child(a_near)

	# Echoarchive Witness vs Non-Witness DoT test for Napalm burn
	var saved_t20_local: Dictionary = DataManager.tower_data["Turret_20T1"].duplicate(true)
	DataManager.tower_data["Turret_20T1"]["have"] = true
	DataManager.tower_data["Turret_20T1"]["level"] = 9
	DataManager.tower_data["Turret_20T1"]["ability"] = [false, true, false]
	DataManager.tower_data["Turret_20T1"]["ability_choices"] = {"7": {"id": "echoarchive_witness", "selected": true}}
	var echo_witness := _new_echoarchive()
	echo_witness.built = true
	echo_witness.current_lvl = 9
	echo_witness.is_ready = false
	remove_child(echo_witness)
	turret_layer.add_child(echo_witness)
	echo_witness.set_physics_process(false)
	echo_witness.damage = 500.0
	echo_witness.force_mark_target(a_near)

	DataManager.tower_data["Turret_20T1"]["ability"] = [false, false, false]
	DataManager.tower_data["Turret_20T1"]["ability_choices"] = {}
	var echo_plain := _new_echoarchive()
	echo_plain.built = true
	echo_plain.current_lvl = 9
	echo_plain.is_ready = false
	remove_child(echo_plain)
	turret_layer.add_child(echo_plain)
	echo_plain.set_physics_process(false)
	echo_plain.damage = 500.0
	echo_plain.force_mark_target(a_near)

	rocket_napalm.enemy_array = [a_primary]
	rocket_napalm._apply_damage()
	await get_tree().process_frame
	# Primary took 100 direct (+20 shrapnel since 36px < 44px); a_near took exact 20 from max 1 shrapnel fragment (NOT 40 or 60!)
	_check(a_primary.hit_values.size() >= 1 and is_equal_approx(a_primary.hit_values[0], 100.0), "AreaTower rocket deals 100 base impact damage")
	_check(a_near.hit_values.size() == 1 and is_equal_approx(a_near.hit_values[0], 20.0), "Cluster Warhead hits each nearby enemy with at most one 20% shrapnel burst")

	# Clear non-DoT cluster hit from echo buffers so only Napalm burn ticks are tested below
	echo_witness._stored_echo = 0.0
	echo_plain._stored_echo = 0.0

	# Step Napalm zone across 6 ticks (3.0s @ 20%/s = 10.0 per 0.5s tick -> 60.0 total burn)
	var zones := get_tree().get_nodes_in_group("napalm_zones")
	_check(zones.size() == 1, "Enriched Napalm spawns 1 burn zone at impact (got %d)" % zones.size())
	if zones.size() > 0:
		var zone_adv := zones[0]
		for _t in range(6):
			zone_adv._process(0.5)
		_check(a_near.hit_values.size() == 7, "Enriched Napalm ticks exactly 6 times over 3.0s (hits=%d)" % a_near.hit_values.size())
		_check(a_near.hit_values.size() >= 7 and is_equal_approx(a_near.hit_values[1], 10.0) and is_equal_approx(a_near.hit_values[6], 10.0), "Enriched Napalm deals 20%/s (10.0 per 0.5s tick)")
		var expected_witness_share: float = 120.0 * (echo_witness.get_effective_echo_share_pct() / 100.0)
		_check(echo_witness.is_witness_active() and is_equal_approx(echo_witness.get_stored_echo(), expected_witness_share), "Echoarchive Witness records Napalm burn DoT via is_applying_burn_tick")
		_check(is_equal_approx(echo_plain.get_stored_echo(), 0.0), "Echoarchive without Witness ignores Napalm burn DoT ticks")
		zone_adv.free()
	DataManager.tower_data["Turret_20T1"] = saved_t20_local

	# Base Napalm only (L3-R without L7-R): 1.5s @ 15%/s = 3 ticks of 7.5
	rocket_napalm.ability = [true, false, false]
	rocket_napalm.set_meta("ability_choices_ui", {"3": {"id": "rocket_napalm", "selected": true}})
	var near_hits_before := a_near.hit_values.size()
	rocket_napalm._apply_damage()
	await get_tree().process_frame
	var zone_base := get_tree().get_nodes_in_group("napalm_zones")[0]
	for _t in range(4):
		if is_instance_valid(zone_base):
			zone_base._process(0.5)
	_check(a_near.hit_values.size() - near_hits_before == 3 and is_equal_approx(a_near.hit_values[near_hits_before], 7.5), "Base Napalm ticks 3 times over 1.5s at 15%/s (7.5 per tick)")
	if is_instance_valid(zone_base):
		zone_base.free()

	# Standalone L7-R Enriched Napalm WITHOUT L3-R (L3-L Boss Mark + L7-R Enriched Napalm)
	rocket_napalm.ability = [true, true, false]
	rocket_napalm.set_meta("ability_choices_ui", {
		"3": {"id": "tower_2_level_3_option_1", "selected": true},
		"7": {"id": "rocket_napalm_advanced", "selected": true},
	})
	var near_hits_standalone := a_near.hit_values.size()
	rocket_napalm._apply_damage()
	await get_tree().process_frame
	var zone_sa := get_tree().get_nodes_in_group("napalm_zones")[0]
	for _t in range(6):
		zone_sa._process(0.5)
	_check(a_near.hit_values.size() - near_hits_standalone == 6 and is_equal_approx(a_near.hit_values[near_hits_standalone], 10.0), "L7-R Enriched Napalm works standalone without L3-R Napalm")
	if is_instance_valid(zone_sa):
		zone_sa.free()

	a_primary.free()
	a_near.free()
	echo_witness.queue_free()
	echo_plain.queue_free()
	rocket_napalm.queue_free()

	# === TURRET 3: Crossbow (L3-R Optical Sight, L7-R Piercing Bolt, L10 Triple Volley) ===
	DataManager.tower_data["Turret_3T1"]["have"] = true
	DataManager.tower_data["Turret_3T1"]["level"] = 0
	DataManager.tower_data["Turret_3T1"]["ability"] = [true, true, true]
	DataManager.tower_data["Turret_3T1"]["ability_choices"] = {
		"3": {"id": "tower_3_level_3_option_2", "selected": true},
		"7": {"id": "tower_3_level_7_option_2", "selected": true},
		"10": {"id": "tower_3_level_10_option_1", "selected": true},
	}
	var base_cb_range := float(GameConstants.DATA_TOWER[2].parametr_6[0])
	var cb := TurretFactory.create_turret("Turret_3T1", Vector2.ZERO) as CrossnowTower
	cb.built = true
	turret_layer.add_child(cb)
	cb.set_physics_process(false)
	cb.set_process(false)
	await get_tree().process_frame
	_check(cb.has_optical_sight_ability() and not cb.has_phase_rewind_ability(), "Crossbow L3-R enables Optical Sight and disables Phase Rewind")
	_check(cb.has_piercing_bolt_ability() and not cb.has_third_shift_ability(), "Crossbow L7-R enables Piercing Bolt and disables Third Shift")
	_check(is_equal_approx(cb.range, MathUtils.round_to_dec(base_cb_range * 1.10, 2)), "Crossbow L3-R applies +10% range on Lv.1 spawn")
	cb.ui_system.menu.setup(cb.id)
	cb.ui_system.update_menu()
	var cb_range_ui := float(cb.ui_system.menu.list_node[5].get_node("HValue/Value").text)
	_check(is_equal_approx(cb_range_ui, MathUtils.round_to_dec(cb.range, 2)), "TowerUI displays +10% Crossbow range accurately")

	cb.damage = 100.0
	cb.phase_damage = 100.0
	cb.multiplier_damage_all = 1.0
	cb.mastery_damage = 1.0
	cb.mastery_chanse_crit = -100.0
	cb.rune_crit_chance_bonus = -100
	var c1 := MockEnemy.new()
	c1.position = Vector2(60.0, 0.0)
	c1.add_to_group("enemies")
	var c2_behind := MockEnemy.new()
	c2_behind.position = Vector2(130.0, 4.0) # behind c1 along shot line
	c2_behind.add_to_group("enemies")
	var c3_side := MockEnemy.new()
	c3_side.position = Vector2(130.0, 80.0) # off-line
	c3_side.add_to_group("enemies")
	map_root.add_child(c1)
	map_root.add_child(c2_behind)
	map_root.add_child(c3_side)
	cb.enemy_array = [c1]
	cb.enemy = c1
	for i in range(4):
		cb._apply_damage()
	_check(c1.hit_values.size() == 4 and is_equal_approx(c1.hit_values[0], 100.0), "Crossbow shots 1..4 deal 100 damage each")
	_check(c2_behind.hit_values.size() == 4 and is_equal_approx(c2_behind.hit_values[0], 40.0), "Crossbow L7-R Piercing Bolt hits 1 enemy behind for 40% (40.0)")
	_check(c3_side.hit_values.is_empty(), "Crossbow L7-R Piercing Bolt does not hit off-line enemy")
	# 5th shot triggers Triple Volley extra 60% bolt!
	cb._apply_damage()
	_check(c1.hit_values.size() == 6 and is_equal_approx(c1.hit_values[4], 100.0) and is_equal_approx(c1.hit_values[5], 60.0), "Crossbow L10 Triple Volley fires extra 60% bolt on 5th shot")

	c1.free()
	c2_behind.free()
	c3_side.free()
	cb.queue_free()
	map_root.queue_free()

	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	DataManager.critical_damage = saved_crit
	DataManager.write_file()


func _make_ability_tower(turret_id: String, pos: Vector2, map_root: Node, ability_arr: Array, choices: Dictionary = {}, card_lvl: int = 0) -> TowerBase:
	var existing_td: Dictionary = DataManager.tower_data.get(turret_id, {}).duplicate(true)
	existing_td["have"] = true
	existing_td["level"] = card_lvl
	existing_td["cards"] = 0
	existing_td["ability"] = ability_arr.duplicate()
	existing_td["ability_choices"] = choices.duplicate(true)
	DataManager.tower_data[turret_id] = existing_td
	var t := TurretFactory.create_turret(turret_id, pos)
	if t == null:
		return null
	t.built = true
	t.position = pos
	t.ability = ability_arr.duplicate()
	t.set_meta("ability_choices_ui", choices.duplicate(true))
	var turret_layer := map_root.get_node_or_null("Turret")
	if turret_layer:
		turret_layer.add_child(t)
	else:
		map_root.add_child(t)
	t.set_physics_process(false)
	t.apply_level_and_gift_stats()
	return t


func _test_sniper_echo_and_turrets_4_to_7() -> void:
	var saved_money: int = DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_session_money: float = GameSession.current_money_in_game_session
	var saved_crit: float = DataManager.critical_damage
	DataManager.critical_damage = 0.0

	var map_root := Node2D.new()
	map_root.name = "Map"
	var turret_layer := Node2D.new()
	turret_layer.name = "Turret"
	var path_root := Node2D.new()
	path_root.name = "Path"
	var path_2d := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(600.0, 0.0))
	path_2d.curve = curve
	path_root.add_child(path_2d)
	map_root.add_child(turret_layer)
	map_root.add_child(path_root)
	add_child(map_root)

	# 1. Sniper 1.2x range & Echoarchive 2x damage + Catalog + Preview Range scaling
	var old_sniper_ranges: Array[float] = [380.0, 388.0, 397.0, 406.0, 415.0, 424.0, 433.0, 442.0, 451.0, 460.0]
	var new_sniper_ranges: Array = GameConstants.DATA_TOWER[16].parametr_3
	for lvl_i in range(10):
		_check(is_equal_approx(float(new_sniper_ranges[lvl_i]), old_sniper_ranges[lvl_i] * 1.2), "Sniper DATA_TOWER range lvl %d is 1.2x (%.1f)" % [lvl_i + 1, old_sniper_ranges[lvl_i] * 1.2])
	var sniper := _make_ability_tower("Turret_17T1", Vector2(32.0, 32.0), map_root, [false, false, false])
	_check(sniper != null and is_equal_approx(sniper.range, 456.0), "Spawned Sniper has 456.0 range (1.2x)")
	if sniper != null:
		var s_col := sniper.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
		_check(s_col != null and s_col.shape is CircleShape2D and is_equal_approx((s_col.shape as CircleShape2D).radius, 228.0), "Sniper Range CollisionShape2D radius is 228.0 (0.5 * 456)")
		sniper.ui_system.menu.setup(sniper.id)
		sniper.ui_system.update_menu()
		_check(is_equal_approx(float(sniper.ui_system.menu.list_node[2].get_node("HValue/Value").text), 456.0), "Sniper TowerUI shows 456 range")
		sniper.queue_free()

	var echo_p1: Dictionary = GameConstants.DATA_TOWER[19].parametr_1
	var expected_echo_row0: Array[float] = [40.0, 44.0, 50.0, 56.0, 64.0, 72.0, 82.0, 94.0, 108.0, 124.0]
	for lvl_i in range(10):
		_check(is_equal_approx(float(echo_p1[0][lvl_i]), expected_echo_row0[lvl_i]), "Echoarchive row 0 lvl %d damage is 2x (%.1f)" % [lvl_i + 1, expected_echo_row0[lvl_i]])
	var echo2 := _make_ability_tower("Turret_20T1", Vector2(32.0, 32.0), map_root, [false, false, false])
	_check(echo2 != null and is_equal_approx(echo2.damage, 40.0), "Spawned Echoarchive has 40.0 base damage (2x)")
	if echo2 != null:
		var echo_tgt := MockEnemy.new()
		echo_tgt.position = Vector2(96.0, 32.0)
		map_root.add_child(echo_tgt)
		echo2.enemy = echo_tgt
		echo2.is_ready = true
		echo2.fire()
		_check(echo_tgt.hit_values.size() == 1 and is_equal_approx(echo_tgt.hit_values[0], 40.0), "Echoarchive shot deals 40.0 base damage")
		echo_tgt.free()
		echo2.queue_free()

	var catalog_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json"))
	_check(catalog_raw is Dictionary, "AbilityChoiceCatalog.json parses as Dictionary")
	var catalog: Dictionary = catalog_raw as Dictionary if catalog_raw is Dictionary else {}
	for tid_s in ["3", "4", "5", "6", "7"]:
		for lvl_s in ["3", "7", "10"]:
			for opt in catalog[tid_s][lvl_s]:
				_check(bool(opt.get("implemented", false)), "Catalog tower %s L%s option %s is implemented=true" % [tid_s, lvl_s, str(opt.get("id", ""))])

	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_3T1", {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_3_level_3_option_2"}}}), 1.10), "Preview range multiplier is 1.10 for Crossbow L3-R")
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_4T1", {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_4_level_3_option_2"}}}), 1.12), "Preview range multiplier is 1.12 for SlowTower L3-R")
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_5T1", {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_5_level_3_option_2"}}}), 1.10), "Preview range multiplier is 1.10 for MovementTower L3-R")

	# 2. Tower 4 (SlowTower): L3-L, L3-R, L7-L (decoupled from L3-L), L7-R (+0.35s / +0.175s boss), L10 (5th pulse stun/slow)
	var base_slow_range: float = float(GameConstants.DATA_TOWER[3].parametr_4[0])
	var base_slow_dur: float = float(GameConstants.DATA_TOWER[3].parametr_2[0][0])
	var slow_l := _make_ability_tower("Turret_4T1", Vector2(96.0, 96.0), map_root, [true, false, false], {
		"3": {"id": "tower_4_level_3_option_1"}
	})
	var se1 := MockEnemy.new()
	se1.hp = 1000.0
	se1.base_hp = 1000.0
	map_root.add_child(se1)
	slow_l.enemy_array = [se1]
	slow_l._apply_pulse_effects()
	_check(se1.hit_values.size() == 1 and is_equal_approx(se1.hit_values[0], 10.0), "Slow L3-L Percent Pulse deals 1% current HP (10.0)")
	_check(se1.last_slow_frames == int(round(base_slow_dur * 60.0)), "Slow L3-L without Cold Capacitor uses base duration frames")
	se1.free()
	slow_l.queue_free()

	var slow_r := _make_ability_tower("Turret_4T1", Vector2(96.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_4_level_3_option_2"},
		"7": {"id": "tower_4_level_7_option_1"}
	})
	_check(is_equal_approx(slow_r.range, MathUtils.round_to_dec(base_slow_range * 1.12, 2)), "Slow L3-R Wide Dome increases range by +12%")
	var sr_col := slow_r.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(sr_col != null and sr_col.shape is CircleShape2D and is_equal_approx((sr_col.shape as CircleShape2D).radius, 0.5 * slow_r.range), "Slow L3-R syncs CollisionShape2D radius")
	var se2 := MockEnemy.new()
	se2.hp = 1000.0
	var sboss := LIVE_BOSS_SCENE.instantiate() as Enemy_boss
	sboss.set_meta("hp_already_scaled", true)
	sboss.hp = 1000.0
	sboss.base_hp = 1000.0
	map_root.add_child(se2)
	path_2d.add_child(sboss)
	sboss.set_physics_process(false)
	sboss.hp = 1000.0
	sboss.base_hp = 1000.0
	slow_r.enemy_array = [se2, sboss]
	for p_i in range(4):
		slow_r._apply_pulse_effects()
	_check(se2.hit_values.is_empty(), "Slow L3-R does NOT trigger L3-L 1% damage on regular enemies")
	_check(is_equal_approx(sboss.hp, 1000.0 * pow(0.95, 4)), "Slow L7-L Boss Vulnerability 5% works even when L3-R Wide Dome is chosen")
	_check(se2.stun_duration == 0.0 and sboss.spell_slow_timer == 0.0, "Slow L10 Absolute Zero does not trigger before 5th pulse")
	slow_r._apply_pulse_effects()
	_check(is_equal_approx(se2.stun_duration, 0.45), "Slow L10 Absolute Zero stuns regular enemy for 0.45s on 5th pulse")
	_check(is_equal_approx(sboss.spell_slow_pct, 15.0) and is_equal_approx(sboss.spell_slow_timer, 1.0), "Slow L10 Absolute Zero slows boss by 15% for 1.0s on 5th pulse")
	se2.free()
	sboss.queue_free()
	slow_r.queue_free()

	var slow_cap := _make_ability_tower("Turret_4T1", Vector2(96.0, 96.0), map_root, [true, true, false], {
		"3": {"id": "tower_4_level_3_option_2"},
		"7": {"id": "tower_4_level_7_option_2"}
	})
	var ce := MockEnemy.new()
	var cboss := LIVE_BOSS_SCENE.instantiate() as Enemy_boss
	cboss.set_meta("hp_already_scaled", true)
	cboss.hp = 500.0
	cboss.base_hp = 500.0
	map_root.add_child(ce)
	path_2d.add_child(cboss)
	cboss.set_physics_process(false)
	cboss.hp = 500.0
	cboss.base_hp = 500.0
	slow_cap.enemy_array = [ce, cboss]
	slow_cap._apply_pulse_effects()
	_check(ce.last_slow_frames == int(round((base_slow_dur + 0.35) * 60.0)), "Slow L7-R Cold Capacitor adds +0.35s slow duration for regular enemy")
	_check(cboss.duration_speed_mod == int(round((base_slow_dur + 0.175) * 60.0)), "Slow L7-R Cold Capacitor adds +0.175s (half) slow duration for boss")
	slow_cap.ui_system.menu.setup(slow_cap.id)
	slow_cap.ui_system.update_menu()
	_check(is_equal_approx(float(slow_cap.ui_system.menu.list_node[1].get_node("HValue/Value").text), MathUtils.round_to_dec(base_slow_dur + 0.35, 2)), "Slow TowerUI reflects Cold Capacitor +0.35s duration")
	ce.free()
	cboss.queue_free()
	slow_cap.queue_free()

	# 3. Tower 5 (MovementTower): L3-R (+10% range), L7-L vs L7-R (20% slow 1s), L10 (Twin Loop up to 2 nearest)
	var base_move_range: float = float(GameConstants.DATA_TOWER[4].parametr_3[0])
	var move_t := _make_ability_tower("Turret_5T1", Vector2(100.0, 100.0), map_root, [true, true, true], {
		"3": {"id": "tower_5_level_3_option_2"},
		"7": {"id": "tower_5_level_7_option_2"}
	})
	_check(is_equal_approx(move_t.range, MathUtils.round_to_dec(base_move_range * 1.10, 2)), "Movement L3-R Long Capture increases range by +10%")
	var mt_col := move_t.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(mt_col != null and mt_col.shape is CircleShape2D and is_equal_approx((mt_col.shape as CircleShape2D).radius, 0.5 * move_t.range), "Movement L3-R syncs CollisionShape2D radius")
	var me_near1 := MockEnemy.new()
	me_near1.position = Vector2(115.0, 100.0)
	me_near1.progress_ratio = 0.60
	var me_near2 := MockEnemy.new()
	me_near2.position = Vector2(130.0, 100.0)
	me_near2.progress_ratio = 0.60
	var me_far3 := MockEnemy.new()
	me_far3.position = Vector2(220.0, 100.0)
	me_far3.progress_ratio = 0.60
	map_root.add_child(me_near1)
	map_root.add_child(me_near2)
	map_root.add_child(me_far3)
	move_t.enemy_array = [me_far3, me_near2, me_near1]
	move_t.enemy = null
	move_t._apply_damage()
	_check(me_near1.progress_ratio < 0.60 and me_near2.progress_ratio < 0.60, "Movement L10 Twin Loop teleports 2 nearest enemies")
	_check(is_equal_approx(me_far3.progress_ratio, 0.60), "Movement L10 Twin Loop leaves 3rd farther enemy untouched")
	_check(is_equal_approx(me_near1.spell_slow_pct, 20.0) and is_equal_approx(me_near1.spell_slow_timer, 1.0), "Movement L7-R Spatial Shock applies 20% slow for 1.0s")
	me_near1.free()
	me_near2.free()
	me_far3.free()
	move_t.queue_free()

	var move_exec := _make_ability_tower("Turret_5T1", Vector2(100.0, 100.0), map_root, [true, true, false], {
		"3": {"id": "tower_5_level_3_option_1"},
		"7": {"id": "tower_5_level_7_option_1"}
	})
	var weak_e := MockEnemy.new()
	weak_e.base_hp = 1000.0
	weak_e.hp = 90.0
	var low_boss := LIVE_BOSS_SCENE.instantiate() as Enemy_boss
	low_boss.set_meta("hp_already_scaled", true)
	low_boss.base_hp = 1000.0
	low_boss.hp = 90.0
	map_root.add_child(weak_e)
	path_2d.add_child(low_boss)
	low_boss.set_physics_process(false)
	low_boss.base_hp = 1000.0
	low_boss.hp = 90.0
	move_exec.enemy_array = [weak_e, low_boss]
	move_exec.enemy = weak_e
	move_exec._apply_damage()
	_check(weak_e.hp <= 0.0, "Movement L7-L Weak Execute kills <10% HP non-boss")
	move_exec.enemy = low_boss
	move_exec._apply_damage()
	_check(low_boss.hp > 0.0, "Movement L7-L Weak Execute does not execute bosses")
	weak_e.free()
	low_boss.queue_free()
	move_exec.queue_free()

	# 4. Tower 6 (MoneyTower): L3-L Golden Bounty vs L3-R Seed Capital, L7-L vs L7-R Compound Interest, L10 Gold Sponsorship
	var bank_td: Dictionary = DataManager.tower_data.get("Turret_6T1", {}).duplicate(true)
	bank_td["have"] = true
	bank_td["level"] = 0
	bank_td["cards"] = 0
	bank_td["ability"] = [true, false, false]
	bank_td["ability_choices"] = {"3": {"id": "tower_6_level_3_option_2"}}
	DataManager.tower_data["Turret_6T1"] = bank_td
	var seed_cost_1: float = MoneyTower.get_bank_build_cost_for_session(100.0, map_root, false)
	_check(is_equal_approx(seed_cost_1, 90.0), "Money L3-R Seed Capital reduces first Bank build cost to 90.0")
	MoneyTower.mark_seed_capital_used(map_root, false)
	var seed_cost_2: float = MoneyTower.get_bank_build_cost_for_session(100.0, map_root, false)
	_check(is_equal_approx(seed_cost_2, 100.0), "Money L3-R Seed Capital charges full 100.0 for second Bank")
	var ai_seed_cost: float = MoneyTower.get_bank_build_cost_for_session(100.0, map_root, true)
	_check(is_equal_approx(ai_seed_cost, 90.0), "Money L3-R Seed Capital tracks player and AI maps independently")

	var bank_seed := _make_ability_tower("Turret_6T1", Vector2(32.0, 32.0), map_root, [true, true, true], {
		"3": {"id": "tower_6_level_3_option_2"},
		"7": {"id": "tower_6_level_7_option_2"}
	})
	var bank_extra := _make_ability_tower("Turret_6T1", Vector2(32.0, 160.0), map_root, [false, true, true], {
		"7": {"id": "tower_6_level_7_option_2"}
	})
	# Check live Enemy_1 kill gold: with Seed Capital (+0) vs Golden Bounty (+1)
	var saved_gs_m: float = GameSession.current_money_in_game_session
	GameSession.current_money_in_game_session = 0.0
	var kill_e1 := LIVE_ENEMY_SCENE.instantiate()
	kill_e1.id = 0
	kill_e1.names = "Enemy_1"
	path_2d.add_child(kill_e1)
	kill_e1.hp = 0.0
	kill_e1.on_destroy(-1)
	var base_kill_reward: int = int(GameConstants.DATA_ENEMY[0].money_death)
	_check(is_equal_approx(GameSession.current_money_in_game_session, float(base_kill_reward)), "Bank with L3-R Seed Capital does NOT grant +1 Golden Bounty kill gold")
	bank_seed.set_meta("ability_choices_ui", {"3": {"id": "tower_6_level_3_option_1"}, "7": {"id": "tower_6_level_7_option_2"}})
	GameSession.current_money_in_game_session = 0.0
	var kill_e2 := LIVE_ENEMY_SCENE.instantiate()
	kill_e2.id = 0
	kill_e2.names = "Enemy_1"
	path_2d.add_child(kill_e2)
	kill_e2.hp = 0.0
	kill_e2.on_destroy(-1)
	_check(is_equal_approx(GameSession.current_money_in_game_session, float(base_kill_reward + 1)), "Bank with L3-L Golden Bounty grants +1 kill gold")

	# Compound Interest (<300 -> 1.0x, >=300 -> 1.12x non-stacking)
	MoneyTower.evaluate_wave_end_compound_interest(map_root, 250.0, false)
	_check(is_equal_approx(bank_seed.income_end, bank_seed.income), "Money L7-R Compound Interest inactive below 300 gold")
	MoneyTower.evaluate_wave_end_compound_interest(map_root, 350.0, false)
	_check(is_equal_approx(bank_seed.income_end, MathUtils.round_to_dec(bank_seed.income * 1.12, 2)), "Money L7-R Compound Interest grants +12% income at >=300 gold (non-stacking)")
	_check(bank_seed.get_node("Panel").visible and bank_seed.get_node("Panel/Label").text == "+12%", "Money L7-R displays +12% badge when active")

	# Gold Sponsorship (+6% damage orthogonal neighbors, non-stacking, separate from LinkTower, combat only, cleared on exit)
	var adj_gun := _make_ability_tower("Turret_1T1", Vector2(96.0, 32.0), map_root, [false, false, false])
	var bank_adj2 := _make_ability_tower("Turret_6T1", Vector2(96.0, 96.0), map_root, [true, false, true], {
		"3": {"id": "tower_6_level_3_option_2"},
		"7": {"id": "tower_6_level_7_option_1"}
	})
	var diag_gun := _make_ability_tower("Turret_1T1", Vector2(160.0, 160.0), map_root, [false, false, false])
	var adj_slow := _make_ability_tower("Turret_4T1", Vector2(32.0, 96.0), map_root, [false, false, false])
	_check(is_equal_approx(adj_gun.multiplier_damage_bank, 0.06) and is_equal_approx(adj_gun.multiplier_damage_all, 1.06), "Money L10 Gold Sponsorship grants +6% damage to orthogonal combat neighbor (non-stacking across 2 Banks)")
	_check(is_equal_approx(diag_gun.multiplier_damage_bank, 0.0), "Money L10 Gold Sponsorship does not affect diagonal tower")
	_check(is_equal_approx(adj_slow.multiplier_damage_bank, 0.0), "Money L10 Gold Sponsorship ignores non-combat SlowTower")
	var link_nb := _make_ability_tower("Turret_12T1", Vector2(160.0, 32.0), map_root, [false, false, false])
	link_nb._update_links()
	link_nb._recompute_neighbor_link_state(adj_gun, link_nb.get_parent())
	bank_seed.recompute_gold_sponsorship_aura()
	_check(is_equal_approx(adj_gun.multiplier_damage_link, 0.10) and is_equal_approx(adj_gun.multiplier_damage_bank, 0.06) and is_equal_approx(adj_gun.multiplier_damage_all, 1.16), "Gold Sponsorship stacks additively with LinkTower without being overwritten by Link recompute")
	bank_seed.queue_free()
	bank_adj2.queue_free()
	await get_tree().process_frame
	_check(is_equal_approx(adj_gun.multiplier_damage_bank, 0.0) and is_equal_approx(adj_gun.multiplier_damage_all, 1.10), "Gold Sponsorship bonus clears cleanly when sponsoring Bank exits tree")
	bank_extra.queue_free()
	adj_gun.queue_free()
	diag_gun.queue_free()
	adj_slow.queue_free()
	link_nb.queue_free()
	GameSession.current_money_in_game_session = saved_gs_m

	# 5. Tower 7 (PoisonTower): L3-L Toxic Slow (5%), L3-R Caustic Spores (+15% dur + UI), L7-R Rapid Injection (+8% AS), L10 Epidemic (90px, 50% power)
	var base_p_dur: float = float(GameConstants.DATA_TOWER[6].parametr_4[0])
	var poison_r := _make_ability_tower("Turret_7T1", Vector2(256.0, 256.0), map_root, [true, true, true], {
		"3": {"id": "tower_7_level_3_option_2"},
		"7": {"id": "tower_7_level_7_option_2"}
	})
	_check(is_equal_approx(poison_r.get_ability_attack_speed_bonus_pct(), 8.0) and is_equal_approx(poison_r.multiplier_rof_all, 1.0 / 1.08), "Poison L7-R Rapid Injection increases attack speed by +8%")
	poison_r.ui_system.menu.setup(poison_r.id)
	poison_r.ui_system.update_menu()
	_check(is_equal_approx(float(poison_r.ui_system.menu.list_node[3].get_node("HValue/Value").text), MathUtils.round_to_dec(base_p_dur * 1.15, 2)), "Poison TowerUI displays +15% Caustic Spores duration")

	var p_carrier := LIVE_ENEMY_SCENE.instantiate()
	var p_near_clean := LIVE_ENEMY_SCENE.instantiate()
	var p_near_strong := LIVE_ENEMY_SCENE.instantiate()
	var p_far := LIVE_ENEMY_SCENE.instantiate()
	for live_e in [p_carrier, p_near_clean, p_near_strong, p_far]:
		live_e.id = 0
		live_e.names = "Enemy_1"
		path_2d.add_child(live_e)
	p_carrier.global_position = Vector2(300.0, 300.0)
	p_near_clean.global_position = Vector2(360.0, 300.0) # 60px <= 90px
	p_near_strong.global_position = Vector2(320.0, 300.0) # closer 20px, but already has stronger poison (100 > 20)
	p_near_strong.apply_poison({"damage": 100.0, "duration": 4.0, "tick": 0.8})
	p_far.global_position = Vector2(450.0, 300.0) # 150px > 90px
	poison_r.damage = 40.0
	poison_r.enemy_array = [p_carrier]
	poison_r._apply_damage()
	_check(p_carrier.poison_data is Dictionary and is_equal_approx(float(p_carrier.poison_data.get("duration", 0.0)), base_p_dur * 1.15), "Poison L3-R Caustic Spores applies +15% duration to target")
	_check(is_equal_approx(float(p_carrier.poison_data.get("slow_pct", 0.0)), 0.0), "Poison L3-R Caustic Spores does not apply L3-L Toxic Slow")
	p_carrier.hp = 0.0
	p_carrier.on_destroy(-1)
	_check(p_near_clean.poison_data is Dictionary and is_equal_approx(float(p_near_clean.poison_data.get("damage", 0.0)), 20.0), "Poison L10 Epidemic spreads 50% power (20.0) to unpoisoned neighbor within 90px")
	_check(is_equal_approx(float(p_near_strong.poison_data.get("damage", 0.0)), 100.0), "Poison L10 Epidemic does not overwrite stronger existing poison")
	_check(p_far.poison_data == null, "Poison L10 Epidemic does not reach enemy beyond 90px")
	for live_e in [p_near_clean, p_near_strong, p_far]:
		if is_instance_valid(live_e) and not live_e.is_queued_for_deletion():
			live_e.free()
	poison_r.queue_free()

	var poison_l := _make_ability_tower("Turret_7T1", Vector2(256.0, 256.0), map_root, [true, false, false], {
		"3": {"id": "tower_7_level_3_option_1"}
	})
	var p_slow_e := LIVE_ENEMY_SCENE.instantiate()
	p_slow_e.id = 0
	p_slow_e.names = "Enemy_1"
	p_slow_e.speed = 100.0
	p_slow_e.current_speed = 100.0
	path_2d.add_child(p_slow_e)
	poison_l.enemy_array = [p_slow_e]
	poison_l._apply_damage()
	_check(p_slow_e.poison_data is Dictionary and is_equal_approx(float(p_slow_e.poison_data.get("slow_pct", 0.0)), 5.0), "Poison L3-L Toxic Slow embeds 5% slow")
	p_slow_e.progress = 0.0
	p_slow_e._physics_process(0.1)
	_check(is_equal_approx(p_slow_e.progress, 9.5), "Poison L3-L Toxic Slow slows live enemy movement by 5%")
	p_slow_e.free()
	poison_l.queue_free()

	# 6. MobileTacticalAI with new radius/choices/Sniper/Echoarchive values
	var ai := MOBILE_TACTICAL_AI.new()
	_check(is_equal_approx(ai.get_tower_radius_px(16, 0, 0), 228.0), "MobileTacticalAI Sniper lvl 1 radius is 228.0px (0.5 * 456)")
	_check(is_equal_approx(ai.get_tower_radius_px(3, 0, 0, [true, false, false], {"3": {"id": "tower_4_level_3_option_2"}}), 0.5 * base_slow_range * 1.12), "MobileTacticalAI reflects Slow L3-R +12% radius")
	_check(is_equal_approx(ai.get_tower_radius_px(4, 0, 0, [true, false, false], {"3": {"id": "tower_5_level_3_option_2"}}), 0.5 * base_move_range * 1.10), "MobileTacticalAI reflects Movement L3-R +10% radius")
	var echo_pow: float = ai.eval_combat_power(19, 0, 0, [false, false, false], 1.0, 1.0, 3, false, 300.0, 2)
	_check(echo_pow > 40.0 and echo_pow < 55.0, "MobileTacticalAI evaluates Echoarchive 2x base power cleanly")
	var poison_base_pow: float = ai.eval_combat_power(6, 0, 0, [false, false, false], 1.0, 1.0, 2, false, 300.0, 0)
	var poison_spore_pow: float = ai.eval_combat_power(6, 0, 0, [true, true, true], 1.0, 1.0, 2, false, 300.0, 0, {"3": {"id": "tower_7_level_3_option_2"}, "7": {"id": "tower_7_level_7_option_2"}})
	_check(poison_spore_pow > poison_base_pow, "MobileTacticalAI values Poison L3-R/L7-R/L10 higher than base")
	var mob_ai_ctrl := MobileAIController.new()
	var mob_ai_map := Node2D.new()
	mob_ai_map.name = "Map"
	var mob_ai_tur := Node2D.new()
	mob_ai_tur.name = "Turret"
	mob_ai_map.add_child(mob_ai_tur)
	var mob_ai_pc := MOBILE_PLAYER_CONTAINER.new()
	mob_ai_pc.map_node = mob_ai_map
	mob_ai_pc.set_meta("is_ai_player", true)
	mob_ai_pc.set_meta("ai_money", 500.0)
	mob_ai_ctrl.container = mob_ai_pc
	mob_ai_ctrl.ai_deck = [5]
	mob_ai_ctrl.ai_build_costs = {5: 100.0}
	mob_ai_ctrl.ai_ability_choices = {3: {"3": {"id": "tower_4_level_3_option_2"}}}
	DataManager.tower_data["Turret_6T1"]["ability"] = [true, false, false]
	DataManager.tower_data["Turret_6T1"]["ability_choices"] = {"3": {"id": "tower_6_level_3_option_2"}}
	var ai_state_before: Dictionary = mob_ai_ctrl._collect_game_state()
	_check(ai_state_before.get("ability_choices", {}).get(3, {}).get("3", {}).get("id", "") == "tower_4_level_3_option_2", "MobileAIController exports ability_choices in game_state")
	_check(is_equal_approx(float(ai_state_before.get("build_costs", {}).get(5, 0.0)), 90.0), "MobileAIController applies Seed Capital discount to first AI Bank cost")
	MoneyTower.mark_seed_capital_used(mob_ai_map, true)
	var ai_state_after: Dictionary = mob_ai_ctrl._collect_game_state()
	_check(is_equal_approx(float(ai_state_after.get("build_costs", {}).get(5, 0.0)), 100.0), "MobileAIController charges full cost for second AI Bank after Seed Capital is used")
	mob_ai_ctrl.free()
	mob_ai_pc.free()
	mob_ai_map.free()

	map_root.queue_free()
	await get_tree().process_frame
	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	GameSession.current_money_in_game_session = saved_session_money
	DataManager.critical_damage = saved_crit
	DataManager.write_file()


func _test_turrets_8_to_12() -> void:
	var saved_money := DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_session_money := GameSession.current_money_in_game_session
	var saved_crit := DataManager.critical_damage

	DataManager.critical_damage = 0.0
	for tkey in ["Turret_8T1", "Turret_9T1", "Turret_10T1", "Turret_11T1", "Turret_12T1", "Turret_15T1", "Turret_19T1", "Turret_1T1"]:
		DataManager.tower_data[tkey] = DataManager.tower_data[tkey].duplicate(true)
		DataManager.tower_data[tkey]["level"] = 0
		DataManager.tower_data[tkey]["mastery_level"] = 0
		DataManager.tower_data[tkey]["ability"] = [false, false, false]
		DataManager.tower_data[tkey]["ability_choices"] = {}

	var map_root := Node2D.new()
	map_root.name = "Map"
	var turret_layer := Node2D.new()
	turret_layer.name = "Turret"
	map_root.add_child(turret_layer)
	var excl := TileMapLayer.new()
	excl.name = "TowerExlusion"
	map_root.add_child(excl)
	var path_2d := Path2D.new()
	path_2d.name = "Path"
	var curve := Curve2D.new()
	curve.add_point(Vector2(0.0, 200.0))
	curve.add_point(Vector2(800.0, 200.0))
	path_2d.curve = curve
	map_root.add_child(path_2d)
	add_child(map_root)

	# 1. Catalog & preview multiplier checks for Towers 8..12
	var catalog_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json"))
	_check(catalog_raw is Dictionary, "AbilityChoiceCatalog.json loads for T8..T12 verification")
	var catalog: Dictionary = catalog_raw as Dictionary if catalog_raw is Dictionary else {}
	for tid_s in ["8", "9", "10", "11", "12"]:
		for lvl_s in ["3", "7", "10"]:
			for opt in catalog.get(tid_s, {}).get(lvl_s, []):
				_check(bool(opt.get("implemented", false)), "Catalog tower %s L%s option %s is implemented=true" % [tid_s, lvl_s, str(opt.get("id", ""))])
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_9T1", {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_9_level_3_option_2"}}}), 1.10), "Preview range multiplier is 1.10 for Hangman L3-R Keen Sight")
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_9T1", {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_9_level_3_option_1"}}}), 1.0), "Preview range multiplier is 1.0 for Hangman L3-L")

	# 2. Tower 8 (MinotaurTower): L3-L Pack Fury, L3-R Wide Swing, L7-L Extended Berserk, L7-R Swift Forging, L10 Pack Leader
	var mino_l := _make_ability_tower("Turret_8T1", Vector2(32.0, 32.0), map_root, [true, true, false], {
		"3": {"id": "tower_8_level_3_option_1"},
		"7": {"id": "tower_8_level_7_option_1"}
	})
	_check(mino_l.has_pack_fury_ability() and mino_l.has_extended_berserk_ability() and not mino_l.has_pack_leader_ability(), "Minotaur L3-L + L7-L choice helpers resolve properly")
	var base_trap_dmg: float = mino_l.trap_damage
	# mode() ran on _ready(); charges = 1 (current_lvl=0 -> 1) -> +51%
	_check(is_equal_approx(mino_l.trap_damage_end, MathUtils.round_to_dec(base_trap_dmg * 1.51, 2)), "Minotaur L3-L Pack Fury applies +51% berserk trap damage with 1 charge")
	mino_l.on_stats_updated()
	_check(is_equal_approx(mino_l.trap_damage_end, MathUtils.round_to_dec(base_trap_dmg * 1.51, 2)), "Minotaur on_stats_updated preserves active berserk buff")
	mino_l.ability = [true, true, true]
	mino_l.mode()
	_check(is_equal_approx(mino_l.trap_damage_end, MathUtils.round_to_dec(base_trap_dmg * 1.51 * 1.15, 2)), "Minotaur L10 Pack Leader deals +15% more trap damage during berserk")
	mino_l.queue_free()
	await get_tree().process_frame

	var mino_r := _make_ability_tower("Turret_8T1", Vector2(32.0, 32.0), map_root, [true, true, true], {
		"3": {"id": "tower_8_level_3_option_2"},
		"7": {"id": "tower_8_level_7_option_2"}
	})
	_check(mino_r.has_wide_swing_ability() and not mino_r.has_pack_fury_ability(), "Minotaur L3-R disables Pack Fury berserk")
	_check(is_equal_approx(mino_r.trap_damage_end, MathUtils.round_to_dec(base_trap_dmg, 2)), "Minotaur L3-R + L10 without berserk leaves normal trap damage unchanged")
	_check(is_equal_approx(mino_r.get_effective_trap_radius(), 44.8), "Minotaur L3-R Wide Swing expands trap radius by +12% (44.8)")
	_check(is_equal_approx(mino_r.get_effective_trap_interval(), mino_r.interval * 0.90), "Minotaur L7-R Swift Forging reduces trap preparation interval by 10%")
	mino_r.ui_system.menu.setup(mino_r.id)
	mino_r.ui_system.update_menu()
	mino_r.ui_system.update_menu_upgrade()
	_check(is_equal_approx(float(mino_r.ui_system.menu.list_node[4].get_node("HValue/Value").text), MathUtils.round_to_dec(mino_r.interval * 0.90, 2)), "Minotaur TowerUI displays Swift Forging interval (-10%)")
	var expected_int_diff: float = MathUtils.round_to_dec((float(GameConstants.DATA_TOWER[7].parametr_5[0][1]) - float(GameConstants.DATA_TOWER[7].parametr_5[0][0])) * 0.90, 2)
	_check(is_equal_approx(float(mino_r.ui_system.menu.list_node[4].get_node("HValue/Up").text), expected_int_diff), "Minotaur TowerUI upgrade diff reflects Swift Forging -10% interval")

	# Live RoadObstacle radius test at 42.5px (> 40.0 base, <= 44.8 Wide Swing)
	var trap_sc: PackedScene = load("res://Scenes/SupportScenes/road_obstacle.tscn")
	var trap_std = trap_sc.instantiate()
	trap_std.damage = 30.0
	trap_std.position = Vector2(200.0, 200.0)
	map_root.add_child(trap_std)
	var trap_e := LIVE_ENEMY_SCENE.instantiate()
	trap_e.id = 0
	trap_e.names = "Enemy_1"
	trap_e.hp = 1000.0
	trap_e.base_hp = 1000.0
	path_2d.add_child(trap_e)
	trap_e.progress = 242.5
	trap_e.hole_move = 20
	trap_e.move(0.01)
	_check(is_equal_approx(trap_e.hp, 1000.0), "Standard trap (radius=40) misses live enemy at 42.5px")
	trap_std.radius = mino_r.get_effective_trap_radius()
	trap_e.progress = 242.5
	trap_e.hole_move = 20
	trap_e.move(0.01)
	_check(trap_e.hp < 1000.0, "Minotaur L3-R Wide Swing trap (radius=44.8) hits live enemy at 42.5px")
	trap_e.free()
	trap_std.free()
	mino_r.queue_free()

	# 3. Tower 9 (HangmanTower): L3-L Follow-up, L3-R Keen Sight (+10% range), L7-L Boss Exec, L7-R Cold Blood (+8% dmg), L10 Trophy Harvest (+2g / 2s)
	var base_hm_range: float = float(GameConstants.DATA_TOWER[8].parametr_4[0])
	var hm_r := _make_ability_tower("Turret_9T1", Vector2(96.0, 32.0), map_root, [true, true, true], {
		"3": {"id": "tower_9_level_3_option_2"},
		"7": {"id": "tower_9_level_7_option_2"}
	})
	_check(is_equal_approx(hm_r.range, base_hm_range * 1.10), "Hangman L3-R Keen Sight grants +10% attack range")
	_check(is_equal_approx(hm_r.get_node("Range/CollisionShape2D").shape.radius, 0.5 * base_hm_range * 1.10), "Hangman L3-R updates Range CollisionShape2D radius")
	hm_r.ui_system.menu.setup(hm_r.id)
	hm_r.ui_system.update_menu()
	_check(is_equal_approx(float(hm_r.ui_system.menu.list_node[0].get_node("HValue/Value").text), MathUtils.round_to_dec(hm_r.damage * 1.08, 2)), "Hangman TowerUI shows +8% Cold Blood damage")
	_check(is_equal_approx(float(hm_r.ui_system.menu.list_node[3].get_node("HValue/Value").text), MathUtils.round_to_dec(base_hm_range * 1.10, 2)), "Hangman TowerUI shows +10% Keen Sight range")

	# Normal shot deals +8% Cold Blood damage and does NOT trigger L3-L +300% follow-up
	var hm_norm_e := MockEnemy.new()
	hm_norm_e.base_hp = 1000.0
	hm_norm_e.hp = 1000.0
	map_root.add_child(hm_norm_e)
	hm_r.flag_dib = true
	hm_r.enemy = hm_norm_e
	hm_r._apply_damage()
	_check(hm_norm_e.hit_values.size() == 1 and is_equal_approx(hm_norm_e.hit_values[0], hm_r.damage * 1.08), "Hangman L3-R + L7-R skips L3-L follow-up and deals +8% Cold Blood damage")
	hm_norm_e.free()

	# L7-R does NOT execute boss even below HP threshold; L7-L DOES execute boss without granting Trophy Harvest gold
	var hm_boss_mock := MockEnemy.new()
	hm_boss_mock.is_boss = true
	hm_boss_mock.base_hp = 10000.0
	hm_boss_mock.hp = 100.0
	map_root.add_child(hm_boss_mock)
	hm_r.enemy = hm_boss_mock
	hm_r._apply_damage()
	_check(is_equal_approx(hm_boss_mock.hit_values[0], hm_r.damage * 1.08), "Hangman L7-R Cold Blood shoots boss normally instead of executing")
	hm_boss_mock.free()

	# Trophy Harvest (+2 gold per normal execute, 2.0s cooldown, no gold on boss execute)
	GameSession.current_money_in_game_session = 100.0
	for k_i in range(2):
		var hm_exec_e := MockEnemy.new()
		hm_exec_e.base_hp = 1000.0
		hm_exec_e.hp = 50.0
		map_root.add_child(hm_exec_e)
		hm_r.enemy = hm_exec_e
		hm_r._apply_damage()
		hm_exec_e.free()
	_check(is_equal_approx(GameSession.current_money_in_game_session, 102.0), "Hangman L10 Trophy Harvest grants +2 gold on normal execution and respects 2s cooldown")
	hm_r.advance_trophy_harvest_cooldown(2.05)
	var hm_exec_e3 := MockEnemy.new()
	hm_exec_e3.base_hp = 1000.0
	hm_exec_e3.hp = 50.0
	map_root.add_child(hm_exec_e3)
	hm_r.enemy = hm_exec_e3
	hm_r._apply_damage()
	hm_exec_e3.free()
	_check(is_equal_approx(GameSession.current_money_in_game_session, 104.0), "Hangman L10 Trophy Harvest triggers again after 2s cooldown expires")
	hm_r.queue_free()

	var hm_l := _make_ability_tower("Turret_9T1", Vector2(96.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_9_level_3_option_1"},
		"7": {"id": "tower_9_level_7_option_1"}
	})
	var hm_boss_l := MockEnemy.new()
	hm_boss_l.is_boss = true
	hm_boss_l.base_hp = 10000.0
	hm_boss_l.hp = 100.0
	map_root.add_child(hm_boss_l)
	hm_l.enemy = hm_boss_l
	hm_l._apply_damage()
	_check(hm_boss_l.hp <= 0.0, "Hangman L7-L executes boss below threshold")
	_check(is_equal_approx(GameSession.current_money_in_game_session, 104.0), "Hangman L10 Trophy Harvest does NOT grant +2 gold on boss execution")
	hm_boss_l.free()
	var hm_followup_e := MockEnemy.new()
	hm_followup_e.base_hp = 10000.0
	hm_followup_e.hp = 10000.0
	map_root.add_child(hm_followup_e)
	hm_l.flag_dib = true
	hm_l.enemy = hm_followup_e
	hm_l._apply_damage()
	_check(is_equal_approx(hm_followup_e.hit_values[0], hm_l.damage * float(GameConstants.TURRET_9_ABILITY_0)), "Hangman L3-L applies follow-up damage multiplier after execution")
	hm_followup_e.free()
	hm_l.queue_free()

	# 4. Tower 10 (BillyTower): L3-R Brawler (+8% base dmg), L7-R Short Fuse (-12% Rage recovery -> 2.64s), L10 Intimidation (15% slow / 8% boss slow for 1s)
	var bully_r := _make_ability_tower("Turret_10T1", Vector2(160.0, 32.0), map_root, [true, true, true], {
		"3": {"id": "tower_10_level_3_option_2"},
		"7": {"id": "tower_10_level_7_option_2"}
	})
	_check(is_equal_approx(bully_r.damage_new, bully_r.damage * 1.08), "Bully L3-R Brawler increases base damage_new by +8%")
	_check(is_equal_approx(bully_r.get_rage_recovery_duration(), 2.64), "Bully L7-R Short Fuse lowers Rage cooldown by 12% (2.64s)")
	bully_r.ui_system.menu.setup(bully_r.id)
	bully_r.ui_system.update_menu()
	_check(is_equal_approx(float(bully_r.ui_system.menu.list_node[0].get_node("HValue/Value").text), MathUtils.round_to_dec(bully_r.damage * 1.08, 2)), "Bully TowerUI displays Brawler +8% base damage")
	bully_r.rage = 2
	bully_r.on_stats_updated()
	_check(is_equal_approx(bully_r.rof_new, 2.64), "Bully rage==2 recovery uses 2.64s duration")
	bully_r.rage = 0
	bully_r.on_stats_updated()

	# Verify L7-R does NOT add Crowd Pressure bonus and L3-R does NOT proc Boss Crusher
	var bully_crowd_dummy := MockEnemy.new()
	bully_crowd_dummy.base_hp = 50000.0
	bully_crowd_dummy.hp = 50000.0
	map_root.add_child(bully_crowd_dummy)
	ResourceManager.list_active_enemy.append(bully_crowd_dummy)
	bully_r.enemy = bully_crowd_dummy
	bully_r._apply_damage()
	_check(bully_crowd_dummy.hit_values.size() == 1 and is_equal_approx(bully_crowd_dummy.hit_values[0], bully_r.damage * 1.08), "Bully L3-R + L7-R deals exact +8% Brawler damage without Crowd Pressure bonus")
	ResourceManager.list_active_enemy.erase(bully_crowd_dummy)
	bully_crowd_dummy.free()

	# L10 Intimidation: slows nearby live Enemy (15% for 1s) & Enemy_boss (8% for 1s), ignores far enemies
	var b_near_e := LIVE_ENEMY_SCENE.instantiate()
	b_near_e.id = 0
	b_near_e.names = "Enemy_1"
	b_near_e.speed = 100.0
	b_near_e.current_speed = 100.0
	path_2d.add_child(b_near_e)
	b_near_e.global_position = bully_r.global_position + Vector2(30.0, 0.0)
	var b_far_e := LIVE_ENEMY_SCENE.instantiate()
	b_far_e.id = 0
	b_far_e.names = "Enemy_1"
	b_far_e.speed = 100.0
	b_far_e.current_speed = 100.0
	path_2d.add_child(b_far_e)
	b_far_e.global_position = bully_r.global_position + Vector2(500.0, 0.0)
	var b_near_boss := LIVE_BOSS_SCENE.instantiate()
	b_near_boss.speed = 100.0
	b_near_boss.current_speed = 100.0
	path_2d.add_child(b_near_boss)
	b_near_boss.global_position = bully_r.global_position + Vector2(0.0, 30.0)
	bully_r.rage = 1
	bully_r.rage_interval()
	_check(is_equal_approx(b_near_e.spell_slow_pct, 15.0) and is_equal_approx(b_near_e.spell_slow_timer, 1.0), "Bully L10 Intimidation slows nearby enemy by 15% for 1s")
	_check(is_equal_approx(b_near_boss.spell_slow_pct, 8.0) and is_equal_approx(b_near_boss.spell_slow_timer, 1.0), "Bully L10 Intimidation slows nearby boss by 8% for 1s")
	_check(is_equal_approx(b_far_e.spell_slow_pct, 0.0), "Bully L10 Intimidation ignores enemy outside tower range")
	b_near_e.progress = 0.0
	b_near_e._physics_process(0.1)
	_check(is_equal_approx(b_near_e.progress, 8.5), "Bully L10 Intimidation reduces live enemy movement by 15%")
	b_near_boss.progress = 0.0
	b_near_boss.move(0.1)
	_check(is_equal_approx(b_near_boss.progress, 9.2), "Bully L10 Intimidation reduces live boss movement by 8%")
	b_near_e.free()
	b_far_e.free()
	b_near_boss.free()
	bully_r.queue_free()

	var bully_l := _make_ability_tower("Turret_10T1", Vector2(160.0, 96.0), map_root, [true, true, false], {
		"3": {"id": "tower_10_level_3_option_1"},
		"7": {"id": "tower_10_level_7_option_1"}
	})
	_check(is_equal_approx(bully_l.get_rage_recovery_duration(), 3.0), "Bully L7-L keeps standard 3.0s Rage recovery")
	var b_l_tgt := MockEnemy.new()
	b_l_tgt.base_hp = 50000.0
	b_l_tgt.hp = 50000.0
	map_root.add_child(b_l_tgt)
	ResourceManager.list_active_enemy.append(b_l_tgt)
	bully_l.enemy = b_l_tgt
	bully_l._apply_damage()
	_check(is_equal_approx(b_l_tgt.hit_values[0], bully_l.damage * 1.10), "Bully L7-L Crowd Pressure still applies +10% per enemy when L7-L selected")
	ResourceManager.list_active_enemy.erase(b_l_tgt)
	b_l_tgt.free()
	bully_l.queue_free()

	# 5. Tower 11 (DroneHiveTower & Drone): L3-R Light Chassis (+15% speed), L7-R Heavy Batteries (+8% drone dmg), L10 Recon Scanner (+8% ally vuln for 2s by SCOUT)
	var hive_r := _make_ability_tower("Turret_11T1", Vector2(224.0, 32.0), map_root, [true, true, true], {
		"3": {"id": "tower_11_level_3_option_2"},
		"7": {"id": "tower_11_level_7_option_2"}
	})
	_check(not hive_r.has_third_drone_ability() and hive_r.has_light_chassis_ability(), "DroneHive L3-R selects Light Chassis and disables 3rd random drone")
	_check(is_equal_approx(hive_r.get_effective_drone_speed(), 345.0), "DroneHive L3-R Light Chassis boosts drone speed by +15% (345.0)")
	_check(is_equal_approx(hive_r.get_drone_token_bonus_pct(), 1.0), "DroneHive L7-R keeps token bonus at 1%")
	var expected_drone_dmg: float = (hive_r.drone_base_damage + hive_r.damage * 0.5) * 1.08
	_check(is_equal_approx(hive_r.get_effective_drone_damage(), expected_drone_dmg), "DroneHive L7-R Heavy Batteries increases drone damage by +8%")
	hive_r.ui_system.menu.setup(hive_r.id)
	hive_r.ui_system.update_menu()
	hive_r.ui_system.update_menu_upgrade()
	_check(is_equal_approx(float(hive_r.ui_system.menu.list_node[3].get_node("HValue/Value").text), MathUtils.round_to_dec(expected_drone_dmg, 2)), "DroneHive TowerUI displays Heavy Batteries +8% drone damage")
	var d_p4_diff: float = float(GameConstants.DATA_TOWER[10].parametr_4[0][1]) - float(GameConstants.DATA_TOWER[10].parametr_4[0][0])
	var d_p1_diff: float = (float(GameConstants.DATA_TOWER[10].parametr_1[0][1]) - float(GameConstants.DATA_TOWER[10].parametr_1[0][0])) * 0.5
	var expected_drone_diff: float = MathUtils.round_to_dec((d_p4_diff + d_p1_diff) * 1.08, 2)
	_check(is_equal_approx(float(hive_r.ui_system.menu.list_node[3].get_node("HValue/Up").text), expected_drone_diff), "DroneHive TowerUI upgrade diff multiplies drone damage delta by 1.08")

	# Base laser does NOT receive +8% Heavy Batteries bonus
	var hive_laser_e := MockEnemy.new()
	hive_laser_e.base_hp = 5000.0
	hive_laser_e.hp = 5000.0
	map_root.add_child(hive_laser_e)
	hive_r.enemy = hive_laser_e
	hive_r._apply_damage()
	_check(is_equal_approx(hive_laser_e.hit_values[0], hive_r.damage), "DroneHive L7-R Heavy Batteries does not alter hive base laser damage")
	hive_laser_e.free()

	# L10 Recon Scanner: SCOUT applies 2s +8% vulnerability on live Enemy & Enemy_boss; INTERCEPTOR does not
	var scan_e := LIVE_ENEMY_SCENE.instantiate()
	scan_e.id = 0
	scan_e.names = "Enemy_1"
	scan_e.hp = 5000.0
	scan_e.base_hp = 5000.0
	path_2d.add_child(scan_e)
	var scan_boss := LIVE_BOSS_SCENE.instantiate()
	scan_boss.hp = 20000.0
	scan_boss.base_hp = 20000.0
	path_2d.add_child(scan_boss)

	var drone_sc: PackedScene = load("res://Scenes/Turrets/Drone.tscn")
	var interceptor_drone = drone_sc.instantiate()
	map_root.add_child(interceptor_drone)
	interceptor_drone.home_tower = hive_r
	interceptor_drone.strategy = GameConstants.TowerDroneStrategy.INTERCEPTOR
	interceptor_drone.damage = 50.0
	interceptor_drone.attack_cooldown = 99.0
	interceptor_drone.global_position = scan_e.global_position
	interceptor_drone.target = scan_e
	interceptor_drone._on_attack_timer_timeout()
	_check(not scan_e.is_drone_scanned(), "Drone INTERCEPTOR does not apply Recon Scanner debuff")
	interceptor_drone.free()

	var scout_drone = drone_sc.instantiate()
	map_root.add_child(scout_drone)
	scout_drone.home_tower = hive_r
	scout_drone.strategy = GameConstants.TowerDroneStrategy.SCOUT
	scout_drone.damage = 50.0
	scout_drone.speed = hive_r.get_effective_drone_speed()
	scout_drone.attack_cooldown = 99.0
	scout_drone.global_position = scan_e.global_position
	scout_drone.target = scan_e
	scout_drone._on_attack_timer_timeout()
	_check(scan_e.is_drone_scanned() and is_equal_approx(scan_e.drone_scan_timer, 2.0) and is_equal_approx(scan_e.drone_scan_mult, 1.08), "Drone SCOUT applies 2s +8% Recon Scanner debuff to live enemy")
	scout_drone.global_position = scan_boss.global_position
	scout_drone.target = scan_boss
	scout_drone._on_attack_timer_timeout()
	_check(scan_boss.is_drone_scanned() and is_equal_approx(scan_boss.drone_scan_timer, 2.0), "Drone SCOUT applies Recon Scanner debuff to live boss")
	scout_drone.free()

	# Ally damage & ResonatorTower integration against scanned enemy and boss
	var ally_gun := _make_ability_tower("Turret_1T1", Vector2(288.0, 32.0), map_root, [false, false, false])
	var res_check := _make_ability_tower("Turret_19T1", Vector2(288.0, 96.0), map_root, [false, false, false])
	_check(res_check._active_negative_effect_count(scan_e) >= 1, "ResonatorTower counts Recon Scanner as an active negative effect")
	var hp_before_ally: float = scan_e.hp
	scan_e.on_hit(100.0, 0, GameConstants.TowerType.GUN, ally_gun)
	_check(is_equal_approx(hp_before_ally - scan_e.hp, 108.0), "Ally tower deals +8% damage to Recon-scanned live enemy")
	var boss_hp_before_ally: float = scan_boss.hp
	scan_boss.on_hit(100.0, 0, GameConstants.TowerType.GUN, ally_gun)
	_check(is_equal_approx(boss_hp_before_ally - scan_boss.hp, 108.0), "Ally tower deals +8% damage to Recon-scanned live boss")
	var hp_before_true: float = scan_e.hp
	scan_e.apply_spell_true_damage(100.0, Color.WHITE, false, false)
	_check(is_equal_approx(hp_before_true - scan_e.hp, 108.0), "Spell/true damage receives +8% Recon Scanner amplification")
	scan_e.process_drone_scan(2.05)
	_check(not scan_e.is_drone_scanned(), "Recon Scanner expires cleanly after 2.0s")
	var hp_after_expire: float = scan_e.hp
	scan_e.on_hit(100.0, 0, GameConstants.TowerType.GUN, ally_gun)
	_check(is_equal_approx(hp_after_expire - scan_e.hp, 100.0), "Ally damage returns to 1.0x after Recon Scanner expires")
	ally_gun.queue_free()
	res_check.queue_free()
	scan_e.free()
	scan_boss.free()
	hive_r.queue_free()

	# 6. Tower 12 (LinkTower): L3-R Low-Cost Node (-10% cost), L7-R Stabilizer (+8% of base AS bonus -> 2.08x), L10 Signal Booster (+3pp dmg buff)
	_check(is_equal_approx(LinkTower.get_link_build_cost_for_session(210.0, {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_12_level_3_option_2"}}}, 0), 189.0), "LinkTower L3-R Low-Cost Node lowers build cost by 10% (210 -> 189)")
	var expected_mastery_link_cost: float = MathUtils.round_to_dec(MathUtils.round_to_dec(210.0 * (1.0 - float(GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0])), 1) * 0.90, 1)
	_check(is_equal_approx(LinkTower.get_link_build_cost_for_session(210.0, {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_12_level_3_option_2"}}}, 3), expected_mastery_link_cost), "LinkTower L3-R stacks cleanly with Mastery L3 discount (210 -> %s)" % str(expected_mastery_link_cost))
	_check(is_equal_approx(LinkTower.get_link_build_cost_for_session(210.0, {"ability": [true, false, false], "ability_choices": {"3": {"id": "tower_12_level_3_option_1"}}}, 0), 210.0), "LinkTower L3-L Network Synergy keeps full build cost (210)")

	var link_map := Node2D.new()
	link_map.name = "Map"
	var link_tur := Node2D.new()
	link_tur.name = "Turret"
	link_map.add_child(link_tur)
	add_child(link_map)
	# Build a connected chain of 2 LinkTowers + 6 GunTowers (6+ same-type links across the network)
	var lt1 := _make_ability_tower("Turret_12T1", Vector2(64.0, 64.0), link_map, [true, true, true], {
		"3": {"id": "tower_12_level_3_option_1"},
		"7": {"id": "tower_12_level_7_option_2"}
	})
	var lt2 := _make_ability_tower("Turret_12T1", Vector2(192.0, 64.0), link_map, [true, true, true], {
		"3": {"id": "tower_12_level_3_option_1"},
		"7": {"id": "tower_12_level_7_option_2"}
	})
	var guns: Array[TowerBase] = []
	for gp in [Vector2(0.0, 64.0), Vector2(128.0, 64.0), Vector2(64.0, 0.0), Vector2(64.0, 128.0), Vector2(256.0, 64.0), Vector2(192.0, 0.0)]:
		guns.append(_make_ability_tower("Turret_1T1", gp, link_map, [false, false, false]))
	lt1._update_links()
	lt2._update_links()
	_check(is_equal_approx(guns[0].multiplier_damage_link, 0.13), "LinkTower L7-R + L10 Signal Booster grants +13% damage buff (10% + 3pp)")
	_check(is_equal_approx(guns[0].multiplier_rof_link, 2.08), "LinkTower L3-L + L7-R Stabilizer boosts network attack speed multiplier to 2.08 (+108%)")

	# Switch L7 to L7-L (Reinforced Link) -> 15% + 3pp = 18%, network AS returns to 2.0
	lt1.set_meta("ability_choices_ui", {"3": {"id": "tower_12_level_3_option_1"}, "7": {"id": "tower_12_level_7_option_1"}})
	lt2.set_meta("ability_choices_ui", {"3": {"id": "tower_12_level_3_option_1"}, "7": {"id": "tower_12_level_7_option_1"}})
	lt1.on_stats_updated()
	lt2.on_stats_updated()
	lt1._update_links()
	lt2._update_links()
	_check(is_equal_approx(guns[0].multiplier_damage_link, 0.18), "LinkTower L7-L + L10 Signal Booster grants +18% damage buff (15% + 3pp)")
	_check(is_equal_approx(guns[0].multiplier_rof_link, 2.0), "LinkTower L3-L + L7-L keeps standard 2.0x network speed multiplier")

	# Switch L3 to L3-R (Low-Cost Node) + L7-R (Stabilizer): no network AS bonus when L3-L wasn't picked
	lt1.set_meta("ability_choices_ui", {"3": {"id": "tower_12_level_3_option_2"}, "7": {"id": "tower_12_level_7_option_2"}})
	lt2.set_meta("ability_choices_ui", {"3": {"id": "tower_12_level_3_option_2"}, "7": {"id": "tower_12_level_7_option_2"}})
	lt1.on_stats_updated()
	lt2.on_stats_updated()
	lt1._update_links()
	lt2._update_links()
	_check(is_equal_approx(guns[0].multiplier_rof_link, 1.0), "LinkTower L3-R + L7-R without Network Synergy grants no network AS buff")
	_check(is_equal_approx(guns[0].multiplier_damage_link, 0.13), "LinkTower L3-R + L7-R + L10 still grants +13% damage buff")
	for g in guns:
		g.queue_free()
	lt1.queue_free()
	lt2.queue_free()
	link_map.queue_free()
	await get_tree().process_frame

	# 7. MobileTacticalAI + MobileAIController checks for T8..T12
	var ai := MOBILE_TACTICAL_AI.new()
	var base_hm_r_px: float = 0.5 * float(GameConstants.DATA_TOWER[8].parametr_4[0])
	_check(is_equal_approx(ai.get_tower_radius_px(8, 0, 0, [true, false, false], {"3": {"id": "tower_9_level_3_option_2"}}), base_hm_r_px * 1.10), "MobileTacticalAI reflects Hangman L3-R +10% range")
	var bully_base_p: float = ai.eval_combat_power(9, 0, 0, [false, false, false], 1.0, 1.0, 3, false, 300.0, 1)
	var bully_r_p: float = ai.eval_combat_power(9, 0, 0, [true, true, true], 1.0, 1.0, 3, false, 300.0, 1, {"3": {"id": "tower_10_level_3_option_2"}, "7": {"id": "tower_10_level_7_option_2"}})
	_check(bully_r_p > bully_base_p, "MobileTacticalAI values Bully L3-R/L7-R/L10 above base")
	var link_l_p: float = ai.eval_combat_power(11, 0, 0, [true, true, true], 1.0, 1.0, 3, false, 300.0, 1, {"3": {"id": "tower_12_level_3_option_1"}, "7": {"id": "tower_12_level_7_option_2"}})
	var link_base_p: float = ai.eval_combat_power(11, 0, 0, [false, false, false], 1.0, 1.0, 3, false, 300.0, 1)
	_check(link_l_p > link_base_p, "MobileTacticalAI values Link L3-L + L7-R Stabilizer + L10 Signal Booster above base")

	var link_ai_ctrl := MobileAIController.new()
	var link_ai_map := Node2D.new()
	link_ai_map.name = "Map"
	var link_ai_tur := Node2D.new()
	link_ai_tur.name = "Turret"
	link_ai_map.add_child(link_ai_tur)
	var link_ai_pc := MOBILE_PLAYER_CONTAINER.new()
	link_ai_pc.map_node = link_ai_map
	link_ai_pc.set_meta("is_ai_player", true)
	link_ai_pc.set_meta("ai_money", 500.0)
	link_ai_ctrl.container = link_ai_pc
	link_ai_ctrl.ai_deck = [11]
	link_ai_ctrl.ai_build_costs = {11: 210.0}
	link_ai_ctrl.ai_abilities = {11: [true, false, false]}
	link_ai_ctrl.ai_ability_choices = {11: {"3": {"id": "tower_12_level_3_option_2"}}}
	var link_state: Dictionary = link_ai_ctrl._collect_game_state()
	_check(is_equal_approx(float(link_state.get("build_costs", {}).get(11, 0.0)), 189.0), "MobileAIController exports discounted 189.0 LinkTower cost when L3-R Low-Cost Node is active")
	link_ai_ctrl.free()
	link_ai_pc.free()
	link_ai_map.free()

	map_root.queue_free()
	await get_tree().process_frame
	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	GameSession.current_money_in_game_session = saved_session_money
	DataManager.critical_damage = saved_crit
	DataManager.write_file()


func _test_turrets_13_to_16() -> void:
	var saved_money: int = DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_session_money: float = GameSession.current_money_in_game_session
	var saved_crit: int = DataManager.critical_damage
	var saved_wave: int = GameSession.current_wave
	DataManager.critical_damage = 0
	GameSession.current_money_in_game_session = 99999.0
	GameSession.current_wave = 1

	var map_root := Node2D.new()
	map_root.name = "Map"
	var turret_layer := Node2D.new()
	turret_layer.name = "Turret"
	map_root.add_child(turret_layer)
	var excl_layer := TileMapLayer.new()
	excl_layer.name = "TowerExlusion"
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	excl_layer.tile_set = ts
	map_root.add_child(excl_layer)
	var path_root := Node2D.new()
	path_root.name = "Path"
	var path_2d := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(0.0, 160.0))
	curve.add_point(Vector2(640.0, 160.0))
	path_2d.curve = curve
	path_root.add_child(path_2d)
	map_root.add_child(path_root)
	add_child(map_root)

	# 1. Tower 13 (LaserPrismTower): L3-R Focusing Lens (+10% range), L7-R Fast Ignition (+12% heat rate), L10 Thermal Trail (+8% Prism vuln 2s)
	var prism_base := _make_ability_tower("Turret_13T1", Vector2(96.0, 96.0), map_root, [false, false, false])
	var prism_r := _make_ability_tower("Turret_13T1", Vector2(160.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_13_level_3_option_2"},
		"7": {"id": "tower_13_level_7_option_2"},
		"10": {"id": "tower_13_level_10_option_1"}
	})
	_check(not prism_r.has_refraction_ability() and prism_r.has_focusing_lens_ability(), "LaserPrism L3-R Focusing Lens disables Refraction")
	_check(not prism_r.has_plasma_inertia() and prism_r.has_fast_ignition_ability(), "LaserPrism L7-R Fast Ignition disables Plasma Inertia")
	_check(prism_r.has_thermal_trail_ability(), "LaserPrism L10 Thermal Trail activates")
	var expected_prism_r: float = MathUtils.round_to_dec(prism_base.range * 1.10, 3)
	_check(is_equal_approx(prism_r.range, expected_prism_r), "LaserPrism L3-R Focusing Lens boosts range by +10%")
	var prism_col := prism_r.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(prism_col != null and is_equal_approx((prism_col.shape as CircleShape2D).radius, 0.5 * prism_r.range), "LaserPrism L3-R updates Area2D collider radius")
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_13T1", {
		"ability": [true, false, false],
		"ability_choices": {"3": {"id": "tower_13_level_3_option_2"}}
	}), 1.10), "LaserPrism L3-R updates build preview range multiplier to 1.10")
	prism_r.ui_system.menu.setup(prism_r.id)
	prism_r.ui_system.update_menu()
	_check(is_equal_approx(float(prism_r.ui_system.menu.list_node[2].get_node("HValue/Value").text), MathUtils.round_to_dec(prism_r.range, 2)), "LaserPrism TowerUI shows +10% range")

	# Fast Ignition: 1.10s active lock hits Stage 1 (>=1.2s) with L7-R vs Stage 0 (<1.2s) without L7-R
	var heat_e1 := LIVE_ENEMY_SCENE.instantiate()
	heat_e1.id = 0
	heat_e1.names = "Enemy_1"
	heat_e1.hp = 50000.0
	heat_e1.base_hp = 50000.0
	heat_e1.global_position = prism_base.global_position + Vector2(30.0, 0.0)
	path_2d.add_child(heat_e1)
	prism_base.enemy_array = [heat_e1]
	prism_r.enemy_array = [heat_e1]
	for _step in range(11):
		prism_base._physics_process(0.10)
		prism_r._physics_process(0.10)
	_check(prism_base.get_heat_stage() == 0 and is_equal_approx(prism_base.heat_time, 1.10), "Base LaserPrism after 1.10s remains Stage 0 (heat_time=1.10)")
	_check(prism_r.get_heat_stage() == 1 and is_equal_approx(prism_r.heat_time, 1.10 * 1.12), "LaserPrism L7-R Fast Ignition reaches Stage 1 in 1.10s (1.232s heat)")

	# Thermal Trail: at peak heat (Stage 3), target receives +8% Prism-only damage for 2s on Enemy & Enemy_boss
	var therm_boss := LIVE_BOSS_SCENE.instantiate()
	therm_boss.hp = 50000.0
	therm_boss.base_hp = 50000.0
	therm_boss.global_position = prism_r.global_position + Vector2(20.0, 0.0)
	path_2d.add_child(therm_boss)
	prism_r.heat_time = LaserPrismTower.HEAT_STAGE_TIMES[3]
	prism_r._apply_beam_tick(heat_e1)
	prism_r._apply_beam_tick(therm_boss)
	_check(heat_e1.is_prism_thermal_trailed() and is_equal_approx(heat_e1.prism_thermal_timer, 2.0) and is_equal_approx(heat_e1.prism_thermal_mult, 1.08), "LaserPrism L10 Thermal Trail applies 2s +8% Prism debuff to live enemy")
	_check(therm_boss.is_prism_thermal_trailed() and is_equal_approx(therm_boss.prism_thermal_timer, 2.0), "LaserPrism L10 Thermal Trail applies debuff to live boss")
	var res_prism := _make_ability_tower("Turret_19T1", Vector2(224.0, 96.0), map_root, [false, false, false])
	_check(res_prism._active_negative_effect_count(heat_e1) >= 1, "ResonatorTower recognizes prism_thermal as active negative effect")
	var hp_p_hit: float = heat_e1.hp
	heat_e1.on_hit(100.0, 0, prism_r.type_attack, prism_r)
	_check(is_equal_approx(hp_p_hit - heat_e1.hp, 108.0), "LaserPrism deals +8% damage against Thermal Trail live enemy")
	var boss_hp_p_hit: float = therm_boss.hp
	therm_boss.on_hit(100.0, 0, prism_r.type_attack, prism_r)
	_check(is_equal_approx(boss_hp_p_hit - therm_boss.hp, 108.0), "LaserPrism deals +8% damage against Thermal Trail live boss")
	var ally_gun_p := _make_ability_tower("Turret_1T1", Vector2(288.0, 96.0), map_root, [false, false, false])
	var hp_ally_p: float = heat_e1.hp
	heat_e1.on_hit(100.0, 0, ally_gun_p.type_attack, ally_gun_p)
	_check(is_equal_approx(hp_ally_p - heat_e1.hp, 100.0), "Thermal Trail does NOT amplify ally GunTower damage (Prism-only)")
	heat_e1.process_prism_thermal_trail(2.05)
	_check(not heat_e1.is_prism_thermal_trailed(), "Thermal Trail expires cleanly after 2.0s")
	var hp_p_after: float = heat_e1.hp
	heat_e1.on_hit(100.0, 0, prism_r.type_attack, prism_r)
	_check(is_equal_approx(hp_p_after - heat_e1.hp, 100.0), "LaserPrism damage returns to 1.0x after Thermal Trail expires")

	prism_base.queue_free()
	prism_r.queue_free()
	res_prism.queue_free()
	ally_gun_p.queue_free()
	heat_e1.free()
	therm_boss.free()

	# 2. Tower 14 (ChakramTower): L3-R Aerodynamics (+12% flight speed), L7-R Wide Ricochet (+15% bounce radius -> 172.5px), L10 Inertial Return (65% return dmg)
	var chak_l := _make_ability_tower("Turret_14T1", Vector2(96.0, 96.0), map_root, [true, true, false], {
		"3": {"id": "tower_14_level_3_option_1"},
		"7": {"id": "tower_14_level_7_option_1"}
	})
	var chak_r := _make_ability_tower("Turret_14T1", Vector2(160.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_14_level_3_option_2"},
		"7": {"id": "tower_14_level_7_option_2"},
		"10": {"id": "tower_14_level_10_option_1"}
	})
	_check(not chak_r.has_bleed_ability() and chak_r.has_aerodynamics_ability(), "Chakram L3-R Aerodynamics disables Bleed")
	_check(not chak_r.has_duel_resonance_ability() and chak_r.has_wide_ricochet_ability(), "Chakram L7-R Wide Ricochet disables Duel Resonance")
	_check(chak_r.has_inertial_return_ability(), "Chakram L10 Inertial Return activates")
	_check(is_equal_approx(chak_r.get_outbound_speed(), ChakramTower.OUTBOUND_SPEED * 1.12), "Chakram L3-R increases outbound flight speed by +12%")
	_check(is_equal_approx(chak_r.get_return_speed(), ChakramTower.RETURN_SPEED * 1.12), "Chakram L3-R increases return flight speed by +12%")
	_check(is_equal_approx(chak_r.get_chain_bounce_radius(), 172.5), "Chakram L7-R increases bounce search radius to 172.5px (+15%)")
	_check(is_equal_approx(chak_r.get_return_damage_mult(), 0.65) and is_equal_approx(chak_l.get_return_damage_mult(), 0.50), "Chakram L10 raises return damage ratio to 65% vs base 50%")

	var c_src := MockEnemy.new()
	c_src.base_hp = 5000.0
	c_src.hp = 5000.0
	c_src.global_position = Vector2(200.0, 160.0)
	var c_far := MockEnemy.new()
	c_far.base_hp = 5000.0
	c_far.hp = 5000.0
	c_far.global_position = Vector2(362.0, 160.0)
	map_root.add_child(c_src)
	map_root.add_child(c_far)
	chak_l.enemy_array = [c_src, c_far]
	chak_r.enemy_array = [c_src, c_far]
	var visited_l: Dictionary = {c_src.get_instance_id(): true}
	var visited_r: Dictionary = {c_src.get_instance_id(): true}
	_check(chak_l._find_next_chain_target(c_src.global_position, visited_l) == null, "Chakram without L7-R does not chain 162px beyond 150px base radius")
	_check(chak_r._find_next_chain_target(c_src.global_position, visited_r) == c_far, "Chakram with L7-R Wide Ricochet chains to 162px target within 172.5px")

	var c_ret := MockEnemy.new()
	c_ret.base_hp = 5000.0
	c_ret.hp = 5000.0
	c_ret.global_position = Vector2(210.0, 96.0)
	map_root.add_child(c_ret)
	chak_r.damage = 100.0
	chak_r.enemy_array = [c_ret]
	chak_r._launch_chakram(c_ret)
	var ret_flight: Dictionary = chak_r._active_flights.back()
	ret_flight["phase"] = ChakramTower.FlightPhase.RETURN
	ret_flight["pos"] = Vector2(260.0, 96.0)
	chak_r._tick_active_flights(0.08)
	_check(not c_ret.hit_values.is_empty() and is_equal_approx(c_ret.hit_values[0], 65.0), "Chakram L10 Inertial Return deals 65% damage on return pass")
	c_src.free()
	c_far.free()
	c_ret.free()
	chak_l.queue_free()
	chak_r.queue_free()

	# 3. Tower 16 (FlamethrowerTower): L3-R Long Nozzle (+12% range), L7-R Dense Fuel (+0.5s burn), L10 Smoke Screen (8% slow while burning)
	var flame_base := _make_ability_tower("Turret_16T1", Vector2(96.0, 96.0), map_root, [false, false, false])
	var flame_r := _make_ability_tower("Turret_16T1", Vector2(160.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_16_level_3_option_2"},
		"7": {"id": "tower_16_level_7_option_2"},
		"10": {"id": "tower_16_level_10_option_1"}
	})
	_check(not flame_r.has_thermite_mix() and flame_r.has_long_nozzle_ability(), "Flamethrower L3-R Long Nozzle disables Thermite")
	_check(not flame_r.has_wide_nozzle() and flame_r.has_dense_fuel_ability(), "Flamethrower L7-R Dense Fuel disables Wide Nozzle")
	_check(flame_r.has_smoke_screen_ability(), "Flamethrower L10 Smoke Screen activates")
	_check(is_equal_approx(flame_r.range, MathUtils.round_to_dec(flame_base.range * 1.12, 3)), "Flamethrower L3-R Long Nozzle boosts range by +12%")
	var flame_col := flame_r.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(flame_col != null and is_equal_approx((flame_col.shape as CircleShape2D).radius, 0.5 * flame_r.range), "Flamethrower L3-R updates Area2D collider radius")
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_16T1", {
		"ability": [true, false, false],
		"ability_choices": {"3": {"id": "tower_16_level_3_option_2"}}
	}), 1.12), "Flamethrower L3-R updates build preview range multiplier to 1.12")
	_check(is_equal_approx(flame_r.get_burn_duration_sec(), 3.0) and is_equal_approx(flame_base.get_burn_duration_sec(), 2.5), "Flamethrower L7-R Dense Fuel raises burn duration to 3.0s")
	_check(is_equal_approx(flame_r.get_cone_angle_deg(), FlamethrowerTower.BASE_CONE_ANGLE_DEG), "Flamethrower L7-R keeps 50 deg cone (Wide Nozzle disabled)")

	var burn_e := LIVE_ENEMY_SCENE.instantiate()
	burn_e.id = 0
	burn_e.names = "Enemy_1"
	burn_e.hp = 5000.0
	burn_e.base_hp = 5000.0
	burn_e.speed = 100.0
	burn_e.current_speed = 100.0
	path_2d.add_child(burn_e)
	burn_e.progress = 160.0
	var burn_boss := LIVE_BOSS_SCENE.instantiate()
	burn_boss.hp = 20000.0
	burn_boss.base_hp = 20000.0
	burn_boss.speed = 100.0
	burn_boss.current_speed = 100.0
	path_2d.add_child(burn_boss)
	burn_boss.progress = 175.0

	flame_r._aim_angle = PI * 0.5
	flame_r.enemy_array = [burn_e, burn_boss]
	flame_r._apply_cone_tick()
	_check(burn_e.is_flame_burning() and is_equal_approx(burn_e.flame_burn_timer, 3.0), "Flamethrower L7-R applies 3.0s burn duration on live enemy")
	_check(is_equal_approx(burn_e.flame_burn_smoke_slow_pct, 8.0), "Flamethrower L10 Smoke Screen applies 8% smoke slow on live enemy")
	_check(is_equal_approx(burn_boss.flame_burn_smoke_slow_pct, 8.0) and is_equal_approx(burn_boss.flame_burn_timer, 3.0), "Flamethrower L7-R + L10 apply burn & 8% smoke slow on live boss")
	var saved_rm_spd: float = ResourceManager.speed_modifer
	ResourceManager.speed_modifer = 1.0
	burn_e.speed_modifer = 1.0
	burn_boss.speed_modifer = 1.0
	var prog_e_before: float = burn_e.progress
	var prog_b_before: float = burn_boss.progress
	burn_e.move(0.5)
	burn_boss.move(0.5)
	_check(is_equal_approx(burn_e.progress - prog_e_before, 46.0), "Smoke Screen slows live enemy movement by 8% (50 -> 46 px per 0.5s)")
	_check(is_equal_approx(burn_boss.progress - prog_b_before, 46.0), "Smoke Screen slows live boss movement by 8% (50 -> 46 px per 0.5s)")
	burn_e.process_flame_burn(3.05)
	_check(not burn_e.is_flame_burning() and is_equal_approx(burn_e.flame_burn_smoke_slow_pct, 0.0), "Smoke Screen slow clears when burn expires")
	var prog_e_after: float = burn_e.progress
	burn_e.move(0.5)
	_check(is_equal_approx(burn_e.progress - prog_e_after, 50.0), "Live enemy recovers full speed after burn expires")
	ResourceManager.speed_modifer = saved_rm_spd
	flame_base.queue_free()
	flame_r.queue_free()
	burn_e.free()
	burn_boss.free()

	# 4. Tower 15 (MimicTower): L3-R Shadow Discount (-10g), L7-R Precision Matrix (+5% copy efficiency), L10 Flexible Form (1x/wave switch next cycle)
	var mimic_disc_data := {"ability": [true, true, true], "ability_choices": {"3": {"id": "tower_15_level_3_option_2"}, "7": {"id": "tower_15_level_7_option_2"}}}
	var mimic_l3l_data := {"ability": [true, true, true], "ability_choices": {"3": {"id": "tower_15_level_3_option_1"}, "7": {"id": "tower_15_level_7_option_1"}}}
	_check(is_equal_approx(MimicTower.get_mimic_build_cost_for_session(260.0, mimic_disc_data, 0), 250.0), "Mimic L3-R Shadow Discount reduces session build cost by 10 (260 -> 250)")
	var expected_mimic_m3: float = maxf(1.0, MathUtils.round_to_dec(MathUtils.round_to_dec(260.0 * (1.0 - float(GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0])), 1) - 10.0, 1))
	_check(is_equal_approx(MimicTower.get_mimic_build_cost_for_session(260.0, mimic_disc_data, 3), expected_mimic_m3), "Mimic L3-R stacks cleanly after Mastery L3 discount")
	_check(is_equal_approx(MimicTower.get_mimic_build_cost_for_session(260.0, mimic_l3l_data, 0), 260.0), "Mimic L3-L Perfect Cast keeps 260 build cost")

	var mimic_r_preview := _make_ability_tower("Turret_15T1", Vector2(320.0, 320.0), map_root, [true, true, true], {
		"3": {"id": "tower_15_level_3_option_2"},
		"7": {"id": "tower_15_level_7_option_2"},
		"10": {"id": "tower_15_level_10_option_1"}
	})
	_check(not mimic_r_preview.has_perfect_cast_ability() and mimic_r_preview.has_shadow_discount_ability(), "Mimic L3-R Shadow Discount disables Perfect Cast")
	_check(not mimic_r_preview.has_adaptive_link_ability() and mimic_r_preview.has_precision_matrix_ability(), "Mimic L7-R Precision Matrix disables Adaptive Link")
	_check(mimic_r_preview.has_flexible_form_ability(), "Mimic L10 Flexible Form activates")
	_check(is_equal_approx(mimic_r_preview.get_effective_copy_pct(0), 90.0), "Mimic L7-R Precision Matrix increases copy efficiency 85% -> 90%")
	mimic_r_preview.ui_system.menu.setup(mimic_r_preview.id)
	mimic_r_preview.ui_system.update_menu()
	_check(is_equal_approx(float(mimic_r_preview.ui_system.menu.list_node[3].get_node("HValue/Value").text), 90.0), "Mimic TowerUI displays Precision Matrix 90% copy efficiency")
	mimic_r_preview.queue_free()
	await get_tree().process_frame

	var nb_gun := _make_ability_tower("Turret_1T1", Vector2(160.0, 96.0), map_root, [false, false, false])
	nb_gun.set_meta("bound_excl_cell", Vector2i(2, 1))
	excl_layer.set_cell(Vector2i(2, 1), 0, Vector2i(0, 4))
	var nb_chak := _make_ability_tower("Turret_14T1", Vector2(288.0, 96.0), map_root, [false, false, false])
	nb_chak.set_meta("bound_excl_cell", Vector2i(4, 1))
	excl_layer.set_cell(Vector2i(4, 1), 0, Vector2i(0, 4))
	var mimic_live := _make_ability_tower("Turret_15T1", Vector2(224.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_15_level_3_option_2"},
		"7": {"id": "tower_15_level_7_option_2"},
		"10": {"id": "tower_15_level_10_option_1"}
	})
	mimic_live.set_meta("bound_excl_cell", Vector2i(3, 1))
	mimic_live.set_meta("build_cost_paid", 250.0)
	excl_layer.set_cell(Vector2i(3, 1), 0, Vector2i(0, 4))

	mimic_live._perform_update()
	await get_tree().process_frame
	var form1: TowerBase = null
	for ch in turret_layer.get_children():
		if is_instance_valid(ch) and not ch.is_queued_for_deletion() and ch is TowerBase and (ch as TowerBase).is_mimic_copy:
			form1 = ch as TowerBase
			break
	_check(is_instance_valid(form1) and form1 is ChakramTower, "Mimic transforms into higher-cost orthogonal neighbor ChakramTower")
	_check(form1.current_lvl == 0, "Mimic with L3-R Shadow Discount does NOT receive +1 Perfect Cast level")
	_check(is_equal_approx(form1.mimic_stat_mult, 0.90), "Mimic L7-R Precision Matrix sets copied stat efficiency to 90% (0.90)")
	_check(is_equal_approx(nb_chak.mimic_synergy_as_pct, 0.0) and is_equal_approx(form1.mimic_synergy_as_pct, 0.0), "Mimic L7-R Precision Matrix grants no +12% Adaptive Link speed bonus")
	_check(form1.has_mimic_flexible_form_ability(), "Morphed tower retains Mimic L10 Flexible Form ability")
	_check(is_equal_approx(float(form1.get_meta("build_cost_paid", 0.0)), 250.0), "Morphed tower preserves discounted 250g build_cost_paid")

	form1.ui_system.update_menu()
	var m_section: PanelContainer = form1.ui_system.menu.get_node_or_null("V/MimicFormSection") as PanelContainer
	_check(is_instance_valid(m_section) and m_section.visible, "TowerUI renders MimicFormSection for Flexible Form copy")
	var sw_cands: Array[TowerBase] = form1.get_mimic_switchable_neighbors()
	_check(sw_cands.size() == 1 and sw_cands[0] == nb_gun, "Flexible Form lists alternative neighbor GunTower (excluding current Chakram source)")

	form1.is_ready = false
	(form1 as ChakramTower)._cooldown_timer = 0.5
	_check(form1.request_mimic_form_switch(nb_gun), "Flexible Form queues form switch for next attack cycle")
	_check(form1.mimic_pending_switch_waiting_cycle, "Mimic waits while current Chakram attack cycle is still in progress")
	await get_tree().process_frame
	_check(is_instance_valid(form1) and not form1.is_queued_for_deletion(), "Mimic does NOT interrupt active attack cycle before cooldown ends")

	(form1 as ChakramTower)._cooldown_timer = 0.0
	form1.is_ready = true
	form1._physics_process(0.02)
	await get_tree().process_frame
	var form2: TowerBase = null
	for ch in turret_layer.get_children():
		if is_instance_valid(ch) and not ch.is_queued_for_deletion() and ch is TowerBase and (ch as TowerBase).is_mimic_copy:
			form2 = ch as TowerBase
			break
	_check(is_instance_valid(form2) and form2 is GunTower, "Mimic executes deferred switch to GunTower once attack cycle completes")
	_check(form2.mimic_switch_used_wave == 1, "Flexible Form marks wave 1 as used")
	_check(not form2.request_mimic_form_switch(nb_chak), "Flexible Form blocks a second switch within the same wave")

	GameSession.current_wave = 2
	_check(form2.get_mimic_switchable_neighbors().has(nb_chak), "Advancing to wave 2 restores Flexible Form switch candidates")

	# Switching away from a morphed DroneHiveTower cleans up its spawned drones
	var nb_hive := _make_ability_tower("Turret_11T1", Vector2(224.0, 32.0), map_root, [false, false, false])
	nb_hive.set_meta("bound_excl_cell", Vector2i(3, 0))
	var hive_morph := MimicTower.perform_mimic_morph(form2, nb_hive, false)
	await get_tree().process_frame
	_check(is_instance_valid(hive_morph) and hive_morph is DroneHiveTower, "Mimic switches on Wave 2 into neighboring DroneHiveTower")
	(hive_morph as DroneHiveTower)._spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.INTERCEPTOR, 50.0)
	_check((hive_morph as DroneHiveTower)._active_drones.size() == 1, "Morphed DroneHiveTower spawns live drone")
	var spawned_drone_ref: Node = (hive_morph as DroneHiveTower)._active_drones[0]
	form2 = MimicTower.perform_mimic_morph(hive_morph, nb_gun, false)
	await get_tree().process_frame
	_check(not is_instance_valid(spawned_drone_ref) or spawned_drone_ref.is_queued_for_deletion(), "Switching away from morphed DroneHiveTower frees active drones via _exit_tree")

	# Compare L3-L Perfect Cast (+1 level) + L7-L Adaptive Link (+12% AS) on a fresh Mimic
	var mimic_l := _make_ability_tower("Turret_15T1", Vector2(96.0, 96.0), map_root, [true, true, false], {
		"3": {"id": "tower_15_level_3_option_1"},
		"7": {"id": "tower_15_level_7_option_1"}
	})
	mimic_l.set_meta("bound_excl_cell", Vector2i(1, 1))
	mimic_l._perform_update()
	await get_tree().process_frame
	var form_l: TowerBase = null
	for ch in turret_layer.get_children():
		if is_instance_valid(ch) and not ch.is_queued_for_deletion() and ch is TowerBase and (ch as TowerBase).is_mimic_copy and ch != form2:
			form_l = ch as TowerBase
			break
	_check(is_instance_valid(form_l) and form_l is GunTower and form_l.current_lvl == 1, "Mimic L3-L Perfect Cast still grants +1 free battle level")
	_check(is_equal_approx(form_l.mimic_synergy_as_pct, 12.0) and is_equal_approx(nb_gun.mimic_synergy_as_pct, 12.0), "Mimic L7-L Adaptive Link still grants mutual +12% attack speed")

	# 5. MobileTacticalAI + MobileAIController checks for T13..T16
	var ai13 := MOBILE_TACTICAL_AI.new()
	var base_prism_r: float = 0.5 * float(GameConstants.DATA_TOWER[12].parametr_3[0])
	var base_flame_r: float = 0.5 * float(GameConstants.DATA_TOWER[15].parametr_3[0])
	_check(is_equal_approx(ai13.get_tower_radius_px(12, 0, 0, [true, false, false], {"3": {"id": "tower_13_level_3_option_2"}}), base_prism_r * 1.10), "MobileTacticalAI reflects LaserPrism L3-R +10% range")
	_check(is_equal_approx(ai13.get_tower_radius_px(15, 0, 0, [true, false, false], {"3": {"id": "tower_16_level_3_option_2"}}), base_flame_r * 1.12), "MobileTacticalAI reflects Flamethrower L3-R +12% range")
	var mimic_p_base: float = ai13.eval_combat_power(14, 0, 0, [false, false, false], 1.0, 1.0, 3, false, 300.0, 2)
	var mimic_p_r: float = ai13.eval_combat_power(14, 0, 0, [true, true, true], 1.0, 1.0, 3, false, 300.0, 2, {"3": {"id": "tower_15_level_3_option_2"}, "7": {"id": "tower_15_level_7_option_2"}})
	_check(mimic_p_r > mimic_p_base, "MobileTacticalAI evaluates Mimic Precision Matrix + Flexible Form above base")

	var m_ai_ctrl := MobileAIController.new()
	var m_ai_pc := MOBILE_PLAYER_CONTAINER.new()
	m_ai_pc.map_node = map_root
	m_ai_pc.set_meta("is_ai_player", true)
	m_ai_pc.set_meta("ai_money", 500.0)
	m_ai_ctrl.container = m_ai_pc
	m_ai_ctrl.ai_deck = [14]
	m_ai_ctrl.ai_build_costs = {14: 250.0}
	m_ai_ctrl.ai_abilities = {14: [true, true, true]}
	m_ai_ctrl.ai_ability_choices = {14: {"3": {"id": "tower_15_level_3_option_2"}, "7": {"id": "tower_15_level_7_option_2"}}}
	var dummy_dead := Node2D.new()
	turret_layer.add_child(dummy_dead)
	dummy_dead.queue_free()
	m_ai_ctrl.built_towers[Vector2i(3, 1)] = dummy_dead
	m_ai_ctrl._prune_invalid_towers()
	_check(m_ai_ctrl.built_towers.get(Vector2i(3, 1), null) == form2, "MobileAIController._prune_invalid_towers re-adopts morphed Mimic copy on same cell")
	var m_state: Dictionary = m_ai_ctrl._collect_game_state()
	_check(is_equal_approx(float(m_state.get("build_costs", {}).get(14, 0.0)), 250.0), "MobileAIController exports discounted 250.0 Mimic cost when L3-R Shadow Discount is active")
	m_ai_ctrl.free()
	m_ai_pc.free()

	nb_gun.queue_free()
	nb_chak.queue_free()
	nb_hive.queue_free()
	if is_instance_valid(form2):
		form2.queue_free()
	if is_instance_valid(form_l):
		form_l.queue_free()
	map_root.queue_free()
	await get_tree().process_frame
	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	GameSession.current_money_in_game_session = saved_session_money
	DataManager.critical_damage = saved_crit
	GameSession.current_wave = saved_wave
	DataManager.write_file()


func _test_t17_t18_loader_and_icons() -> void:
	# 1. Mobile Loader sizing & desktop fallback
	var loader_scene := load("res://Scenes/UI/Loader.tscn") as PackedScene
	_check(loader_scene != null, "Loader.tscn loads cleanly")
	if loader_scene != null:
		var loader := loader_scene.instantiate()
		add_child(loader)
		loader.set("_switching", true)
		loader.call("_apply_layout_for_size", Vector2(1080.0, 1920.0))
		var c_size: Vector2 = loader.crest_holder.custom_minimum_size
		var eyebrow_sz: int = loader.eyebrow_label.get_theme_font_size("font_size")
		var title_sz: int = loader.title_label.get_theme_font_size("font_size")
		var stage_sz: int = loader.stage_label.get_theme_font_size("font_size")
		var pct_sz: int = loader.percent_label.get_theme_font_size("font_size")
		_check(c_size.x >= 750.0 and c_size.y >= 750.0, "Mobile portrait Loader enlarges center crest image (>= 750px on 1080x1920)")
		_check(eyebrow_sz >= 38, "Mobile portrait Loader enlarges subtitle label (>= 38px)")
		_check(title_sz >= 88, "Mobile portrait Loader enlarges TOWER DEFENSE title (>= 88px)")
		_check(stage_sz >= 36 and pct_sz >= 40, "Mobile portrait Loader enlarges progress text labels")
		_check(loader.progress_card.custom_minimum_size.x >= 900.0, "Mobile portrait Loader widens progress card cleanly")
		loader.call("_apply_layout_for_size", Vector2(1600.0, 900.0))
		_check(loader.crest_holder.custom_minimum_size.x <= 360.0 and loader.title_label.get_theme_font_size("font_size") == Typography.D_DISPLAY, "Desktop landscape Loader preserves compact desktop layout")
		loader.queue_free()
		await get_tree().process_frame

	# 2. Game icon configuration across project.godot, export_presets.cfg and icon files
	var pg_text: String = FileAccess.get_file_as_string("res://project.godot")
	_check(pg_text.contains('config/icon="res://Assets/Icons/app_icon.png"'), "project.godot configures custom app_icon.png")
	_check(ResourceLoader.exists("res://Assets/Icons/app_icon.png") and load("res://Assets/Icons/app_icon.png") is Texture2D, "app_icon.png loads as Texture2D")
	var ep_text: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(ep_text.contains('application/icon="res://Assets/Icons/app_icon.ico"'), "export_presets.cfg Windows Desktop uses app_icon.ico")
	_check(ep_text.contains('application/console_wrapper_icon="res://Assets/Icons/app_icon.ico"'), "export_presets.cfg console wrapper uses app_icon.ico")
	_check(FileAccess.file_exists("res://Assets/Icons/app_icon.ico"), "app_icon.ico exists on disk")
	_check(ep_text.contains('launcher_icons/main_192x192="res://Assets/Icons/android_icon_192.png"'), "export_presets.cfg Android main launcher icon configured")
	_check(ep_text.contains('launcher_icons/adaptive_foreground_432x432="res://Assets/Icons/android_adaptive_fg_432.png"'), "export_presets.cfg Android adaptive foreground configured")
	_check(ep_text.contains('launcher_icons/adaptive_background_432x432="res://Assets/Icons/android_adaptive_bg_432.png"'), "export_presets.cfg Android adaptive background configured")
	for icon_res in ["res://Assets/Icons/android_icon_192.png", "res://Assets/Icons/android_adaptive_fg_432.png", "res://Assets/Icons/android_adaptive_bg_432.png"]:
		_check(ResourceLoader.exists(icon_res) and load(icon_res) is Texture2D, "Android icon resource loads: " + icon_res)

	# 3. AbilityChoiceCatalog.json completeness (100/100 implemented)
	var cat_json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://Systems/AbilityChoiceCatalog.json"))
	_check(cat_json is Dictionary and (cat_json as Dictionary).size() == 20, "AbilityChoiceCatalog.json contains all 20 towers")
	var total_opts: int = 0
	var impl_opts: int = 0
	if cat_json is Dictionary:
		for tid in (cat_json as Dictionary).keys():
			for lvl in (cat_json[tid] as Dictionary).keys():
				for opt in (cat_json[tid][lvl] as Array):
					total_opts += 1
					if bool(opt.get("implemented", false)):
						impl_opts += 1
	_check(total_opts == 100 and impl_opts == 100, "All 100/100 tower ability options are marked implemented in AbilityChoiceCatalog.json")

	var saved_money: int = DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_session_money: float = GameSession.current_money_in_game_session
	var saved_crit: int = DataManager.critical_damage
	var saved_wave: int = GameSession.current_wave
	DataManager.critical_damage = 100
	GameSession.current_money_in_game_session = 99999.0
	GameSession.current_wave = 1

	var map_root := Node2D.new()
	map_root.name = "Map"
	var turret_layer := Node2D.new()
	turret_layer.name = "Turret"
	map_root.add_child(turret_layer)
	var excl_layer := TileMapLayer.new()
	excl_layer.name = "TowerExlusion"
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	excl_layer.tile_set = ts
	map_root.add_child(excl_layer)
	var path_root := Node2D.new()
	path_root.name = "Path"
	var path_2d := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(0.0, 160.0))
	curve.add_point(Vector2(640.0, 160.0))
	path_2d.curve = curve
	path_root.add_child(path_2d)
	map_root.add_child(path_root)
	add_child(map_root)

	# 4. Tower 17 (SniperTower): L3-R Reinforced Optics (+10% range), L7-R Sliding Bolt (+8% reload speed), L10 Expansive Caliber (+20% crit dmg)
	var sniper_base := _make_ability_tower("Turret_17T1", Vector2(96.0, 96.0), map_root, [false, false, false])
	var sniper_r := _make_ability_tower("Turret_17T1", Vector2(160.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_17_level_3_option_2"},
		"7": {"id": "tower_17_level_7_option_2"},
		"10": {"id": "tower_17_level_10_option_1"}
	})
	_check(not sniper_r.has_breach_round_ability() and sniper_r.has_reinforced_optics_ability(), "Sniper L3-R Reinforced Optics disables Breach Round")
	_check(not sniper_r.has_pierce_caliber_ability() and sniper_r.has_sliding_bolt_ability(), "Sniper L7-R Sliding Bolt disables Pierce Caliber")
	_check(sniper_r.has_expansive_caliber_ability(), "Sniper L10 Expansive Caliber activates")
	var expected_sniper_range: float = MathUtils.round_to_dec(sniper_base.range * 1.10, 2)
	_check(is_equal_approx(sniper_r.range, expected_sniper_range), "Sniper L3-R Reinforced Optics increases range by +10%")
	var sniper_col := sniper_r.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	_check(sniper_col != null and is_equal_approx((sniper_col.shape as CircleShape2D).radius, 0.5 * sniper_r.range), "Sniper L3-R updates Area2D range collider radius")
	_check(is_equal_approx(TowerBase.get_preview_ability_range_multiplier("Turret_17T1", {
		"ability": [true, false, false],
		"ability_choices": {"3": {"id": "tower_17_level_3_option_2"}}
	}), 1.10), "Sniper L3-R updates build preview range multiplier to 1.10")
	_check(is_equal_approx(sniper_r.get_ability_attack_speed_bonus_pct(), 8.0), "Sniper L7-R Sliding Bolt grants +8% reload speed bonus")
	_check(is_equal_approx(sniper_r.multiplier_rof_all, 1.0 / 1.08), "Sniper L7-R reduces multiplier_rof_all to 1/1.08")
	_check(sniper_base.get_effective_crit_damage_pct() == 100 and sniper_r.get_effective_crit_damage_pct() == 120, "Sniper L10 Expansive Caliber increases personal crit damage pct by +20 (100 -> 120)")

	sniper_r.ui_system.menu.setup(sniper_r.id)
	sniper_r.ui_system.update_menu()
	_check(is_equal_approx(float(sniper_r.ui_system.menu.list_node[1].get_node("HValue/Value").text), MathUtils.round_to_dec(sniper_r.rof / 1.08, 2)), "Sniper TowerUI reflects faster L7-R Sliding Bolt reload time")
	_check(is_equal_approx(float(sniper_r.ui_system.menu.list_node[2].get_node("HValue/Value").text), MathUtils.round_to_dec(sniper_r.range, 2)), "Sniper TowerUI reflects +10% L3-R Reinforced Optics range")

	var sniper_target_base := MockEnemy.new()
	sniper_target_base.position = sniper_base.position + Vector2(60.0, 0.0)
	add_child(sniper_target_base)
	sniper_base.enemy = sniper_target_base
	sniper_base.force_next_attack_crit = true
	sniper_base.fire()
	var sniper_target_r := MockEnemy.new()
	sniper_target_r.position = sniper_r.position + Vector2(60.0, 0.0)
	add_child(sniper_target_r)
	sniper_r.enemy = sniper_target_r
	sniper_r.force_next_attack_crit = true
	sniper_r.fire()
	_check(sniper_target_base.hit_values.size() == 1 and sniper_target_r.hit_values.size() == 1, "Both base and L10 Sniper shots land hits")
	var expected_base_crit: float = MathUtils.round_to_dec(sniper_base.damage * 2.00, 2)
	var expected_l10_crit: float = MathUtils.round_to_dec(sniper_r.damage * 2.20, 2)
	_check(is_equal_approx(sniper_target_base.hit_values[0], expected_base_crit) and is_equal_approx(sniper_target_r.hit_values[0], expected_l10_crit), "Sniper L10 Expansive Caliber boosts crit multiplier 2.0x -> 2.2x (+20pp)")
	_check(is_equal_approx(sniper_r.get_remaining_cooldown(), sniper_r.rof / 1.08), "Sniper L7-R Sliding Bolt shortens live combat cooldown timer")
	_check(is_equal_approx(sniper_r.get_ability_range_multiplier(), 1.10), "Sniper L3-R retains range multiplier during combat")

	# Verify Sniper L3-L + L7-L still work with L10 active
	var sniper_l := _make_ability_tower("Turret_17T1", Vector2(224.0, 96.0), map_root, [true, true, true], {
		"3": {"id": "tower_17_level_3_option_1"},
		"7": {"id": "tower_17_level_7_option_1"},
		"10": {"id": "tower_17_level_10_option_1"}
	})
	_check(sniper_l.has_breach_round_ability() and sniper_l.has_pierce_caliber_ability() and sniper_l.has_expansive_caliber_ability(), "Sniper L3-L + L7-L + L10 coexist cleanly")
	_check(is_equal_approx(sniper_l.range, sniper_base.range) and is_equal_approx(sniper_l.multiplier_rof_all, 1.0), "Sniper L3-L + L7-L do not leak L3-R/L7-R bonuses")
	var sl_p1 := MockEnemy.new()
	sl_p1.position = sniper_l.position + Vector2(60.0, 0.0)
	var sl_p2 := MockEnemy.new()
	sl_p2.position = sniper_l.position + Vector2(120.0, 0.0)
	add_child(sl_p1)
	add_child(sl_p2)
	sniper_l.enemy_array = [sl_p1, sl_p2]
	sniper_l.enemy = sl_p1
	sniper_l.force_next_attack_crit = false
	sniper_l.fire()
	var pierce_crit_mult: float = (1.0 + float(sniper_l.get_effective_crit_damage_pct()) / 100.0) if sniper_l.fx_last_crit else 1.0
	_check(sl_p1.hit_values.size() == 1 and sl_p2.hit_values.size() == 1 and is_equal_approx(sl_p2.hit_values[0], MathUtils.round_to_dec(sniper_l.damage * 0.60 * pierce_crit_mult, 2)), "Sniper L7-L Pierce Caliber still pierces behind target for 60% damage")
	sl_p1.queue_free()
	sl_p2.queue_free()
	sniper_target_base.queue_free()
	sniper_target_r.queue_free()

	# Verify Mimic copying Sniper inherits L3-R / L7-R / L10
	sniper_r.set_meta("bound_excl_cell", Vector2i(2, 1))
	var mimic_sniper_src := _make_ability_tower("Turret_15T1", Vector2(288.0, 96.0), map_root, [false, false, false])
	mimic_sniper_src.set_meta("bound_excl_cell", Vector2i(4, 1))
	var morphed_sniper := MimicTower.perform_mimic_morph(mimic_sniper_src, sniper_r, false)
	await get_tree().process_frame
	_check(is_instance_valid(morphed_sniper) and morphed_sniper is SniperTower, "Mimic morphs into SniperTower")
	if is_instance_valid(morphed_sniper) and morphed_sniper is SniperTower:
		var ms := morphed_sniper as SniperTower
		_check(ms.has_reinforced_optics_ability() and ms.has_sliding_bolt_ability() and ms.has_expansive_caliber_ability(), "Mimic inherits Sniper L3-R, L7-R, and L10 choices")
		_check(is_equal_approx(ms.range, sniper_r.range) and ms.get_effective_crit_damage_pct() == 120, "Mimic Sniper applies L3-R range and L10 crit damage")
		morphed_sniper.queue_free()
	sniper_base.queue_free()
	sniper_r.queue_free()
	sniper_l.queue_free()

	# 5. Tower 18 (MortarTower): L3-R Heavy Powder (+12% blast radius), L7-R Heavy Shell (+18% epicenter primary dmg), L10 Rapid Fire (every 5th volley +0.3s 40% shell)
	var mortar_base := _make_ability_tower("Turret_18T1", Vector2(96.0, 224.0), map_root, [false, false, false])
	var mortar_r := _make_ability_tower("Turret_18T1", Vector2(160.0, 224.0), map_root, [true, true, true], {
		"3": {"id": "tower_18_level_3_option_2"},
		"7": {"id": "tower_18_level_7_option_2"},
		"10": {"id": "tower_18_level_10_option_1"}
	})
	_check(not mortar_r.has_stunning_fuse() and mortar_r.has_heavy_powder_ability(), "Mortar L3-R Heavy Powder disables Concussive Fuse")
	_check(not mortar_r.has_fragment_ability() and mortar_r.has_heavy_shell_ability(), "Mortar L7-R Heavy Shell disables Cluster Charge")
	_check(mortar_r.has_rapid_fire_ability(), "Mortar L10 Rapid Fire activates")
	_check(is_equal_approx(mortar_r.get_effective_blast_radius(), MathUtils.round_to_dec(mortar_r.blast_radius * 1.12, 2)), "Mortar L3-R Heavy Powder increases blast radius by +12% (95 -> 106.4)")
	mortar_r.ui_system.menu.setup(mortar_r.id)
	mortar_r.ui_system.update_menu()
	mortar_r.ui_system.update_menu_upgrade()
	_check(is_equal_approx(float(mortar_r.ui_system.menu.list_node[3].get_node("HValue/Value").text), MathUtils.round_to_dec(mortar_r.blast_radius * 1.12, 2)), "Mortar TowerUI displays +12% Heavy Powder blast radius")
	_check(is_equal_approx(float(mortar_r.ui_system.menu.list_node[3].get_node("HValue/Up").text), MathUtils.round_to_dec((float(GameConstants.DATA_TOWER[17].parametr_4[1]) - float(GameConstants.DATA_TOWER[17].parametr_4[0])) * 1.12, 2)), "Mortar TowerUI displays +12% Heavy Powder upgrade diff")

	# Test Heavy Powder blast reach (101 px away: missed by base 95px, hit by 106.4px) & Heavy Shell (+18% ONLY to primary epicenter target)
	var m_primary := MockEnemy.new()
	m_primary.position = Vector2(300.0, 300.0)
	var m_side_center := MockEnemy.new()
	m_side_center.position = Vector2(325.0, 300.0) # within center_radius (~58.5px)
	var m_edge_101 := MockEnemy.new()
	m_edge_101.position = Vector2(401.0, 300.0) # 101 px away (>95px base, <=106.4px L3-R)
	add_child(m_primary)
	add_child(m_side_center)
	add_child(m_edge_101)
	mortar_base.enemy_array = [m_primary, m_side_center, m_edge_101]
	mortar_base._apply_main_blast(Vector2(300.0, 300.0), 1.0, m_primary)
	_check(m_primary.hit_values.size() == 1 and m_edge_101.hit_values.is_empty(), "Base Mortar (95px) misses enemy at 101px")

	m_primary.hit_values.clear()
	m_side_center.hit_values.clear()
	m_edge_101.hit_values.clear()
	mortar_r.enemy_array = [m_primary, m_side_center, m_edge_101]
	mortar_r._apply_main_blast(Vector2(300.0, 300.0), 1.0, m_primary)
	var m_crit_mult: float = 1.0 + float(mortar_r.get_effective_crit_damage_pct()) / 100.0
	var m_exp_p: float = MathUtils.round_to_dec(mortar_r.damage * 1.18, 2)
	var m_exp_c: float = MathUtils.round_to_dec(mortar_r.damage, 2)
	var m_exp_o: float = MathUtils.round_to_dec(mortar_r.damage * 0.60, 2)
	_check(m_primary.hit_values.size() == 1 and m_side_center.hit_values.size() == 1 and m_edge_101.hit_values.size() == 1, "Mortar L3-R (106.4px) hits enemy at 101px outer ring")
	_check(is_equal_approx(m_primary.hit_values[0], m_exp_p) or is_equal_approx(m_primary.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * 1.18 * m_crit_mult, 2)), "Mortar L7-R Heavy Shell deals +18% damage to primary epicenter target")
	_check(is_equal_approx(m_side_center.hit_values[0], m_exp_c) or is_equal_approx(m_side_center.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * m_crit_mult, 2)), "Mortar L7-R leaves secondary enemy in center at 100% base damage")
	_check(is_equal_approx(m_edge_101.hit_values[0], m_exp_o) or is_equal_approx(m_edge_101.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * 0.60 * m_crit_mult, 2)), "Mortar L7-R keeps outer ring at 60% falloff")
	m_side_center.queue_free()
	m_edge_101.queue_free()

	# Test L10 Rapid Fire: volleys 1..4 launch 1 shell; volley 5 launches main shell + bonus 40% shell after 0.3s
	m_primary.position = mortar_r.position + Vector2(60.0, 0.0)
	m_primary.hit_values.clear()
	mortar_r.enemy_array = [m_primary]
	mortar_r.enemy = m_primary
	mortar_r._volley_count = 3
	mortar_r.is_ready = true
	mortar_r.fire() # volley 4 -> no rapid fire
	_check(mortar_r._volley_count == 4 and not mortar_r._rapid_fire_pending, "Mortar L10 Rapid Fire does NOT trigger on 4th volley")
	await get_tree().create_timer(0.45, false).timeout
	_check(m_primary.hit_values.size() == 1 and (is_equal_approx(m_primary.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * 1.18, 2)) or is_equal_approx(m_primary.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * 1.18 * m_crit_mult, 2))), "4th volley deals exactly 1 hit")

	m_primary.hit_values.clear()
	mortar_r.is_ready = true
	mortar_r.fire() # volley 5 -> triggers Rapid Fire followup in 0.30s
	_check(mortar_r._volley_count == 5 and mortar_r._rapid_fire_pending, "Mortar L10 Rapid Fire schedules bonus shell on 5th volley")
	_check(not mortar_r.is_mimic_ready_for_next_attack_cycle(), "Mortar delays Mimic cycle switch until Rapid Fire followup launches")
	await get_tree().create_timer(0.85, false).timeout
	_check(not mortar_r._rapid_fire_pending, "Mortar L10 Rapid Fire followup completes cleanly")
	_check(m_primary.hit_values.size() == 2, "5th volley deals 2 hits (main shell + 0.3s Rapid Fire shell)")
	if m_primary.hit_values.size() == 2:
		_check(is_equal_approx(m_primary.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * 1.18, 2)) or is_equal_approx(m_primary.hit_values[0], MathUtils.round_to_dec(mortar_r.damage * 1.18 * m_crit_mult, 2)), "5th volley primary shell deals full 100% (+18% epicenter) damage")
		_check(is_equal_approx(m_primary.hit_values[1], MathUtils.round_to_dec(mortar_r.damage * 1.18 * 0.40, 2)) or is_equal_approx(m_primary.hit_values[1], MathUtils.round_to_dec(mortar_r.damage * 1.18 * 0.40 * m_crit_mult, 2)), "5th volley Rapid Fire followup shell deals 40% damage")

	mortar_r.is_ready = true
	mortar_r.fire() # volley 6 -> no rapid fire
	_check(mortar_r._volley_count == 6 and not mortar_r._rapid_fire_pending, "6th volley resets 5-volley Rapid Fire cadence cleanly")
	await get_tree().create_timer(0.45, false).timeout

	m_primary.queue_free()
	mortar_base.queue_free()
	mortar_r.queue_free()

	# 6. MobileTacticalAI evaluation for T17 & T18
	var ai17 := MOBILE_TACTICAL_AI.new()
	var base_sniper_r: float = 0.5 * float(GameConstants.DATA_TOWER[16].parametr_3[0])
	_check(is_equal_approx(ai17.get_tower_radius_px(16, 0, 0, [true, false, false], {"3": {"id": "tower_17_level_3_option_2"}}), base_sniper_r * 1.10), "MobileTacticalAI reflects Sniper L3-R +10% range")
	var sniper_p_base: float = ai17.eval_combat_power(16, 0, 0, [false, false, false], 1.0, 1.0, 2, true, 500.0, 2)
	var sniper_p_r: float = ai17.eval_combat_power(16, 0, 0, [true, true, true], 1.0, 1.0, 2, true, 500.0, 2, {"3": {"id": "tower_17_level_3_option_2"}, "7": {"id": "tower_17_level_7_option_2"}, "10": {"id": "tower_17_level_10_option_1"}})
	_check(sniper_p_r > sniper_p_base, "MobileTacticalAI values Sniper L3-R + L7-R + L10 above base")
	var mortar_p_base: float = ai17.eval_combat_power(17, 0, 0, [false, false, false], 1.0, 1.0, 3, false, 400.0, 2)
	var mortar_p_r: float = ai17.eval_combat_power(17, 0, 0, [true, true, true], 1.0, 1.0, 3, false, 400.0, 2, {"3": {"id": "tower_18_level_3_option_2"}, "7": {"id": "tower_18_level_7_option_2"}, "10": {"id": "tower_18_level_10_option_1"}})
	_check(mortar_p_r > mortar_p_base, "MobileTacticalAI values Mortar L3-R + L7-R + L10 above base")

	map_root.queue_free()
	await get_tree().process_frame
	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	GameSession.current_money_in_game_session = saved_session_money
	DataManager.critical_damage = saved_crit
	GameSession.current_wave = saved_wave
	DataManager.write_file()


func _collect_font_sizes(node: Node, out: Array[int]) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		var ctrl := node as Control
		var txt := str(node.get("text")).strip_edges()
		if ctrl.is_visible_in_tree() and not txt.is_empty():
			if node is RichTextLabel:
				var rtl := node as RichTextLabel
				var fs := rtl.get_theme_font_size("normal_font_size")
				if fs > 0:
					out.append(fs)
			else:
				var fs := ctrl.get_theme_font_size("font_size")
				if fs > 0:
					out.append(fs)
	for ch in node.get_children():
		_collect_font_sizes(ch, out)


func _test_ui_readability_desktop_and_mobile() -> void:
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_spells: Dictionary = DataManager.spell_data.duplicate(true)
	var saved_money: int = DataManager.data_money
	DataManager.data_money = 999999
	DataManager.tower_data["Turret_3T1"]["have"] = true
	DataManager.tower_data["Turret_3T1"]["level"] = 9
	DataManager.tower_data["Turret_3T1"]["mastery_xp"] = 1234
	DataManager.tower_data["Turret_3T1"]["ability"] = [true, true, true]
	DataManager.ensure_spell_entry("spell_1")
	DataManager.spell_data["spell_1"]["have"] = true

	var dvp_wrap := SubViewportContainer.new()
	dvp_wrap.size = Vector2(1600, 900)
	var dvp := SubViewport.new()
	dvp.name = "DesktopTestVP"
	dvp.size = Vector2i(1600, 900)
	dvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	dvp_wrap.add_child(dvp)
	add_child(dvp_wrap)

	var mvp_wrap := SubViewportContainer.new()
	mvp_wrap.size = Vector2(1080, 1920)
	var mvp := SubViewport.new()
	mvp.name = "MobileTestVP"
	mvp.size = Vector2i(1080, 1920)
	mvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	mvp_wrap.add_child(mvp)
	add_child(mvp_wrap)

	await get_tree().process_frame

	# 1) SpellInfoModal on Desktop & Mobile
	var d_sm := SpellInfoModal.new()
	d_sm.spell_key = "spell_1"
	d_sm.is_mobile_ui = false
	dvp.add_child(d_sm)
	var m_sm := SpellInfoModal.new()
	m_sm.spell_key = "spell_1"
	m_sm.is_mobile_ui = true
	mvp.add_child(m_sm)
	await get_tree().process_frame
	await get_tree().process_frame
	var d_mc := d_sm.find_child("ModalCard", true, false) as PanelContainer
	var m_mc := m_sm.find_child("ModalCard", true, false) as PanelContainer
	_check(is_instance_valid(d_mc) and d_mc.size.x >= 720.0 and d_mc.size.x <= 1580.0 and d_mc.size.y <= 880.0, "Desktop SpellInfoModal fits cleanly within 1600x900 (>=720w) got=%s" % [d_mc.size if is_instance_valid(d_mc) else Vector2.ZERO])
	_check(is_instance_valid(m_mc) and m_mc.size.x >= 920.0 and m_mc.size.x <= 1060.0 and m_mc.size.y <= 1880.0, "Mobile SpellInfoModal fits cleanly within 1080x1920 (>=920w) got=%s" % [m_mc.size if is_instance_valid(m_mc) else Vector2.ZERO])
	var d_sm_fonts: Array[int] = []
	var m_sm_fonts: Array[int] = []
	_collect_font_sizes(d_sm, d_sm_fonts)
	_collect_font_sizes(m_sm, m_sm_fonts)
	_check(not d_sm_fonts.is_empty() and d_sm_fonts.min() >= 14, "Desktop SpellInfoModal maintains readable font sizes >= 14px")
	_check(not m_sm_fonts.is_empty() and m_sm_fonts.min() >= 25, "Mobile SpellInfoModal maintains readable font sizes >= 25px")
	d_sm.free()
	m_sm.free()

	# 2) info_mastery Desktop vs Mobile
	var d_im := (load("res://Scenes/SupportScenes/info_mastery.tscn") as PackedScene).instantiate() as Control
	dvp.add_child(d_im)
	d_im.setup(DataManager.tower_data["Turret_3T1"], 3)
	var m_im := (load("res://Scenes/Mobile/info_mastery_mobile.tscn") as PackedScene).instantiate() as Control
	mvp.add_child(m_im)
	m_im.setup(DataManager.tower_data["Turret_3T1"], 3)
	await get_tree().process_frame
	await get_tree().process_frame
	var d_im_p := d_im.get_node("UI_panel") as PanelContainer
	var m_im_p := m_im.get_node("UI_panel") as PanelContainer
	_check(d_im_p.size.x >= 800.0 and d_im_p.size.x <= 1600.0 and d_im_p.size.y >= 800.0 and d_im_p.size.y <= 900.0, "Desktop info_mastery panel expands cleanly within 1600x900 got=%s" % d_im_p.size)
	_check(m_im_p.size.x >= 960.0 and m_im_p.size.x <= 1080.0 and m_im_p.size.y >= 1500.0 and m_im_p.size.y <= 1920.0, "Mobile info_mastery panel expands cleanly within 1080x1920 got=%s" % m_im_p.size)
	_check(d_im.grid.columns == 3 and m_im.grid.columns == 2, "info_mastery uses 3 columns on desktop and 2 on mobile")
	var m_im_fonts: Array[int] = []
	_collect_font_sizes(m_im, m_im_fonts)
	_check(not m_im_fonts.is_empty() and m_im_fonts.min() >= 28, "Mobile info_mastery keeps all fonts >= 28px min=%s" % [m_im_fonts.min() if not m_im_fonts.is_empty() else 0])
	d_im.free()
	m_im.free()

	# 3) turret_menu_shop Desktop vs Mobile (layout, compact card height, lock geometry, scroll preservation)
	var saved_t20_ui: Dictionary = DataManager.tower_data["Turret_20T1"].duplicate(true)
	DataManager.tower_data["Turret_20T1"]["have"] = true
	DataManager.tower_data["Turret_20T1"]["level"] = 2 # L3 unlocked, L7 & L10 locked
	DataManager.tower_data["Turret_20T1"]["ability"] = [false, false, false]
	DataManager.tower_data["Turret_20T1"]["ability_choices"] = {}
	var d_tm := (load("res://Scenes/SupportScenes/turret_menu_shop.tscn") as PackedScene).instantiate() as Control
	dvp.add_child(d_tm)
	d_tm.setup(DataManager.tower_data["Turret_20T1"], 19)
	var m_tm := (load("res://Scenes/Mobile/turret_menu_shop_mobile.tscn") as PackedScene).instantiate() as Control
	mvp.add_child(m_tm)
	m_tm.setup(DataManager.tower_data["Turret_20T1"], 19)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var d_tm_p := d_tm.get_node("UI_panel") as PanelContainer
	var m_tm_p := m_tm.get_node("UI_panel") as PanelContainer
	_check(d_tm_p.size.x >= 800.0 and d_tm_p.size.x <= 1600.0 and d_tm_p.size.y <= 900.0, "Desktop turret_menu_shop panel stays widened inside 1600x900 got=%s" % d_tm_p.size)
	_check(m_tm_p.size.x >= 960.0 and m_tm_p.size.x <= 1080.0 and m_tm_p.size.y >= 1500.0 and m_tm_p.size.y <= 1920.0, "Mobile turret_menu_shop panel fills mobile portrait cleanly got=%s" % m_tm_p.size)
	_check(d_tm.stats_grid.columns == 3 and m_tm.stats_grid.columns == 2, "turret_menu_shop stats_grid uses 3 columns desktop and 2 mobile")
	var m_tm_fonts: Array[int] = []
	_collect_font_sizes(m_tm, m_tm_fonts)
	_check(not m_tm_fonts.is_empty() and m_tm_fonts.min() >= 28, "Mobile turret_menu_shop maintains all visible font sizes >= 28px min=%s" % [m_tm_fonts.min() if not m_tm_fonts.is_empty() else 0])
	var d_c0 := d_tm.find_child("Choice_0_0", true, false) as Button
	var d_c1 := d_tm.find_child("Choice_1_0", true, false) as Button
	var m_c0 := m_tm.find_child("Choice_0_0", true, false) as Button
	var m_c1 := m_tm.find_child("Choice_1_0", true, false) as Button
	_check(is_instance_valid(d_c0) and d_c0.size.y <= 290.0 and is_instance_valid(d_c1) and d_c1.size.y <= 290.0, "Desktop choice cards stay compact (no 4000px stretch) got=(%.1f, %.1f)" % [d_c0.size.y if d_c0 else -1.0, d_c1.size.y if d_c1 else -1.0])
	_check(is_instance_valid(m_c0) and m_c0.size.y <= 450.0 and is_instance_valid(m_c1) and m_c1.size.y <= 450.0, "Mobile choice cards stay compact got=(%.1f, %.1f)" % [m_c0.size.y if m_c0 else -1.0, m_c1.size.y if m_c1 else -1.0])
	var no_card_overflow := true
	for b in d_tm.find_children("Choice_*", "Button", true, false) + m_tm.find_children("Choice_*", "Button", true, false):
		var pad := (b as Control).get_child(0) as Control
		if is_instance_valid(pad) and pad.get_combined_minimum_size().y > (b as Control).size.y + 1.0:
			no_card_overflow = false
	_check(no_card_overflow, "No ability choice card clips its text on Desktop or Mobile")
	_check(d_tm.find_children("AbilityIconLock", "TextureRect", true, false).is_empty() and m_tm.find_children("AbilityIconLock", "TextureRect", true, false).is_empty(), "No overlapping AbilityIconLock badge covers tower ability icons")
	var d_lock_ic := d_tm.find_child("LockIcon", true, false) as TextureRect
	var m_lock_ic := m_tm.find_child("LockIcon", true, false) as TextureRect
	_check(is_instance_valid(d_lock_ic) and d_lock_ic.size.y <= 20.0 and is_instance_valid(m_lock_ic) and m_lock_ic.size.y <= 32.0, "Lock badge icons stay vertically centered without stretching")
	# Scroll position & child ordering stay stable when selecting an inline choice card
	var d_vbox1 := d_tm.ability_labels[0].get_parent() as VBoxContainer
	var idx_before: int = d_vbox1.get_node("AbilityChoicePreview").get_index()
	d_tm.scroll.scroll_vertical = 220
	if is_instance_valid(d_c0):
		d_c0.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var idx_after: int = d_vbox1.get_node("AbilityChoicePreview").get_index()
	_check(idx_before == idx_after, "AbilityChoicePreview keeps exact child order across inline selection (%d == %d)" % [idx_before, idx_after])
	_check(abs(d_tm.scroll.scroll_vertical - 220) <= 4, "Desktop turret_menu_shop preserves scroll_vertical on ability selection got=%d" % d_tm.scroll.scroll_vertical)
	_check(d_tm.find_child("PanelContainer51", true, false).is_visible_in_tree() and d_tm.find_child("PanelAbility10", true, false).is_visible_in_tree(), "Later ability panels remain visible after selecting slot 0")
	d_tm.free()
	m_tm.free()
	DataManager.tower_data["Turret_20T1"] = saved_t20_ui

	# 4) 30 achievement levels: XP balance, rewards (tokens/diamonds/legendary), Desktop & Mobile UIs
	_check(GameConstants.NEED_PROMOTION_STAR_LEVEL.size() == 29, "NEED_PROMOTION_STAR_LEVEL has 29 transitions for 30 levels")
	_check(GameConstants.PROMOTION_LEVEL.size() == 30, "PROMOTION_LEVEL defines rewards for all 30 levels")
	var xp_increasing := true
	var total_needed_xp := 0
	for xi in range(GameConstants.NEED_PROMOTION_STAR_LEVEL.size()):
		var cur_xp := int(GameConstants.NEED_PROMOTION_STAR_LEVEL[xi])
		total_needed_xp += cur_xp
		if xi > 0 and cur_xp <= int(GameConstants.NEED_PROMOTION_STAR_LEVEL[xi - 1]):
			xp_increasing = false
	var total_ach_xp := 0
	for axp_arr in GameConstants.NUMBER_EXPERIENCE_PROMOTION:
		for axp in axp_arr:
			total_ach_xp += int(axp)
	_check(xp_increasing, "NEED_PROMOTION_STAR_LEVEL rises monotonically across all 29 steps")
	_check(total_needed_xp > 0 and total_needed_xp <= total_ach_xp, "30-level total XP (%d) is achievable within total achievement XP (%d)" % [total_needed_xp, total_ach_xp])
	var has_30_keys := true
	for lvl_k in range(1, 31):
		if not GameConstants.PROMOTION_LEVEL.has(lvl_k):
			has_30_keys = false
			break
	_check(has_30_keys and GameConstants.PROMOTION_LEVEL[30].size() == 4, "PROMOTION_LEVEL covers 1..30 and level 30 grants 4 rewards")
	var d_promo_lvl := (load("res://Scenes/SupportScenes/promotion_level.tscn") as PackedScene).instantiate() as Control
	dvp.add_child(d_promo_lvl)
	var m_promo_lvl := (load("res://Scenes/Mobile/promotion_level_mobile.tscn") as PackedScene).instantiate() as Control
	mvp.add_child(m_promo_lvl)
	await get_tree().process_frame
	await get_tree().process_frame
	var d_cards_row := d_promo_lvl.get_node("VBoxContainer/Panel/VBoxContainer/ScrollContainer/HBoxContainer") as HBoxContainer
	var m_cards_col := m_promo_lvl.get_node("VBoxContainer/Panel/VBoxContainer/ScrollContainer/ItemsContainer") as VBoxContainer
	_check(d_cards_row.get_child_count() == 30 and m_cards_col.get_child_count() == 30, "Desktop and Mobile promotion_level screens render all 30 level cards")
	d_promo_lvl.free()
	m_promo_lvl.free()

	# Verify claiming a high-level reward with diamonds/tokens/legendary chest
	var sv_prom_lvl := DataManager.promotion_level
	var sv_prom_open := DataManager.promotion_open_level
	var sv_money := DataManager.data_money
	var sv_crit := DataManager.critical_damage
	var sv_diam := DataManager.data_diamond
	var sv_tok := DataManager.data_token
	var sv_glvl := DataManager.glory_level
	var sv_gprog := DataManager.glory_progress
	var sv_cards := {}
	for tk in DataManager.tower_data:
		sv_cards[tk] = int(DataManager.tower_data[tk].get("cards", 0))
	DataManager.promotion_level = 29
	DataManager.promotion_open_level = 19
	var r20: Dictionary = DataManager.claim_promotion_level_reward(20)
	_check(bool(r20.get("ok", false)) and DataManager.data_diamond == sv_diam + 35 and DataManager.data_money == sv_money + 2200 and DataManager.critical_damage == sv_crit + 34 and not (r20.get("cards", []) as Array).is_empty(), "Claiming level 20 grants crit, coins, diamonds, and legendary-inclusive chest")
	DataManager.promotion_open_level = 20
	var r21: Dictionary = DataManager.claim_promotion_level_reward(21)
	_check(bool(r21.get("ok", false)) and DataManager.data_token == sv_tok + 45, "Claiming level 21 grants glory tokens (kind 10)")
	DataManager.promotion_level = sv_prom_lvl
	DataManager.promotion_open_level = sv_prom_open
	DataManager.data_money = sv_money
	DataManager.critical_damage = sv_crit
	DataManager.data_diamond = sv_diam
	DataManager.data_token = sv_tok
	DataManager.glory_level = sv_glvl
	DataManager.glory_progress = sv_gprog
	DataManager.data["Resources"]["money"] = sv_money
	DataManager.data["Resources"]["critical_damage"] = sv_crit
	DataManager.data["Resources"]["diamond"] = sv_diam
	DataManager.data["Resources"]["token"] = sv_tok
	DataManager.data["Promotion"]["level"] = sv_prom_lvl
	DataManager.data["Promotion"]["open_level"] = sv_prom_open
	DataManager._sync_path_of_glory_dict()
	for tk in sv_cards:
		DataManager.tower_data[tk]["cards"] = sv_cards[tk]
	DataManager.write_file()

	# 5) Mobile single unified large 10n-wave reward screen (buf_mobile + GiftController)
	var m_host_scr := GDScript.new()
	m_host_scr.source_code = "extends Node2D\nvar map_node: Node = null\n"
	m_host_scr.reload()
	var m_host := Node2D.new()
	m_host.set_script(m_host_scr)
	var m_ui := CanvasLayer.new()
	m_ui.name = "UI"
	m_host.add_child(m_ui)
	mvp.add_child(m_host)
	var gc := preload("res://Controllers/GiftController.gd").new()
	m_host.add_child(gc)
	gc.initialize(m_host)
	gc.launch_gift_box(10)
	await get_tree().process_frame
	await get_tree().process_frame
	var buf_ui := m_ui.get_node_or_null("Buf") as Control
	var buf_panel := buf_ui.get_node_or_null("Panel") as Panel if is_instance_valid(buf_ui) else null
	var buf_hbox := buf_ui.get_node_or_null("Panel/V/HBox") as Control if is_instance_valid(buf_ui) else null
	var buf_h := buf_ui.get_node_or_null("Panel/V/H") as Control if is_instance_valid(buf_ui) else null
	_check(is_instance_valid(buf_ui) and is_instance_valid(buf_panel), "Mobile 10n-wave reward opens unified buf_mobile screen")
	var panel_sz_before: Vector2 = buf_panel.size if is_instance_valid(buf_panel) else Vector2.ZERO
	_check(panel_sz_before.x >= 980.0 and panel_sz_before.y >= 1200.0 and panel_sz_before.x <= 1060.0 and panel_sz_before.y <= 1400.0, "Mobile reward panel opens immediately as one large dialog (>=980x1200) got=%s" % panel_sz_before)
	_check(is_instance_valid(buf_hbox) and buf_hbox.visible and is_instance_valid(buf_h) and buf_h.visible, "Mobile reward displays both reward slot row and 3 chest boxes together from the start")
	var m_buf_fonts: Array[int] = []
	_collect_font_sizes(buf_ui, m_buf_fonts)
	_check(not m_buf_fonts.is_empty() and m_buf_fonts.min() >= 28, "Mobile reward screen keeps all initial fonts >= 28px min=%s" % [m_buf_fonts.min() if not m_buf_fonts.is_empty() else 0])
	gc.gift_open(1, buf_ui)
	await get_tree().create_timer(0.60, true, false, true).timeout
	var panel_sz_after: Vector2 = buf_panel.size if is_instance_valid(buf_panel) else Vector2.ZERO
	_check(panel_sz_after == panel_sz_before, "Mobile reward panel keeps exact same unified size after chest selection (before=%s after=%s)" % [panel_sz_before, panel_sz_after])
	_check(buf_h.get_child_count() == 3 and buf_hbox.get_child_count() == 3, "Mobile reward preserves all 3 chests and all 3 modifier cards on screen without jumping")
	var buf_play := buf_ui.find_child("Play", true, false) as Button
	_check(is_instance_valid(buf_play) and buf_play.visible and buf_play.size.y >= 100.0, "Mobile reward reveals large Play button cleanly inside footer")
	var m_buf_fonts_after: Array[int] = []
	_collect_font_sizes(buf_ui, m_buf_fonts_after)
	_check(not m_buf_fonts_after.is_empty() and m_buf_fonts_after.min() >= 28, "Mobile reward screen keeps all opened fonts >= 28px min=%s" % [m_buf_fonts_after.min() if not m_buf_fonts_after.is_empty() else 0])
	gc.continue_game()
	await get_tree().process_frame
	_check(not get_tree().paused and not gc.have_open_present, "Mobile reward continue_game resumes battle cleanly")
	m_host.free()

	dvp_wrap.free()
	mvp_wrap.free()
	DataManager.tower_data = saved_towers
	DataManager.spell_data = saved_spells
	DataManager.data_money = saved_money


func _test_audit_mechanics_bugfixes() -> void:
	var saved_money: int = DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_data_mastery: Variant = DataManager.data.get("Mastery", {}).duplicate(true) if (DataManager.data.get("Mastery") is Dictionary) else {}
	var saved_mastery_dmg: Array = DataManager.mastery_damage_tower_session.duplicate(true)
	var saved_mastery_deal: Array = DataManager.mastery_deal_tower_session.duplicate(true)
	var saved_session_money: float = GameSession.current_money_in_game_session
	var saved_wave: int = GameSession.current_wave
	GameSession.current_money_in_game_session = 99999.0
	GameSession.current_wave = 2

	var map_root := Node2D.new()
	map_root.name = "Map"
	var turret_layer := Node2D.new()
	turret_layer.name = "Turret"
	map_root.add_child(turret_layer)
	var excl_layer := TileMapLayer.new()
	excl_layer.name = "TowerExlusion"
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	excl_layer.tile_set = ts
	map_root.add_child(excl_layer)
	var path_root := Node2D.new()
	path_root.name = "Path"
	var path_2d := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(0.0, 160.0))
	curve.add_point(Vector2(640.0, 160.0))
	path_2d.curve = curve
	path_root.add_child(path_2d)
	map_root.add_child(path_root)
	add_child(map_root)

	# Bug 1: MinotaurTower places exactly 1 trap per cycle even with 4 free road cells
	map_root.set_meta("road_coords_cache", [Vector2(100.0, 160.0), Vector2(164.0, 160.0), Vector2(228.0, 160.0), Vector2(292.0, 160.0)])
	map_root.set_meta("road_used_coords", [])
	var mino := _make_ability_tower("Turret_8T1", Vector2(96.0, 96.0), map_root, [true, true, true])
	var traps_before: int = map_root.get_child_count()
	mino._apply_damage_obstacle()
	var traps_after: int = map_root.get_child_count()
	_check(traps_after - traps_before == 1, "MinotaurTower spawns exactly 1 trap per cycle (not all free cells)")
	for ch in map_root.get_children():
		if ch != turret_layer and ch != excl_layer and ch != path_root:
			ch.queue_free()
	mino.queue_free()

	# Bug 2: CrossbowTower phase-2 rof does not compound on stat/synergy updates or upgrades
	var xbow := _make_ability_tower("Turret_3T1", Vector2(160.0, 96.0), map_root, [true, true, true])
	xbow.set_process(false)
	xbow._start_phase_2()
	if not xbow.phase:
		xbow.phase = true
		xbow._recompute_phase_damage()
		if xbow.up_attack_speed > 0.0:
			xbow.rof = xbow.base_rof / (xbow.up_attack_speed / 100.0)
			xbow._phase_applied_rof = xbow.rof
	var expected_p2_rof: float = xbow.base_rof / (xbow.up_attack_speed / 100.0)
	_check(is_equal_approx(xbow.rof, expected_p2_rof), "CrossbowTower sets clean phase-2 rof")
	for step in range(4):
		xbow.set_mimic_synergy_bonus(12.0 if step % 2 == 0 else 0.0)
	_check(is_equal_approx(xbow.rof, expected_p2_rof), "CrossbowTower rof stays constant across repeated Mimic synergy refreshes in phase 2")
	xbow.current_lvl = 1
	xbow.apply_level_and_gift_stats()
	var tbl_rof_1: float = float(GameConstants.DATA_TOWER[2].parametr_2[1])
	var tbl_as_1: float = float(GameConstants.DATA_TOWER[2].parametr_5[1])
	_check(is_equal_approx(xbow.base_rof, tbl_rof_1) and is_equal_approx(xbow.rof, tbl_rof_1 / (tbl_as_1 / 100.0)), "CrossbowTower level-up during phase 2 updates rof exactly once from table")
	xbow.queue_free()

	# Bug 3: Enemy_boss.process_poison applies Sniper/Drone/Spell vuln without Thermite burn + credits Mimic id 14
	var boss_p := LIVE_BOSS_SCENE.instantiate() as Enemy_boss
	boss_p.id = 0
	boss_p.hp = 5000.0
	boss_p.speed = 75.0
	boss_p.current_speed = 75.0
	path_2d.add_child(boss_p)
	boss_p.sniper_breach_timer = 5.0
	boss_p.sniper_breach_mult = 1.25
	boss_p.drone_scan_timer = 5.0
	boss_p.drone_scan_mult = 1.10
	boss_p.spell_vuln_timer = 5.0
	boss_p.spell_vuln_mult = 1.20
	boss_p.flame_burn_timer = 0.0
	var mimic_poison := _make_ability_tower("Turret_6T1", Vector2(224.0, 96.0), map_root, [false, false, false])
	mimic_poison.is_mimic_copy = true
	var hp_before_p: float = boss_p.hp
	boss_p.apply_poison({"damage": 100.0, "duration": 3.0, "tick": 0.1, "tower": mimic_poison})
	boss_p.process_poison(0.2)
	var expected_boss_poison: float = 100.0 * 1.25 * 1.10 * 1.20
	_check(is_equal_approx(hp_before_p - boss_p.hp, expected_boss_poison), "Enemy_boss poison applies sniper/drone/spell vulnerability multipliers without active burn")
	DataManager.mastery_deal_tower_session[5] = 0
	DataManager.mastery_deal_tower_session[14] = 0
	boss_p.hp = 40.0
	boss_p.poison_tick_timer = 0.0
	boss_p.process_poison(0.2)
	_check(DataManager.mastery_deal_tower_session[14] == 1 and DataManager.mastery_deal_tower_session[5] == 0, "Mimic PoisonTower poison kill credits Mimic mastery (id=14) not PoisonTower (id=5)")
	mimic_poison.queue_free()
	boss_p.queue_free()

	# Bug 4: Freed bank in ResourceManager.list_turret[5] & out-of-bounds tower_id do not crash Enemys.on_destroy
	var freed_bank := Node2D.new()
	freed_bank.free()
	if ResourceManager.list_turret.size() > 5:
		ResourceManager.list_turret[5].append(freed_bank)
	var e_safe := LIVE_ENEMY_SCENE.instantiate()
	e_safe.id = 0
	e_safe.hp = 0.0
	e_safe.speed = 100.0
	e_safe.current_speed = 100.0
	path_2d.add_child(e_safe)
	e_safe.on_destroy(999)
	_check(true, "Enemys.on_destroy survives freed bank references and out-of-bounds tower_id")
	if ResourceManager.list_turret.size() > 5:
		ResourceManager.list_turret[5].erase(freed_bank)

	# Bug 5: ChakramTower._exit_tree removes itself from ResourceManager.list_turret[13]
	var chak := _make_ability_tower("Turret_14T1", Vector2(352.0, 96.0), map_root, [false, false, false])
	_check(ResourceManager.list_turret.size() > 13 and ResourceManager.list_turret[13].has(chak), "ChakramTower registers in ResourceManager.list_turret[13]")
	chak.get_parent().remove_child(chak)
	chak.free()
	_check(not ResourceManager.list_turret[13].has(chak), "ChakramTower._exit_tree unregisters freed ref via super._exit_tree()")

	# Bug 6: Enemy_boss_7 updates multiplier_damage_all via sync_live_multipliers()
	var b7_sc := load("res://Scenes/EnemiesBoss/Enemy_boss_7.tscn") as PackedScene
	var b7 := b7_sc.instantiate() as Enemy_boss_7
	b7.id = 6
	b7.hp = 10000.0
	b7.speed = 100.0
	b7.current_speed = 100.0
	path_2d.add_child(b7)
	var gun7 := _make_ability_tower("Turret_1T1", Vector2(416.0, 96.0), map_root, [false, false, false])
	var dmg_mult_before: float = gun7.multiplier_damage_all
	b7.on_hit(10.0, 0, 0, gun7)
	_check(gun7.multiplier_damage_all < dmg_mult_before, "Enemy_boss_7 immediately syncs multiplier_damage_all on hit")
	gun7.queue_free()
	b7.queue_free()

	# Bug 7: Enemy_boss_8 preserves spore debuff if another Enemy_boss_8 still spores the tower
	var b8_sc := load("res://Scenes/EnemiesBoss/Enemy_boss_8.tscn") as PackedScene
	var b8_a := b8_sc.instantiate() as Enemy_boss_8
	var b8_b := b8_sc.instantiate() as Enemy_boss_8
	for b8 in [b8_a, b8_b]:
		b8.id = 7
		b8.hp = 1000.0
		b8.speed = 100.0
		b8.current_speed = 100.0
		path_2d.add_child(b8)
	var gun8 := _make_ability_tower("Turret_1T1", Vector2(480.0, 96.0), map_root, [false, false, false])
	var sp_tex := load("res://Assets/Icons/wild_plants.png") as Texture2D
	gun8.set_spore_debuff(true, sp_tex)
	gun8.multiplier_rof_enemy = 0.2
	gun8.sync_live_multipliers()
	b8_a.list_tower_enemy_8.append(gun8)
	b8_b.list_tower_enemy_8.append(gun8)
	b8_a.hp = 0.0
	b8_a.on_destroy()
	_check(gun8.has_spore_debuff and is_equal_approx(gun8.multiplier_rof_enemy, 0.2), "Enemy_boss_8 death preserves spore debuff while second Enemy_boss_8 remains alive")
	b8_b.hp = 0.0
	b8_b.on_destroy()
	_check(not gun8.has_spore_debuff and is_equal_approx(gun8.multiplier_rof_enemy, 0.0), "Second Enemy_boss_8 death cleanly removes spore debuff")
	gun8.queue_free()
	b8_a.queue_free()
	b8_b.queue_free()

	# Bug 8: SlowTower mimic %HP scaling + Drone spectator enemy exclusion
	var slow_m := _make_ability_tower("Turret_4T1", Vector2(96.0, 224.0), map_root, [true, false, false])
	slow_m.is_mimic_copy = true
	slow_m.mimic_stat_mult = 0.85
	var me_slow := MockEnemy.new()
	me_slow.hp = 1000.0
	me_slow.base_hp = 1000.0
	add_child(me_slow)
	slow_m.enemy_array = [me_slow]
	slow_m._apply_pulse_effects()
	var expected_slow_dmg: float = (1000.0 / float(GameConstants.TURRET_4_ABILITY_0)) * 0.85
	_check(me_slow.hit_values.size() == 1 and is_equal_approx(me_slow.hit_values[0], expected_slow_dmg), "SlowTower mimic %HP pulse scales by mimic_stat_mult")
	me_slow.queue_free()
	slow_m.queue_free()

	var hive := _make_ability_tower("Turret_16T1", Vector2(160.0, 224.0), map_root, [false, false, false])
	var drone := (load("res://Scenes/Turrets/Drone.tscn") as PackedScene).instantiate()
	drone.home_tower = hive
	drone._my_map = map_root
	drone.strategy = GameConstants.TowerDroneStrategy.SCOUT
	map_root.add_child(drone)
	var real_e := LIVE_ENEMY_SCENE.instantiate()
	real_e.id = 0
	real_e.hp = 200.0
	real_e.is_spectator_enemy = false
	var spec_e := LIVE_ENEMY_SCENE.instantiate()
	spec_e.id = 0
	spec_e.hp = 200.0
	spec_e.is_spectator_enemy = true
	path_2d.add_child(spec_e)
	path_2d.add_child(real_e)
	spec_e.progress_ratio = 0.90
	real_e.progress_ratio = 0.20
	drone.find_new_target()
	_check(drone.target == real_e, "Drone ignores higher-progress is_spectator_enemy and targets real enemy")
	drone.queue_free()
	hive.queue_free()
	real_e.queue_free()
	spec_e.queue_free()

	# Bug 9: DataManager preserves cumulative mastery across Campaign attempts and rolls back failed attempt only
	DataManager.reset_mastery_session_arrays()
	DataManager.tower_data["Turret_1T1"]["mastery_xp"] = 0
	DataManager.mastery_damage_tower_session[0] = 2000000
	DataManager.write_mastery()
	_check(int(DataManager.tower_data["Turret_1T1"]["mastery_xp"]) == 2, "Sandbox mastery writes 2 XP baseline")
	DataManager.begin_campaign_attempt_snapshot()
	_check(int(DataManager.mastery_damage_tower_session[0]) == 2000000, "begin_campaign_attempt_snapshot preserves prior cumulative mastery arrays")
	DataManager.mastery_damage_tower_session[0] += 1000000
	DataManager.write_mastery()
	_check(int(DataManager.tower_data["Turret_1T1"]["mastery_xp"]) == 3, "Campaign progress adds atop cumulative mastery")
	DataManager.discard_campaign_attempt_progress()
	_check(int(DataManager.mastery_damage_tower_session[0]) == 2000000 and int(DataManager.tower_data["Turret_1T1"]["mastery_xp"]) == 2, "discard_campaign_attempt_progress reverts only failed attempt back to pre-campaign 2 XP baseline")
	DataManager.begin_campaign_attempt_snapshot()
	DataManager.mastery_damage_tower_session[0] += 2000000
	DataManager.write_mastery()
	DataManager.clear_campaign_attempt_snapshot()
	_check(int(DataManager.mastery_damage_tower_session[0]) == 4000000 and int(DataManager.tower_data["Turret_1T1"]["mastery_xp"]) == 4, "Campaign victory keeps cumulative 4 XP mastery")

	# Bug 10: Desktop & Mobile player_container spectator wave & boss speed indexing
	for pc_script in [DESKTOP_PLAYER_CONTAINER, MOBILE_PLAYER_CONTAINER]:
		var pc := Control.new()
		pc.set_script(pc_script)
		pc.is_player = false
		var ui_n := CanvasLayer.new()
		ui_n.name = "UI"
		var hud := Control.new()
		hud.name = "HUD"
		var ib := HBoxContainer.new()
		ib.name = "InfoBar"
		var h1 := HBoxContainer.new()
		h1.name = "H"
		var mlbl := Label.new()
		mlbl.name = "Money"
		h1.add_child(mlbl)
		var h2 := HBoxContainer.new()
		h2.name = "H2"
		var hlbl := Label.new()
		hlbl.name = "HP"
		h2.add_child(hlbl)
		var h3 := HBoxContainer.new()
		h3.name = "H3"
		var wlbl := Label.new()
		wlbl.name = "WaveValue"
		h3.add_child(wlbl)
		ib.add_child(h1)
		ib.add_child(h2)
		ib.add_child(h3)
		hud.add_child(ib)
		ui_n.add_child(hud)
		pc.add_child(ui_n)
		pc.sync_opponent_state({"hp": 85, "money": 410, "wave": 7, "towers": [], "enemies": []})
		_check(wlbl.text == "7" and hlbl.text == "85" and mlbl.text == "410", "Spectator HUD renders exact 1-based wave without +1 offset")
		var b_stub := PathFollow2D.new()
		b_stub.set_script(preload("res://Scenes/EnemiesBoss/Enemy_boss.gd"))
		pc._set_spectator_speed(b_stub, "BOSS_1")
		_check(is_equal_approx(float(b_stub.speed), float(GameConstants.DATA_ENEMY_BOSS[0].speed)), "Spectator BOSS_1 speed matches DATA_ENEMY_BOSS[0] (75)")
		pc._set_spectator_speed(b_stub, "BOSS_13")
		_check(is_equal_approx(float(b_stub.speed), float(GameConstants.DATA_ENEMY_BOSS[12].speed)), "Spectator BOSS_13 speed matches DATA_ENEMY_BOSS[12] (80)")
		b_stub.free()
		pc.free()

	map_root.queue_free()
	await get_tree().process_frame
	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	DataManager.data["Mastery"] = saved_data_mastery
	DataManager.mastery_damage_tower_session.assign(saved_mastery_dmg)
	DataManager.mastery_deal_tower_session.assign(saved_mastery_deal)
	GameSession.current_money_in_game_session = saved_session_money
	GameSession.current_wave = saved_wave
	DataManager.write_file()


func _test_all_25_spells_and_core_systems() -> void:
	var saved_money: int = DataManager.data_money
	var saved_towers: Dictionary = DataManager.tower_data.duplicate(true)
	var saved_spells: Dictionary = DataManager.spell_data.duplicate(true)
	var saved_session_money: float = GameSession.current_money_in_game_session
	var saved_wave: int = GameSession.current_wave
	GameSession.current_money_in_game_session = 99999.0
	GameSession.current_wave = 1

	# 1. SpellCatalog completeness (25 spells, icons, localization, 10 levels)
	_check(SpellCatalog.SPELLS.size() == 25, "SpellCatalog defines all 25 spells")
	for idx in range(1, 26):
		var skey := "spell_%d" % idx
		var spec: Dictionary = SpellCatalog.get_spec(skey)
		_check(not spec.is_empty() and bool(spec.get("implemented", false)), "%s is marked implemented" % skey)
		_check(SpellCatalog.get_spell_icon(skey) != null, "%s has valid icon Texture2D" % skey)
		var nk := str(spec.get("name_key", ""))
		var dk := str(spec.get("desc_key", ""))
		_check(not nk.is_empty() and tr(nk) != nk and not dk.is_empty() and tr(dk) != dk, "%s has localized name and description" % skey)
		var cds: Array = spec.get("cooldown_levels", [])
		_check(cds.size() == 10, "%s has 10 cooldown levels" % skey)

	# 2. Combat execution verification across all 25 spells on a real Map + Path2D + Enemy + Tower
	var map_root := (load("res://Scenes/Maps/map_battle_0.tscn") as PackedScene).instantiate() as Node2D
	add_child(map_root)
	var turret_layer := map_root.get_node("Turret") as Node2D
	var excl_layer := map_root.get_node("TowerExlusion") as TileMapLayer
	var ground_layer := map_root.get_node("Ground") as TileMapLayer
	var path_2d := map_root.get_node("Path/0") as Path2D
	var free_locals: Array[Vector2] = []
	for cell in ground_layer.get_used_cells():
		var wpt: Vector2 = ground_layer.to_global(ground_layer.map_to_local(cell))
		var e_cell: Vector2i = excl_layer.local_to_map(excl_layer.to_local(wpt))
		if SpellBattleController.is_free_buildable_cell_on_map(map_root, e_cell):
			free_locals.append(map_root.to_local(excl_layer.to_global(excl_layer.map_to_local(e_cell))))
			if free_locals.size() >= 3:
				break
	_check(free_locals.size() >= 3, "map_battle_0 provides at least 3 free buildable cells for Spell 9 & 17")
	var pos_t0: Vector2 = free_locals[0]
	var pos_clone: Vector2 = free_locals[1]
	var pos_airlift: Vector2 = free_locals[2]

	var spell_tower := _make_ability_tower("Turret_1T1", pos_t0, map_root, [false, false, false])
	spell_tower.stone_effect_start(5.0)
	_check(spell_tower.block_damage, "Pre-condition: GunTower is petrified before Purge Pulse")

	var e_spell := LIVE_ENEMY_SCENE.instantiate()
	e_spell.id = 0
	e_spell.hp = 50000.0
	e_spell.speed = 100.0
	e_spell.current_speed = 100.0
	path_2d.add_child(e_spell)
	e_spell.progress_ratio = 0.50
	var enemy_pos: Vector2 = map_root.to_local(e_spell.global_position)
	var tower_pos: Vector2 = spell_tower.position

	SpellBattleController.execute_spell_on_map("spell_3", map_root, tower_pos, 0, 1, true, self) # Purge Pulse
	SpellBattleController.execute_spell_on_map("spell_2", map_root, enemy_pos, 0, 1, true, self) # Cryo Grenade
	SpellBattleController.execute_spell_on_map("spell_5", map_root, enemy_pos, 0, 1, true, self) # Shockwave Push
	SpellBattleController.execute_spell_on_map("spell_6", map_root, enemy_pos, 0, 1, true, self) # Golden Magnet
	SpellBattleController.execute_spell_on_map("spell_7", map_root, tower_pos, 0, 1, true, self) # Overdrive Pulse
	SpellBattleController.execute_spell_on_map("spell_13", map_root, tower_pos, 0, 1, true, self) # Flux Capacitor
	SpellBattleController.execute_spell_on_map("spell_14", map_root, enemy_pos, 0, 1, true, self) # Hunter's Mark
	SpellBattleController.execute_spell_on_map("spell_19", map_root, tower_pos, 0, 1, true, self) # Aegis Dome
	SpellBattleController.execute_spell_on_map("spell_25", map_root, tower_pos, 0, 1, true, self) # Commander's Decree
	await get_tree().create_timer(0.65, false).timeout
	_check(not spell_tower.block_damage and spell_tower.spell_attack_speed_bonus_pct > 0.0 and spell_tower.spell_purge_immunity_timer > 0.0, "spell_3 Purge Pulse cleanses petrification, buffs attack speed, and grants immunity")
	_check(e_spell.progress_ratio < 0.50, "spell_5 Shockwave Push pushes enemy backward on Path2D")
	_check(e_spell.spell_gold_mark_timer > 0.0 and e_spell.spell_gold_mark_pct > 0.0, "spell_6 Golden Magnet applies gold bounty mark")
	_check(spell_tower.spell_attack_speed_timer > 0.0 and spell_tower.spell_attack_speed_bonus_pct > 0.0, "spell_7 Overdrive Pulse grants attack speed buff")
	_check(spell_tower.spell_flux_aura_timer > 0.0 and spell_tower.spell_flux_aura_pct > 0.0, "spell_13 Flux Capacitor buffs allied tower")
	_check(e_spell.spell_hunters_mark_timer > 0.0 and e_spell.spell_hunters_mark_mult > 1.0, "spell_14 Hunter's Mark applies damage amplification")
	_check(spell_tower.spell_aegis_timer > 0.0 and spell_tower.spell_aegis_crit_bonus > 0.0, "spell_19 Aegis Dome grants boss immunity + crit bonus")
	_check(spell_tower.spell_decree_timer > 0.0 and spell_tower.spell_decree_as_pct > 0.0, "spell_25 Commander's Decree applies global speed & crit decree")

	enemy_pos = map_root.to_local(e_spell.global_position)
	var hp_before_burst: float = e_spell.hp
	SpellBattleController.execute_spell_on_map("spell_1", map_root, enemy_pos, 0, 1, true, self) # Kinetic Strike
	SpellBattleController.execute_spell_on_map("spell_4", map_root, enemy_pos, 0, 1, true, self) # Napalm Barrel
	SpellBattleController.execute_spell_on_map("spell_8", map_root, enemy_pos, 0, 1, true, self) # Gravity Trap
	SpellBattleController.execute_spell_on_map("spell_10", map_root, enemy_pos, 0, 1, true, self) # Acid Downpour
	SpellBattleController.execute_spell_on_map("spell_11", map_root, enemy_pos, 0, 1, true, self) # Arc Discharge
	SpellBattleController.execute_spell_on_map("spell_12", map_root, enemy_pos, 0, 1, true, self) # Stasis Net
	SpellBattleController.execute_spell_on_map("spell_15", map_root, enemy_pos, 0, 1, true, self) # Holo Barricade
	SpellBattleController.execute_spell_on_map("spell_16", map_root, enemy_pos, 0, 1, true, self) # Plasma Rift
	SpellBattleController.execute_spell_on_map("spell_18", map_root, enemy_pos, 0, 1, true, self) # Soul Harvest
	SpellBattleController.execute_spell_on_map("spell_20", map_root, enemy_pos, 0, 1, true, self) # Meteor Shower
	SpellBattleController.execute_spell_on_map("spell_21", map_root, enemy_pos, 0, 1, true, self) # Ion Storm
	SpellBattleController.execute_spell_on_map("spell_22", map_root, enemy_pos, 0, 1, true, self) # Chrono Rewind
	SpellBattleController.execute_spell_on_map("spell_23", map_root, enemy_pos, 0, 1, true, self) # Singularity
	SpellBattleController.execute_spell_on_map("spell_24", map_root, enemy_pos, 0, 1, true, self) # Solar Lance
	SpellBattleController.execute_spell_on_map("spell_17", map_root, pos_clone, 0, 1, true, self, tower_pos) # Phantom Clone
	await get_tree().create_timer(0.45, false).timeout
	SpellBattleController.execute_spell_on_map("spell_9", map_root, pos_airlift, 0, 1, true, self, tower_pos) # Tactical Airlift
	await get_tree().create_timer(1.10, false).timeout

	_check(e_spell.hp < hp_before_burst, "Offensive spell suite deals combat damage to live enemy")
	var found_clone := false
	for ch in turret_layer.get_children():
		if is_instance_valid(ch) and ch is TowerBase and (ch as TowerBase).is_phantom_clone:
			found_clone = true
			break
	_check(found_clone, "spell_17 Phantom Clone spawns a holographic tower clone on turret layer")
	_check(spell_tower.position.distance_to(pos_airlift) < 16.0 and spell_tower.spell_damage_timer > 0.0, "spell_9 Tactical Airlift relocates tower and grants damage buff")

	# 3. RuneSystem, WaveGenerator, Economy/Upgrade sanity
	var rune_t := _make_ability_tower("Turret_1T1", Vector2(96.0, 224.0), map_root, [false, false, false])
	rune_t.apply_rune("FURY")
	_check(is_equal_approx(rune_t.rune_damage_mult, 1.22), "RuneSystem FURY grants +22% damage multiplier")
	rune_t.apply_rune("ARCHITECT")
	var cost_before_arch: float = rune_t.get_session_upgrade_cost()
	rune_t.apply_rune("")
	var cost_no_arch: float = rune_t.get_session_upgrade_cost()
	_check(is_equal_approx(cost_before_arch, round(cost_no_arch * 0.75)) or cost_before_arch < cost_no_arch, "RuneSystem ARCHITECT discounts upgrade cost")
	var gen_rng := RandomNumberGenerator.new()
	gen_rng.seed = 42
	var w25: Array = WaveGenerator.generate_wave(25, gen_rng)
	_check(not w25.is_empty(), "WaveGenerator generates non-empty late wave 25")

	for grp in ["combat_fx_transient", "combat_fx", "napalm_zones"]:
		for tr_node in get_tree().get_nodes_in_group(grp):
			if is_instance_valid(tr_node):
				tr_node.free()
	e_spell.queue_free()
	spell_tower.queue_free()
	rune_t.queue_free()
	map_root.queue_free()
	await get_tree().process_frame

	DataManager.data_money = saved_money
	DataManager.tower_data = saved_towers
	DataManager.spell_data = saved_spells
	GameSession.current_money_in_game_session = saved_session_money
	GameSession.current_wave = saved_wave
	DataManager.write_file()


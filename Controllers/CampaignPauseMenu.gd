extends CanvasLayer

# Kept independent of the game's regular pause button, which can already pause the tree.
var game_scene: Node
var was_paused := false
var panel_root: Control
var confirm_box: VBoxContainer
var menu_box: VBoxContainer

func initialize(scene: Node) -> void:
	game_scene = scene
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_menu()
	hide()

func open_menu() -> void:
	if not is_instance_valid(game_scene):
		return
	var end_controller = game_scene.get("game_end_controller")
	if is_instance_valid(end_controller) and "game_ended" in end_controller and end_controller.game_ended:
		return
	if visible:
		if confirm_box.visible:
			_show_confirmation(false)
		else:
			_resume()
	else:
		_open()

func _input(event: InputEvent) -> void:
	# Escape works even when the project's InputMap was not replaced or differs.
	if not (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)):
		return
	if not is_instance_valid(game_scene) or GameSession.game_mode not in [GameConstants.GameMode.CAMPAIGN, GameConstants.GameMode.SANDBOX]:
		return
	var end_controller = game_scene.get("game_end_controller")
	if is_instance_valid(end_controller) and "game_ended" in end_controller and end_controller.game_ended:
		return
	get_viewport().set_input_as_handled()
	if visible:
		if confirm_box.visible:
			_show_confirmation(false)
		else:
			_resume()
	else:
		_open()

func _build_menu() -> void:
	panel_root = Control.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel_root)
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.mouse_filter = Control.MOUSE_FILTER_STOP

	var shade = ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.04, 0.76)
	panel_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	panel_root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -150
	panel.offset_bottom = 150
	var frame = StyleBoxFlat.new()
	frame.bg_color = Color("20262d")
	frame.border_color = Color("b79a60")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(10)
	frame.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", frame)

	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)
	var title = Label.new()
	title.text = tr("KEY_PAUSE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Typography.D_HEADER)
	title.add_theme_color_override("font_color", Color("f4e2b9"))
	stack.add_child(title)

	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 10)
	stack.add_child(menu_box)
	_add_button(menu_box, tr("KEY_PAUSE_RESUME"), _resume)
	_add_button(menu_box, tr("KEY_PAUSE_MAP") if GameSession.game_mode == GameConstants.GameMode.CAMPAIGN else tr("KEY_PAUSE_MENU"), _request_exit)

	confirm_box = VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 8)
	stack.add_child(confirm_box)
	var warning = Label.new()
	warning.text = tr("KEY_PAUSE_WARNING")
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_box.add_child(warning)
	_add_button(confirm_box, tr("KEY_PAUSE_EXIT"), _exit_to_map)
	_add_button(confirm_box, tr("KEY_SKIN_CANCEL"), _cancel_exit)
	confirm_box.hide()

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 45)
	button.pressed.connect(callback)
	parent.add_child(button)

func _open() -> void:
	var build_controller = game_scene.get("build_controller")
	if is_instance_valid(build_controller) and "build_mode" in build_controller and build_controller.build_mode:
		build_controller.cancel_build_mode()
	was_paused = get_tree().paused
	_show_confirmation(false)
	show()
	get_tree().paused = true
	AudioManager.play_sfx("pause_toggle")
	menu_box.get_child(0).grab_focus()

func _resume() -> void:
	AudioManager.play_sfx("pause_toggle")
	hide()
	get_tree().paused = was_paused

func _request_exit() -> void:
	_show_confirmation(true)

func _cancel_exit() -> void:
	_show_confirmation(false)

func _show_confirmation(value: bool) -> void:
	confirm_box.visible = value
	menu_box.visible = not value

func _exit_to_map() -> void:
	# Leaving is not a victory or a defeat and does not grant rewards.
	GameSession.reset_battle_runtime_state()
	GameSession.current_wave = 0
	GameSession.current_game_score = 0
	GameSession.base_health = 10
	GameSession.speed_game = GameConstants.SPEED_NORMAL_GAME_SESSION
	Engine.time_scale = 1.0
	get_tree().paused = false
	var is_mobile := OS.get_name() in ["Android", "iOS"]
	var destination := "res://Scenes/Mobile/company_world_mobile.tscn" if is_mobile else "res://Scenes/UI/company_world.tscn"
	if GameSession.game_mode == GameConstants.GameMode.SANDBOX:
		destination = "res://Scenes/Mobile/Menu_mobile.tscn" if is_mobile else "res://Scenes/UI/Menu.tscn"
	get_tree().change_scene_to_file(destination)

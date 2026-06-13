extends Button

var turret_type
var turret_index
var main_scene

func _get_drag_data(at_position):
	# Запускаем режим стройки
	main_scene.build_controller.initiate_build_mode(turret_type, turret_index)
	
	# Создаем визуальный превью для драга (Godot сам таскает его)
	var preview = Control.new()
	var icon = TextureRect.new()
	# Берем иконку из кнопки или загружаем
	var tex_rect = get_node_or_null("Icon") # Путь к иконке внутри кнопки
	if tex_rect:
		icon.texture = tex_rect.texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			icon.size = Vector2(120, 120) 
		else:
			icon.size = Vector2(60, 60)
		icon.position = -icon.size / 2 # Центрируем
	
	preview.add_child(icon)
	set_drag_preview(preview)
	
	return "building" # Возвращаем данные (любые)

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# Проверяем, был ли успешный сброс (drop)
		# is_drag_successful() возвращает true, если мышь отпустили над Control, который принимает данные.
		# Но у нас "Fake Drag" (мы строим на карте), поэтому нам это не важно.
		
		if main_scene.build_controller.build_mode:
			# Принудительно обновляем позицию перед постройкой
			main_scene.build_controller.update_tower_preview()
			
			if main_scene.build_controller.build_valid:
				main_scene.build_controller.verify_and_build()
			
			main_scene.build_controller.cancel_build_mode()

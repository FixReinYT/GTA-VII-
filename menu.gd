extends Control

const Story = preload("res://story.gd")
const GOLD := Color("#ffbc69")
var intro := Control.new()
var screen := Control.new()
var actions := VBoxContainer.new()
var details := Label.new()
var start_button: Button
var showing_intro := true
var elapsed := 0.0

func fill(parent: Control, item: Control):
	parent.add_child(item)
	item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func caption(parent: Control, words: String, pos: Vector2, size_px: int, tint: Color) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.text = words
	label.position = pos
	label.add_theme_font_size_override("font_size",size_px)
	label.modulate = tint
	return label

func _ready():
	fill(self,screen)
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://art/night.webp")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fill(screen,backdrop)
	var shade := TextureRect.new()
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color("#07101b"),Color("#081323ec"),Color("#07111d22")])
	ramp.offsets = PackedFloat32Array([0,0.39,1])
	var grad := GradientTexture2D.new()
	grad.gradient = ramp
	grad.fill_to = Vector2(1,0)
	shade.texture = grad
	fill(screen,shade)
	caption(screen,"ЛЕЙК-СИТИ    /    СЮЖЕТНЫЙ РЕЖИМ",Vector2(52,63),15,GOLD)
	caption(screen,"LAKE CITY",Vector2(47,98),82,Color.WHITE)
	caption(screen,"Четыре минуты",Vector2(54,200),26,Color.WHITE)
	screen.add_child(actions)
	actions.position = Vector2(52,295)
	actions.add_theme_constant_override("separation",9)
	var saved := Story.read_chapter()
	var launch := func():
		if saved==4:
			Story.save_chapter(0)
		get_tree().change_scene_to_file("res://city.tscn")
	start_button = choice("Продолжить · глава %d" % (saved+1) if saved in [1,2,3] else ("Пройти заново" if saved==4 else "Начать историю"),launch)
	choice("Управление",func(): details.text = "WASD / стрелки — движение   ·   Пробел — тормоз\nEsc — пауза   ·   R — начать миссию заново")
	choice("Во весь экран",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	choice("Выйти",func(): get_tree().quit())
	screen.add_child(details)
	details.position = Vector2(53,545)
	details.text = "Четыре главы   ·   Автосохранение между главами"
	fill(self,intro)
	var black := ColorRect.new()
	black.color = Color("#080d15")
	fill(intro,black)
	var logo := caption(intro,"L A K E   C I T Y",Vector2.ZERO,58,Color.WHITE)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.modulate.a = 0
	var anim := create_tween()
	anim.tween_property(logo,"modulate",GOLD,0.8)
	anim.tween_interval(0.6)
	anim.tween_property(logo,"modulate:a",0.0,0.6)
	var audio := AudioStreamPlayer.new()
	add_child(audio)
	audio.stream = preload("res://art/ident.wav")
	audio.play()
	screen.hide()

func choice(words: String, action: Callable) -> Button:
	var button := Button.new()
	actions.add_child(button)
	button.text = words
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(300,43)
	button.add_theme_font_size_override("font_size",20)
	for state in ["normal","hover","focus","pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#1b2b3eee") if state=="normal" else Color("#654529")
		style.border_width_left = 3
		style.border_color = Color("#425367") if state=="normal" else GOLD
		style.content_margin_left = 16
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(action)
	return button

func finish_intro():
	showing_intro = false
	intro.hide()
	screen.show()
	start_button.grab_focus()

func _process(dt):
	elapsed += dt
	if showing_intro and elapsed >= 2.2:
		finish_intro()

func _input(event):
	if showing_intro and event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		finish_intro()

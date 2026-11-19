extends Node3D

const ROUTE := [Vector3(0,0,-24), Vector3(0,0,-88), Vector3(64,0,-88), Vector3(64,0,-148)]
const TITLES := ["ПРАЧЕЧНАЯ  /  Остановись у Рэя", "ПОГОНЯ  /  Доберись до эстакады", "ЭСТАКАДА  /  Уйди по боковой улице", "ГАРАЖ  /  Остановись у ворот"]
var car := CharacterBody3D.new()
var patrol := Node3D.new()
var marker := Node3D.new()
var camera := Camera3D.new()
var hud := Label.new()
var stage := 0
var speed := 0.0
var clock := 0.0
var trail: Array[Vector3] = []
var sample_time := 0.0
var capture := 0.0
var ended := false
var beacon: MeshInstance3D
var briefing := "Вера: Мотор работает. Рэй, я у входа."
var materials := {}

func block(parent: Node3D, pos: Vector3, size: Vector3, color: String, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	if not materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color)
		materials[color] = mat
	mesh.material_override = materials[color]
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var wall := StaticBody3D.new()
		parent.add_child(wall)
		wall.position = pos
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		wall.add_child(shape)
	return mesh

func model(parent: Node3D, asset: String, pos: Vector3, factor: float) -> Node3D:
	var scene: PackedScene = load("res://art/kaykit/%s.gltf" % asset)
	var visual: Node3D = scene.instantiate()
	parent.add_child(visual)
	visual.position = pos
	visual.scale = Vector3.ONE * factor
	return visual

func vehicle(body: Node3D, asset: String):
	var visual := model(body,asset,Vector3.UP*0.31,5.0)
	visual.rotation.y = PI

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel"):
		var pause_screen := AcceptDialog.new()
		pause_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(pause_screen)
		pause_screen.title = "Lake City"
		pause_screen.dialog_text = "Игра на паузе"
		pause_screen.ok_button_text = "Продолжить"
		pause_screen.add_button("Главное меню",true,"menu")
		var resume := func():
			get_tree().paused = false
			pause_screen.queue_free()
		pause_screen.confirmed.connect(resume)
		pause_screen.canceled.connect(resume)
		pause_screen.custom_action.connect(func(_id):
			get_tree().paused = false
			get_tree().change_scene_to_file("res://menu.tscn"))
		get_tree().paused = true
		pause_screen.popup_centered()
		get_viewport().set_input_as_handled()

func _ready():
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-52,-35,0)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("bbcee6")
	world.environment.ambient_light_energy = 0.85
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color("708794")
	world.environment.fog_density = 0.005
	add_child(world)
	block(self,Vector3(30,-0.55,-70),Vector3(340,1,340),"d3e4eb")
	for x in [-64,0,64,128]:
		block(self,Vector3(x,-0.07,-72),Vector3(15,0.12,240),"455467")
	for z in [8,-40,-88,-148,-196]:
		block(self,Vector3(32,-0.065,z),Vector3(210,0.12,15),"455467")
	var rng := RandomNumberGenerator.new()
	rng.seed = 171
	for x in range(-80,151,16):
		for z in range(-184,28,16):
			if absi(x)%64 < 12 or mini(mini(absi(z+40),absi(z+88)),mini(absi(z+148),absi(z-8))) < 12:
				continue
			var kinds := ["building_A_withoutBase","building_B_withoutBase","building_D_withoutBase","building_F_withoutBase"]
			var building := model(self,kinds[rng.randi_range(0,3)],Vector3(x,0,z),5.4)
			building.rotation.y = rng.randi_range(0,3)*PI/2
			var wall := StaticBody3D.new()
			add_child(wall)
			wall.position = Vector3(x,3,z)
			var collider := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(10.5,6,10.5)
			collider.shape = box
			wall.add_child(collider)
	for z in range(-175,25,16):
		for x in [-8,72]:
			model(self,"streetlight",Vector3(x,0,z),5)
	for prop in [["firehydrant",8,-25],["bench",8,-21],["dumpster",73,-150]]:
		model(self,prop[0],Vector3(prop[1],0,prop[2]),4)
	for x in range(-72,145,12):
		block(self,Vector3(x,3.5,-94),Vector3(0.8,7,0.8),"384450",true)
	block(self,Vector3(32,7,-94),Vector3(226,1,5),"26313e")
	add_child(car)
	vehicle(car,"car_sedan")
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2,1.5,4.4)
	collider.shape = shape
	car.add_child(collider)
	collider.position.y = 0.85
	add_child(patrol)
	vehicle(patrol,"car_police")
	beacon = block(patrol,Vector3(0,1.85,0.2),Vector3(1.35,0.23,0.45),"ff463b")
	patrol.hide()
	add_child(marker)
	block(marker,Vector3(0,3,0),Vector3(0.45,6,0.45),"ffba52")
	marker.position = ROUTE[0]
	add_child(camera)
	camera.current = true
	camera.far = 400
	camera.position = Vector3(0,6,10)
	camera.look_at(car.position)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.position = Vector2(16,16)
	panel.add_child(hud)
	hud.add_theme_font_size_override("font_size",17)
	show_status()

func show_status():
	var dist := int(car.position.distance_to(marker.position))
	hud.text = "LAKE CITY    /    ЧЕТЫРЕ МИНУТЫ\n%s   ·   %d м\n%s\n%d км/ч    |    WASD / стрелки — руль и газ    ·    Пробел — тормоз    ·    R — заново" % [TITLES[stage],dist,briefing,roundi(absf(speed)*3.6)]

func _physics_process(dt):
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene.call_deferred()
		return
	if ended:
		return
	clock += dt
	var gas := int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")) - int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"))
	var steer := int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")) - int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"))
	speed = move_toward(speed,gas*24.0 if gas >= 0 else -8.0,dt*(24 if Input.is_physical_key_pressed(KEY_SPACE) else 7))
	if Input.is_physical_key_pressed(KEY_SPACE):
		speed = move_toward(speed,0,40*dt)
	car.rotate_y(steer*signf(speed)*minf(absf(speed)*0.17,1.65)*dt)
	car.velocity = car.velocity.lerp(-car.basis.z*speed,minf(1,dt*4))
	if car.move_and_slide():
		speed *= 0.8
	camera.position = camera.position.lerp(car.position+car.basis.z*10+Vector3.UP*6,1-exp(-5*dt))
	camera.look_at(car.position-car.basis.z*3+Vector3.UP)
	if stage > 0:
		sample_time += dt
		if sample_time >= 0.12:
			trail.append(car.position)
			sample_time = 0
		if trail.size() > 0:
			var dest := trail[0]
			if patrol.position.distance_to(dest) < 1:
				trail.pop_front()
			else:
				patrol.look_at(dest)
				patrol.position = patrol.position.move_toward(dest,14*dt)
		beacon.visible = fmod(clock,0.4)<0.2
		capture = maxf(0,capture+dt*(1 if patrol.position.distance_to(car.position)<5 else -2))
		if capture > 4:
			ended = true
			hud.text = "ПАТРУЛЬ ПЕРЕКРЫЛ ВЫЕЗД    /    R — повторить"
			return
	if car.position.distance_to(marker.position)<7 and (stage in [1,2] or absf(speed)<2):
		if stage == 3:
			ended = true
			hud.text = "ГАРАЖ ОТЦА    /    Миссия пройдена\nРэй: В сумке восемнадцать тысяч. Кто забрал остальное?\nR — сыграть ещё раз"
			return
		stage += 1
		if stage == 1:
			patrol.position = car.position + Vector3(0,0,35)
			patrol.show()
		briefing = ["","Диспетчер: Вызов принят четыре минуты назад.   Рэй: Но я только вышел!","Вера: Держись. Уходим направо под надземку.","Рэй: Налево, к гаражу. Тормози у метки!"][stage]
		marker.position = ROUTE[stage]
	show_status()

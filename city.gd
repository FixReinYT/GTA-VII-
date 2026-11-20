extends Node3D

const Story = preload("res://story.gd")
var cable: MeshInstance3D
var final_cars:=Node3D.new()
const District = preload("res://district.gd")
var people := preload("res://sidewalk.gd").new()
var driver:=preload("res://driver.gd").new()
var streets:=preload("res://streets.gd").new()
var masonry:=ShaderMaterial.new()
var free_drive := false
var steering := 0.0
var reverse_delay := 0.0
var chapter := 0
var card := PanelContainer.new()
var card_text := Label.new()
var card_button := Button.new()
var pending := ""
var fork := false
var second := Node3D.new()
var trailer := Node3D.new()
var winter := preload("res://winter.gd").new()
var hud_panel := PanelContainer.new()
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
	visual.name="VehicleSkin"

var orbit_yaw := 0.0
var orbit_pitch := 0.32
var orbit_zoom := 1.0

func sync_cursor():
	var playing := pending.is_empty() and not get_tree().paused and get_window().has_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if playing else Input.MOUSE_MODE_VISIBLE

func _input(event):
	if not pending.is_empty() or get_tree().paused:
		return
	if event is InputEventMouseMotion:
		var offset:Vector2=event.screen_relative*0.003
		if driver.walking:
			driver.heading-=offset.x
		else:
			orbit_yaw=wrapf(orbit_yaw-offset.x,-PI,PI)
		orbit_pitch=clampf(orbit_pitch+offset.y,-0.06,1.05)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			orbit_zoom=maxf(0.60,orbit_zoom-0.10)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			orbit_zoom=minf(1.55,orbit_zoom+0.10)

func _exit_tree():
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _unhandled_key_input(event):
	if event is InputEventKey and event.physical_keycode==KEY_F and event.pressed and not event.echo and pending=="" and not people.boarding:
		var was_walking:=driver.walking
		var target:Dictionary={}
		if driver.walking:
			target=streets.nearby(driver.position,minf(3.3,driver.position.distance_to(car.position)))
		if target.is_empty():
			driver.switch_seat(car,speed)
		else:
			streets.transfer(self,target)
		if driver.walking!=was_walking:
			if driver.walking:
				driver.heading+=orbit_yaw
			else:
				orbit_yaw=wrapf(driver.heading-car.rotation.y,-PI,PI)
		if driver.walking:
			speed=0
			car.velocity=Vector3.ZERO
		show_status()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.physical_keycode==KEY_T and event.pressed and not event.echo and pending=="":
		streets.taxi(self)
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
			sync_cursor.call_deferred()
		pause_screen.confirmed.connect(resume)
		pause_screen.canceled.connect(resume)
		pause_screen.custom_action.connect(func(_id):
			get_tree().paused = false
			get_tree().change_scene_to_file("res://menu.tscn"))
		get_tree().paused = true
		sync_cursor()
		pause_screen.popup_centered()
		get_viewport().set_input_as_handled()

func _ready():
	get_window().focus_entered.connect(sync_cursor)
	get_window().focus_exited.connect(func(): Input.mouse_mode=Input.MOUSE_MODE_VISIBLE)
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-18,-48,0)
	light.light_color = Color("9bb8e4")
	light.light_energy = 0.37
	light.shadow_enabled = true
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode=Environment.BG_SKY
	var twilight:=ProceduralSkyMaterial.new()
	twilight.sky_top_color=Color("172a4d")
	twilight.sky_horizon_color=Color("4c5872")
	twilight.ground_horizon_color=Color("333f56")
	world.environment.sky=Sky.new()
	world.environment.sky.sky_material=twilight
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("879ec8")
	world.environment.ambient_light_energy = 0.58
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color("404e67")
	world.environment.fog_density = 0.0028
	add_child(world)
	block(self,Vector3(32,-0.55,-92),Vector3(490,1,470),"d3e4eb")
	for x in District.AVENUES:
		block(self,Vector3(x,-0.07,-92),Vector3(15,0.12,454),"455467")
	for z in District.STREETS:
		block(self,Vector3(32,-0.065,z),Vector3(478,0.12,15),"455467")
	masonry.shader=preload("res://masonry.gdshader")
	masonry.set_shader_parameter("palette",preload("res://art/kaykit/citybits_texture.png"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 171
	for x in range(-192,265,16):
		for z in range(-304,128,16):
			if absi(x)%64 < 12 or District.near_street(z):
				continue
			if x < -70 and (z > -196 and z < -40):
				block(self,Vector3(x,1.3,z),Vector3(0.5,2.6,0.5),"594437")
				var pine:=CylinderMesh.new()
				pine.top_radius=0
				pine.bottom_radius=2.5
				pine.height=5
				pine.radial_segments=6
				var crown:=MeshInstance3D.new()
				add_child(crown)
				crown.mesh=pine
				crown.position=Vector3(x,4,z)
				var needles:=StandardMaterial3D.new()
				needles.albedo_color=Color("40594c")
				crown.material_override=needles
				continue
			if x>150:
				block(self,Vector3(x,1.4,z),Vector3(10,2.8,4),"794f46",true)
				block(self,Vector3(x,4.2,z),Vector3(9,2.8,3.9),"516a77")
				continue
			var kinds := ["building_A_withoutBase","building_B_withoutBase","building_D_withoutBase","building_F_withoutBase"]
			var building := model(self,kinds[rng.randi_range(0,3)],Vector3(x,0,z),5.4)
			for facade in building.find_children("*","MeshInstance3D",true,false):
				facade.material_override=masonry
			if z < -192 or x > 80:
				building.scale.y*=1.0+0.35*(absi(x/16+z/16)%4)
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
		if absf(x-roundf(x/64.0)*64)<7:
			continue
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
	marker.position = Story.ROUTES[0][0]
	add_child(camera)
	camera.current = true
	camera.far = 620
	camera.position = Vector3(0,6,10)
	camera.look_at(car.position)
	add_child(people)
	people.setup()
	add_child(driver)
	driver.setup(people)
	add_child(streets)
	streets.setup(self)
	var avenue:=preload("res://avenue.gd").new()
	add_child(avenue)
	avenue.setup(self)
	add_child(winter)
	winter.setup(self,car)
	add_child(second)
	block(second,Vector3.UP*3,Vector3(0.5,6,0.5),"5bdddc")
	second.hide()
	add_child(trailer)
	vehicle(trailer,"car_sedan")
	cable=block(self,Vector3.ZERO,Vector3(0.05,0.05,1),"c7bcab")
	add_child(final_cars)
	for location in [Vector3(-65,0,-85),Vector3(-70,0,-85),Vector3(64,0,-84)]:
		var parked:=Node3D.new()
		final_cars.add_child(parked)
		vehicle(parked,"car_police" if location.x==-70 else "car_sedan")
		parked.position=location
		parked.rotation.y=1.0
	var radar:=preload("res://radar.gd").new()
	add_child(radar)
	radar.position=Vector2(18,458)
	radar.city=self
	add_child(hud_panel)
	hud_panel.position=Vector2(18,18)
	hud_panel.add_child(hud)
	hud.add_theme_font_size_override("font_size",17)
	add_child(card)
	card.position=Vector2(88,145)
	var skin:=StyleBoxFlat.new()
	skin.bg_color=Color("#0b1424f7")
	skin.border_width_left=4
	skin.border_color=Color("#eab574")
	for edge in [SIDE_TOP,SIDE_BOTTOM,SIDE_LEFT,SIDE_RIGHT]:
		skin.set_content_margin(edge,24)
	card.add_theme_stylebox_override("panel",skin)
	var column:=VBoxContainer.new()
	card.add_child(column)
	column.add_child(card_text)
	card_text.custom_minimum_size=Vector2(770,130)
	card_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	card_text.add_theme_font_size_override("font_size",22)
	column.add_child(card_button)
	card_button.pressed.connect(advance_card)
	free_drive=get_tree().get_meta("free_drive",false)
	begin_chapter(0 if free_drive else mini(Story.read_chapter(),3))
	if free_drive:
		people.reset_ray(false)
		marker.hide()
		advance_card()

func begin_chapter(index: int):
	driver.park()
	chapter=index
	stage=0
	speed=0
	steering=0
	reverse_delay=0
	people.reset_ray(index==0)
	car.velocity=Vector3.ZERO
	car.position=Story.START[index]
	car.rotation.y=PI if index in [1,2] else 0.0
	camera.position=car.position+car.basis.z*10+Vector3.UP*6
	camera.look_at(car.position+Vector3.UP)
	trail.clear()
	capture=0
	patrol.hide()
	fork=false
	second.hide()
	marker.show()
	final_cars.visible=index==3
	cable.hide()
	trailer.visible=index==1
	trailer.position=Vector3(-64,0,-88)
	marker.position=Story.ROUTES[index][0]
	briefing=Story.RADIO[index][0]
	display_card("intro","ГЛАВА %d   /   %s" % [index+1,Story.NAMES[index]],Story.BRIEF[index],"За руль")

func display_card(kind: String, title: String, body: String, button: String):
	pending=kind
	sync_cursor()
	card_text.text=title+"\n\n"+body
	card_button.text=button
	card.show()
	streets.dispatch.hide()
	hud_panel.hide()
	card_button.grab_focus()

func advance_card():
	match pending:
		"intro":
			card.hide()
			streets.dispatch.show()
			hud_panel.show()
			pending=""
			sync_cursor()
			show_status()
		"next":
			Story.save_chapter(chapter+1)
			begin_chapter(chapter+1)
		"retry": begin_chapter(chapter)
		"credits":
			display_card("menu","LAKE CITY   /   ТИТРЫ","История Веры Крус и Рэя.\nМодели города и автомобилей — Kay Lousberg, KayKit.\nСпасибо за прохождение.","Главное меню")
		"menu": get_tree().change_scene_to_file("res://menu.tscn")

func finish_story(family: bool):
	Story.save_chapter(4)
	var title := "Семейная частота" if family else "Хозяйка города"
	var body := "Рэй свернул на восток. Они убрали машину, и скорая прошла. Утром банк забрал контракт. Отец молча положил перед Верой второй ключ от мастерской." if family else "Рэй нагнал конвой. Вера получила кассу и диспетчерскую сеть. Наутро она услышала отца в эфире чужой компании. На её частоту он больше не вышел."
	display_card("credits","ЭПИЛОГ   /   "+title,body,"Титры")

func show_status():
	if driver.walking:
		var distance:=roundi(driver.position.distance_to(car.position))
		var foreign:=streets.nearby(driver.position,minf(3.3,distance))
		var hint:="F — сесть за руль" if distance<=3 else "Машина · %d м" % distance
		if not foreign.is_empty():
			hint="F — сесть в машину рядом"
		hud.text="ПЕШКОМ   ·   "+hint+"\nWASD / стрелки — идти   ·   Shift — бег   ·   мышь — обзор"
		return
	if free_drive:
		hud.text="СВОБОДНАЯ ПОЕЗДКА    /    %s     ·     %d км/ч    ·    F — выйти" % [District.district_name(car.position),roundi(absf(speed)*3.6)]
		return
	if fork:
		hud.text="ПОСЛЕДНИЙ ВЫБОР\nЗапад · янтарная метка — конвой     /     Восток · бирюзовая — отец\nОстановись у выбранной метки."
		return
	hud.text="ГЛАВА %d   /   %s      ·      %d км/ч\n%s    ·    %d м\n%s" % [chapter+1,Story.NAMES[chapter],roundi(absf(speed)*3.6),Story.GOALS[chapter][stage],int(car.position.distance_to(marker.position)),briefing]

	hud.text+="    ·    "+District.district_name(car.position)+"    ·    F — выйти"

func needs_stop() -> bool:
	return stage==Story.ROUTES[chapter].size()-1 or (chapter==0 and stage==0) or (chapter==1 and stage==2) or (chapter==2 and stage in [1,2])

func _physics_process(dt):
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene.call_deferred()
		return
	winter.animate(dt,speed)
	if pending!="":
		return
	streets.tick(self,dt)
	if pending!="":
		return
	clock += dt
	people.animate(dt,car,driver.position if driver.walking else car.position)
	var gas := int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")) - int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"))
	var steer := int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")) - int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"))
	if driver.walking:
		driver.walk(dt,steer,gas,people,camera,orbit_pitch,orbit_zoom)
		show_status()
		if chapter==0 and stage>0 and not free_drive:
			pursue(dt)
		return
	var brake := Input.is_physical_key_pressed(KEY_SPACE)
	if brake or people.boarding:
		speed=move_toward(speed,0.0,27*dt)
	elif gas>0:
		speed=move_toward(speed,26.0,(18 if speed<0 else 9)*dt)
		reverse_delay=0
	elif gas<0:
		if speed>0:
			speed=move_toward(speed,0,21*dt)
			reverse_delay=0
		else:
			reverse_delay+=dt
			if reverse_delay>0.22:
				speed=move_toward(speed,-6,6*dt)
	else:
		speed=move_toward(speed,0,(1.6+absf(speed)*0.055)*dt)
		reverse_delay=0
	steering=move_toward(steering,float(steer),(5 if steer==0 else 3.8)*dt)
	var turn_rate:=minf(absf(speed)*0.27,1.72)/(1+maxf(absf(speed)-10,0)*0.045)
	car.rotate_y(steering*signf(speed)*turn_rate*dt)
	car.velocity=car.velocity.lerp(-car.basis.z*speed,1-exp(-14*dt))
	if car.move_and_slide():
		speed *= 0.8
	if people.vehicle_contacts(car,speed) and free_drive:
		streets.report(self)
	var focus:=car.position+Vector3.UP*1.45
	var boom:=Vector3(0,sin(orbit_pitch),cos(orbit_pitch)).rotated(Vector3.UP,car.rotation.y+orbit_yaw)
	var desired:=focus+boom*7.8*orbit_zoom
	var ray:=PhysicsRayQueryParameters3D.create(focus,desired,1,[car.get_rid()])
	var obstruction:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not obstruction.is_empty():
		desired=obstruction.position+obstruction.normal*0.18
	camera.position=camera.position.lerp(desired,1-exp(-11*dt))
	if camera.position.distance_to(focus)>0.1:
		camera.look_at(focus)
	if car.position.x<District.WEST or car.position.x>District.EAST or car.position.z<District.NORTH or car.position.z>District.SOUTH:
		if free_drive:
			car.position=Vector3(0,0,0)
			speed=0
			car.velocity=Vector3.ZERO
			return
		display_card("retry","Дорога закрыта","Дальше проезд занесло снегом. Вернись на маршрут.","Повторить главу")
		return
	if free_drive:
		show_status()
		return
	if chapter==1 and stage>=3:
		var hitch:=car.position+car.basis.z*2
		var offset:=trailer.position-hitch
		if offset.length()>3:
			trailer.position=hitch+offset.normalized()*3
			trailer.look_at(hitch)
		var end:=trailer.position-trailer.basis.z*1.8+Vector3.UP*0.42
		var start:=hitch+Vector3.UP*0.42
		if start.distance_to(end)>0.1:
			cable.show()
			cable.position=(start+end)*0.5
			cable.look_at(end)
			cable.scale.z=start.distance_to(end)
	if fork:
		if absf(speed)<2:
			if car.position.distance_to(second.position)<7:
				finish_story(true)
			elif car.position.distance_to(marker.position)<7:
				finish_story(false)
		return
	if chapter==0 and stage > 0:
		pursue(dt)
		if pending!="":
			return
	if car.position.distance_to(marker.position)<7 and (not needs_stop() or absf(speed)<2):
		if chapter==1 and stage==1 and absf(speed)*3.6>30:
			display_card("retry","Штрафстоянка","Патруль остановил машину за превышение. На посту нужно сбросить скорость до 30 км/ч.","Повторить главу")
			return
		if stage==Story.ROUTES[chapter].size()-1:
			if chapter==3:
				fork=true
				marker.position=Vector3(-64,0,-88)
				second.position=Vector3(64,0,-88)
				second.show()
			else:
				var endings:=["В сумке восемнадцать тысяч. По бумагам пропал миллион. Рэй разворачивает квитанцию: подпись дежурного и номер машины.","Под запаской лежат запечатанные пачки. Ведомость указывает на мэрию. Отец просит отдать документы в газету. Вера звонит мэру.","Вера ставит подпись. На соседнем дворе гаснет вывеска. Отец перестаёт отвечать на её звонки."]
				display_card("next",Story.NAMES[chapter]+"   /   Глава пройдена",endings[chapter],"Следующая глава")
			show_status()
			return
		stage+=1
		if chapter==0 and stage==1:
			people.boarding=true
			speed=0
			car.velocity=Vector3.ZERO
			patrol.position=car.position+Vector3(0,0,35)
			patrol.show()
		briefing=Story.RADIO[chapter][stage]
		marker.position=Story.ROUTES[chapter][stage]
	show_status()

func pursue(dt):
	sample_time += dt
	if sample_time >= 0.12:
		trail.append(driver.position if driver.walking else car.position)
		sample_time = 0
	if trail.size() > 0:
		var dest := trail[0]
		if patrol.position.distance_to(dest) < 1:
			trail.pop_front()
		else:
			patrol.look_at(dest)
			patrol.position = patrol.position.move_toward(dest,14*dt)
	beacon.visible = fmod(clock,0.4)<0.2
	capture = maxf(0,capture+dt*(1 if patrol.position.distance_to(driver.position if driver.walking else car.position)<5 else -2))
	if capture > 4:
		display_card("retry","Задержание","Патруль перекрыл выезд. Рэй прячет сумку под сиденьем.","Повторить главу")
		return

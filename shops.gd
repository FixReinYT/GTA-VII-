extends Node3D

const LOCATIONS := [Vector3(8.7,0,-22),Vector3(-8.7,0,-58),Vector3(72.7,0,-114)]
const NAMES := ["Полярная закусочная","Куртки Крус","Оружейная лавка"]
const SIGNS := ["POLAR GRILL","CRUZ OUTFITTERS","LAKE CITY ARMS"]
const COLORS := ["bf6249","49867d","676b89"]
const STOCK := [["Горячий кофе","Бургер"],["Куртка · хвоя","Куртка · индиго","Своя куртка"],["Пистолет + 12 патронов","12 патронов"]]
const PRICES := [[4,9],[25,30,0],[55,10]]
var shop:=-1
var panel:=PanelContainer.new()
var title:=Label.new()
var choices:=VBoxContainer.new()
var feedback:=Label.new()
var profile:Dictionary
var city:Node
var equipped:=false
var arm:Node3D
var gun:Node3D
var cool:=0.0
var swing:=0.0
var alternate:=false

func setup(world):
	city=world
	profile=city.streets.profile
	for i in LOCATIONS.size():
		var booth:=Node3D.new()
		add_child(booth)
		booth.position=LOCATIONS[i]
		booth.rotation.y=PI/2 if i==1 else -PI/2
		for side in [-1,1]:
			city.block(booth,Vector3(side*2.45,1.45,-1.4),Vector3(0.14,2.9,0.14),"314052",true)
		city.block(booth,Vector3(0,1,-1.2),Vector3(4.8,1.6,0.65),COLORS[i],true)
		city.block(booth,Vector3(0,2.85,-0.9),Vector3(5.4,0.2,2.6),COLORS[i])
		city.block(booth,Vector3(0,2.65,0.37),Vector3(5.25,0.58,0.12),"28333f")
		var sign:=Label3D.new()
		booth.add_child(sign)
		sign.text=SIGNS[i]
		sign.position=Vector3(0,2.65,0.45)
		sign.font_size=44
		sign.pixel_size=0.009
		var seller:Dictionary=city.people.person(2+i,Vector3.ZERO)
		seller.body.reparent(booth,false)
		seller.body.position=Vector3(0,0,-2)
		seller.body.rotation.y=PI
	city.add_child(panel)
	panel.position=Vector2(225,145)
	var column:=VBoxContainer.new()
	panel.add_child(column)
	column.custom_minimum_size.x=550
	column.add_theme_constant_override("separation",10)
	column.add_child(title)
	title.add_theme_font_size_override("font_size",28)
	column.add_child(choices)
	column.add_child(feedback)
	var leave:=Button.new()
	leave.text="Уйти"
	column.add_child(leave)
	leave.pressed.connect(close)
	panel.hide()
	arm=city.driver.avatar.limbs[3]
	gun=city.block(arm,Vector3(0,-0.56,-0.12),Vector3(0.10,0.13,0.32),"343f4b")
	gun.hide()
	dress()

func nearest(pos:Vector3)->int:
	for i in LOCATIONS.size():
		if pos.distance_to(LOCATIONS[i])<3.2:
			return i
	return -1

func open():
	if not city.driver.walking:
		return
	shop=nearest(city.driver.position)
	if shop<0:
		return
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for i in STOCK[shop].size():
		var button:=Button.new()
		choices.add_child(button)
		button.text="%s     $%d" % [STOCK[shop][i],price(i)]
		button.pressed.connect(buy.bind(i))
	refresh()
	feedback.text=""
	panel.show()
	panel.move_to_front()
	choices.get_child(0).grab_focus()
	city.sync_cursor()

func price(i:int)->int:
	if shop==1 and (i==2 or i in profile.coats):
		return 0
	return PRICES[shop][i]

func refresh():
	title.text="  %s    ·    $%d" % [NAMES[shop],city.streets.money]

func buy(i:int):
	if shop<0 or i<0 or i>=STOCK[shop].size():
		return
	var cost:=price(i)
	if shop==2 and ((i==0 and profile.gun) or (i==1 and not profile.gun)):
		feedback.text="Пистолет уже куплен" if profile.gun else "Сначала купи пистолет"
		return
	if shop==0 and profile.energy>=100:
		feedback.text="Силы полностью восстановлены"
		return
	if city.streets.money<cost:
		feedback.text="Не хватает денег"
		return
	city.streets.money-=cost
	match shop:
		0:
			profile.energy=mini(100,int(profile.energy)+(25 if i==0 else 60))
			feedback.text="Силы восстановлены · %d/100" % profile.energy
		1:
			if i!=2 and i not in profile.coats:
				profile.coats.append(i)
			profile.coat=i
			dress()
			feedback.text="Куртка надета"
			choices.get_child(i).text=STOCK[1][i]+"     $0"
		2:
			profile.gun=true
			profile.ammo+=12
			select_weapon(true)
			feedback.text="Боезапас · %d" % profile.ammo
	city.streets.save_wallet()
	refresh()

func dress():
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(["347463","514e91","a34a3a"][int(profile.coat)])
	var body:Node3D=city.driver.avatar.body
	body.get_child(0).material_override=mat
	for limb in [2,3]:
		city.driver.avatar.limbs[limb].get_child(0).material_override=mat

func close():
	panel.hide()
	shop=-1
	city.sync_cursor()

func select_weapon(use_gun:bool):
	equipped=use_gun and profile.gun
	gun.visible=equipped

func attack():
	if not city.driver.walking or cool>0:
		return
	if equipped and profile.ammo<=0:
		return
	var reach:=23.0 if equipped else 1.85
	cool=0.42 if equipped else 0.36
	swing=0.24
	alternate=not alternate
	var origin:Vector3=city.driver.position+Vector3.UP
	var forward:=Vector3.FORWARD.rotated(Vector3.UP,city.driver.heading)
	city.driver.avatar.body.rotation.y=city.driver.heading
	var query:=PhysicsRayQueryParameters3D.create(origin,origin+forward*reach,1,[city.driver.get_rid()])
	var wall:=get_world_3d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		reach=origin.distance_to(wall.position)
	var victim:Dictionary={}
	for person in city.people.walkers:
		if not person.body.visible or person.down>0:
			continue
		var delta:Vector3=person.body.position+Vector3.UP-origin
		var depth:=delta.dot(forward)
		if depth>0 and depth<=reach and delta.cross(forward).length()<(0.6 if equipped else 0.78):
			victim=person
			reach=depth
	if equipped:
		profile.ammo-=1
		city.streets.save_wallet()
		var flash:MeshInstance3D=city.block(self,origin+forward*reach*0.5,Vector3(.035,.035,maxf(reach,0.1)),"ffe5ac")
		flash.rotation.y=city.driver.heading
		get_tree().create_timer(0.06).timeout.connect(flash.queue_free)
	if not victim.is_empty():
		victim.down=2.2 if equipped else 1.1
		victim.push=forward*(2.8 if equipped else 1.6)
		victim.body.rotation.x=1.28
		for witness in city.people.walkers:
			if witness.body.position.distance_squared_to(victim.body.position)<80:
				witness.fright=2
				witness.escape=origin-Vector3.UP
	if city.free_drive and (equipped or not victim.is_empty()):
		city.streets.report(city)

func pose(dt:float):
	cool=maxf(0,cool-dt)
	swing=maxf(0,swing-dt)
	if equipped:
		arm.rotation.x=1.48+0.2*swing
	elif swing>0:
		var hand:Node3D=city.driver.avatar.limbs[2 if alternate else 3]
		hand.rotation.x=sin(PI*swing/0.24)*1.8

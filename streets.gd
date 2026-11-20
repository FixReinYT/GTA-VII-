extends Node3D

const Map=preload("res://district.gd")
const MODELS=["car_taxi","car_stationwagon","car_hatchback"]
const DESTINATIONS=[Vector3(64,0,-148),Vector3(-128,0,-40),Vector3(192,0,-88)]
var fleet:Array[Dictionary]=[]
var active_model:="car_sedan"
var active_owned:=true
var wanted:=0
var unseen:=0.0
var detained:=0.0
var police:=Node3D.new()
var tracks:Array[Vector3]=[]
var dispatch:=Label.new()
var fare:=0
var trips:=0
var money:=75
var profile:={"gun":false,"ammo":0,"coat":2,"coats":[],"energy":70.0}
var customer:Dictionary
var stop:=Node3D.new()
var destination:=Vector3.ZERO

func setup(city):
	var cfg:=ConfigFile.new()
	if cfg.load("user://taxi.cfg")==OK:
		money=int(cfg.get_value("driver","cash",0))
		trips=int(cfg.get_value("driver","trips",0))
		for key in profile.keys():
			profile[key]=cfg.get_value("gear",key,profile[key])
	for i in 20:
		var body:=StaticBody3D.new()
		add_child(body)
		var shape:=CollisionShape3D.new()
		var box:=BoxShape3D.new()
		box.size=Vector3(2,1.4,4.1)
		shape.shape=box
		body.add_child(shape)
		shape.position.y=0.8
		var model: String=MODELS[i%3]
		city.vehicle(body,model)
		var col: int=(i*3)%7
		var row: int=(i*5)%8
		var x: float=Map.AVENUES[col]+3.4
		var z: float=Map.STREETS[row]+3.4
		var east: float=Map.AVENUES[col+1]-3.4
		var south: float=Map.STREETS[row+1]-3.4
		var corners: Array[Vector3]=[Vector3(x,0,z),Vector3(east,0,z),Vector3(east,0,south),Vector3(x,0,south)]
		body.position=corners[0]
		var parked:=i<3
		if parked:
			body.position=Vector3(-5.2,0,-7-i*10)
		else:
			body.look_at(corners[1])
		fleet.append({"body":body,"route":corners,"next":1,"moving":not parked,"model":model,"owned":false,"velocity":0.0,"speed":5.0+i%5})
	add_child(police)
	city.vehicle(police,"car_police")
	police.hide()
	customer=city.people.person(3,Vector3.ZERO)
	customer.body.hide()
	add_child(stop)
	city.block(stop,Vector3.UP*1.4,Vector3(0.25,2.8,0.25),"5bdddc")
	stop.hide()
	city.add_child(dispatch)
	dispatch.position=Vector2(18,104)
	dispatch.add_theme_constant_override("outline_size",5)
	dispatch.add_theme_font_size_override("font_size",19)

func nearby(pos: Vector3,limit: float) -> Dictionary:
	var closest:Dictionary={}
	for item in fleet:
		var dist:=pos.distance_to(item.body.position)
		if dist<limit:
			limit=dist
			closest=item
	return closest

func transfer(city, other: Dictionary):
	var body:StaticBody3D=other.body
	var old:Transform3D=city.car.transform
	city.car.transform=body.transform
	body.transform=old
	var active:Node3D=city.car.get_node("VehicleSkin")
	var next:Node3D=body.get_node("VehicleSkin")
	active.name="Outgoing"
	next.reparent(city.car,false)
	active.reparent(body,false)
	active.name="VehicleSkin"
	var stolen:=not bool(other.owned)
	var previous:=active_model
	active_model=other.model
	other.model=previous
	other.owned=active_owned
	active_owned=true
	other.moving=false
	city.driver.park()
	city.speed=0
	city.car.velocity=Vector3.ZERO
	if fare>0:
		end_fare()
	if stolen and city.free_drive:
		report(city)

func report(city):
	if wanted==0:
		tracks.clear()
		var start:Vector3=city.car.position
		var nearest: float=Map.AVENUES[0]
		for x in Map.AVENUES:
			if absf(x-start.x)<absf(nearest-start.x):
				nearest=x
		police.position=Vector3(nearest,0,start.z+(-26 if start.z>90 else 26))
		tracks.append(Vector3(nearest,0,start.z))
		police.show()
	wanted=mini(3,wanted+1)
	unseen=0

func end_fare():
	fare=0
	stop.hide()
	customer.body.hide()

func taxi(city):
	if not city.free_drive or city.driver.walking or active_model!="car_taxi" or fare!=0:
		return
	destination=DESTINATIONS[trips%DESTINATIONS.size()]
	stop.position=Vector3(-5,0,-39)
	stop.show()
	customer.body.position=stop.position+Vector3.LEFT*2.5
	customer.body.show()
	fare=1

func tick(city,dt:float):
	var focus:Vector3=city.driver.position if city.driver.walking else city.car.position
	for item in fleet:
		if not item.moving:
			continue
		var body:StaticBody3D=item.body
		var target:Vector3=item.route[item.next]
		var step:=body.position.direction_to(target)
		var gap:=minf(lane_gap(body.position,step,focus),lane_gap(body.position,step,city.car.position))
		for other in fleet:
			if other.body!=body:
				gap=minf(gap,lane_gap(body.position,step,other.body.position)-2.0)
		for walker in city.people.walkers:
			if walker.body.visible:
				gap=minf(gap,lane_gap(body.position,step,walker.body.position))
		var cruise:float=minf(item.speed,sqrt(10.0*maxf(0.0,gap-3.0)))
		item.velocity=move_toward(item.velocity,cruise,dt*(7.0 if item.velocity>cruise else 2.6))
		if body.position.distance_to(target)<0.4:
			item.next=(int(item.next)+1)%4
		else:
			body.look_at(target)
			body.position=body.position.move_toward(target,minf(item.velocity*dt,maxf(0,gap-2.6)))
	dispatch.text=""
	if not city.free_drive:
		return
	if wanted>0:
		if tracks.is_empty() or tracks.back().distance_to(focus)>2:
			tracks.append(focus)
		var point:Vector3=tracks[0]
		if police.position.distance_to(point)>0.1:
			police.look_at(point)
			police.position=police.position.move_toward(point,(8+wanted*2)*dt)
		elif tracks.size()>1:
			tracks.pop_front()
		var distance:=police.position.distance_to(focus)
		unseen=unseen+dt if distance>42 else 0.0
		detained=detained+dt if distance<3.8 else 0.0
		dispatch.text="РОЗЫСК   "+"★".repeat(wanted)
		if unseen>7 or detained>3:
			var busted:=detained>3
			wanted=0
			detained=0
			police.hide()
			if busted:
				end_fare()
				city.driver.park()
				city.car.position=Vector3(0,0,0)
				city.car.velocity=Vector3.ZERO
				city.speed=0
				city.display_card("intro","Задержание","Веру отпустили у центрального участка. Машину вернули.","Продолжить")
	if fare>0:
		dispatch.text+="   ТАКСИ   ·   "+("Забери пассажира" if fare==1 else "Довези пассажира")+"   ·   %d м" % int(stop.position.distance_to(focus))
		if not city.driver.walking and absf(city.speed)<1.5 and city.car.position.distance_to(stop.position)<7:
			if fare==1:
				customer.body.hide()
				stop.position=destination
				fare=2
			else:
				money+=45
				trips+=1
				end_fare()
				save_wallet()
	elif active_model=="car_taxi" and not city.driver.walking:
		dispatch.text+="   T — заказ такси"
	dispatch.text+="   $%d" % money


func lane_gap(origin:Vector3,direction:Vector3,point:Vector3)->float:
	var relative:=point-origin
	var ahead:=relative.dot(direction)
	if ahead>0 and ahead<18 and absf(relative.cross(direction).y)<1.65:
		return ahead
	return 100.0

func save_wallet():
	var cfg:=ConfigFile.new()
	cfg.set_value("driver","cash",money)
	cfg.set_value("driver","trips",trips)
	for key in profile:
		cfg.set_value("gear",key,profile[key])
	cfg.save("user://taxi.cfg")

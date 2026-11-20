extends Node
func _ready():
	run.call_deferred()
func run():
	var city = load("res://city.tscn").instantiate()
	add_child(city)
	await get_tree().physics_frame
	city.set_physics_process(false)
	if not check_shops(city) or not check_street_behaviour(city):
		get_tree().quit(1)
		return
	for free in [false,true]:
		city.free_drive=free
		city.begin_chapter(0)
		city.advance_card()
		var motion:=InputEventMouseMotion.new()
		motion.screen_relative=Vector2(12,3)
		var before:float=city.orbit_yaw
		city._input(motion)
		if is_equal_approx(before,city.orbit_yaw):
			get_tree().quit(1)
			return
		var event:=InputEventKey.new()
		event.physical_keycode=KEY_F
		event.pressed=true
		city._unhandled_key_input(event)
		if not city.driver.walking:
			get_tree().quit(1)
			return
		before=city.driver.heading
		city._input(motion)
		if is_equal_approx(before,city.driver.heading):
			get_tree().quit(1)
			return
		var start: Vector3=city.driver.position
		Input.action_press("ui_up")
		for i in 15:
			city._physics_process(1.0/60)
		Input.action_release("ui_up")
		if city.driver.position.distance_to(start)<0.12:
			get_tree().quit(1)
			return
		city._unhandled_key_input(event)
		if city.driver.walking:
			get_tree().quit(1)
			return
		var walker: Dictionary=city.people.walkers.back()
		city.car.position=walker.body.position+Vector3.BACK*2.1
		city.speed=8
		city._physics_process(1.0/60)
		if walker.down<=0:
			get_tree().quit(1)
			return
		city.car.position=Vector3.ZERO
		for i in 190:
			city.people.animate(1.0/60,city.car,Vector3.ZERO)
		if walker.down>0 or absf(walker.body.rotation.x)>0.05:
			get_tree().quit(1)
			return
	city.free_drive=true
	city.begin_chapter(0)
	city.advance_card()
	city.streets.wanted=0
	var interact:=InputEventKey.new()
	interact.physical_keycode=KEY_F
	interact.pressed=true
	city._unhandled_key_input(interact)
	city.driver.position=city.streets.fleet[0].body.position+Vector3.RIGHT*1.7
	city._unhandled_key_input(interact)
	if city.driver.walking or city.streets.active_model!="car_taxi" or city.streets.wanted!=1:
		get_tree().quit(1)
		return
	var initial_cash:int=city.streets.money
	city.streets.taxi(city)
	for stop in 2:
		city.car.position=city.streets.stop.position
		city.streets.tick(city,1.0/60)
	if city.streets.fare!=0 or city.streets.money!=initial_cash+45:
		get_tree().quit(1)
		return
	city.streets.police.position=city.car.position
	city.streets.tracks.clear()
	for tick in 190:
		city.streets.tick(city,1.0/60)
	if city.streets.wanted!=0 or city.pending!="intro":
		get_tree().quit(1)
		return
	print("PASS vehicle transfer, fare payout and arrest")
	city.free_drive=false
	for family in [true,false]:
		city.begin_chapter(0 if family else 3)
		city.advance_card()
		if not drive(city,family):
			get_tree().quit(1)
			return
		print("ENDING PASSED: ",city.card_text.text)
		city.advance_card()
		if city.pending!="menu":
			get_tree().quit(1)
			return
	var proof:=FileAccess.open("user://campaign-passed.txt",FileAccess.WRITE)
	proof.store_line("Passed both endings")
	proof.close()
	get_tree().quit(0)

func drive(city,family: bool) -> bool:
	for tick in 9000:
		var target: Vector3 = city.second.position if city.fork and family else city.marker.position
		var delta: Vector3 = target-city.car.position
		var angle: float = (-city.car.basis.z).signed_angle_to(delta.normalized(),Vector3.UP)
		var stop: bool = (city.needs_stop() or city.fork) and delta.length()<6
		for action in ["ui_up","ui_down","ui_left","ui_right"]:
			Input.action_release(action)
		var limit := minf(18, sqrt(maxf(0,delta.length()-3)*11))
		if city.chapter==1 and city.stage==1 and delta.length()<32:
			limit=minf(limit,7)
		if abs(angle)>0.25:
			limit = minf(limit,6)
		if not stop and city.speed < limit:
			Input.action_press("ui_up")
		if (stop and city.speed>0.5) or city.speed>limit+0.2:
			Input.action_press("ui_down")
		if abs(angle)>0.06:
			Input.action_press("ui_left" if angle>0 else "ui_right")
		city._physics_process(1.0/60)
		if city.pending=="next":
			print("PASS ",city.chapter)
			city.advance_card()
			city.advance_card()
		if city.pending=="credits":
			return true
		if city.pending=="retry":
			break
	print("FAIL ",city.chapter,"/",city.stage," at ",city.car.position," goal ",city.marker.position,"  ",city.card_text.text)
	return false

func check_street_behaviour(city)->bool:
	var walker:Dictionary=city.people.walkers.back()
	var original:Vector3=walker.body.position
	var paths=city.people.paths
	var corner:int=paths.nearest_corner(Vector3(-8.6,0,-31.4))
	var other:int=paths.nearest_corner(Vector3(8.6,0,-31.4))
	walker.body.position=paths.corners[corner]
	walker.last=corner
	walker.goal=other
	city.car.position=walker.body.position+Vector3(5,0,8)
	var curb:Vector3=walker.body.position
	city.people.advance_walker(walker,0.1,city.car,[],9)
	if walker.body.position!=curb:
		return false
	city.car.position=Vector3(80,0,80)
	city.people.advance_walker(walker,0.1,city.car,[],0)
	if walker.body.position.distance_to(curb)<0.05:
		return false
	city.car.position=walker.body.position+Vector3.BACK*7
	city.people.advance_walker(walker,0.1,city.car,[],10)
	if walker.fright<=0:
		return false
	var traffic:Dictionary=city.streets.fleet[3]
	var forward:Vector3=traffic.body.position.direction_to(traffic.route[traffic.next])
	walker.body.position=traffic.body.position+forward*4
	walker.body.show()
	traffic.velocity=6.0
	city.streets.tick(city,0.1)
	if traffic.velocity>=6:
		return false
	walker.body.position=original
	walker.goal=paths.nearest_corner(original)
	walker.last=-1
	walker.fright=0.0
	print("PASS curb wait, crossing, evasive step and traffic braking")
	return true

func check_shops(city)->bool:
	city.begin_chapter(0)
	city.advance_card()
	city.driver.switch_seat(city.car,0)
	var shops=city.shops
	var original_cash:int=city.streets.money
	var original:Dictionary=shops.profile.duplicate(true)
	city.streets.money=120
	shops.profile.merge({"gun":false,"ammo":0,"coat":2,"coats":[],"energy":20},true)
	for index in 3:
		city.driver.position=shops.LOCATIONS[index]
		shops.open()
		if shops.shop!=index or not shops.panel.visible:
			return false
		shops.buy(0)
		shops.close()
	if city.streets.money!=36 or shops.profile.energy!=45 or shops.profile.coat!=0 or not shops.equipped:
		return false
	var victim:Dictionary=city.people.walkers.back()
	var home:Vector3=victim.body.position
	city.driver.position=Vector3.ZERO
	city.car.position=Vector3(22,0,0)
	city.driver.heading=0
	victim.body.position=Vector3.FORWARD*1.2
	victim.body.show()
	shops.select_weapon(false)
	shops.attack()
	if victim.down<=0:
		return false
	shops.select_weapon(true)
	shops.cool=0
	victim.down=0.0
	victim.body.position=Vector3.FORWARD*4
	shops.attack()
	var cfg:=ConfigFile.new()
	if victim.down<=0 or cfg.load("user://taxi.cfg")!=OK or cfg.get_value("gear","ammo")!=11 or cfg.get_value("driver","cash")!=36:
		return false
	for key in original:
		shops.profile[key]=original[key]
	city.streets.money=original_cash
	city.streets.save_wallet()
	shops.select_weapon(false)
	shops.dress()
	victim.body.position=home
	victim.body.rotation.x=0.0
	for npc in city.people.walkers:
		npc.fright=0.0
	victim.down=0.0
	print("PASS shop entry, purchases, clothing, energy, punch, shot and saved inventory")
	return true

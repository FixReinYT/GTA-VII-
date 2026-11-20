extends Node
func _ready():
	run.call_deferred()
func run():
	var city = load("res://city.tscn").instantiate()
	add_child(city)
	await get_tree().physics_frame
	city.set_physics_process(false)
	for free in [false,true]:
		city.free_drive=free
		city.begin_chapter(0)
		city.advance_card()
		var event:=InputEventKey.new()
		event.physical_keycode=KEY_F
		event.pressed=true
		city._unhandled_key_input(event)
		if not city.driver.walking:
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

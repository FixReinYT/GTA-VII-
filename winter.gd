extends Node3D

var train := Node3D.new()
var particles := CPUParticles3D.new()
var engine := AudioStreamPlayer.new()
var phase := 0.0

func setup(city, car: Node3D):
	var asphalt:=ShaderMaterial.new()
	asphalt.shader=preload("res://asphalt.gdshader")
	for item in city.get_children():
		if item is MeshInstance3D and item.material_override==city.materials["455467"]:
			item.material_override=asphalt
	for info in [[Vector3(-7,3,-24),"LAKE  LAUNDRY"],[Vector3(72,3,-148),"CRUZ  •  TOWING"],[Vector3(-72,3,-87),"IMPOUND  24H"],[Vector3(7,3,-40),"CITY  CONTRACTS"]]:
		var signpost: Vector3=info[0]
		city.block(self,signpost-Vector3.UP*1.6,Vector3(0.18,3.2,0.18),"36404e")
		city.block(self,signpost,Vector3(5.6,1.05,0.23),"223244")
		var label:=Label3D.new()
		add_child(label)
		label.text=info[1]
		label.position=signpost+Vector3(0,0,0.13)
		label.pixel_size=0.012
		label.font_size=39
		label.modulate=Color("#ffd098")
		label.outline_size=1
	var line := StandardMaterial3D.new()
	line.albedo_color = Color("#b2bdba")
	for x in [-64,0,64,128]:
		for z in range(-178,27,9):
			city.block(self,Vector3(x,0.012,z),Vector3(0.14,0.015,3.5),"abb6af")
	for x in [-64,0,64]:
		for z in [-148,-88,-40,8]:
			for stripe in range(-5,6,2):
				city.block(self,Vector3(x+stripe,0.02,z+9),Vector3(0.8,0.02,3),"c7d0d0")
	for x in range(-68,142,12):
		city.block(self,Vector3(x,7.8,-94),Vector3(10.5,0.28,4.7),"485567")
	add_child(train)
	for i in range(3):
		var center := Vector3(i*11,9.3,-94)
		city.block(train,center,Vector3(10.7,2.7,3.7),"7a879a")
		for w in range(-4,5,2):
			city.block(train,center+Vector3(w,0.4,1.88),Vector3(1.4,1,0.05),"ffdaa0")
	for pos in [Vector3(-6,4,-22),Vector3(71,4,-148),Vector3(-71,4,-88),Vector3(6,4,-40)]:
		var lamp := OmniLight3D.new()
		add_child(lamp)
		lamp.position=pos
		lamp.light_color=Color("#ffbf7d")
		lamp.light_energy=3
		lamp.omni_range=16
	for side in [-1,1]:
		var head := SpotLight3D.new()
		car.add_child(head)
		head.position=Vector3(side*0.7,0.9,-1.8)
		head.rotation.x=-0.13
		head.spot_range=26
		head.spot_angle=32
		head.light_color=Color("#ffe4ba")
		head.light_energy=3.4
	car.add_child(particles)
	particles.position.y=6
	particles.amount=320
	particles.lifetime=3
	particles.preprocess=3
	particles.local_coords=false
	particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents=Vector3(15,5,18)
	particles.gravity=Vector3(-0.65,-3,0)
	var flake:=BoxMesh.new()
	flake.size=Vector3(0.035,0.07,0.035)
	flake.material=line
	particles.mesh=flake
	var stream:=AudioStreamGenerator.new()
	stream.mix_rate=11025
	stream.buffer_length=0.18
	engine.stream=stream
	engine.volume_db=-22
	add_child(engine)
	engine.play()

func animate(dt: float, speed: float):
	train.position.x=wrapf(train.position.x+dt*14,-108,150)
	var playback:=engine.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		for i in playback.get_frames_available():
			phase=fmod(phase+TAU*(36+absf(speed)*2.0)/11025,TAU)
			var engine_sample:=sin(phase)*0.55+sin(phase*2)*0.24+sin(phase*4)*0.1
			playback.push_frame(Vector2.ONE*engine_sample)

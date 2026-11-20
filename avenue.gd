extends Node3D

var city:Node
var glow_materials:Dictionary={}

func piece(parent:Node3D,p:Vector3,size:Vector3,color:String,lit:=false)->MeshInstance3D:
	var box:MeshInstance3D=city.block(parent,p,size,color)
	if lit:
		if not glow_materials.has(color):
			var mat:=StandardMaterial3D.new()
			mat.albedo_color=Color(color)
			mat.emission_enabled=true
			mat.emission=Color(color)
			mat.emission_energy_multiplier=1.4
			glow_materials[color]=mat
		box.material_override=glow_materials[color]
	return box

func lettering(parent:Node3D,words:String,p:Vector3,height:float,tint:String):
	var label:=Label3D.new()
	parent.add_child(label)
	label.text=words
	label.font_size=64
	label.pixel_size=height/64
	label.outline_size=0
	label.modulate=Color(tint)
	label.position=p

func storefront():
	var shop:=Node3D.new()
	add_child(shop)
	shop.position=Vector3(-10.6,0,-24)
	shop.rotation.y=PI/2
	city.block(shop,Vector3(0,2,-3.2),Vector3(12,4,6),"763f36",true)
	piece(shop,Vector3(0,2.05,0),Vector3(12,4.1,0.32),"532f2b")
	piece(shop,Vector3(0,4.15,-2.8),Vector3(12.5,0.24,6.5),"d0d8df")
	piece(shop,Vector3(0,3.42,0.25),Vector3(11.9,0.98,0.35),"273e47")
	for y in [2.96,3.89]:
		piece(shop,Vector3(0,y,0.45),Vector3(11.85,0.045,0.05),"ffb879",true)
	lettering(shop,"L A K E   L A U N D R Y",Vector3(0,3.43,0.47),0.64,"ffe0a0")
	for i in 6:
		var x:float=-4.8+i*1.9
		piece(shop,Vector3(x,1.61,0.18),Vector3(1.77,2.35,0.12),"bd8a54",true)
		piece(shop,Vector3(x,2.49,0.27),Vector3(1.61,0.12,0.07),"ffe2b0",true)
		if i==3:
			piece(shop,Vector3(x,1.39,0.32),Vector3(1.35,2.56,0.08),"35505b")
			lettering(shop,"OPEN",Vector3(x,1.98,0.39),0.31,"ffac77")
			piece(shop,Vector3(x+0.42,1.1,0.39),Vector3(0.06,0.42,0.08),"d6bd95")
		else:
			piece(shop,Vector3(x,0.98,0.29),Vector3(1.37,1.3,0.22),"b6b7ac")
			var drum:=MeshInstance3D.new()
			var disk:=CylinderMesh.new()
			disk.top_radius=0.44
			disk.bottom_radius=0.44
			disk.height=0.07
			drum.mesh=disk
			shop.add_child(drum)
			drum.position=Vector3(x,0.92,0.44)
			drum.rotation.x=PI/2
			drum.material_override=city.materials["35505b"] if city.materials.has("35505b") else city.materials["273e47"]
			piece(shop,Vector3(x+0.37,1.50,0.42),Vector3(0.27,0.09,0.04),"b9edcf",true)
		piece(shop,Vector3(x+0.89,1.55,0.54),Vector3(0.065,2.57,0.12),"37414a")
	var blade:=Node3D.new()
	shop.add_child(blade)
	blade.position=Vector3(-5.25,4.45,1.2)
	blade.rotation.y=-PI/2
	piece(blade,Vector3.ZERO,Vector3(2.75,1.02,0.18),"913e38")
	lettering(blade,"WASH",Vector3(0,0,0.1),0.66,"fff0b8")

func setup(owner_city):
	city=owner_city
	storefront()
	var towers:=ShaderMaterial.new()
	towers.shader=preload("res://skyline.gdshader")
	var rng:=RandomNumberGenerator.new()
	rng.seed=87121
	for i in 42:
		var x:=rng.randf_range(-230,270)
		var z:=rng.randf_range(-313,-254)
		var h:=rng.randf_range(23,69)
		if i==0:
			x=-13
			h=97
		var w:=rng.randf_range(9,20)
		var tower:=piece(self,Vector3(x,h/2,z),Vector3(w,h,w*0.81),"38445c")
		tower.position.z-=80
		tower.material_override=towers
		if i%3==0:
			var crown:=piece(self,tower.position+Vector3.UP*(h/2+2),Vector3(w*0.66,4,w*0.54),"38445c")
			crown.material_override=towers
			piece(self,crown.position+Vector3.UP*5,Vector3(0.23,8,0.23),"8899ad")
			piece(self,crown.position+Vector3.UP*9,Vector3(0.35,0.35,0.35),"ff6549",true)
	for x in range(-72,145,8):
		for z in [-96.5,-91.5]:
			var brace:=piece(self,Vector3(x,7.3,z),Vector3(8.1,0.22,0.2),"9c6246")
			brace.rotation.z=0.17 if x%16==0 else -0.17
			piece(self,Vector3(x,8.1,z),Vector3(8,0.20,0.22),"c69b78")
	for z in range(-78,10,15):
		for side in [-1,1]:
			var x:float=side*7.8
			piece(self,Vector3(x,2.8,z),Vector3(0.14,5.6,0.14),"394454")
			piece(self,Vector3(x-side*0.55,5.53,z),Vector3(1.16,0.12,0.12),"485364")
			piece(self,Vector3(x-side*1.13,5.43,z),Vector3(0.53,0.13,0.35),"ffd699",true)
			var lamp:=OmniLight3D.new()
			add_child(lamp)
			lamp.position=Vector3(x-side*1.13,4.98,z)
			lamp.light_color=Color("ffb268")
			lamp.light_energy=2.1
			lamp.omni_range=11
			lamp.distance_fade_enabled=true
			lamp.distance_fade_begin=33

extends Node3D

# Compact articulated winter outfits. All walkers share meshes and materials.
const COATS := ["a34a3a","446365","444765","9a703b","586940","77435e"]
var library := {}
var colors := {}
var walkers: Array[Dictionary] = []
var ray: Dictionary
var boarding := false
var clock := 0.0

func part(parent: Node3D, kind: String, tint: String, pos: Vector3, size: Vector3):
	if not library.has(kind):
		if kind=="boot":
			library[kind]=BoxMesh.new()
		else:
			var mesh:=SphereMesh.new()
			mesh.radial_segments=8
			mesh.rings=4
			library[kind]=mesh
	if not colors.has(tint):
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color(tint)
		colors[tint]=mat
	var piece:=MeshInstance3D.new()
	parent.add_child(piece)
	piece.mesh=library[kind]
	piece.material_override=colors[tint]
	piece.position=pos
	piece.scale=size

func person(index: int, pos: Vector3) -> Dictionary:
	var body:=Node3D.new()
	add_child(body)
	body.position=pos
	var coat: String=COATS[index%COATS.size()]
	var skin: String=["b67d61","dba687","88624e"][index%3]
	part(body,"round",coat,Vector3.UP*1.08,Vector3(0.55,0.77,0.37))
	part(body,"round",skin,Vector3(0,1.63,-0.025),Vector3(0.31,0.38,0.29))
	part(body,"round","2b3544",Vector3.UP*1.77,Vector3(0.35,0.23,0.32))
	part(body,"round","c5ad8a",Vector3.UP*1.45,Vector3(0.38,0.15,0.35))
	var limbs: Array[Node3D]=[]
	for arm in [false,true]:
		for side in [-1,1]:
			var pivot:=Node3D.new()
			body.add_child(pivot)
			pivot.position=Vector3(side*(0.26 if arm else 0.13),1.35 if arm else 0.83,0)
			limbs.append(pivot)
			part(pivot,"round",coat if arm else "343a49",Vector3.DOWN*(0.25 if arm else 0.38),Vector3(0.18,0.59,0.2) if arm else Vector3(0.21,0.78,0.23))
			if not arm:
				part(pivot,"boot","322f34",Vector3(0,-0.74,-0.043),Vector3(0.19,0.16,0.31))
	return {"body":body,"limbs":limbs,"origin":pos,"phase":index*2.73,"down":0.0,"push":Vector3.ZERO,"returning":false}

func setup():
	for i in 64:
		var avenue: int=preload("res://district.gd").AVENUES[i%8]
		var street: int=preload("res://district.gd").STREETS[i/8]
		walkers.append(person(i,Vector3(avenue+(8.5 if i%3 else -8.5),0,street+23)))
	for n in 4:
		walkers.append(person(n,Vector3(-8.3 if n%2==0 else 8.6,0,-13-n*8)))
	ray=person(5,Vector3(-5.4,0,-24))
	var bag:=ray.body as Node3D
	part(bag,"round","483a32",Vector3(0.4,0.63,0.02),Vector3(0.3,0.38,0.55))
	var tag:=Label3D.new()
	bag.add_child(tag)
	tag.text="РЭЙ"
	tag.position.y=2.1
	tag.pixel_size=0.007
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED

func reset_ray(waiting: bool):
	boarding=false
	ray.body.visible=waiting
	ray.body.position=ray.origin

func stride(person_data: Dictionary, phase: float):
	for limb in 4:
		person_data.limbs[limb].rotation.x=sin(phase)*0.48*(1 if limb in [0,3] else -1)

func vehicle_contacts(car: Node3D, speed: float) -> bool:
	var hit:=false
	if absf(speed)<2.0:
		return false
	for walker in walkers:
		var body: Node3D=walker.body
		if not body.visible or walker.down>0:
			continue
		var local:=car.to_local(body.position)
		if absf(local.x)<1.37 and absf(local.z)<2.45:
			hit=true
			walker.down=2.8
			walker.returning=true
			walker.push=-car.basis.z*signf(speed)*minf(absf(speed)*0.42,5.0)
			body.rotation.y=car.rotation.y
			body.rotation.x=signf(speed)*1.35

	return hit

func animate(dt: float, car: Node3D, focus: Vector3):
	clock+=dt
	for walker in walkers:
		var node: Node3D=walker.body
		node.visible=focus.distance_squared_to(walker.origin)<5600
		if not node.visible:
			continue
		var distance:=fposmod(clock*1.17+float(walker.phase),24.0)
		if walker.down>0:
			node.position+=walker.push*dt
			walker.push=walker.push.move_toward(Vector3.ZERO,10*dt)
			walker.down=maxf(0,walker.down-dt)
			if walker.down<0.55:
				node.rotation.x=move_toward(node.rotation.x,0,dt*3)
			continue
		var destination: Vector3=walker.origin+Vector3.BACK*(absf(distance-12)-6)
		if walker.returning:
			if car.position.distance_to(node.position)<2.7:
				continue
			node.position=node.position.move_toward(destination,2.3*dt)
			walker.returning=node.position.distance_to(destination)>0.1
		else:
			node.position=destination
		node.rotation.y=0 if distance<12 else PI
		stride(walker,clock*4.4+float(walker.phase))
	if boarding:
		var door:=car.position+car.basis.x*1.25
		ray.body.look_at(door)
		ray.body.position=ray.body.position.move_toward(door,dt*4.4)
		stride(ray,clock*8)
		if ray.body.position.distance_to(door)<0.2:
			ray.body.hide()
			boarding=false

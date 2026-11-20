extends Node3D

# Compact articulated winter outfits. All walkers share meshes and materials.
const COATS := ["a34a3a","446365","444765","9a703b","586940","77435e"]
var paths:=preload("res://footpaths.gd").new()
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
	for walker in walkers:
		walker.goal=paths.nearest_corner(walker.origin)
		walker.last=-1
		walker.rest=0.0
		walker.fright=0.0
		walker.escape=Vector3.ZERO
		walker.pace=paths.rng.randf_range(1.05,1.66)
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
			for witness in walkers:
				if witness!=walker and witness.body.position.distance_squared_to(body.position)<72:
					witness.fright=1.6
					witness.escape=body.position
			walker.down=2.8
			walker.returning=true
			walker.push=-car.basis.z*signf(speed)*minf(absf(speed)*0.42,5.0)
			body.rotation.y=car.rotation.y
			body.rotation.x=signf(speed)*1.35

	return hit

func approaching(pos:Vector3, body:Node3D, speed:float)->bool:
	if absf(speed)<1.8:
		return false
	var local:=body.to_local(pos)
	var ahead:float=-local.z*signf(speed)
	return absf(local.x)<2.35 and ahead>=0 and ahead<3+absf(speed)*1.45

func advance_walker(walker:Dictionary,dt:float,car:Node3D,traffic:Array,car_speed:float):
	var node:Node3D=walker.body
	var goal:Vector3=paths.corners[walker.goal]
	var direction:=node.position.direction_to(goal)
	var pace:float=walker.pace
	if approaching(node.position,car,car_speed):
		walker.fright=1.25
		walker.escape=car.position
	if walker.fright>0:
		walker.fright=maxf(0,walker.fright-dt)
		var away:Vector3=node.position-walker.escape
		# Pick a clear escape direction. Test at torso height against parked cars and facades.
		direction=away.normalized()
		if absf(car_speed)>1.8 and approaching(node.position,car,car_speed):
			direction=car.basis.x*(1 if car.to_local(node.position).x>=0 else -1)
		var start:=node.position+Vector3.UP
		var query:=PhysicsRayQueryParameters3D.create(start,start+direction*1.1,1)
		if not node.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			direction=Vector3.ZERO
		pace=3.6
	elif walker.rest>0:
		walker.rest-=dt
		stride(walker,0)
		return
	elif node.position.distance_squared_to(goal)<0.12:
		var next:=paths.choose(walker.goal,walker.last)
		walker.last=walker.goal
		walker.goal=next
		if paths.rng.randf()<0.2:
			walker.rest=paths.rng.randf_range(0.6,2.0)
		return
	elif walker.last>=0 and paths.corners[walker.last].distance_to(goal)<20 and node.position.distance_to(paths.corners[walker.last])<1.1:
		# At the curb, look ahead to where the pedestrian and vehicle paths meet.
		var crossing:=node.position+direction*5.0
		if approaching(crossing,car,car_speed):
			stride(walker,0)
			return
		for item in traffic:
			if item.moving and approaching(crossing,item.body,item.velocity):
				stride(walker,0)
				return
	if direction.length_squared()>0.01:
		node.rotation.y=lerp_angle(node.rotation.y,atan2(-direction.x,-direction.z),minf(1.0,dt*10))
		node.position+=direction*dt*pace
	stride(walker,clock*pace*3.6+float(walker.phase))

func animate(dt: float, car: Node3D, focus: Vector3, traffic:Array=[], car_speed:=0.0):
	clock+=dt
	for walker in walkers:
		var node: Node3D=walker.body
		node.visible=focus.distance_squared_to(node.position)<5600
		if not node.visible:
			continue
		if walker.down>0:
			node.position+=walker.push*dt
			walker.push=walker.push.move_toward(Vector3.ZERO,10*dt)
			walker.down=maxf(0,walker.down-dt)
			if walker.down<0.55:
				node.rotation.x=move_toward(node.rotation.x,0,dt*3)
			continue
		advance_walker(walker,dt,car,traffic,car_speed)
	if boarding:
		var door:=car.position+car.basis.x*1.25
		ray.body.look_at(door)
		ray.body.position=ray.body.position.move_toward(door,dt*4.4)
		stride(ray,clock*8)
		if ray.body.position.distance_to(door)<0.2:
			ray.body.hide()
			boarding=false

extends CharacterBody3D

const District=preload("res://district.gd")
var walking := false
var avatar: Dictionary
var capsule := CapsuleShape3D.new()
var heading := 0.0
var step_phase := 0.0

func setup(people):
	capsule.radius=0.32
	capsule.height=1.8
	var hitbox:=CollisionShape3D.new()
	hitbox.shape=capsule
	hitbox.position.y=0.91
	add_child(hitbox)
	avatar=people.person(0,Vector3.ZERO)
	avatar.body.reparent(self,false)
	park()

func park():
	walking=false
	collision_layer=0
	collision_mask=0
	velocity=Vector3.ZERO
	hide()

func switch_seat(car: CharacterBody3D, speed: float):
	if walking:
		if position.distance_to(car.position)<3.3:
			park()
		return
	if absf(speed)>1.5:
		return
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	for offset in [-1.85,1.85]:
		var door: Vector3=car.position+car.basis.x*offset
		query.transform.origin=door+Vector3.UP*0.91
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			position=door
			heading=car.rotation.y
			avatar.body.rotation.y=heading
			collision_layer=2
			collision_mask=1
			walking=true
			show()
			return

func jump():
	if walking and is_on_floor():
		velocity.y=6.1

func walk(dt: float, horizontal: float, forward: float, people, camera: Camera3D, pitch: float, zoom: float, can_sprint: bool):
	var direction:=Vector3(-horizontal,0,-forward).rotated(Vector3.UP,heading).limit_length(1)
	var pace:=6.1 if can_sprint and Input.is_physical_key_pressed(KEY_SHIFT) else 3.4
	velocity.x=direction.x*pace
	velocity.z=direction.z*pace
	velocity.y-=18.0*dt
	move_and_slide()
	position.x=clampf(position.x,District.WEST,District.EAST)
	position.z=clampf(position.z,District.NORTH,District.SOUTH)
	if direction.length_squared()>0.01:
		avatar.body.rotation.y=lerp_angle(avatar.body.rotation.y,atan2(-direction.x,-direction.z),1-exp(-14*dt))
		step_phase+=pace*dt*2.4
	people.stride(avatar,step_phase if direction.length_squared()>0 else 0.0)
	var focus:=position+Vector3.UP*1.2
	var desired:=focus+Vector3(0,sin(pitch),cos(pitch)).rotated(Vector3.UP,heading)*4.2*zoom
	var ray:=PhysicsRayQueryParameters3D.create(focus,desired,1,[get_rid()])
	var obstacle:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not obstacle.is_empty():
		desired=obstacle.position+obstacle.normal*0.18
	camera.position=camera.position.lerp(desired,1-exp(-10*dt))
	if camera.position.distance_to(focus)>0.1:
		camera.look_at(focus)

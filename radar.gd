extends Control
var city: Node3D

func project_point(p: Vector3) -> Vector2:
	return Vector2((p.x+87)*0.67+9,(p.z+201)*0.57+25)

func _draw():
	if not city or not city.pending.is_empty():
		return
	draw_rect(Rect2(0,0,168,159),Color("#0c1728e8"))
	draw_string(ThemeDB.fallback_font,Vector2(10,16),"ДИСПЕТЧЕРСКАЯ    N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#e0d6c6"))
	for x in [-64,0,64,128]:
		draw_line(project_point(Vector3(x,0,-194)),project_point(Vector3(x,0,25)),Color("#54647b"),3)
	for z in [-196,-148,-88,-40,8]:
		draw_line(project_point(Vector3(-76,0,z)),project_point(Vector3(137,0,z)),Color("#54647b"),3)
	draw_circle(project_point(city.marker.position),4,Color("#ffbe65"))
	if city.fork:
		draw_circle(project_point(city.second.position),4,Color("#55e4df"))
	if city.patrol.visible:
		draw_circle(project_point(city.patrol.position),3,Color("#ff555c"))
	var pos:=project_point(city.car.position)
	var direction:=Vector2(-city.car.basis.z.x,-city.car.basis.z.z).normalized()
	draw_colored_polygon(PackedVector2Array([pos+direction*6,pos-direction*4+direction.orthogonal()*4,pos-direction*4-direction.orthogonal()*4]),Color.WHITE)

func _process(_dt):
	queue_redraw()

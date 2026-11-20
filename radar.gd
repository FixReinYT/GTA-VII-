extends Control
const District=preload("res://district.gd")
var city: Node3D

func project_point(p: Vector3) -> Vector2:
	return Vector2((p.x-District.WEST)*0.315+9,(p.z-District.NORTH)*0.28+24)

func _draw():
	if not city or not city.pending.is_empty():
		return
	draw_rect(Rect2(0,0,168,159),Color("#0c1728e8"))
	draw_string(ThemeDB.fallback_font,Vector2(10,16),"ДИСПЕТЧЕРСКАЯ    N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#e0d6c6"))
	for x in District.AVENUES:
		draw_line(project_point(Vector3(x,0,District.NORTH)),project_point(Vector3(x,0,District.SOUTH)),Color("#54647b"),3)
	for z in District.STREETS:
		draw_line(project_point(Vector3(District.WEST,0,z)),project_point(Vector3(District.EAST,0,z)),Color("#54647b"),3)
	for i in city.shops.LOCATIONS.size():
		var marker_pos:=project_point(city.shops.LOCATIONS[i])
		draw_string(ThemeDB.fallback_font,marker_pos,["Е","К","О"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#9fe7a6"))
	if city.marker.visible:
		draw_circle(project_point(city.marker.position),4,Color("#ffbe65"))
	if city.fork:
		draw_circle(project_point(city.second.position),4,Color("#55e4df"))
	if city.patrol.visible:
		draw_circle(project_point(city.patrol.position),3,Color("#ff555c"))
	if city.streets.police.visible:
		draw_circle(project_point(city.streets.police.position),3,Color("#ff555c"))
	if city.streets.stop.visible:
		draw_circle(project_point(city.streets.stop.position),4,Color("#55e4df"))
	var pos:=project_point(city.car.position)
	if city.driver.walking:
		draw_circle(pos,3,Color("#84d3dc"))
		pos=project_point(city.driver.position)
	var direction:=Vector2(-city.car.basis.z.x,-city.car.basis.z.z).normalized()
	draw_colored_polygon(PackedVector2Array([pos+direction*6,pos-direction*4+direction.orthogonal()*4,pos-direction*4-direction.orthogonal()*4]),Color.WHITE)

func _process(_dt):
	queue_redraw()

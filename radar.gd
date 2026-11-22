extends Control
const District=preload("res://district.gd")
var city:Node3D
var expanded:=false
var origin:=Vector2.ZERO
var scale_factor:=1.0
var canvas:=Vector2.ZERO

func project_point(p:Vector3)->Vector2:
	return (Vector2(p.x,p.z)-origin)*scale_factor+Vector2(0,24)

func rect_at(p:Vector2,extent:Vector2,tint:Color):
	var start:=(p-extent*0.5-origin)*scale_factor+Vector2(0,24)
	var rect:=Rect2(start,extent*scale_factor).intersection(Rect2(Vector2(0,24),canvas))
	if rect.has_area():
		draw_rect(rect,tint)

func dot(p:Vector3,tint:Color,radius:float):
	var at:=project_point(p)
	if Rect2(Vector2(0,24),canvas).has_point(at):
		draw_circle(at,radius,tint)

func _draw():
	if not city or not city.pending.is_empty() or city.shops.shop>=0:
		return
	var actor:Node3D=city.driver if city.driver.walking else city.car
	canvas=Vector2(620,530) if expanded else Vector2(172,138)
	scale_factor=1.13 if expanded else 1.36
	origin=Vector2(32,-92)-canvas/(2*scale_factor) if expanded else Vector2(actor.position.x,actor.position.z)-canvas/(2*scale_factor)
	draw_rect(Rect2(Vector2.ZERO,canvas+Vector2(0,24)),Color("#25383c"))
	draw_string(ThemeDB.fallback_font,Vector2(6,17),"ЛЕЙК-СИТИ     ·     M — закрыть" if expanded else "N ↑    РАЙОН    ·    M — карта",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	for x in District.AVENUES:
		rect_at(Vector2(x,-92),Vector2(15,454),Color("#546777"))
	for z in District.STREETS:
		rect_at(Vector2(32,z),Vector2(478,15),Color("#546777"))
	for item in city.map_shapes:
		rect_at(item.p,item.s,item.c)
	rect_at(Vector2(32,-94),Vector2(226,4),Color("#a78561"))
	for i in city.shops.LOCATIONS.size():
		var at:=project_point(city.shops.LOCATIONS[i])
		if Rect2(Vector2(0,24),canvas).has_point(at):
			draw_circle(at,7,Color("#233e36"))
			draw_string(ThemeDB.fallback_font,at+Vector2(-4,4),["Е","К","О"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#d5ffbe"))
	for item in [[city.marker,Color("#ffbe65")],[city.second,Color("#55e4df")],[city.streets.stop,Color("#55e4df")],[city.patrol,Color("#ff555c")],[city.streets.police,Color("#ff555c")]]:
		if item[0].visible:
			dot(item[0].position,item[1],4)
	if city.driver.walking:
		dot(city.car.position,Color("#8fd8e3"),4)
	var heading:float=city.driver.heading if city.driver.walking else city.car.rotation.y
	var direction:=Vector2(-sin(heading),-cos(heading))
	var pos:=project_point(actor.position)
	draw_colored_polygon(PackedVector2Array([pos+direction*6,pos-direction*4+direction.orthogonal()*4,pos-direction*4-direction.orthogonal()*4]),Color.WHITE)
	if expanded:
		draw_string(ThemeDB.fallback_font,Vector2(16,543),"Е — кафе     К — одежда     О — оружие     ● — цель",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)

func _process(_dt):
	queue_redraw()

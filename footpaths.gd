extends RefCounted
const District=preload("res://district.gd")
var corners: Array[Vector3]=[]
var links: Array[PackedInt32Array]=[]
var rng:=RandomNumberGenerator.new()

func _init():
	rng.seed=90921
	for z in District.STREETS:
		for x in District.AVENUES:
			for side_z in [-8.6,8.6]:
				for side_x in [-8.6,8.6]:
					corners.append(Vector3(x+side_x,0,z+side_z))
	for i in corners.size():
		var exits:=PackedInt32Array()
		for direction in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
			var best:=-1
			var nearest:=90.0
			for j in corners.size():
				var offset:=corners[j]-corners[i]
				var distance:=offset.dot(direction)
				if distance>0.1 and distance<nearest and absf(direction.cross(offset).y)<0.02:
					best=j
					nearest=distance
			if best>=0:
				exits.append(best)
		links.append(exits)

func nearest_corner(pos:Vector3)->int:
	var best:=0
	for i in corners.size():
		if pos.distance_squared_to(corners[i])<pos.distance_squared_to(corners[best]):
			best=i
	return best

func choose(current:int,previous:int)->int:
	var options:=links[current].duplicate()
	if options.size()>1:
		var index:=options.find(previous)
		if index>=0:
			options.remove_at(index)
	return options[rng.randi_range(0,options.size()-1)]

extends RefCounted

const AVENUES := [-192,-128,-64,0,64,128,192,256]
const STREETS := [-304,-248,-196,-148,-88,-40,8,64,120]
const WEST := -207
const EAST := 271
const NORTH := -319
const SOUTH := 135

static func near_street(z: float) -> bool:
	for street in STREETS:
		if absf(z-street)<12:
			return true
	return false

static func district_name(pos: Vector3) -> String:
	if pos.z < -196:
		return "Северное депо"
	if pos.x < -64:
		return "Западный парк"
	if pos.x > 150:
		return "Грузовой порт"
	if pos.z > 16:
		return "Южные кварталы"
	return "Старый центр"

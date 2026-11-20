extends SceneTree
func _initialize():
	run.call_deferred()

func picture(path: String):
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_jpg(path,0.9) != OK:
		quit(1)

func run():
	change_scene_to_file("res://menu.tscn")
	await scene_changed
	await create_timer(2.5).timeout
	assert(current_scene.screen.visible)
	await picture("build/Menu.jpg")
	current_scene.start_button.pressed.emit()
	await scene_changed
	current_scene.advance_card()
	await create_timer(0.35).timeout
	await picture("build/City.jpg")
	current_scene.set_physics_process(false)
	current_scene.camera.position=Vector3(3,2.7,-16)
	current_scene.camera.look_at(Vector3(-9.7,2,-24))
	await picture("build/Laundry.jpg")
	quit()

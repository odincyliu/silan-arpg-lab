extends SceneTree


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var scene: Node3D = load("res://scenes/world/region_a.tscn").instantiate()
    root.add_child(scene)
    for i in 90:
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/playable_preview.png")
    var player: CharacterBody3D = scene.get_node("Player")
    player.set_physics_process(false)
    player.global_position = Vector3(-340, 1, -600)
    for i in 90:
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/ruins_preview.png")
    var camera: Camera3D = scene.get_node("CameraRig/Camera3D")
    scene.get_node("CameraRig").set_process(false)
    camera.global_position = Vector3(120, 160, 150)
    camera.look_at(Vector3(-45, 0, -80), Vector3.UP)
    scene.get_node("HUD").visible = false
    for i in 10:
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/region_preview.png")
    print("CAPTURE_OK")
    scene.queue_free()
    for i in 4:
        await process_frame
    quit()

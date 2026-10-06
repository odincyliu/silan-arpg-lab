extends SceneTree


func _initialize() -> void:
    call_deferred("_capture")


func _frames(count: int) -> void:
    for i in count:
        await process_frame
    await RenderingServer.frame_post_draw


func _capture() -> void:
    var scene: Node3D = load("res://scenes/world/shattered_ruins.tscn").instantiate()
    root.add_child(scene)
    await _frames(100)
    root.get_texture().get_image().save_png("res://docs/shattered_ruins_overview.png")
    var key := InputEventKey.new()
    key.physical_keycode = KEY_V
    key.pressed = true
    scene._unhandled_input(key)
    await _frames(100)
    root.get_texture().get_image().save_png("res://docs/shattered_ruins_play.png")
    var player: CharacterBody3D = scene.get_node("Player")
    player.global_position = Vector3(40, 20, -10)
    await _frames(120)
    root.get_texture().get_image().save_png("res://docs/shattered_ruins_detail.png")
    print("RUINS_CAPTURE_OK position=", player.global_position, " grounded=", player.is_on_floor())
    scene.queue_free()
    await _frames(4)
    quit()

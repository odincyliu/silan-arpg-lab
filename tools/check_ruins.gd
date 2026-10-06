extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_check")


func _frames(count: int) -> void:
    for i in count:
        await physics_frame


func _expect(condition: bool, message: String) -> void:
    print("PASS " if condition else "FAIL ", message)
    if not condition:
        failures.append(message)


func _toggle_view() -> void:
    var event := InputEventKey.new()
    event.physical_keycode = KEY_V
    event.keycode = KEY_V
    event.pressed = true
    root.push_input(event)
    await process_frame
    var release := InputEventKey.new()
    release.physical_keycode = KEY_V
    release.keycode = KEY_V
    root.push_input(release)
    await process_frame


func _first_mesh(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node
    for child in node.get_children():
        var found := _first_mesh(child)
        if found:
            return found
    return null


func _check() -> void:
    var scene: Node3D = load("res://scenes/world/shattered_ruins.tscn").instantiate()
    root.add_child(scene)
    await _frames(5)
    var player: CharacterBody3D = scene.get_node("Player")
    var rig: Node3D = scene.get_node("CameraRig")
    var terrain := _first_mesh(scene.get_node("OriginalTerrain"))
    var box := terrain.mesh.get_aabb()
    _expect(scene.overview and not rig.is_processing(), "預設顯示原始地點全景")
    _expect(terrain.mesh.get_surface_count() == 1, "原始曲面使用完整地表圖集")
    _expect(absf(box.size.x - 320.0) < 0.2 and absf(box.size.z - 320.0) < 0.2, "原始 320 × 320 m 區塊尺度")
    _expect(box.size.y > 13.0, "保留來源曲面高度，未用平面取代")
    _expect(scene.get_node("OriginalTerrain").get_meta("source_patch_count") == 100, "100 原始曲面片可追溯")
    _expect(scene.get_node("OriginalTerrain").get_meta("source_tile_count") == 25600, "25,600 原始地表格可追溯")
    _expect(scene.get_node("OriginalRuins").get_child_count() > 0, "完整原始遺跡群存在")
    _expect(scene.get_node("OriginalFlora").get_child_count() == 11, "11 個來源靜態植物皆保留")
    await _toggle_view()
    await _frames(90)
    _expect(not scene.overview and rig.is_processing(), "V 切換至角色探索")
    _expect(player.is_on_floor(), "出生點能落在原始地形上")
    var start := player.global_position
    Input.action_press("move_back")
    await _frames(60)
    Input.action_release("move_back")
    await _frames(30)
    _expect(player.global_position.distance_to(start) > 1.0, "可在遺跡地形上實際移動")
    _expect(player.is_on_floor(), "移動後仍貼齊來源地形")
    var tree: AnimationTree = player.get_node("Visual/AnimationTree")
    tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
    await _frames(4)
    _expect(tree.get("parameters/Attack/active"), "遺跡場景仍可觸發揮擊")
    await _toggle_view()
    var paused := player.global_position
    Input.action_press("move_forward")
    await _frames(20)
    Input.action_release("move_forward")
    _expect(player.global_position.is_equal_approx(paused), "俯瞰時角色暫停，避免走出畫面")
    await _toggle_view()
    _expect(rig.is_processing() and player.is_physics_processing(), "返回探索後恢復角色與相機")
    print("RUINS_RESULT ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
    scene.queue_free()
    await _frames(5)
    quit(0 if failures.is_empty() else 1)

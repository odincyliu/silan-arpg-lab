extends SceneTree

var failures: Array[String] = []
var scene: Node3D


func _initialize() -> void:
    call_deferred("_check")


func _expect(condition: bool, message: String) -> void:
    print("PASS " if condition else "FAIL ", message)
    if not condition:
        failures.append(message)


func _frames(count: int) -> void:
    for i in count:
        await physics_frame


func _check() -> void:
    scene = load("res://scenes/world/region_a.tscn").instantiate()
    root.add_child(scene)
    await _frames(100)
    var player: CharacterBody3D = scene.get_node("Player")
    var tree: AnimationTree = player.get_node("Visual/AnimationTree")
    var skeleton: Skeleton3D = player.get_node("Visual/Armature/Skeleton3D")
    _expect(player.is_on_floor(), "出生點落地；沒有穿過地面")
    _expect(absf(player.global_position.y) < 0.2, "人偶腳底位於地面，1 單位 = 1 公尺")
    _expect(skeleton.get_bone_count() == 65, "Quaternius 原始 65 骨骼人偶")
    _expect(tree.active, "AnimationTree 啟用")
    var leg := skeleton.find_bone("calf_l")
    var idle_pose := skeleton.get_bone_pose_rotation(leg)
    var start := player.global_position
    Input.action_press("walk_toggle")
    # 走路切換是離散事件；測試直接設定相同遊戲狀態。
    player.walking = true
    Input.action_release("walk_toggle")
    Input.action_press("move_forward")
    await _frames(90)
    _expect(player.speed > 2.3 and player.speed < 2.7, "走路速度約 2.5 m/s")
    _expect(start.distance_to(player.global_position) > 2.0, "WASD 透過 CharacterBody3D 實際移動")
    _expect(idle_pose.angle_to(skeleton.get_bone_pose_rotation(leg)) > 0.01, "走路動畫骨骼確實變動")
    player.walking = false
    await _frames(70)
    _expect(player.speed > 4.8 and player.speed < 5.2, "跑步速度約 5 m/s")
    Input.action_press("sprint")
    await _frames(70)
    _expect(player.speed > 7.8 and player.speed < 8.2, "衝刺速度約 8 m/s")
    Input.action_release("move_forward")
    Input.action_release("sprint")
    await _frames(80)
    _expect(player.speed < 0.01, "減速後停住")
    var blend: Vector2 = tree.get("parameters/Locomotion/blend_position")
    _expect(blend.length() < 0.02, "停下後平滑回到 Idle")
    player.global_position = Vector3(300, 12, -200)
    player.velocity = Vector3.ZERO
    await _frames(160)
    _expect(player.is_on_floor(), "緩坡區有地形碰撞")
    Input.action_press("move_right")
    await _frames(60)
    _expect(player.is_on_floor(), "緩坡移動持續貼地")
    Input.action_release("move_right")
    var camera: Camera3D = scene.get_node("CameraRig/Camera3D")
    var angle := rad_to_deg(asin(camera.global_basis.z.y))
    _expect(angle > 30 and angle < 60, "ARPG 鏡頭俯角在合理範圍")
    tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
    await _frames(4)
    _expect(tree.get("parameters/Attack/active"), "UAL2 Melee_Hook 單次動作可以觸發")
    _expect(scene.get_node("Terrain").get_child_count() == 56, "56 地形區塊完整載入")
    _expect(scene.get_node("Village").get_child_count() > 0, "原始 Silan 村莊 GLB 存在")
    var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ryzom/converted/region_a.json"))
    var count := 0
    for plant: Dictionary in map.plants:
        if str(plant.source_form).to_lower() in ["fo_s1_giant_tree", "fo_s2_birch"]:
            count += 1
    _expect(count == 695, "695 棵實際 Ryzom 樹木原始座標可追溯")
    print("RESULT ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
    scene.queue_free()
    await _frames(5)
    quit(0 if failures.is_empty() else 1)

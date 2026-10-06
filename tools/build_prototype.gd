extends SceneTree

const CONVERTED := "res://assets/ryzom/converted/"
var data: Dictionary
var world: Node3D
var terrain: Node3D
var flat_zones: Array[Rect2] = [Rect2(-80, -35, 170, 155), Rect2(-510, -840, 320, 340)]
var road_points: Array[Vector2] = [Vector2(0, 0), Vector2(-30, -90), Vector2(-95, -220),
                                Vector2(-220, -365), Vector2(-285, -490), Vector2(-360, -610)]


func _initialize() -> void:
    call_deferred("_build")


func _build() -> void:
    data = JSON.parse_string(FileAccess.get_file_as_string(CONVERTED + "region_a.json"))
    for directory in ["res://scenes/player", "res://scenes/world", "res://scenes/environment", "res://assets/ryzom/meshes"]:
        DirAccess.make_dir_recursive_absolute(directory)
    _build_player()
    world = Node3D.new()
    world.name = "RegionA"
    world.set_script(load("res://scripts/world.gd"))
    terrain = _group("Terrain")
    var village := _group("Village")
    var forest := _group("Forest")
    var roads := _group("Roads")
    var landmarks := _group("Landmarks")
    _group("Collision")
    _build_terrain()
    _object(village, "zonematerial-foret-start_village_newbieland", Vector3(-64, 0, 115), true)
    _object(landmarks, "zonematerial-foret-ruines_newbieland", Vector3(-544, 0, -525), true)
    _object(landmarks, "chlorogoo_watchtower", Vector3(100, _height(100, -260), -260), true)
    _object(landmarks, "karavan_sensor", Vector3(-560, _height(-560, -740), -740), true)
    _build_forest(forest)
    _build_road(roads)
    _lighting()
    _boundary()
    _label(landmarks, "SILAN  /  STARTING CAMP", Vector3(0, 9, 45))
    _label(landmarks, "SHATTERED RUINS", Vector3(-360, 30, -650))
    _label(landmarks, "CHLOROGOO WATCHTOWER", Vector3(100, 75, -260))
    _label(landmarks, "KARAVAN SENSOR", Vector3(-560, 17, -740))
    var spawn := Marker3D.new()
    spawn.name = "PlayerSpawn"
    spawn.position = Vector3(-5, 1.5, 40)
    world.add_child(spawn)
    var player: Node3D = load("res://scenes/player/player.tscn").instantiate()
    player.name = "Player"
    player.position = spawn.position
    world.add_child(player)
    var rig := Node3D.new()
    rig.name = "CameraRig"
    rig.set_script(load("res://scripts/arpg_camera.gd"))
    rig.set("target_path", NodePath("../Player"))
    world.add_child(rig)
    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera.fov = 52
    camera.far = 1400
    rig.add_child(camera)
    var skills := Node3D.new()
    skills.name = "TemporarySkillHooks"
    skills.set_script(load("res://scripts/skill_hooks.gd"))
    skills.set("player_path", NodePath("../Player"))
    world.add_child(skills)
    _hud()
    _own(world, world)
    root.add_child(world)
    # MultiMesh 的 GPU 緩衝區在 RendererDummy 無法讀回；使用實際渲染器烘焙。
    for i in 3:
        await process_frame
    await RenderingServer.frame_post_draw
    # 保留玩家為獨立場景實例；資源重建時不需重複展開。
    var packed := PackedScene.new()
    packed.pack(world)
    assert(ResourceSaver.save(packed, "res://scenes/world/region_a.tscn") == OK)
    _save_inputs()
    print("BUILD_OK tiles=", data.cells.size(), " plants=", data.plants.size(), " size=1280x1120m")
    world.free()
    quit()


func _build_player() -> void:
    var body := CharacterBody3D.new()
    body.name = "Player"
    body.set_script(load("res://scripts/player.gd"))
    body.collision_layer = 2
    body.collision_mask = 1
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position.y = 0.9
    body.add_child(collision)
    var visual: Node3D = load("res://assets/animations/UAL1_Standard.glb").instantiate()
    visual.scene_file_path = ""
    visual.name = "Visual"
    body.add_child(visual)
    var ap: AnimationPlayer = visual.find_child("AnimationPlayer", true, false)
    var library := AnimationLibrary.new()
    for name in ["Idle", "Walk", "Jog_Fwd", "Sprint"]:
        assert(ap.has_animation(name), "Godot 匯入動畫名稱不存在：" + name)
        var clip: Animation = ap.get_animation(name).duplicate()
        clip.loop_mode = Animation.LOOP_LINEAR
        library.add_animation(name, clip)
    var second: Node = load("res://assets/animations/UAL2_Standard.glb").instantiate()
    var second_ap: AnimationPlayer = second.find_child("AnimationPlayer", true, false)
    library.add_animation("Melee_Hook", second_ap.get_animation("Melee_Hook").duplicate())
    second.free()
    for old in ap.get_animation_library_list():
        ap.remove_animation_library(old)
    ap.add_animation_library("", library)
    var tree := AnimationTree.new()
    tree.name = "AnimationTree"
    tree.anim_player = NodePath("../AnimationPlayer")
    var blend := AnimationNodeBlendTree.new()
    var locomotion := AnimationNodeBlendSpace2D.new()
    locomotion.min_space = Vector2(-1, 0)
    locomotion.max_space = Vector2(1, 2)
    locomotion.x_label = "movement_x"
    locomotion.y_label = "speed"
    locomotion.sync = true
    var idle := AnimationNodeAnimation.new()
    idle.animation = "Idle"
    locomotion.add_blend_point(idle, Vector2.ZERO, -1, "Idle")
    var names := ["Walk", "Jog_Fwd", "Sprint"]
    var speeds := [0.5, 1.0, 2.0]
    for i in names.size():
        for x in [-1.0, 0.0, 1.0]:
            var node := AnimationNodeAnimation.new()
            node.animation = names[i]
            locomotion.add_blend_point(node, Vector2(x, speeds[i]), -1, names[i] + "_" + str(int(x) + 1))
    blend.add_node("Locomotion", locomotion, Vector2(0, 0))
    var attack_clip := AnimationNodeAnimation.new()
    attack_clip.animation = "Melee_Hook"
    blend.add_node("Melee", attack_clip, Vector2(0, 200))
    var attack := AnimationNodeOneShot.new()
    attack.fadein_time = 0.12
    attack.fadeout_time = 0.2
    blend.add_node("Attack", attack, Vector2(300, 0))
    blend.connect_node("Attack", 0, "Locomotion")
    blend.connect_node("Attack", 1, "Melee")
    blend.connect_node("output", 0, "Attack")
    tree.tree_root = blend
    visual.add_child(tree)
    tree.active = true
    _own(body, body)
    var packed := PackedScene.new()
    packed.pack(body)
    assert(ResourceSaver.save(packed, "res://scenes/player/player.tscn") == OK)
    body.free()


func _group(name: String) -> Node3D:
    var node := Node3D.new()
    node.name = name
    world.add_child(node)
    return node


func _own(node: Node, owner_node: Node) -> void:
    for child in node.get_children():
        child.owner = owner_node
        if child.scene_file_path.is_empty():
            _own(child, owner_node)


func _height(x: float, z: float) -> float:
    # 離線暫時地面：只重建緩坡，不假裝這是 NeL 原始 Patch 高度。
    var fade := 1.0
    for zone in flat_zones:
        var nearest := Vector2(clampf(x, zone.position.x, zone.end.x), clampf(z, zone.position.y, zone.end.y))
        fade *= smoothstep(0.0, 45.0, nearest.distance_to(Vector2(x, z)))
    return (3.0 * sin(x / 90.0) * cos(z / 115.0) + 2.0 * sin(z / 53.0)) * fade


func _build_terrain() -> void:
    var material := StandardMaterial3D.new()
    material.albedo_texture = load("res://assets/ryzom/textures/ground.png")
    material.albedo_color = Color(0.65, 0.7, 0.65)
    material.roughness = 1.0
    for cell: Dictionary in data.cells:
        var origin := Vector3(cell.position[0], 0, cell.position[2] - 160)
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for z in range(20):
            for x in range(20):
                var a := Vector2(origin.x + x * 8, origin.z + z * 8)
                var b := a + Vector2(8, 0)
                var c := a + Vector2(0, 8)
                var d := a + Vector2(8, 8)
                for point in [a, b, c, b, d, c]:
                    var dx := _height(point.x + 0.1, point.y) - _height(point.x - 0.1, point.y)
                    var dz := _height(point.x, point.y + 0.1) - _height(point.x, point.y - 0.1)
                    st.set_normal(Vector3(-dx / 0.2, 1, -dz / 0.2).normalized())
                    st.set_uv(point / 8.0)
                    st.add_vertex(Vector3(point.x, _height(point.x, point.y), point.y))
        st.set_material(material)
        var mesh := st.commit()
        var id := "chunk_%s_%s" % [int(cell.grid[0]), absi(int(cell.grid[1]))]
        var path := "res://assets/ryzom/meshes/" + id + ".res"
        ResourceSaver.save(mesh, path)
        var instance := MeshInstance3D.new()
        instance.name = id
        instance.mesh = load(path)
        instance.set_meta("ryzom_ligo_template", cell.template)
        terrain.add_child(instance)
        var static_body := StaticBody3D.new()
        var shape := CollisionShape3D.new()
        shape.shape = mesh.create_trimesh_shape()
        static_body.add_child(shape)
        instance.add_child(static_body)


func _object(parent: Node3D, name: String, position: Vector3, collision: bool) -> Node3D:
    var object: Node3D = load(CONVERTED + name + ".glb").instantiate()
    object.scene_file_path = ""
    object.name = name.replace("-", "_")
    object.position = position
    parent.add_child(object)
    if collision:
        _mesh_collision(object)
    return object


func _mesh_collision(node: Node) -> void:
    if node is MeshInstance3D and node.mesh:
        # 以原始表面產生靜態碰撞，避免用整棟包圍盒封住村莊廣場。
        node.create_trimesh_collision()
    for child in node.get_children():
        if child is not StaticBody3D:
            _mesh_collision(child)


func _first_mesh(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node
    for child in node.get_children():
        var mesh := _first_mesh(child)
        if mesh:
            return mesh
    return null


func _build_forest(parent: Node3D) -> void:
    for form in ["fo_s2_birch", "fo_s1_giant_tree"]:
        var template: Node3D = load(CONVERTED + form + ".glb").instantiate()
        var source_mesh := _first_mesh(template)
        var points: Array[Dictionary] = []
        for plant: Dictionary in data.plants:
            if str(plant.source_form).to_lower() == form:
                points.append(plant)
        # 分成 160 m 區塊，讓整片森林仍有正常視錐剔除。
        var groups := {}
        for plant in points:
            var pos: Array = plant.position
            var key := Vector2i(floori(pos[0] / 160), floori(pos[2] / 160))
            if not groups.has(key):
                groups[key] = []
            groups[key].append(plant)
        for key: Vector2i in groups:
            var batch: Array = groups[key]
            var multimesh := MultiMesh.new()
            multimesh.transform_format = MultiMesh.TRANSFORM_3D
            multimesh.mesh = source_mesh.mesh
            multimesh.instance_count = batch.size()
            for index in batch.size():
                var plant: Dictionary = batch[index]
                var pos: Array = plant.position
                var local := Vector3(pos[0], _height(pos[0], pos[2]), pos[2])
                var basis := Basis(Vector3.UP, -float(plant.angle)).scaled(Vector3.ONE * float(plant.source_scale))
                multimesh.set_instance_transform(index, Transform3D(basis, local) * source_mesh.transform)
                # 狀態以原生靜態圓柱碰撞表示樹幹，樹冠不妨礙行走。
                var trunk := StaticBody3D.new()
                var cylinder := CylinderShape3D.new()
                cylinder.radius = (1.7 if form == "fo_s1_giant_tree" else 0.3) * float(plant.source_scale)
                cylinder.height = 3.0
                var shape := CollisionShape3D.new()
                shape.shape = cylinder
                trunk.position = local + Vector3.UP * 1.5
                trunk.add_child(shape)
                parent.add_child(trunk)
            var instance := MultiMeshInstance3D.new()
            instance.name = "%s_%s_%s" % [form, key.x, key.y]
            instance.multimesh = multimesh
            parent.add_child(instance)
        template.free()


func _build_road(parent: Node3D) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.33, 0.26, 0.15)
    material.roughness = 1.0
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var paths: Array = [road_points, [Vector2(-95, -220), Vector2(-10, -260), Vector2(100, -260)],
                      [Vector2(-360, -610), Vector2(-450, -715), Vector2(-560, -740)]]
    for path: Array in paths:
        for i in range(path.size() - 1):
            var start: Vector2 = path[i]
            var end: Vector2 = path[i + 1]
            var tangent := (end - start).normalized()
            var side := Vector2(-tangent.y, tangent.x) * 2.3
            var steps := ceili(start.distance_to(end) / 4.0)
            for j in steps:
                var a := start.lerp(end, float(j) / steps)
                var b := start.lerp(end, float(j + 1) / steps)
                for point in [a - side, b - side, a + side, b - side, b + side, a + side]:
                    st.set_normal(Vector3.UP)
                    st.add_vertex(Vector3(point.x, _height(point.x, point.y) + 0.08, point.y))
    st.set_material(material)
    var mesh := st.commit()
    ResourceSaver.save(mesh, "res://assets/ryzom/meshes/temporary_roads.res")
    var road := MeshInstance3D.new()
    road.name = "ReconstructedRoutes"
    road.mesh = load("res://assets/ryzom/meshes/temporary_roads.res")
    parent.add_child(road)


func _lighting() -> void:
    var group := _group("Environment")
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.16, 0.29, 0.42)
    sky_material.sky_horizon_color = Color(0.62, 0.73, 0.7)
    sky_material.ground_bottom_color = Color(0.2, 0.22, 0.13)
    sky.sky_material = sky_material
    settings.sky = sky
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color(0.68, 0.76, 0.66)
    settings.ambient_light_energy = 0.35
    settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    settings.fog_enabled = true
    settings.fog_light_color = Color(0.63, 0.72, 0.65)
    settings.fog_density = 0.0011
    environment.environment = settings
    group.add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_color = Color(1.0, 0.93, 0.78)
    sun.light_energy = 0.9
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 110
    group.add_child(sun)


func _boundary() -> void:
    for spec in [[Vector3(-704, 12, -285), Vector3(1, 35, 1120)],
                 [Vector3(576, 12, -285), Vector3(1, 35, 1120)],
                 [Vector3(-64, 12, -845), Vector3(1280, 35, 1)],
                 [Vector3(-64, 12, 275), Vector3(1280, 35, 1)]]:
        var body := StaticBody3D.new()
        body.position = spec[0]
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = spec[1]
        shape.shape = box
        body.add_child(shape)
        world.get_node("Collision").add_child(body)


func _label(parent: Node3D, text: String, position: Vector3) -> void:
    var label := Label3D.new()
    label.text = text
    label.font_size = 32
    label.pixel_size = 0.003
    label.modulate = Color(0.95, 0.86, 0.55)
    label.outline_size = 10
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = false
    label.position = position
    parent.add_child(label)


func _hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    world.add_child(hud)
    var panel := PanelContainer.new()
    panel.name = "Panel"
    panel.position = Vector2(18, 18)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.06, 0.055, 0.83)
    style.border_color = Color(0.6, 0.5, 0.27, 0.6)
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 16
    style.content_margin_bottom = 16
    panel.add_theme_stylebox_override("panel", style)
    var info := Label.new()
    info.name = "Info"
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.79))
    panel.add_child(info)
    var map := Control.new()
    map.name = "Minimap"
    map.set_script(load("res://scripts/minimap.gd"))
    map.set("player_path", NodePath("../../Player"))
    map.anchor_left = 1.0
    map.anchor_right = 1.0
    map.position = Vector2(-280, 18)
    map.size = Vector2(250, 220)
    map.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(map)


func _save_inputs() -> void:
    var actions := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A,
                    "move_right": KEY_D, "sprint": KEY_SHIFT, "walk_toggle": KEY_C,
                    "respawn": KEY_R, "melee": KEY_1, "area_skill": KEY_2}
    for action: String in actions:
        var key := InputEventKey.new()
        key.physical_keycode = actions[action]
        var events: Array[InputEvent] = [key]
        if action == "melee":
            var mouse := InputEventMouseButton.new()
            mouse.button_index = MOUSE_BUTTON_LEFT
            events.append(mouse)
        ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
    ProjectSettings.save()

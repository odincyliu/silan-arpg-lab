extends SceneTree

const CONVERTED := "res://assets/ryzom/converted/"
const OFFSET := Vector3(-160, 0, 160)
var world: Node3D
var plant_count := 0


func _initialize() -> void:
    call_deferred("_build")


func _own(node: Node, owner_node: Node) -> void:
    for child in node.get_children():
        child.owner = owner_node
        if child.scene_file_path.is_empty():
            _own(child, owner_node)


func _collisions(node: Node) -> void:
    if node is MeshInstance3D and node.mesh:
        node.create_trimesh_collision()
    for child in node.get_children():
        if child is not StaticBody3D:
            _collisions(child)


func _object(parent: Node3D, file: String, position: Vector3, collide: bool) -> Node3D:
    var object: Node3D = load(CONVERTED + file + ".glb").instantiate()
    object.scene_file_path = ""
    object.position = position
    parent.add_child(object)
    if collide:
        _collisions(object)
    return object


func _height(x: float, z: float) -> float:
    var query := PhysicsRayQueryParameters3D.create(Vector3(x, 100, z), Vector3(x, -30, z), 1)
    var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
    assert(not hit.is_empty(), "原始地形缺少碰撞：" + str(Vector2(x, z)))
    return hit.position.y


func _build() -> void:
    world = Node3D.new()
    world.name = "ShatteredRuins"
    var terrain := _object(world, "silan_ruins_terrain", OFFSET, true)
    terrain.name = "OriginalTerrain"
    terrain.set_meta("source_patch_count", 100)
    terrain.set_meta("source_tile_count", 25600)
    _own(world, world)
    root.add_child(world)
    for i in 3:
        await physics_frame
    # 植物先貼齊真實地形，再加入建築；避免把植物射線貼到屋頂。
    var flora := Node3D.new()
    flora.name = "OriginalFlora"
    world.add_child(flora)
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONVERTED + "region_a.json"))
    var aliases := {"fo_s1_giant_tree": "fo_s1_giant_tree", "fo_s1_arbreagrelot": "fo_s1_arbragrelot",
                   "fo_s3_champignou_a": "fo_s3_champignou_a", "fo_s3_champignou_b": "fo_s3_champignou_b"}
    for plant: Dictionary in data.plants:
        var px: float = float(plant.position[0])
        var pz: float = float(plant.position[2])
        if px < -544 or px > -224 or pz < -845 or pz > -525:
            continue
        var form := str(plant.source_form).to_lower()
        if not aliases.has(form):
            continue
        var position := Vector3(px + 384, 0, pz + 685)
        position.y = _height(position.x, position.z)
        var object := _object(flora, aliases[form], position, false)
        object.rotation.y = -float(plant.angle)
        object.scale = Vector3.ONE * float(plant.source_scale)
        object.set_meta("source_name", plant.source_name)
        object.set_meta("source_form", form)
        plant_count += 1
    flora.set_meta("source_instance_count", plant_count)
    var spawn_height := _height(10, 10)
    root.remove_child(world)
    for plant in flora.get_children():
        _collisions(plant)
    var ruins := _object(world, "zonematerial-foret-ruines_newbieland", OFFSET, true)
    ruins.name = "OriginalRuins"
    var spawn := Marker3D.new()
    spawn.name = "PlayerSpawn"
    spawn.position = Vector3(10, spawn_height + 1.0, 10)
    world.add_child(spawn)
    var player: Node3D = load("res://scenes/player/player.tscn").instantiate()
    player.name = "Player"
    player.position = spawn.position
    world.add_child(player)
    var rig := Node3D.new()
    rig.name = "CameraRig"
    rig.set_script(load("res://scripts/arpg_camera.gd"))
    rig.set("target_path", NodePath("../Player"))
    rig.set("distance", 34.0)
    rig.set("pitch", deg_to_rad(38.0))
    rig.set("yaw", deg_to_rad(-40.0))
    world.add_child(rig)
    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera.fov = 60
    camera.far = 700
    rig.add_child(camera)
    var skills := Node3D.new()
    skills.name = "TemporarySkillHooks"
    skills.set_script(load("res://scripts/skill_hooks.gd"))
    skills.set("player_path", NodePath("../Player"))
    world.add_child(skills)
    _lighting()
    _hud()
    _boundaries()
    _own(world, world)
    world.set_script(load("res://scripts/ruins_world.gd"))
    root.add_child(world)
    for i in 3:
        await process_frame
    await RenderingServer.frame_post_draw
    var packed := PackedScene.new()
    assert(packed.pack(world) == OK)
    assert(ResourceSaver.save(packed, "res://scenes/world/shattered_ruins.tscn") == OK)
    print("RUINS_BUILD_OK original_patches=100 painted_tiles=25600 original_plants=", plant_count)
    world.free()
    quit()


func _lighting() -> void:
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var material := ProceduralSkyMaterial.new()
    material.sky_top_color = Color(0.15, 0.3, 0.42)
    material.sky_horizon_color = Color(0.68, 0.75, 0.69)
    material.ground_bottom_color = Color(0.18, 0.23, 0.16)
    sky.sky_material = material
    settings.sky = sky
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color(0.7, 0.78, 0.69)
    settings.ambient_light_energy = 0.32
    settings.fog_enabled = true
    settings.fog_light_color = Color(0.59, 0.69, 0.61)
    settings.fog_density = 0.00045
    environment.environment = settings
    world.add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-48, -38, 0)
    sun.light_color = Color(1.0, 0.96, 0.84)
    sun.light_energy = 0.9
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 100
    world.add_child(sun)


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
    style.bg_color = Color(0.045, 0.085, 0.065, 0.86)
    style.set_content_margin_all(14)
    panel.add_theme_stylebox_override("panel", style)
    var label := Label.new()
    label.name = "Info"
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(0.94, 0.95, 0.85))
    panel.add_child(label)


func _boundaries() -> void:
    for spec in [[Vector3(-160, 20, 0), Vector3(1, 80, 320)],
                 [Vector3(160, 20, 0), Vector3(1, 80, 320)],
                 [Vector3(0, 20, -160), Vector3(320, 80, 1)],
                 [Vector3(0, 20, 160), Vector3(320, 80, 1)]]:
        var body := StaticBody3D.new()
        body.position = spec[0]
        var collision := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = spec[1]
        collision.shape = box
        body.add_child(collision)
        world.add_child(body)

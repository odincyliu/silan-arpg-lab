extends SceneTree


func _initialize() -> void:
    for path in ["res://assets/animations/UAL1_Standard.glb", "res://assets/animations/UAL2_Standard.glb"]:
        var scene: Node = load(path).instantiate()
        root.add_child(scene)
        print("MODEL ", path)
        _inspect(scene)
        scene.queue_free()
    quit()


func _inspect(node: Node) -> void:
    if node is Skeleton3D:
        print("SKELETON ", node.name, " bones=", node.get_bone_count())
    if node is MeshInstance3D:
        print("MESH ", node.name, " bounds=", node.get_aabb(), " transform=", node.transform)
    if node is AnimationPlayer:
        var anim: Animation = node.get_animation("Idle_Loop") if node.has_animation("Idle_Loop") else node.get_animation(node.get_animation_list()[0])
        print("ANIMPLAYER ", node.name, " root=", node.root_node, " first_track=", anim.track_get_path(0), " LIST=", node.get_animation_list())
    for child in node.get_children():
        _inspect(child)

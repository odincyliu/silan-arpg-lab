extends SceneTree


func _initialize() -> void:
    call_deferred("_debug")


func _debug() -> void:
    var scene: Node3D = load("res://scenes/world/region_a.tscn").instantiate()
    root.add_child(scene)
    for i in 30:
        await process_frame
    var player := scene.get_node("Player")
    var tree: AnimationTree = player.get_node("Visual/AnimationTree")
    var ap: AnimationPlayer = player.get_node("Visual/AnimationPlayer")
    var sk: Skeleton3D = player.get_node("Visual/Armature/Skeleton3D")
    print("TREE active=", tree.active, " root=", tree.root_node, " anim_player=", tree.anim_player)
    var blend: AnimationNodeBlendTree = tree.tree_root
    var space: AnimationNodeBlendSpace2D = blend.get_node("Locomotion")
    print("SPACE triangles=", space.get_triangle_count(), " auto=", space.auto_triangles)
    print("POSE ", sk.get_bone_pose_rotation(sk.find_bone("calf_l")))
    tree.active = false
    ap.play("Melee_Hook")
    ap.advance(0.3)
    print("MANUAL_POSE ", sk.get_bone_pose_rotation(sk.find_bone("calf_l")))
    print("ANIM ", ap.get_animation_list())
    for name in ["fo_s2_birch", "fo_s1_giant_tree", "zonematerial-foret-start_village_newbieland"]:
        var object: Node = load("res://assets/ryzom/converted/" + name + ".glb").instantiate()
        root.add_child(object)
        print("ASSET ", name, " ", object.transform)
        _print_mesh(object)
        object.queue_free()
    for child in scene.get_node("Forest").get_children():
        if child is MultiMeshInstance3D:
            print("FOREST ", child.multimesh.mesh.get_aabb(), " ", child.multimesh.get_instance_transform(0))
            break
    print("CAM ", scene.get_node("CameraRig/Camera3D").global_basis)
    scene.queue_free()
    for i in 10:
        await process_frame
    quit()


func _print_mesh(node: Node) -> void:
    if node is MeshInstance3D:
        print("MESH ", node.name, " box=", node.mesh.get_aabb(), " global=", node.global_transform)
    for child in node.get_children():
        _print_mesh(child)

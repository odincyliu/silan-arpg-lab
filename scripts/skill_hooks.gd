extends Node3D

@export var player_path: NodePath
@onready var player: CharacterBody3D = get_node(player_path)
var cooldown: float = 0.0


func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)


func _unhandled_input(event: InputEvent) -> void:
    if cooldown > 0.0:
        return
    if event.is_action_pressed("melee"):
        cooldown = 0.7
        var tree: AnimationTree = player.get_node("Visual/AnimationTree")
        tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
        _marker(1.6, Color(1.0, 0.72, 0.23, 0.7), 0.4)
    elif event.is_action_pressed("area_skill"):
        cooldown = 0.7
        _marker(4.0, Color(0.1, 0.8, 1.0, 0.6), 1.2)


func _marker(radius: float, color: Color, duration: float) -> void:
    var ring := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius - 0.08
    mesh.outer_radius = radius
    mesh.rings = 48
    mesh.ring_segments = 8
    ring.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = material
    add_child(ring)
    ring.global_position = player.global_position + Vector3.UP * 0.12
    var tween := create_tween()
    tween.tween_property(material, "albedo_color:a", 0.0, duration)
    tween.tween_callback(ring.queue_free)

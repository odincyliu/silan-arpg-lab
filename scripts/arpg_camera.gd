extends Node3D

@export var target_path: NodePath
@export var distance: float = 20.0
@export var follow_speed: float = 8.0
var desired_distance: float = 20.0
var yaw: float = 0.0
var pitch: float = deg_to_rad(45.0)
@onready var target: Node3D = get_node(target_path)
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
    desired_distance = distance
    global_position = target.global_position + Vector3.UP


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            desired_distance = clampf(desired_distance - 2.0, 9.0, 45.0)
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            desired_distance = clampf(desired_distance + 2.0, 9.0, 45.0)
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        yaw -= event.relative.x * 0.005
        pitch = clampf(pitch + event.relative.y * 0.003, deg_to_rad(35.0), deg_to_rad(55.0))


func _process(delta: float) -> void:
    global_position = global_position.lerp(target.global_position + Vector3.UP * 1.2,
                                          1.0 - exp(-follow_speed * delta))
    distance = lerpf(distance, desired_distance, 1.0 - exp(-10.0 * delta))
    var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
    camera.global_position = global_position + offset
    # 地形與建築遮挡只縮短鏡頭，仍維持 ARPG 仰角。
    var query := PhysicsRayQueryParameters3D.create(global_position, camera.global_position, 1)
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        camera.global_position = hit.position + hit.normal * 0.6
    camera.look_at(global_position, Vector3.UP)

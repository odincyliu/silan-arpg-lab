extends CharacterBody3D

@export var walk_speed: float = 2.5
@export var run_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 12.0
@export var deceleration: float = 16.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 18.0

var movement_x: float = 0.0
var movement_y: float = 0.0
var speed: float = 0.0
var walking: bool = false
var blend_value: Vector2 = Vector2.ZERO
var spawn_position: Vector3
@onready var visual: Node3D = $Visual
@onready var animation_tree: AnimationTree = $Visual/AnimationTree


func _ready() -> void:
    spawn_position = global_position
    floor_snap_length = 0.6
    floor_max_angle = deg_to_rad(48.0)
    floor_stop_on_slope = true
    floor_constant_speed = true


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("walk_toggle"):
        walking = not walking
    if event.is_action_pressed("respawn"):
        global_position = spawn_position
        velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var camera := get_viewport().get_camera_3d()
    var direction := Vector3.ZERO
    if camera:
        var forward := -camera.global_basis.z
        forward.y = 0.0
        var right := camera.global_basis.x
        right.y = 0.0
        direction = (right.normalized() * input_vector.x - forward.normalized() * input_vector.y).normalized()
    var target_speed := run_speed
    if walking:
        target_speed = walk_speed
    if Input.is_action_pressed("sprint"):
        target_speed = sprint_speed
    var rate := acceleration if direction.length_squared() > 0.01 else deceleration
    velocity.x = move_toward(velocity.x, direction.x * target_speed, rate * delta)
    velocity.z = move_toward(velocity.z, direction.z * target_speed, rate * delta)
    if is_on_floor():
        velocity.y = -0.5
    else:
        velocity.y -= gravity * delta
    move_and_slide()
    speed = Vector2(velocity.x, velocity.z).length()
    if direction.length_squared() > 0.01:
        # glTF 人偶面向 +Z；移動方向由鏡頭平面決定。
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z),
                                      1.0 - exp(-rotation_speed * delta))
    movement_x = input_vector.x
    movement_y = -input_vector.y
    # 面向移動方向，因此使用免費包的前進循環；不偽裝成不存在的側移動畫。
    var locomotion_amount: float = clampf(speed / run_speed, 0.0, 1.0)
    if speed > run_speed:
        locomotion_amount = 1.0 + clampf((speed - run_speed) / (sprint_speed - run_speed), 0.0, 1.0)
    blend_value = blend_value.lerp(Vector2(0.0, locomotion_amount), 1.0 - exp(-8.0 * delta))
    animation_tree.set("parameters/Locomotion/blend_position", blend_value)
    if global_position.y < -40.0:
        global_position = spawn_position
        velocity = Vector3.ZERO

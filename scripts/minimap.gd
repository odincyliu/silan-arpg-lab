extends Control

@export var player_path: NodePath
@onready var player: Node3D = get_node(player_path)
const BOUNDS := Rect2(-704.0, -845.0, 1280.0, 1120.0)


func _draw() -> void:
    draw_style_box(get_theme_stylebox("panel", "Panel"), Rect2(Vector2.ZERO, size))
    var points := [Vector2.ZERO, Vector2(-330, -560), Vector2(-505, -730), Vector2(110, -240)]
    var colors := [Color(1.0, 0.8, 0.3), Color(0.9, 0.58, 0.35), Color(0.3, 0.85, 0.65), Color(0.6, 0.9, 0.3)]
    for i in points.size():
        draw_circle(_map(points[i]), 4.0, colors[i])
    var pos := Vector2(player.global_position.x, player.global_position.z)
    draw_circle(_map(pos), 4.0, Color.WHITE)


func _map(point: Vector2) -> Vector2:
    return Vector2(12, 12) + (point - BOUNDS.position) / BOUNDS.size * (size - Vector2(24, 24))

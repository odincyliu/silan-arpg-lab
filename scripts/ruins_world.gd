extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var info: Label = $HUD/Panel/Info
@onready var rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
var overview := false


func _ready() -> void:
    _toggle_view()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_V:
        _toggle_view()


func _toggle_view() -> void:
    overview = not overview
    rig.set_process(not overview)
    player.set_physics_process(not overview)
    if overview:
        camera.global_position = Vector3(-160, 115, 190)
        camera.look_at(Vector3(15, 6, -20), Vector3.UP)


func _process(_delta: float) -> void:
    var pos := player.global_position
    info.text = "SHATTERED RUINS / SILAN\nOriginal Ryzom landmark\n\n320 x 320 m ruined settlement\nOriginal terrain and ground painting\nOriginal ruins and flora positions\n\nV Overview / Explore on foot\nWASD Move  C Walk  Shift Sprint\nRMB Rotate  Wheel Zoom\n1 Melee  2 Area  R Respawn\n\n%.0f, %.0f m  /  %.1f m/s" % [pos.x, pos.z, player.speed]

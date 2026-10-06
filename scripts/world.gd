extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var info: Label = $HUD/Panel/Info
@onready var minimap: Control = $HUD/Minimap


func _ready() -> void:
    # 輸入也保存於 project.godot；此處只提供初次產生專案時的兼容保護。
    var actions := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A,
                    "move_right": KEY_D, "sprint": KEY_SHIFT, "walk_toggle": KEY_C,
                    "respawn": KEY_R, "melee": KEY_1, "area_skill": KEY_2}
    for action: String in actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var key := InputEventKey.new()
            key.physical_keycode = actions[action]
            InputMap.action_add_event(action, key)
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    if not InputMap.action_has_event("melee", mouse):
        InputMap.action_add_event("melee", mouse)


func _process(_delta: float) -> void:
    var pos := player.global_position
    if OS.has_feature("web"):
        # Web 沒有 Windows 系統中文字型；操作中文說明由 HTML 頁面提供。
        info.text = "SILAN ARPG LAB\nQuaternius Mannequin x Ryzom\n\nWASD Move   C Walk / Run\nShift Sprint   Wheel Zoom\nRMB drag Rotate camera\nLMB / 1 Melee   2 Area marker\nR Return to village\n\nPosition %.0f, %.0f m   %.1f m/s\n\nOriginal village, ruins and trees\nSilan layout and vegetation\nTemporary terrain and roads" % [pos.x, pos.z, player.speed]
        minimap.queue_redraw()
        return
    info.text = "REGION A  /  SILAN\nQuaternius Mannequin × Ryzom\n\nWASD  移動   C  走路／跑步\nShift  衝刺   滾輪  縮放\n右鍵拖曳  旋轉鏡頭\n左鍵／1  揮擊   2  範圍標記\nR  回到村莊\n\n位置  %.0f, %.0f m    %.1f m/s\n\n真實村莊／遺跡／樹木網格\nSilan 布局與植被座標\n地面高度／道路為暫時重建" % [pos.x, pos.z, player.speed]
    minimap.queue_redraw()

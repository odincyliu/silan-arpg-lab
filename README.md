# Silan ARPG Lab

**[瀏覽器試玩](https://odincyliu.github.io/silan-arpg-lab/)** · [素材與授權](THIRD_PARTY_NOTICES.md)

非官方 Godot 4 Silan 探索原型。以 Ryzom 開放美術實驗 ARPG 移動、相機與動畫；地形高度及道路仍為暫時重建。

獨立 Godot 4 專案，使用 Quaternius 動畫庫附帶的黃色 Mannequin。角色方案依使用者最新指示，取代原先的 Universal Base Characters。

## 直接試玩

Web：開啟上方網址，按「開始探索」。需支援 WebGL 2 的桌面瀏覽器；首次會下載 WASM 與遊戲資源。Web HUD 使用英文，頁面提供中文操作說明；尚未加入手機觸控操作。

1. 用 `D:\funny\Godot_latest_version\Godot.exe` 匯入本資料夾的 `project.godot`。
2. 按 **F5**。也可以開啟 `scenes/world/region_a.tscn` 後按 **F6**。
3. 或雙擊 `Play.cmd`，直接啟動遊戲。

已使用 Godot **4.7.1 stable** 驗證。執行時不需要 Blender、Python、Ryzom Client、NeL、伺服器或網路。

## Web 建置與 GitHub Pages

`export_presets.cfg` 使用 Compatibility／WebGL 2、單執行緒，無須自訂跨來源隔離 HTTP headers。安裝 Godot 4.7.1 官方 export templates 後：

```powershell
New-Item -ItemType Directory -Force build/web
& 'D:\funny\Godot_latest_version\Godot_console.exe' --headless --editor --import --quit --path .
& 'D:\funny\Godot_latest_version\Godot_console.exe' --headless --path . --export-release Web build/web/index.html
python tools/prepare_web.py
python -m http.server 8000 --directory build/web
```

開啟 `http://localhost:8000`。請透過 HTTP 伺服器試玩，直接開啟 HTML 檔案無法載入 WASM。

GitHub Pages 設為 **GitHub Actions**。每次 push 至 `main`，`.github/workflows/pages.yml` 都會匯入、執行行為驗證、匯出 release、補齊授權頁並部署。版本固定 4.7.1；編輯器及 Web 模板皆下載自 Godot 官方 release，首次下載較久，之後使用 cache。`build/` 與 `.godot/` 不提交 Git，網站成果保存於 Pages artifact。

## 授權

原創控制程式、網頁殼及發布流程採 [範圍限定的 MIT](LICENSE)。Ryzom 美術及衍生布局採 **FAL 1.3**，Quaternius Mannequin／動畫採 **CC0**，離線 MAX 轉換工具採 **GPL**。詳細來源、修改與完整授權文字見 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)。不能把整份專案的美術標為 MIT；本專案不代表 Ryzom 官方。

| 操作 | 效果 |
|---|---|
| WASD | 依鏡頭方向移動，預設跑步 |
| C | 切換走路／跑步 |
| Shift | 衝刺 |
| 滑鼠滾輪 | 縮放 |
| 按住右鍵拖曳 | 旋轉鏡頭；俯角限制 35–55° |
| 左鍵／1 | UAL2 Melee_Hook 揮擊與 1.6 m 標記 |
| 2 | 4 m 範圍標記 |
| R | 回到村莊 |

## 這一版的範圍

- 約 **1,280 × 1,120 m**，56 個靜態地面區塊，村莊到遺跡約 650–800 m；以 2.5 m/s 走路來回約 9–11 分鐘。
- 真實 Silan 起始村莊、Shattered Ruins 網格、Ryzom birch／giant tree、Chlorogoo 瞭望塔與 Karavan sensor。
- 695 棵樹沿用 Ryzom 原始植被座標與比例，以 MultiMesh 分區呈現。
- 村莊與遺跡依原始 Ligo 格網定位；額外兩個大型地標是原型的手動擺放。
- **地形高度及道路是暫時重建，尚未轉換 NeL 原始 Bezier Patch 地形。** 不宣稱是完整復刻的 Silan。
- 玩家場景僅包含 Idle／Walk／Jog／Sprint／Melee_Hook 五個動畫與 AnimationTree。

詳細狀態、來源、比例與限制見 [CURRENT_STATE](docs/CURRENT_STATE.md)、[ASSET_SOURCES](docs/ASSET_SOURCES.md)、[SCALE_REFERENCE](docs/SCALE_REFERENCE.md)、[CONVERSION_NOTES](docs/CONVERSION_NOTES.md)。

## 調整與接回正式專案

- 角色：`scenes/player/player.tscn`，控制器：`scripts/player.gd`。
- 在 Player Inspector 調整 walk_speed、run_speed、sprint_speed、acceleration、deceleration、rotation_speed、gravity。
- AnimationTree：`Player/Visual/AnimationTree`，`Locomotion` 為 BlendSpace2D，`Attack` 為 OneShot。
- 相機：`scripts/arpg_camera.gd`，初始距離 20 m、45°俯角。
- 技能完全隔離在 `scripts/skill_hooks.gd` 與 `TemporarySkillHooks` 節點，可直接刪除。
- 中性布局：`assets/ryzom/converted/region_a.json`。原始資產與轉換結果分開保存。
- 沒有實作帳號、戰鬥後端、物品、任務、連線、存檔或串流。

## 搬到另一台電腦

`godot_ryzom_poc_playable.zip` 是可匯入的輕量專案，包含執行資源、原始選用網格、授權、文件及轉換工具；不包含 2 GB 官方來源壓縮包和無關的已解壓資產。解壓後匯入 `project.godot` 即可。

完整本機來源包保留在 `assets/ryzom/source/ryzomcore_graphics-rev5.7z`。只試玩不需搬移它。完整來源檔可用 ASSET_SOURCES 中的官方網址重新下載。

## 重建與驗證

可選的離線需求：Python 3.10+、Blender 5.2.1、7-Zip。Python 輔助工具若需要圖片檢視，執行 `python -m pip install -r requirements.txt`。

```powershell
python tools/ryzom_converter/convert_world_data.py
& 'D:\blender\blender-5.2.1-windows-x64\blender.exe' --background --factory-startup --python-exit-code 1 --python tools/ryzom_converter/convert_assets.py
& 'D:\funny\Godot_latest_version\Godot_console.exe' --headless --editor --import --quit --path .
& 'D:\funny\Godot_latest_version\Godot_console.exe' --path . --script res://tools/build_prototype.gd
& 'D:\funny\Godot_latest_version\Godot_console.exe' --headless --path . --script res://tools/check_prototype.gd
```

**場景烘焙請使用有畫面的 Godot。** RendererDummy 不會保存 MultiMesh 變換緩衝區；使用 headless 烘焙會使森林集中到原點。遊戲與測試可正常 headless 執行。

若在受限沙盒中執行 Godot，明確加入 `--log-file <本專案絕對路徑>/docs/engine.log`；引擎啟動階段建立 AppData 日誌可能被阻擋。一般 Windows 使用者無須此設定。

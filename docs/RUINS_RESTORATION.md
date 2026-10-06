# Silan 原始遺跡區塊還原

預設場景：`scenes/world/shattered_ruins.tscn`。首次顯示俯瞰，V 進入／返回角色探索。

## 直接取自原始資料

來源為官方 graphics rev5 包中的 `landscape/ligo/jungle/max/zonematerial-foret-ruines_newbieland.max`。

1. 使用已保存的 MAX 讀取器解析 Scene reference graph。
2. 找到唯一非凍結的 `QuadPatch01`，確認最上層修改器是 NeL Painter。
3. 讀取該修改器本機資料中的最終 PatchMesh `0x1140` 與 RPatchMesh `0x4001`。此快取沒有 vertex mapper，121 個來源頂點也沒有跨曲面綁定；轉換器遇到這些條件改變會直接失敗，不誤用下層的平面 RPO。
4. 以來源角點、8 個切線控制點及 4 個內部控制點計算 100 個三次 Bezier 曲面，套用原始節點變換。每片取樣 32 × 32 格，總共 204,800 個三角面；與表面一致的靜態碰撞由 Godot 產生。
5. 使用官方 `jungle.bank` 的 2,324 個 CTile 索引讀取 25,600 格地表。依原引擎 UV 旋轉與 256 象限規則合成各地表層、alpha 轉場及來源頂點色彩，使用圖集邊緣延伸避免相鄰 patch 滲色。
6. 同一份 MAX 中的完整遺跡網格群採相同變換；補齊 `ge_mission_ruine_burn.png`，避免原型中的缺失材質。
7. 原始 flora primitives 裁切出此 320 m 區塊的 14 個標記。11 個靜態植物均使用對應來源模型；3 個 FX 標記未轉換。表單 `fo_s1_arbreagrelot` 對應來源模型檔 `fo_s1_arbragrelot.max`。

原始 XY 平面映射至 Godot X/−Z，Z 高度映射至 Godot Y，1 單位 = 1 公尺。整組區塊平移 `(-160, 0, 160)` 置中，未改動區塊內的相對位置。來源地表與植物原始檔、bank、MAX 均隨 repo 保存；完整來源包網址仍見 ASSET_SOURCES。

轉換清單：[ruins_terrain_manifest.json](ruins_terrain_manifest.json)、[ruins_props_manifest.json](ruins_props_manifest.json)。

參考官方格式實作：

- [NeL PatchMesh / RPatchMesh 讀取格式](https://github.com/ryzom/ryzomcore/blob/core4/nel/tools/3d/pipeline_max/nelpatch/rpo_data.cpp)
- [最終 Painter 快取評估條件](https://github.com/ryzom/ryzomcore/blob/core4/nel/tools/3d/pipeline_max_export_common/patch_eval.h)
- [Bezier 曲面 S/T 控制點排列](https://github.com/ryzom/ryzomcore/blob/core4/nel/src/3d/bezier_patch.cpp)
- [地表旋轉與 256 象限](https://github.com/ryzom/ryzomcore/blob/core4/nel/src/3d/tessellation.cpp)

## 明確的呈現限制

此版還原的是原始遺跡模板完整靜態區塊。相鄰 Silan 地形區塊尚未搬入，俯瞰可看到區塊邊界。不是把目前線上 Ryzom 的完整場景檔直接載入 Godot，也不是逐像素復刻。

- 來源區塊來自官方 2020 年打包的可編輯檔，與目前線上遊戲可能有年代差異。
- 地表圖集取樣 16 px/m；原引擎近距離微位移、Lumel 光照、動態草、粒子與天空未移植。
- 使用 Godot 標準材質、天空、霧及動態陰影，與 NeL 的呈現會不同。
- 沒有 NPC、動物、原始遊戲角色、任務與多人系統。

原型黃色 Mannequin、技能圓環與操作 HUD 是本專案功能，不屬於原版遺跡。

## 重建及驗證

```powershell
& 'D:\blender\blender-5.2.1-windows-x64\blender.exe' --background --factory-startup --python-exit-code 1 --python tools/ryzom_converter/convert_ruins_terrain.py
& 'D:\blender\blender-5.2.1-windows-x64\blender.exe' --background --factory-startup --python-exit-code 1 --python tools/ryzom_converter/convert_ruins_props.py
& 'D:\funny\Godot_latest_version\Godot_console.exe' --headless --editor --import --quit --path .
& 'D:\funny\Godot_latest_version\Godot_console.exe' --path . --script res://tools/build_ruins.gd
& 'D:\funny\Godot_latest_version\Godot_console.exe' --headless --path . --script res://tools/check_ruins.gd
```

`check_ruins.gd` 驗證來源尺度、高度起伏、內容數量、V 視角切換、出生點貼地、實際移動、碰撞及揮擊。`capture_ruins.gd` 使用實際渲染器保存全景、角色探索與近景畫面。GitHub Actions 同時執行舊區域與遺跡行為驗證。

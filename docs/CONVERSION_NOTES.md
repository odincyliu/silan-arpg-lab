# 轉換決策與可追溯性

## A：直接轉換的 Ryzom 內容

- `zonematerial-foret-start_village_newbieland.max` → GLB：真正 Silan 起始村莊的一整組建築與外部碰撞殼。
- `zonematerial-foret-ruines_newbieland.max` → GLB：Shattered Ruins 的原始遺跡群。
- `fo_s1_giant_tree.max`／`fo_s2_birch.max` → GLB：實際 Ryzom 森林模型及來源貼圖。
- Chlorogoo tent／watchtower、goo flora 1–4、Karavan sensor：原始 3DS 幾何＋同名 PNG → GLB。Region A 目前使用 watchtower 與 sensor，其他已轉但未擺入場景。
- 原始 NeL MAX 材質使用自訂外掛；現成 MAX 匯入器會漏掉材質。本專案遍歷各材質參數與貼圖參照，將第一張原始色彩圖接到 Principled BSDF，再輸出 Godot StandardMaterial3D。季節貼圖選用來源的第一個可找到版本。
- 一些舊 MAX 使用 `tower2.tga` 等舊名，但官方包實際檔名是 `g_tower2.png`。記錄並套用 g_ 前綴別名；`tr_centretronc` 對應相同用途的 `g_centretronc`。
- `.colext`／`_col` 原始碰撞殼以 `-colonly` 名稱匯入為碰撞，不顯示重疊表面。其他建築表面使用 Godot 靜態三角面碰撞。

完整原始檔路徑、尺寸、面數見 `mesh_conversion_manifest.json`，材質解析見 `blender_conversion.log`。所謂 zonematerial MAX 的成功轉換，**只包含村莊／遺跡網格，並不包含其中的 NeL terrain Patch**。

## B：由 Ryzom 設計資料重建

- 選擇 newbieland／Silan 的起始村莊到 Shattered Ruins 範圍；「Region A」只是本專案名。
- `newbieland.land` 的格網尺寸、位置與模板名稱 → `region_a.json`。裁切 grid X 60–67、Y -75–-69，56 格。
- 起始村莊格位 `(64,-74)`；GLB 保留自己的區塊內變換，外部位移為 `(-64,0,115)`。
- 遺跡為 `(61,-70)` 開始的多格模板；位移為 `(-544,0,-525)`。
- `flora_newbieland.primitive` 中裁切出 2,760 點；447 個 birch、248 個 giant tree 使用相同的來源模型、原始 XY、角度和比例。其餘未轉換的植物／粒子點沒有隨意換成樹木。
- 树木點的 Z 全是 0，代表需貼齊地形，不代表可當作真實高度。這版把樹木放在暫時地面上，樹幹使用簡單原生圓柱碰撞。
- 以 160 m 區塊建立 MultiMesh，靜態載入，不做串流。

## C：明確的暫時近似

- **地面高度**：原始 NeL Bezier Patch 尚未轉換。本版離線烘焙低幅緩坡，村莊與遺跡附近整平，套用真實 Ryzom 地面貼圖，並建立一致的地面碰撞。這是尺寸與步行測試地面，不能當成原版 Silan 的山谷、崖壁或水域。
- **道路**：手動畫出廣場 → 樹林 → 遺跡與两條支路。不是原始道路資料，不宣稱原版路線。道路為無厚度可視標記，地面提供碰撞。
- **額外地標位置**：watchtower 與 sensor 是真正 Ryzom 模型，但位置由原型手動選擇，並非原版 Silan 擺放。
- **照明**：Godot ProceduralSky＋DirectionalLight；未重現 Ryzom 天空、霧與日夜週期。
- **技能**：UAL2 Melee_Hook＋圓環、範圍圓環；無傷害與戰鬥系統。
- 區域邊緣使用不可見阻擋牆；原版區域邊界地形尚未轉換。

## 管線

```
官方 graphics rev5 / 官方 leveldesign develop
→ 取用 MAX、3DS、PNG、LAND、PRIMITIVES
→ Blender MAX 匯入 + 小型 3DS 幾何解析 + 材質適配
→ GLB / 原始貼圖 / JSON
→ Godot 離線場景烘焙
→ region_a.tscn + player.tscn
```

不編譯／執行 Ryzom 引擎，沒有 C++ 類別移植到 GDScript。

## Godot 特別事項

- 預設匯入會移除動畫名稱的 `_Loop` 後綴。使用 Godot 中的 `Idle`、`Walk`、`Jog_Fwd`、`Sprint`，並明確設為循環。
- 免費 Standard 只有前進走／跑／衝刺，沒有普通 locomotion 的八方向側移全集。角色面向移動方向，不用前進動畫假裝側移。
- AnimationTree 使用同步的 BlendSpace2D、平滑 blend_position，以及 UAL2 OneShot；不每幀呼叫 play。
- MultiMesh 變換要用真實渲染器烘焙後保存，RendererDummy 在此版本不會提供可序列化的變換緩衝區。
- 保存時保留獨立 player 場景的內部 ownership，避免覆寫外部場景子節點導致 Godot 退出時洩漏。環境 GLB 轉成完整烘焙節點後保存。

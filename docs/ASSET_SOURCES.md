# 資產來源與授權

下載／轉換日期：2026-10-06。轉換者：本原型專案。來源與修改不得被誤認為本專案原創美術。

| 資產 | 原作者／來源 | 授權 | 使用狀態 |
|---|---|---|---|
| Universal Base Characters Standard | [Quaternius](https://quaternius.com/packs/universalbasecharacters.html) | CC0 1.0 | 已下載免費 Superhero Male 原始檔供參考；依使用者指示，執行版本改用黃色 Mannequin |
| Universal Animation Library Standard | [Quaternius](https://quaternius.com/packs/universalanimationlibrary.html) | CC0 1.0 | 黃色 Mannequin、Idle、Walk、Jog、Sprint；非 Root Motion |
| Universal Animation Library 2 Standard | [Quaternius](https://quaternius.com/packs/universalanimationlibrary2.html) | CC0 1.0 | Melee_Hook 單次揮擊；非 Root Motion |
| Ryzom graphics | Nevrax／Winch Gate／Ryzom contributors：[官方倉庫](https://github.com/ryzom/ryzomcore_graphics) | 官方提供 CC BY-SA 3.0／FAL 1.3；本專案 Ryzom 衍生資產採 FAL 1.3，完整文字隨專案保存 | 選用村莊、遺跡、樹木、3DS 物件、原始貼圖、Ligo 格網及植被資料 |
| Ryzom level-design | [官方倉庫](https://github.com/ryzom/ryzomcore_leveldesign) | CC BY-SA 3.0／FAL 1.3 | newbieland 的 urban、region primitives 與 continent 參考 |

官方 graphics 打包資產：[ryzomcore_graphics-rev5.7z](https://cdn.ryzom.dev/pub/assets/ryzomcore_graphics-rev5.7z)。使用官方打包版本避免 Git LFS 23 GB 倉庫及歷史下載。此包是 2020 年打包版本；leveldesign 來源為目前 develop 分支，兩者存在年代差異。

## Quaternius 取得方式

官方 itch.io 頁面與免費下載端在本機回傳 403，瀏覽器也有憑證鏈問題。沒有購買或使用付費 Pro／Source 版本。

使用 [NafisRayan/Animate-Rigged-Humanoid-No-Blender](https://github.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender) 公開鏡像中保留的 **Standard 原始檔**。原作者及 CC0 授權檔均保留；每個實際下載 URL 與 SHA-256 見 `quaternius_download_manifest.json`。不是使用該鏡像的已合成測試角色。

- `assets/animations/UAL1_Standard.glb`／`UAL2_Standard.glb` 是鏡像原始免費 GLB。
- `UAL1_LICENSE.txt`／`UAL2_LICENSE.txt` 保留原作者授權文字。
- `scenes/player/player.tscn` 是本專案在 Godot 選出必要動畫、加入 AnimationTree 後的結果。
- Superhero 男性外部 glTF 的貼圖 URI 曾改成本專案相對路徑，但這個角色未使用於遊戲。

## 離線工具

- [nrgsille76/io_scene_max](https://github.com/nrgsille76/io_scene_max)，Blender 官方 Extensions 所列 MAX 匯入器。版本 commit `37db107126f956f7219152671443080360565691`。上游程式標頭與 LICENSE 為 GPL-2.0-or-later／GPL v2，套件 manifest 為 GPL-3.0-or-later；原始聲明完整保留於 `tools/ryzom_converter/vendor/io_scene_max-main`，本專案依 GPL v3 或更新版整合使用。
- 本專案 `convert_assets.py` 的 MAX 材質適配部分依 GPL-3.0-or-later 提供，完整文字見同目錄 `COPYING`。工具只是離線轉換用途。
- [NeoSpark314/blenderNel3dImport](https://github.com/NeoSpark314/blenderNel3dImport)，Holger Dammertz，GPL v3。已檢查但未使用於最終轉換；程式及 COPYING 保留，沒有成為 Godot 執行依賴。
- Blender 僅用於離線轉 GLB；Godot 執行時無任何 Ryzom C++／NeL 動態函式庫。

Ryzom 衍生 GLB、貼圖及布局資料須保留來源、修改說明及相應授權，不應將 Ryzom 美術改標成 CC0。本專案把 Quaternius 與 Ryzom 放在不同資產目錄。

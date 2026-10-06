# 素材與第三方授權

Silan ARPG Lab 是非官方探索原型，與 Ryzom、Nevrax、Winch Gate 或 Quaternius 無官方合作或背書關係。Ryzom 名稱只用於說明素材來源。

## Ryzom 美術及布局：Free Art License 1.3

原作者：Nevrax、Winch Gate 及 Ryzom contributors。原始資產提供 FAL 1.3／CC BY-SA 3.0 雙授權，本專案選用 **FAL 1.3**，不將這些資產改標為 MIT 或 CC0。

- 官方來源：[graphics](https://github.com/ryzom/ryzomcore_graphics)、[leveldesign](https://github.com/ryzom/ryzomcore_leveldesign)。
- 官方原始壓縮包：[ryzomcore_graphics-rev5.7z](https://cdn.ryzom.dev/pub/assets/ryzomcore_graphics-rev5.7z)。
- 授權文字：[Ryzom_FAL_1.3.txt](docs/licenses/Ryzom_FAL_1.3.txt)；保留上游附帶的完整雙授權文字。
- 適用範圍：`assets/ryzom/`、`scenes/world/region_a.tscn` 與其中嵌入的 Ryzom 網格／貼圖，以及使用這些素材的遊戲畫面、預覽圖片。場景中獨立的原創控制邏輯仍按根目錄 LICENSE 使用。
- 修改者：odincyliu 的 Silan ARPG Lab 專案，2026-10-06。修改包括 MAX／3DS 至 GLB 轉換、NeL 材質映射、貼圖打包、原始 Ligo 格網及植被座標轉為 Godot 資料、場景烘焙；地面高度及道路為原型的暫時重建。詳細見 [CONVERSION_NOTES](docs/CONVERSION_NOTES.md) 與 [ASSET_SOURCES](docs/ASSET_SOURCES.md)。
- 選用原始檔與中間成果隨 repo 保存；未包含完整 2 GB 原始包，可由上述官方網址取得。Ryzom 衍生資產的再發布及修改須保留作者、來源、修改資訊與 FAL 1.3。

## Quaternius：CC0 1.0

黃色 Mannequin、Idle／Walk／Jog／Sprint／Melee_Hook 動畫來自 Quaternius 免費 Standard Universal Animation Library 1／2。不是 Superhero Male。

- [UAL1 官方頁](https://quaternius.com/packs/universalanimationlibrary.html)、[UAL2 官方頁](https://quaternius.com/packs/universalanimationlibrary2.html)。
- 原始授權：`assets/animations/UAL1_LICENSE.txt`、`UAL2_LICENSE.txt`；角色參考授權保存於 `assets/character/`。
- 下載鏡像及 SHA-256 記錄：[quaternius_download_manifest.json](docs/quaternius_download_manifest.json)。
- 修改：選取五個動畫、移除不需要的動畫、加入 AnimationTree 與角色控制器。角色美術與動畫保留 CC0；原創控制程式適用 MIT。

## Godot Engine：MIT 與其第三方函式庫授權

Web 版使用官方 Godot 4.7.1 stable 匯出模板。[Godot](https://godotengine.org/) 原作者 Juan Linietsky、Ariel Manzur 及 Godot Engine contributors。

保留 [Godot MIT License](docs/licenses/Godot_LICENSE.txt) 與 [第三方 COPYRIGHT](docs/licenses/Godot_COPYRIGHT.txt)。Web 部署會一起提供這些文字。

## 離線轉換工具：GPL，不是遊戲執行依賴

- `tools/ryzom_converter/vendor/io_scene_max-main`：[nrgsille76/io_scene_max](https://github.com/nrgsille76/io_scene_max)，commit `37db107126f956f7219152671443080360565691`。上游 `import_max.py` 標示 GPL-2.0-or-later、LICENSE 是 GPL v2，而 `blender_manifest.toml` 宣告 GPL-3.0-or-later。原檔完整保留，未自行改寫上游聲明；本專案使用 GPL v3 或更新版進行這組工具的整合。
- `tools/ryzom_converter/convert_assets.py` 是 MAX 材質適配與轉換包裝，依 **GPL-3.0-or-later** 提供。完整文字見 `tools/ryzom_converter/COPYING`。
- `tools/ryzom_converter/import_nel3d.py`：[NeoSpark314/blenderNel3dImport](https://github.com/NeoSpark314/blenderNel3dImport)，Holger Dammertz，GPL v3；保存供研究，未用於最終轉換。
- Blender、Python 與上述工具不包含於 Web 遊戲。使用 GPL 工具轉出的美術不因使用工具而自動改為 GPL；這裡的 Ryzom 衍生美術仍採 FAL 1.3。

根目錄 LICENSE 的 MIT 授權僅涵蓋列明的原創程式範圍，並不覆蓋上述素材及工具。

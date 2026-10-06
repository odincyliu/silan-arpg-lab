# 目前狀態

更新：2026-10-06。版本：**可玩的第一版 Region A**，不是完整地形轉換或逐像素復刻。

## 已可使用

- F5／F6 啟動 `region_a.tscn`，全程本機單人執行。
- Quaternius 黃色 Mannequin，Idle／Walk／Jog／Sprint、平滑停步混合；UAL2 Melee_Hook 揮擊。
- CharacterBody3D，WASD、走／跑切換、衝刺、緩坡貼地、摔落恢復與手動重生。
- 45° ARPG 相機、35–55°俯角限制、縮放、右鍵旋轉與鏡頭阻擋檢查。
- 1,280 × 1,120 m、56 靜態地面區塊，真正 Silan 起始村莊／遺跡與兩種真實 Ryzom 樹木。
- 原始座標的 447 birch＋248 giant tree，MultiMesh 分區，簡單樹幹碰撞。
- 原始村莊廣場與建築、周圍樹林／開闊地、暫時連接道路、大型遺跡、瞭望塔及 Karavan sensor。
- 世界碰撞、邊界、照明、小地圖、兩個可刪除的技能比例鉤子。

## 直接轉換／重建／替代

詳見 CONVERSION_NOTES 的 A／B／C。最重要的區別：

- 建築、遺跡、樹木與地標 **真實網格及貼圖**。
- 村莊／遺跡的大區塊位置、樹木點 **來源資料驅動**。
- **地面高度與道路為近似**；沒有原始山谷、崖壁、河湖。NeL terrain Patch 仍未完成。
- 部分來源粒子、其他植物與 NeL 複合材質沒有重建；不以無關素材替換。

## 驗證

Godot 4.7.1 stable，Windows，OpenGL Compatibility，NVIDIA GeForce MX570 A。

- `import_final.log`：資產匯入與腳本載入。
- `build.log`：實際渲染器烘焙 56 區塊與原始植被變換。
- `acceptance_verbose.log`：出生落地、脚底位置、65 骨骼、動畫確實改變、2.5／5／8 m/s、減速停步、Idle 混合、坡面碰撞、ARPG 俯角、OneShot、村莊、56 區塊、695 來源樹木，全部 PASS。
- `preview.log`：真實桌面渲染器啟動／結束；修正後無腳本、資源及退出洩漏錯誤。
- `portable_import.log`／`portable_acceptance.log`：打包專案解壓到新的目錄，在沒有原工作區快取的情況下重新匯入並通過相同測試。
- `playable_preview.png`、`ruins_preview.png`、`region_preview.png`：直接從遊戲視口擷取並檢查，非示意圖。

早期的 `runtime_check.log`、`acceptance.log` 曾記錄已修正的動畫名稱／ownership／MultiMesh 問題。判讀最終结果請看上列最终驗證日誌。

## 已知畫面限制

- 地面紋理統一使用原始 jungle moss 貼圖，未重建 Ryzom terrain 的分區混合／道路材質。
- 仍有少數原始材質無法解析：village grass-tuft-foot、空材質，以及 ruin_burn 特效材質。大部分村莊／遺跡貼圖已恢復；缺少特效或小表面可能使用預設材質。
- 季節貼圖採第一個找到的來源版本，未實作整區季節同步。
- 樹冠 alpha 與舊 UV 保留基本外觀；没有實作 Ryzom billboard／完整 LOD／特殊風動。
- 區域遠景因暫時地面與未轉換邊界較平坦，不能以此版判斷原作完整地形品質。

## 已知碰撞限制

- 建築使用原始碰撞殼＋表面三角面，部分門檻／遺跡碎塊可能卡腳；目前不含台階攀爬系統。
- 樹幹是簡化圓柱，不代表整棵樹的精確碰撞。
- 未逐條人工走遍所有入口／所有路線；自動測試涵蓋出生點、移動、停止與緩坡。
- 區域邊界是暫時阻擋牆。R 可立即回到村莊。

## 下一步

優先轉換 `.max` 中的 NeL Bezier Patch 或取得官方已建置 `.zone`，用真正高度與材質分區替換暫時地面，再驗證門檻、道路與樹木貼地。這是完整接受條件仍欠缺的主要內容。

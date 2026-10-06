# 使用者影片場景比對

參考影片：[PYDOING－開放原始碼的大型多人線上角色扮演遊戲－Ryzom](https://www.youtube.com/watch?v=RpsQClKLYm4)。2026-10-06 實際查看影片畫面。

- **1:04**：營地外圍森林、細長巨樹、birch、蘑菇、木柵欄與矮植被。
- **1:46**：Ranger Camp 的弧形營地建築、NPC 和營地周邊植被。
- 比對結果：Silan／Ranger Camp 與周邊新手區；Ryzom wiki 的 [Silan](https://en.wiki.ryzom.com/wiki/Silan) 頁面也列出 Ranger Camp。

## 本專案已找到的同區域來源

```
landscape/ligo/jungle/max/zonematerial-foret-start_village_newbieland.max
landscape/ligo/jungle/newbieland.land
primitive/newbieland/flora_newbieland.primitive
stuff/jungle/decors/vegetations/bad_distance_sans_croisillons/fo_s1_giant_tree.max
stuff/jungle/decors/vegetations/bad_distance_sans_croisillons/fo_s2_birch.max
```

上述村莊與兩種樹木已直接轉成 GLB。格網與植被點已用於 Region A。不是另外找 generic fantasy village 來模仿影片。

## 尚未相同的部分

影片是原始 Ryzom client：包含原始 terrain Patch 高度、草花／蘑菇密度、特殊材質、燈光、霧、季節及 NPC。Godot 原型採 ARPG 鏡頭，且地面高度／路線仍近似，還沒有影片中全部的植被和材質效果。

因此可確認資產和區域來源已找到，不能宣稱原型畫面已完整重現影片。

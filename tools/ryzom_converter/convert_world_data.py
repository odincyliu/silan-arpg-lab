"""保存 Silan 原始格網與植被點到 Godot 中性 JSON；不產生隨機森林。"""
import sys
import collections
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/ryzom/source"
ORIGIN = (10304.0, -11725.0)


def main() -> None:
    """裁切起始村莊到 Silan 遺跡的 1280 × 1120 公尺區域。"""
    output = ROOT / "assets/ryzom/converted"
    textures = ROOT / "assets/ryzom/textures"
    textures.mkdir(parents=True, exist_ok=True)
    graphic_root = SOURCE / "graphics"
    for source_name, target in [("j-moussejungle-256-a-01.png", "ground.png"),
                                ("newbieland.tga", "silan_source_map.tga")]:
        source = next(graphic_root.rglob(source_name))
        shutil.copyfile(source, textures / target)
    cells = []
    land = ET.parse(graphic_root / "landscape/ligo/jungle/newbieland.land")
    for index, cell in enumerate(land.findall(".//ELM")):
        x, y = 51 + index % 20, -77 + index // 20
        if 60 <= x <= 67 and -75 <= y <= -69:
            cells.append({"grid": [x, y], "template": cell.findtext("NAME/S", ""),
                          "rotation": int(cell.findtext("ROT", "0")), "flip": int(cell.findtext("FLIP", "0")),
                          "position": [x * 160 - ORIGIN[0], 0, -(y * 160 - ORIGIN[1])]})
    plants = []
    flora = ET.parse(graphic_root / "primitive/newbieland/flora_newbieland.primitive")
    for node in flora.iter():
        if node.attrib.get("TYPE") != "CPrimPoint":
            continue
        point = node.find("PT")
        if point is None:
            continue
        x, y = float(point.attrib["X"]), float(point.attrib["Y"])
        if not (9600 <= x < 10880 and -12000 <= y < -10880):
            continue
        props = {p.findtext("NAME"): p.findtext("STRING") for p in node.findall("PROPERTY")}
        plants.append({"position": [x - ORIGIN[0], 0.0, -(y - ORIGIN[1])],
                       "source_form": props.get("form"), "source_name": props.get("name"),
                       "source_scale": float(props.get("scale", "1")),
                       "angle": float(node.findtext("ANGLE", "0") or node.find("ANGLE").get("VALUE", "0"))})
    regions = []
    for node in ET.parse(SOURCE / "region.primitive").iter():
        props = {p.findtext("NAME"): p.findtext("STRING") for p in node.findall("PROPERTY")}
        points = node.findall("PT")
        if points:
            regions.append({"name": props.get("name"), "type": props.get("class"),
                            "points": [[float(p.attrib["X"]) - ORIGIN[0],
                                        -(float(p.attrib["Y"]) - ORIGIN[1])] for p in points]})
    data = {"origin_ryzom_xy": ORIGIN, "unit_ratio": 1.0, "tile_size_m": 160,
            "bounds_xz": [-704, -845, 576, 275], "cells": cells, "plants": plants, "regions": regions,
            "village_glb_translation": [-64, 0, 115], "ruins_glb_translation": [-544, 0, -525],
            "height_status": "暫時重建；原始 NeL Bezier Patch 地形尚未轉換。原始植被點 Z=0，不能當成高度。"}
    (output / "region_a.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print("CELLS", len(cells), "PLANTS", len(plants), collections.Counter(p["source_form"] for p in plants))


if __name__ == "__main__":
    main()

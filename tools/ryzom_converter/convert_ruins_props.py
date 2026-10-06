# SPDX-License-Identifier: GPL-3.0-or-later
"""補齊遺跡原始植物與燒毀痕跡貼圖，保留來源 MAX 自己的幾何與材質。"""

import sys
import json
from pathlib import Path

try:
    import bpy
except ImportError:
    sys.exit("請以 Blender --background --python 執行；分析環境請 pip install -r requirements.txt。")

sys.path.insert(0, str(Path(__file__).parent))
import convert_assets as converter


def main() -> None:
    """轉換來源表單對應的植物與使用完整貼圖的遺跡群。"""
    base = converter.ROOT / "assets/ryzom/source/graphics"
    plants = base / "stuff/jungle/decors/vegetations/bad_distance_sans_croisillons"
    sources = [plants / (name + ".max") for name in
               ["fo_s1_arbragrelot", "fo_s3_champignou_a", "fo_s3_champignou_b"]]
    sources.append(base / "landscape/ligo/jungle/max/zonematerial-foret-ruines_newbieland.max")
    manifest = []
    for source in sources:
        converter.reset()
        converter.import_max.load(None, bpy.context, filepath=str(source), use_image_search=False,
                                  object_filter={"MATERIAL", "UV"})
        for obj in bpy.context.scene.objects:
            if obj.type == "MESH" and ("colext" in obj.name.lower() or obj.name.lower().endswith("_col")):
                obj.name += "-colonly"
        textures = set()
        for obj in bpy.context.scene.objects:
            if obj.type != "MESH":
                continue
            for material in obj.data.materials:
                if material and material.node_tree:
                    for node in material.node_tree.nodes:
                        if node.type == "TEX_IMAGE" and node.image:
                            textures.add(str(Path(node.image.filepath).relative_to(converter.ROOT)).replace("\\", "/"))
        manifest.append({"source": str(source.relative_to(converter.ROOT)), "source_textures": sorted(textures),
                         **converter.export(source.stem)})
    (converter.ROOT / "docs/ruins_props_manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()

"""檢查 MAX 匯入器保存的貼圖路徑與地形物件。"""
import sys
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent / "vendor/io_scene_max-main/source"))
import import_max
import re

original = import_max.adjust_material
seen = set()


def inspect_material(filename, search, obj, mat):
    if mat is not None and import_max.get_guid(mat) not in (2, 6, 0x200):
        print("CUSTOM", hex(import_max.get_guid(mat)), import_max.get_material_name(mat))
        def dump(chunk, depth=0):
            if id(chunk) in seen or depth > 8:
                return
            seen.add(id(chunk))
            data = getattr(chunk, "data", None)
            if isinstance(data, bytes) and not getattr(chunk, "children", []):
                for encoding in ("utf-16-le", "latin1"):
                    text = data.decode(encoding, errors="ignore")
                    if any(ext in text.lower() for ext in (".tga", ".png", ".dds", ".bmp")):
                        print("TEXTURE_CHUNK", hex(chunk.types), re.findall(r"[\w .:/\\-]+\.(?:tga|png|dds|bmp)", text, re.I))
            for child in getattr(chunk, "children", []):
                dump(child, depth + 1)
            for ref in import_max.get_references(chunk):
                if ref:
                    dump(ref, depth + 1)
            for ref in import_max.get_reference(chunk).values():
                if ref:
                    dump(ref, depth + 1)
        dump(mat)
    return original(filename, search, obj, mat)


import_max.adjust_material = inspect_material

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
path = ROOT / "assets/ryzom/source/graphics/landscape/ligo/jungle/max/zonematerial-foret-start_village_newbieland.max"
import_max.load(None, bpy.context, filepath=str(path), use_image_search=False, object_filter={"MATERIAL", "UV"})
for image in bpy.data.images:
    print("IMAGE", image.name, image.filepath)
for mat in list(bpy.data.materials)[:20]:
    print("MAT", mat.name, [(n.type, n.image.name if n.type == "TEX_IMAGE" and n.image else "")
                           for n in mat.node_tree.nodes] if mat.node_tree else [])
print("OBJECTS", [(o.name, o.type) for o in bpy.context.scene.objects])

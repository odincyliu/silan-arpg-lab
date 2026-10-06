# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 odincyliu. See COPYING in this directory.
"""以 Blender 背景程序將 Ryzom 可編輯網格轉為 GLB，不依賴 NeL 執行階段。"""
import sys
import json
import re
from pathlib import Path

try:
    import bpy
except ImportError:
    sys.exit("請使用 Blender --background --python convert_assets.py 執行；一般 Python 不包含 bpy。")

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / "vendor/io_scene_max-main/source"))
from inspect_sources import meshes
import import_max

ORIGINAL_MATERIAL = import_max.adjust_material
TEXTURES = {p.name.lower(): p for p in (ROOT / "assets/ryzom/source/graphics").rglob("*.png")}


def texture_paths(chunk: object, seen: set[int], depth: int = 0) -> list[str]:
    """搜尋材質自己的參數與貼圖參照，不讀取容器的完整場景緩衝區。"""
    if chunk is None or id(chunk) in seen or depth > 10:
        return []
    seen.add(id(chunk))
    paths = []
    data = getattr(chunk, "data", None)
    children = getattr(chunk, "children", [])
    if isinstance(data, bytes) and not children:
        for encoding in ("utf-16-le", "latin1"):
            paths.extend(re.findall(r"[\w .:/\\-]+\.(?:png|tga|dds)", data.decode(encoding, errors="ignore"), re.I))
    for child in children:
        paths.extend(texture_paths(child, seen, depth + 1))
    for ref in import_max.get_references(chunk):
        paths.extend(texture_paths(ref, seen, depth + 1))
    for ref in import_max.get_reference(chunk).values():
        paths.extend(texture_paths(ref, seen, depth + 1))
    return paths


def nel_material(filename: str, search: bool, obj: bpy.types.Object, mat: object) -> object:
    """將 NeL MAX 外掛材質的第一張原始色彩貼圖映射到 Principled 材質。"""
    if mat is None or import_max.get_guid(mat) != 0x222B9EB964C75FEC:
        return ORIGINAL_MATERIAL(filename, search, obj, mat)
    candidates = texture_paths(mat, set())
    path = None
    for candidate in candidates:
        name = Path(candidate.replace("\\", "/")).with_suffix(".png").name.lower()
        # 部分原始 MAX 使用舊版沒有 g_ 前綴的相同貼圖名稱。
        aliases = [name, "g_" + name, name.replace("tr_centretronc", "g_centretronc")]
        path = next((TEXTURES[a] for a in aliases if a in TEXTURES), None)
        if path:
            break
    material = bpy.data.materials.new(path.stem if path else "NeL_unresolved")
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.9
    if path:
        tex = material.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(path), check_existing=True)
        material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        material.node_tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    obj.data.materials.append(material)
    print("NEL_MATERIAL", path.name if path else candidates[:1], flush=True)
    return None


import_max.adjust_material = nel_material


def reset() -> None:
    """清空此獨立背景程序的新場景。"""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def export(name: str) -> dict:
    """輸出自足 GLB 並記錄網格尺寸。"""
    bpy.context.view_layer.update()
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH" and len(o.data.polygons)]
    if not objects:
        raise ValueError("匯入器沒有產生任何三角面：" + name)
    from mathutils import Vector
    points = [o.matrix_world @ Vector(v) for o in objects for v in o.bound_box]
    bounds = [[min(v[i] for v in points), max(v[i] for v in points)] for i in range(3)]
    path = ROOT / "assets/ryzom/converted" / (name + ".glb")
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", export_cameras=False,
                              export_lights=False, export_animations=False)
    print("EXPORTED", name, len(objects), bounds, flush=True)
    return {"name": name, "bounds_xyz_source": bounds, "mesh_count": len(objects),
            "triangles": sum(len(o.data.polygons) for o in objects)}


def main() -> None:
    """優先使用 3DS；另測試舊 MAX 是否保有可讀取網格。"""
    source = ROOT / "assets/ryzom/source/graphics"
    records = []
    for path in (source / "stuff/generique/agents/waibao").glob("*.3ds"):
        reset()
        raw = path.read_bytes()
        for model in meshes(raw, 0, len(raw)):
            mesh = bpy.data.meshes.new(model["name"])
            mesh.from_pydata(model["vertices"], [], model["faces"])
            mesh.update()
            obj = bpy.data.objects.new(model["name"], mesh)
            bpy.context.collection.objects.link(obj)
            if model["uv"]:
                uv = mesh.uv_layers.new(name="UVMap")
                for polygon in mesh.polygons:
                    for loop_index in polygon.loop_indices:
                        uv.data[loop_index].uv = model["uv"][mesh.loops[loop_index].vertex_index]
            mat = bpy.data.materials.new(path.stem)
            mat.use_nodes = True
            shader = mat.node_tree.nodes.get("Principled BSDF")
            shader.inputs["Roughness"].default_value = 0.85
            image_path = path.with_suffix(".png")
            if image_path.exists():
                texture = mat.node_tree.nodes.new("ShaderNodeTexImage")
                texture.image = bpy.data.images.load(str(image_path))
                mat.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
                mat.node_tree.links.new(texture.outputs["Alpha"], shader.inputs["Alpha"])
            mesh.materials.append(mat)
        records.append({"source": str(path.relative_to(ROOT)), **export(path.stem.replace(" ", "_"))})
    for path in [source / "landscape/ligo/jungle/max/zonematerial-foret-start_village_newbieland.max",
                 source / "landscape/ligo/jungle/max/zonematerial-foret-ruines_newbieland.max",
                 source / "stuff/jungle/decors/vegetations/bad_distance_sans_croisillons/fo_s1_giant_tree.max",
                 source / "stuff/jungle/decors/vegetations/bad_distance_sans_croisillons/fo_s2_birch.max"]:
        reset()
        try:
            import_max.load(None, bpy.context, filepath=str(path), use_image_search=False,
                            object_filter={"MATERIAL", "UV"})
            # 原始碰撞外殼保留為 Godot 可識別的碰撞節點，避免顯示重疊白色表面。
            for obj in bpy.context.scene.objects:
                if obj.type == "MESH" and ("colext" in obj.name.lower() or obj.name.lower().endswith("_col")):
                    obj.name += "-colonly"
            records.append({"source": str(path.relative_to(ROOT)), **export(path.stem)})
        except Exception as exc:
            print("MAX_LIMITATION", path.name, str(exc), flush=True)
            records.append({"source": str(path.relative_to(ROOT)), "error": str(exc)})
    (ROOT / "docs/mesh_conversion_manifest.json").write_text(json.dumps(records, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()

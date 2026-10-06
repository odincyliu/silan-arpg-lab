# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 odincyliu. See COPYING in this directory.
"""讀取原始 Silan 遺跡的最終 NeL Painter 曲面與地表拼貼，烘焙為 GLB。"""

import sys
import hashlib
import json
import struct
from pathlib import Path
from typing import Any, Iterator

try:
    import bpy
    import numpy as np
    from mathutils import Vector
except ImportError:
    sys.exit("請用 Blender --background --python 執行。一般 Python 分析環境請 pip install -r requirements.txt。")

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/ryzom/source/graphics"
TILE_ROOT = SOURCE / "landscape/_texture_tiles/jungle"
OUT = ROOT / "assets/ryzom/converted"
sys.path.insert(0, str(Path(__file__).parent / "vendor/io_scene_max-main/source"))
import import_max as max_reader


class Reader:
    """有界的小端序資料讀取器；不容許破損資料靜默截斷。"""

    def __init__(self, data: bytes) -> None:
        self.data = data
        self.pos = 0

    def take(self, fmt: str) -> tuple:
        """讀取固定格式並移動游標。"""
        result = struct.unpack_from("<" + fmt, self.data, self.pos)
        self.pos += struct.calcsize("<" + fmt)
        return result


def descendants(chunk: Any, tag: int) -> Iterator[Any]:
    """在指定擁有者範圍內尋找容器，不混用不同類別的同名標籤。"""
    for child in getattr(chunk, "children", []):
        if child.types == tag:
            yield child
        yield from descendants(child, tag)


def decode_paint(data: bytes) -> list[dict]:
    """解碼 RPatchMesh v9 的地表層、旋轉、256 象限及逐頂點色彩。"""
    reader = Reader(data)
    version, count = reader.take("Ii")
    if version != 9 or count != 100:
        raise ValueError(f"此轉換器只接受已驗證的遺跡 v9／100 patch，實際為 {version}/{count}")
    patches = []
    for _ in range(count):
        log_s, log_t, tile_count = reader.take("iii")
        order_s, order_t = 1 << log_s, 1 << log_t
        if tile_count != order_s * order_t:
            raise ValueError("地表格數與曲面尺寸不一致")
        tiles = []
        for _ in range(tile_count):
            layers, flags, noise = reader.take("HHB")
            entries = [reader.take("Bii") for _ in range(3)]
            if not 1 <= layers <= 3:
                raise ValueError("遺跡地表出現空白或無效層數")
            tiles.append({"layers": entries[:layers], "flags": flags, "noise": noise})
        color_count = reader.take("i")[0]
        if color_count != (order_s + 1) * (order_t + 1):
            raise ValueError("曲面色彩數量不一致")
        colors = reader.take("I" * color_count)
        reader.take("4I")
        patches.append({"s": order_s, "t": order_t, "tiles": tiles, "colors": colors})
    vertex_count = reader.take("i")[0]
    bindings = [reader.take("B10I") for _ in range(vertex_count)]
    if any(binding[0] for binding in bindings):
        raise ValueError("此區塊含跨曲面綁定，需先執行官方 binding 評估")
    reader.take("iBBii")
    if reader.pos != len(data):
        raise ValueError("RPatchMesh 尾端長度不吻合")
    return patches


def decode_bank(path: Path) -> list[dict]:
    """由嚴格匹配到檔案末端的 CTile v4 陣列取得原始 bank 索引。"""
    data = path.read_bytes()
    if data[:9] != b"\x04\x00\x00\x00BANK\x04":
        raise ValueError("不是來源 jungle.bank v4")
    candidates = []
    for offset in range(len(data) - 20):
        count = struct.unpack_from("<I", data, offset)[0]
        if not 100 < count < 10000 or data[offset + 4] != 4:
            continue
        reader = Reader(data)
        reader.pos = offset + 4
        tiles = []
        try:
            for _ in range(count):
                version, flags = reader.take("BI")
                if version != 4:
                    raise ValueError("非 CTile v4")
                names = []
                for _ in range(3):
                    size = reader.take("I")[0]
                    if size > 250 or reader.pos + size > len(data):
                        raise ValueError("無效貼圖路徑長度")
                    names.append(data[reader.pos:reader.pos + size].decode("ascii"))
                    reader.pos += size
                tiles.append({"flags": flags, "names": names})
            if reader.pos == len(data):
                candidates.append(tiles)
        except (ValueError, UnicodeDecodeError, struct.error):
            continue
    if len(candidates) != 1:
        raise ValueError(f"CTile 陣列定位有歧義：{len(candidates)} 個候選")
    return candidates[0]


def read_final_patch() -> tuple[Any, list[dict], Any]:
    """僅接受最上層 NeL Painter 已評估快取；不誤用平面的基礎 RPO。"""
    original = max_reader.ByteArrayChunk.set_data

    def keep_raw(chunk: Any, data: bytes) -> None:
        original(chunk, data)
        chunk.raw_data = data

    max_reader.ByteArrayChunk.set_data = keep_raw
    path = SOURCE / "landscape/ligo/jungle/max/zonematerial-foret-ruines_newbieland.max"
    max_file = max_reader.ImportMaxFile(str(path))
    for read in [max_reader.read_class_data, max_reader.read_config, max_reader.read_directory,
                 max_reader.read_class_directory]:
        read(max_file, str(path))
    max_reader.SCENE_LIST = max_reader.read_chunks(max_file, "Scene", max_reader.SceneChunk)
    nodes = [c for c in max_reader.SCENE_LIST[0].children if c.get_first(0x0962)
             and max_reader.get_node_name(c) == "QuadPatch01"]
    if len(nodes) != 1 or nodes[0].get_first(0x0976):
        raise ValueError("找不到唯一非凍結的原始遺跡地形")
    prs, derived, _, _ = max_reader.get_matrix_mesh_material(nodes[0])
    if max_reader.get_guid(max_reader.get_references(derived)[0]) != 0x3C3D68E70C49560F:
        raise ValueError("最上層不是 NeL Painter；不可直接使用快取")
    slots = [c for c in derived.children if c.types == 0x2500]
    local = next(c for c in descendants(slots[0], 0x1000) if c.get_first(0x1140))
    if local.get_first(0x1130):
        raise ValueError("最上層仍需 vertex mapper 評估")
    geometry = local.get_first(0x1140)
    paint = decode_paint(local.get_first(0x4001).raw_data)
    return geometry, paint, max_reader.create_matrix(prs)


def main() -> None:
    """產出原始遺跡曲面、來源地表圖集、選用貼圖及可追溯清單。"""
    geometry, paint, matrix = read_final_patch()
    bank_path = TILE_ROOT / "jungle.bank"
    max_path = SOURCE / "landscape/ligo/jungle/max/zonematerial-foret-ruines_newbieland.max"
    bank = decode_bank(bank_path)
    files = {str(p.relative_to(TILE_ROOT)).replace("\\", "/").lower(): p for p in TILE_ROOT.rglob("*.png")}
    images: dict[str, np.ndarray] = {}
    used: set[str] = set()

    def pixels(name: str) -> np.ndarray:
        key = name.replace("\\", "/").lower()
        if key not in files:
            raise FileNotFoundError(f"原始地表貼圖缺少：{key}")
        used.add(key)
        if key not in images:
            image = bpy.data.images.load(str(files[key]), check_existing=True)
            rgba = np.empty(image.size[0] * image.size[1] * 4, dtype=np.float32)
            image.pixels.foreach_get(rgba)
            images[key] = rgba.reshape(image.size[1], image.size[0], 4)
        return images[key]

    def layer(tile_id: int, rotate: int, case: int, alpha: bool = False) -> np.ndarray:
        if not 0 <= tile_id < len(bank):
            raise ValueError(f"地表層索引超出 bank：{tile_id}")
        entry = bank[tile_id]
        name = entry["names"][2 if alpha else 0]
        if not name:
            if alpha:
                return np.ones((32, 32, 4), dtype=np.float32)
            raise ValueError("使用到空白 diffuse 地表")
        # NeL bitmap 的第一列是 UV V=0；Blender 像素陣列從影像底列開始。
        image = pixels(name)[::-1]
        rotation = (rotate + (entry["flags"] & 3 if alpha else 0)) & 3
        u, v = np.meshgrid((np.arange(32)+0.5)/32, (np.arange(32)+0.5)/32)
        if rotation == 1:
            u, v = 1-v, u
        elif rotation == 2:
            u, v = 1-u, 1-v
        elif rotation == 3:
            u, v = v, 1-u
        if case:
            offset = case - 1
            u = u*0.5 + (0.5 if offset in (2, 3) else 0.0)
            v = v*0.5 + (0.5 if offset in (1, 2) else 0.0)
        ys = np.minimum(v*image.shape[0], image.shape[0]-1).astype(int)
        xs = np.minimum(u*image.shape[1], image.shape[1]-1).astype(int)
        return image[ys, xs, :]

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    corners = np.asarray([struct.unpack("<3f", c.get_first(0x03E8).raw_data)
                          for c in geometry.children if c.types == 0x0BE0])
    handles = np.asarray([struct.unpack("<3f", c.get_first(0x03E8).raw_data)
                          for c in geometry.children if c.types == 0x0BCC])
    quads = [c for c in geometry.children if c.types == 0x0BF4]
    if len(quads) != len(paint) or len(corners) != 121:
        raise ValueError("曲面幾何數量與地表資料不符")
    vertices, faces, uvs = [], [], []
    atlas = np.ones((5200, 5200, 4), dtype=np.float32)
    t = np.linspace(0.0, 1.0, 33)
    basis = np.stack([(1-t)**3, 3*t*(1-t)**2, 3*t*t*(1-t), t**3], axis=1)
    used_ids = set()
    for index, (quad, texture) in enumerate(zip(quads, paint)):
        v = struct.unpack("<4i", quad.get_first(0x03F2).raw_data)
        h = struct.unpack("<8i", quad.get_first(0x03FC).raw_data)
        interior = struct.unpack("<4i", quad.get_first(0x0406).raw_data)
        flags = struct.unpack("<i", quad.get_first(0x041A).raw_data)[0]
        if flags & 1:
            middle = [handles[h[j*2]] + handles[h[(j*2+7) % 8]] - corners[v[j]] for j in range(4)]
        else:
            middle = [handles[i] for i in interior]
        control = np.asarray([
            [corners[v[0]], handles[h[0]], handles[h[1]], corners[v[1]]],
            [handles[h[7]], middle[0], middle[1], handles[h[2]]],
            [handles[h[6]], middle[3], middle[2], handles[h[3]]],
            [corners[v[3]], handles[h[5]], handles[h[4]], corners[v[2]]],
        ])
        surface = np.einsum("si,tj,ijc->stc", basis, basis, control)
        start = len(vertices)
        vertices.extend(tuple(matrix @ Vector(point)) for point in surface.reshape(-1, 3))
        for s in range(32):
            for q in range(32):
                a = start + s*33 + q
                faces.append((a, a+1, a+34, a+33))
        col, row = index % 10, index // 10
        for s in t:
            for q in t:
                uvs.append(((col*520 + 4 + s*512)/5200, (row*520 + 4 + q*512)/5200))
        patch_image = np.ones((512, 512, 4), dtype=np.float32)
        if texture["s"] != 16 or texture["t"] != 16:
            raise ValueError("遺跡不是 16 × 16 地表格")
        for number, tile in enumerate(texture["tiles"]):
            case = tile["flags"] & 7
            s, q = number % 16, number // 16
            result = None
            for _, tile_id, rotate in tile["layers"]:
                used_ids.add(tile_id)
                rgb = layer(tile_id, rotate, case)
                if result is None:
                    result = rgb.copy()
                else:
                    mask = layer(tile_id, rotate, case, True)
                    # 原始 alpha PNG 多為 RGB 灰階，Alpha 通道本身可能全白。
                    opacity = mask[:, :, :1] * mask[:, :, 3:4]
                    result[:, :, :3] = result[:, :, :3]*(1-opacity) + rgb[:, :, :3]*opacity
            result[:, :, 3] = 1.0
            patch_image[q*32:(q+1)*32, s*32:(s+1)*32] = result
        colors = np.asarray([[(color >> 16) & 255, (color >> 8) & 255, color & 255]
                             for color in texture["colors"]], dtype=np.float32).reshape(17, 17, 3)/255
        coordinate = (np.arange(512)+0.5)/32
        low = np.floor(coordinate).astype(int)
        weight = coordinate - low
        shade = (colors[low[:, None], low[None, :]]*(1-weight[:, None, None])*(1-weight[None, :, None])
                 + colors[low[:, None]+1, low[None, :]]*weight[:, None, None]*(1-weight[None, :, None])
                 + colors[low[:, None], low[None, :]+1]*(1-weight[:, None, None])*weight[None, :, None]
                 + colors[low[:, None]+1, low[None, :]+1]*weight[:, None, None]*weight[None, :, None])
        patch_image[:, :, :3] *= shade
        atlas[row*520:(row+1)*520, col*520:(col+1)*520] = np.pad(patch_image, ((4, 4), (4, 4), (0, 0)), mode="edge")
        if index % 20 == 0:
            print("PATCH", index, flush=True)
    OUT.mkdir(parents=True, exist_ok=True)
    image = bpy.data.images.new("Silan_Ruins_Original_Paint", width=5200, height=5200)
    image.pixels.foreach_set(atlas.ravel())
    image.filepath_raw = str(OUT / "silan_ruins_terrain_atlas.png")
    image.file_format = "PNG"
    image.save()
    material = bpy.data.materials.new("Original_NeL_Painted_Ground")
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 1.0
    tex = material.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    material.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])
    mesh = bpy.data.meshes.new("Silan_Ruins_100_Authored_Bezier_Patches")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    uv = mesh.uv_layers.new(name="OriginalPatchPaint")
    for polygon in mesh.polygons:
        polygon.use_smooth = True
        for loop in polygon.loop_indices:
            uv.data[loop].uv = uvs[mesh.loops[loop].vertex_index]
    obj = bpy.data.objects.new("OriginalRuinsTerrain", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.ops.export_scene.gltf(filepath=str(OUT / "silan_ruins_terrain.glb"), export_format="GLB",
                              export_animations=False, export_cameras=False, export_lights=False)
    heights = [v[2] for v in vertices]
    report = {"source": "zonematerial-foret-ruines_newbieland.max", "node": "QuadPatch01",
              "evaluated_state": "top NeL Painter cache; no mapper; no vertex bindings",
              "patches": len(quads), "tiles": sum(len(p["tiles"]) for p in paint),
              "vertices": len(vertices), "triangles": len(faces)*2, "tile_bank_entries": len(bank),
              "used_tile_ids": sorted(used_ids), "source_height_range": [min(heights), max(heights)],
              "source_bounds_xy": [0, 0, 320, 320], "source_textures": sorted(used),
              "source_max_sha256": hashlib.sha256(max_path.read_bytes()).hexdigest(),
              "source_bank_sha256": hashlib.sha256(bank_path.read_bytes()).hexdigest(),
              "limitations": ["ground atlas resampled to 16 px/m",
                              "NeL micro-displacement and dynamic lighting not baked"]}
    (ROOT / "docs/ruins_terrain_manifest.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8", newline="\n")
    print("TERRAIN_OK", report["patches"], report["tiles"], report["source_height_range"], flush=True)


if __name__ == "__main__":
    main()

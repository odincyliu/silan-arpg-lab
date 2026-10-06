"""列出 Silan 原始區域定位與 3DS 網格尺寸。"""
import sys
import struct
from collections.abc import Iterator
import xml.etree.ElementTree as ET
from pathlib import Path


def chunks(data: bytes, start: int, end: int) -> Iterator[tuple[int, int, int]]:
    """逐塊讀取具有長度欄位的 3DS 容器。"""
    while start + 6 <= end:
        tag, length = struct.unpack_from("<HI", data, start)
        if length < 6 or start + length > end:
            raise ValueError("無效 3DS 區塊")
        yield tag, start + 6, start + length
        start += length


def meshes(data: bytes, start: int, end: int, name: str = "") -> list[dict]:
    """解析幾何、UV 與面索引，保留原始物件名稱。"""
    result = []
    for tag, a, b in chunks(data, start, end):
        if tag in (0x4D4D, 0x3D3D):
            result.extend(meshes(data, a, b, name))
        elif tag == 0x4000:
            n = data.index(0, a)
            result.extend(meshes(data, n + 1, b, data[a:n].decode("latin1")))
        elif tag == 0x4100:
            mesh = {"name": name, "vertices": [], "faces": [], "uv": []}
            for t, x, y in chunks(data, a, b):
                if t == 0x4110:
                    count = struct.unpack_from("<H", data, x)[0]
                    mesh["vertices"] = [struct.unpack_from("<3f", data, x + 2 + i * 12) for i in range(count)]
                elif t == 0x4120:
                    count = struct.unpack_from("<H", data, x)[0]
                    mesh["faces"] = [struct.unpack_from("<4H", data, x + 2 + i * 8)[:3] for i in range(count)]
                elif t == 0x4140:
                    count = struct.unpack_from("<H", data, x)[0]
                    mesh["uv"] = [struct.unpack_from("<2f", data, x + 2 + i * 8) for i in range(count)]
            if mesh["vertices"] and mesh["faces"]:
                result.append(mesh)
    return result


def main() -> None:
    """顯示轉換前需確認的世界座標。"""
    source = Path(__file__).resolve().parents[2] / "assets/ryzom/source"
    land = ET.parse(source / "graphics/landscape/ligo/jungle/newbieland.land")
    for i, cell in enumerate(land.findall(".//ELM")):
        name = cell.findtext("NAME/S", "")
        if any(word in name for word in ("start_village", "ruines", "69_cb")):
            print("TILE", 51 + i % 20, -77 + i // 20, name, cell.findtext("ROT"), cell.findtext("FLIP"))
    for filename in ("urban.primitive", "region.primitive"):
        for node in ET.parse(source / filename).iter():
            points = node.findall("PT")
            if not points:
                continue
            properties = {p.findtext("NAME"): p.findtext("STRING") for p in node.findall("PROPERTY")}
            if filename == "urban.primitive" and "chiang" not in str(properties).lower():
                continue
            print(filename, properties.get("name"), [p.attrib for p in points][:2])
    for path in (source / "graphics/stuff/generique/agents/waibao").glob("*.3ds"):
        data = path.read_bytes()
        models = meshes(data, 0, len(data))
        points = [v for m in models for v in m["vertices"]]
        print(path.name, len(models), "bounds", [min(v[i] for v in points) for i in range(3)],
              [max(v[i] for v in points) for i in range(3)])


if __name__ == "__main__":
    main()

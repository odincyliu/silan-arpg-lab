"""打包可攜專案及實際使用的來源，排除大型原始壓縮包與快取。"""
import sys
import json
import struct
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    """依實際 GLB 貼圖與轉換記錄收集來源，保留授權與重建工具。"""
    selected: set[Path] = set()
    for folder in ("scripts", "scenes", "docs", "tools", "assets/animations",
                   "assets/ryzom/converted", "assets/ryzom/meshes", "assets/ryzom/textures"):
        for path in (ROOT / folder).rglob("*"):
            if not path.is_file() or "__pycache__" in path.parts or path.suffix in (".import", ".pyc", ".zip"):
                continue
            if path.name.endswith("_tree.json") or path.name == "archive_listing.txt":
                continue
            if path.suffix == ".log" and path.name not in ("acceptance_verbose.log", "preview.log", "build.log",
                                                       "blender_conversion.log", "import_final.log",
                                                       "portable_import.log", "portable_acceptance.log"):
                continue
            selected.add(path)
    for name in ("project.godot", "README.md", "Play.cmd", "requirements.txt", ".gitignore"):
        selected.add(ROOT / name)
    for name in ("License_Standard.txt", "NafisRayan_tree.json", ".gdignore"):
        selected.add(ROOT / "assets/character" / name)
    source = ROOT / "assets/ryzom/source"
    for name in (".gdignore", "urban.primitive", "region.primitive", "newbieland.continent", "graphics_LICENSE.md"):
        selected.add(source / name)
    graphic_root = source / "graphics"
    for name in ("LICENSE", "landscape/ligo/jungle/newbieland.land", "landscape/ligo/jungle/newbieland.tga",
                 "primitive/newbieland/flora_newbieland.primitive"):
        selected.add(graphic_root / name)
    manifest = json.loads((ROOT / "docs/mesh_conversion_manifest.json").read_text(encoding="utf-8"))
    selected.update(ROOT / record["source"] for record in manifest)
    # 轉換記錄包含未用的 3DS，保存其同名貼圖讓離線重建結果一致。
    for record in manifest:
        path = ROOT / record["source"]
        if path.suffix == ".3ds":
            selected.add(path.with_suffix(".png"))
    texture_index = {path.name.lower(): path for path in graphic_root.rglob("*.png")}
    selected.add(texture_index["j-moussejungle-256-a-01.png"])
    for path in (ROOT / "assets/ryzom/converted").glob("*.glb"):
        raw = path.read_bytes()
        length = struct.unpack_from("<I", raw, 12)[0]
        gltf = json.loads(raw[20:20 + length])
        for image in gltf.get("images", []):
            name = image.get("name", "").lower()
            if name in texture_index:
                selected.add(texture_index[name])
            elif name + ".png" in texture_index:
                selected.add(texture_index[name + ".png"])
    destination = ROOT.parent / "godot_ryzom_poc_playable.zip"
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(selected):
            if not path.exists():
                raise FileNotFoundError("必要來源不存在：" + str(path))
            archive.write(path, Path(ROOT.name) / path.relative_to(ROOT))
    print("PACKAGE", destination, "FILES", len(selected), "SIZE_MB", round(destination.stat().st_size / 1024 ** 2, 1))


if __name__ == "__main__":
    main()

"""取得 CC0 Standard 原始檔鏡像；官方 itch.io 在此環境回傳 403。"""

import sys
import hashlib
import json
from pathlib import Path
from urllib.parse import quote
from urllib.request import urlopen


def main() -> None:
    """只下載免費男性角色、必要貼圖與兩套非根位移動畫。"""
    root = Path(__file__).resolve().parents[1]
    index = json.loads((root / "assets/character/NafisRayan_tree.json").read_text())
    records = []
    for item in index["tree"]:
        source = item["path"]
        target = None
        if "/Base Characters/Godot - UE/Superhero_Male_FullBody." in source:
            target = root / "assets/character" / Path(source).name
        elif source.startswith("Universal Base Characters[Standard]/") and source.endswith(".png"):
            target = root / "assets/character/textures" / Path(source).name
        elif source.endswith("License_Standard.txt"):
            target = root / "assets/character" / Path(source).name
        elif source.endswith("/Unreal-Godot/UAL1_Standard.glb"):
            target = root / "assets/animations/UAL1_Standard.glb"
        elif source.endswith("/Unreal-Godot/UAL2_Standard.glb"):
            target = root / "assets/animations/UAL2_Standard.glb"
        elif source.endswith("/License.txt"):
            target = root / "assets/animations" / ("UAL2_LICENSE.txt" if "Library 2" in source else "UAL1_LICENSE.txt")
        if target is None:
            continue
        url = "https://raw.githubusercontent.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender/main/" + quote(source)
        target.parent.mkdir(parents=True, exist_ok=True)
        payload = urlopen(url, timeout=90).read()
        target.write_bytes(payload)
        records.append({"url": url, "file": str(target.relative_to(root)), "sha256": hashlib.sha256(payload).hexdigest()})
        print(target.name, len(payload), flush=True)
    (root / "docs/quaternius_download_manifest.json").write_text(json.dumps(records, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()

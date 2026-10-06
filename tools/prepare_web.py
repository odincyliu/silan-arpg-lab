"""補上 Web 發布版的素材授權頁與完整授權文字。"""

import html
import shutil
from pathlib import Path


def main() -> None:
    """保留匯出成果，建立可離線閱讀的署名及來源頁。"""
    root = Path(__file__).resolve().parents[1]
    output = root / "build" / "web"
    if not (output / "index.html").is_file():
        raise FileNotFoundError("請先匯出 Web 至 build/web/index.html")
    notices = (root / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
    license_dir = output / "licenses"
    license_dir.mkdir(parents=True, exist_ok=True)
    sources = [
        root / "LICENSE",
        *sorted((root / "docs" / "licenses").glob("*.txt")),
        root / "assets" / "animations" / "UAL1_LICENSE.txt",
        root / "assets" / "animations" / "UAL2_LICENSE.txt",
    ]
    for source in sources:
        shutil.copy2(source, license_dir / source.name)
    links = "\n".join(
        f'<li><a href="licenses/{html.escape(source.name)}">'
        f"{html.escape(source.name)}</a></li>" for source in sources
    )
    page = f'''<!doctype html>
<html lang="zh-Hant"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>素材來源與授權 · Silan ARPG Lab</title>
<style>body{{max-width:960px;margin:32px auto;padding:0 20px;background:#101a20;color:#e6e8dd;font:16px/1.7 system-ui,sans-serif}}a{{color:#c5dba2}}pre{{white-space:pre-wrap;overflow-wrap:anywhere;font:inherit}}</style>
<h1>素材來源與授權</h1>
<p><a href="index.html">回到遊戲</a> · <a href="https://github.com/odincyliu/silan-arpg-lab/blob/main/THIRD_PARTY_NOTICES.md">GitHub 來源與可點擊參考連結</a></p>
<ul>{links}</ul><pre>{html.escape(notices)}</pre></html>
'''
    (output / "licenses.html").write_text(page, encoding="utf-8")
    (output / ".nojekyll").touch()
    print("Web 授權頁與完整授權文字已保存。")


if __name__ == "__main__":
    main()

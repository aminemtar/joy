"""Resize the approved JOY master art into the native runner icon sizes.

Run from the repository root: python tool/build_app_icons.py
Requires Pillow for development only; it is not an app dependency.
"""
import io
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
master = Image.open(root / "assets/art/app_icon.png").convert("RGB")

def write(path: Path, size: int):
    buffer = io.BytesIO()
    master.resize((size, size), Image.Resampling.LANCZOS).save(buffer, format="PNG", optimize=True)
    path.write_bytes(buffer.getvalue())
    with Image.open(path) as image:
        image.load()
        assert image.size == (size, size)

for density, size in {"mdpi":48,"hdpi":72,"xhdpi":96,"xxhdpi":144,"xxxhdpi":192}.items():
    write(root / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)
icons = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for item in json.loads((icons / "Contents.json").read_text())["images"]:
    if "filename" in item:
        points = float(item["size"].split("x")[0])
        scale = float(item["scale"].removesuffix("x"))
        write(icons / item["filename"], round(points * scale))
write(root / "web/favicon.png", 32)
for size in [192,512]:
    for name in [f"Icon-{size}.png",f"Icon-maskable-{size}.png"]:
        write(root / "web/icons" / name, size)

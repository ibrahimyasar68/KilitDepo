"""Google Play mağaza görsellerini üretir (proje kökünden):

    python3 tool/generate_store_assets.py

Üretilenler (store/graphics/):
  - icon-512.png          Uygulama simgesi: 512x512, 32 bit PNG, tam kare
                          (Play köşeleri kendisi yuvarlar; gölge/köşe EKLENMEZ).
  - feature-graphic.png   Tanıtım görseli: 1024x500, 24 bit PNG (saydamlık yok).

Logo geometrisi tool/generate_brand_assets.py ile aynıdır. Gereken: Pillow.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tool"))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

from generate_brand_assets import render_icon  # noqa: E402

OUT = ROOT / "store" / "graphics"
FONTS = ROOT / "assets" / "fonts"

TEAL_DARK = (6, 52, 41)
TEAL = (15, 110, 86)
MINT = (165, 240, 214)


def font(name, size):
    return ImageFont.truetype(str(FONTS / f"Inter-{name}.ttf"), size)


def icon_512():
    img = render_icon(512, rounded=False, tag=True)  # RGB, tam kare
    img.convert("RGBA").save(OUT / "icon-512.png", optimize=True)


def feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), TEAL_DARK)
    px = img.load()
    # Soldan sağa koyu → marka yeşili geçiş + sağ üstte hafif ışıma.
    for y in range(h):
        for x in range(w):
            t = x / (w - 1)
            r = TEAL_DARK[0] + (TEAL[0] - TEAL_DARK[0]) * t
            g = TEAL_DARK[1] + (TEAL[1] - TEAL_DARK[1]) * t
            b = TEAL_DARK[2] + (TEAL[2] - TEAL_DARK[2]) * t
            dx, dy = (x - w * 0.95) / w, (y + h * 0.1) / h
            glow = max(0.0, 1 - (dx * dx + dy * dy) ** 0.5 / 0.75) * 0.22
            px[x, y] = (
                int(r + (255 - r) * glow),
                int(g + (255 - g) * glow),
                int(b + (255 - b) * glow),
            )

    logo = render_icon(300, rounded=True, tag=True)
    img.paste(logo, (90, (h - 300) // 2), logo)

    d = ImageDraw.Draw(img)
    x = 450
    d.text((x, 128), "KilitDepo", font=font("Bold", 92), fill=(255, 255, 255))
    d.text(
        (x, 250),
        "Şifreleriniz yalnızca\ncihazınızda, şifreli.",
        font=font("SemiBold", 38),
        fill=(235, 250, 245),
        spacing=10,
    )
    d.text(
        (x, 372),
        "Çevrimdışı  ·  Reklamsız  ·  Hesap gerektirmez",
        font=font("Medium", 24),
        fill=MINT,
    )
    img.save(OUT / "feature-graphic.png", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    icon_512()
    feature_graphic()
    for f in sorted(OUT.glob("*.png")):
        im = Image.open(f)
        print(f"{f.relative_to(ROOT)}: {im.size[0]}x{im.size[1]} {im.mode}, "
              f"{f.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()

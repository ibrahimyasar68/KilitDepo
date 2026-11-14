"""KilitDepo logo ve uygulama ikonlarını üretir.

Geometri lib/core/widgets/app_logo.dart içindeki VaultKeyholePainter ile
aynıdır (100x100 birimlik ızgara). Çalıştırma (proje kökünden):

    python3 tool/generate_brand_assets.py

Gereken tek paket: Pillow. Üretilenler:
  - assets/brand/kilitdepo_logo.svg ("İY Labs" etiketli)
  - ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png (kare, saydamlıksız)
  - android/app/src/main/res/mipmap-*/ic_launcher.png (yuvarlak köşeli; eski
    Android sürümleri için)
  - android/app/src/main/res/mipmap-*/ic_launcher_foreground.png +
    mipmap-anydpi-v26/ic_launcher.xml (Android 8+ uyarlanabilir simge;
    Android 13+ temalı simge için tek renkli katman dahil)
  - assets/brand/kilitdepo_logo_1024.png ("İY Labs" etiketli logo)
  - assets/brand/splash_logo.png (etiketli), splash_android12.png (açılış ekranı;
    ardından: dart run flutter_native_splash:create)

Tüm logolar "İY Labs" etiketlidir ve uygulama içi logo (AppLogo) ile aynı
düzendedir: kasa tam ortada, küçük etiket kutucuğun sağ alt köşesinde.
Daire maskeli simgelerde (Android uyarlanabilir simge, Android 12+ açılış
ekranı) etiket, kesilmemesi için güvenli dairenin sağ alt kenarındadır.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TEAL = (0x0F, 0x6E, 0x56, 255)
WHITE = (255, 255, 255, 255)
SUPERSAMPLE = 4
GLYPH_RATIO = 0.68  # çizimin kutucuğa oranı (AppLogo ile aynı)
TILE_RADIUS_RATIO = 0.233


def draw_glyph(draw, origin, unit, color, details):
    """100 birimlik ızgaradaki kasa + anahtar deliğini çizer."""
    ox, oy = origin
    w = (6 if details else 7) * unit

    def p(x, y):
        return (ox + x * unit, oy + y * unit)

    # Kasa gövdesi: PIL çizgiyi kutunun içine doğru çizdiği için yarım
    # çizgi kalınlığı kadar dışa genişletilir (SVG'deki ortalı çizgi).
    h = w / (2 * unit)
    x0, y0 = p(20 - h, 20 - h)
    x1, y1 = p(84 + h, 78 + h)
    draw.rounded_rectangle(
        (x0, y0, x1, y1), radius=(10 + h) * unit, outline=color, width=round(w)
    )

    if details:
        for a, b in (((13, 34), (13, 42)), ((13, 56), (13, 64)),
                     ((32, 78), (32, 84)), ((72, 78), (72, 84))):
            draw.line((p(*a), p(*b)), fill=color, width=round(w))
            for x, y in (a, b):  # yuvarlak uçlar
                cx, cy = p(x, y)
                r = w / 2
                draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)

    # Anahtar deliği (küçük boyutlarda daha iri, okunsun diye).
    if details:
        cy0, rr, top, bot, half_top, half_bot = 44, 7, 48, 62, 3.5, 6.5
    else:
        cy0, rr, top, bot, half_top, half_bot = 43, 10, 49, 68, 5, 9
    cx, cy = p(52, cy0)
    r = rr * unit
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)
    draw.polygon([p(52 - half_top, top), p(52 + half_top, top),
                  p(52 + half_bot, bot), p(52 - half_bot, bot)], fill=color)


# "İY Labs" etiketi (AppLogo._ProducerTag ile aynı oranlar, kutucuğa göre).
TAG_TEXT = "İY Labs"
TAG_FONTS = (
    # Önce uygulamaya gömülü yazı tipi (uygulama içi logo ile aynı görünüm).
    str(ROOT / "assets" / "fonts" / "Inter-Bold.ttf"),
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
)


def _tag_font(size):
    for path in TAG_FONTS:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    raise SystemExit("Etiket için kalın bir TTF yazı tipi bulunamadı.")


def draw_tag(img, tile_px, origin=(0, 0), scale=1.0, center_bottom=None,
             corner_at=None, backing=None, cutout=False):
    """Yarı saydam hap + beyaz "İY Labs" yazısı çizer.

    Varsayılan: kutucuğun sağ alt köşesi (uygulama içi logo ile aynı).
    scale: ana ekran simgelerinde okunabilirlik için büyütme katsayısı.
    center_bottom: verilirse hap yatayda ortalanır ve alt kenarı bu
    orana (kutucuk yüksekliğine göre) oturur.
    corner_at: hapın sağ alt köşesinin konacağı nokta.
    backing: hap kasanın çizgilerinin üzerine geliyorsa, çizgiler yazının
    arkasında görünmesin diye önce bu renkle opak doldurulur.
    cutout: tek renkli (temalı) simge için hap alanı saydam yapılır ve
    yalnızca hap çerçevesi + yazı çizilir.
    """
    font = _tag_font(round(tile_px * 0.075 * scale))
    ox, oy = origin
    l, t, r, b = font.getbbox(TAG_TEXT)
    text_w, text_h = r - l, b - t
    pill_h = tile_px * 0.13 * scale
    pill_w = text_w + 2 * tile_px * 0.045 * scale
    if corner_at is not None:
        # Hapın sağ alt köşesi verilen noktaya oturur.
        x1, y1 = corner_at
        x0 = x1 - pill_w
    elif center_bottom is None:
        x1 = ox + tile_px * (1 - 0.07)
        y1 = oy + tile_px * (1 - 0.065)
        x0 = x1 - pill_w
    else:
        x0 = ox + (tile_px - pill_w) / 2
        x1 = x0 + pill_w
        y1 = oy + tile_px * center_bottom
    y0 = y1 - pill_h
    box = (x0, y0, x1, y1)
    if cutout or backing is not None:
        hole = Image.new("L", img.size, 0)
        ImageDraw.Draw(hole).rounded_rectangle(box, radius=pill_h / 2, fill=255)
        fill = (0, 0, 0, 0) if cutout else backing
        img.paste(Image.new("RGBA", img.size, fill), (0, 0), hole)
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    if cutout:
        od.rounded_rectangle(box, radius=pill_h / 2, outline=WHITE,
                             width=max(1, round(pill_h * 0.08)))
    else:
        od.rounded_rectangle(box, radius=pill_h / 2,
                             fill=(255, 255, 255, round(255 * 0.18)))
    od.text((x0 + (pill_w - text_w) / 2 - l, y0 + (pill_h - text_h) / 2 - t),
            TAG_TEXT, font=font, fill=WHITE)
    img.alpha_composite(overlay)
    return (x0, y0, x1, y1)


def render_icon(px, rounded, tag=False):
    """px boyutunda ikon. rounded=False: iOS için tam dolu kare.
    tag=True: "İY Labs" etiketi kutucuğun sağ alt köşesinde; kasa ortada
    (uygulama içi AppLogo ile birebir aynı düzen ve oranlar)."""
    big = px * SUPERSAMPLE
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0) if rounded else TEAL)
    draw = ImageDraw.Draw(img)
    if rounded:
        draw.rounded_rectangle(
            (0, 0, big - 1, big - 1), radius=big * TILE_RADIUS_RATIO, fill=TEAL
        )
    glyph = big * GLYPH_RATIO
    offset = (big - glyph) / 2
    draw_glyph(draw, (offset, offset), glyph / 100, WHITE, details=px >= 64)
    if tag:
        draw_tag(img, big)
    img = img.resize((px, px), Image.LANCZOS)
    return img if rounded else img.convert("RGB")


GLYPH_SVG = (
    '<g fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" '
    'stroke-linejoin="round"><rect x="20" y="20" width="64" height="58" rx="10"/>'
    '<path d="M13 34v8M13 56v8M32 78v6M72 78v6"/></g>'
    '<g fill="#FFFFFF"><circle cx="52" cy="44" r="7"/>'
    '<path d="M48.5 48h7l3 14h-13z"/></g>'
)


def svg(with_tag):
    # 360 birimlik kutucuk; çizim 244 birim (0.68), ortada.
    tag = (
        '<rect x="226" y="296" width="108" height="38" rx="19" '
        'fill="#FFFFFF" fill-opacity="0.18"/>'
        '<text x="280" y="322" text-anchor="middle" fill="#FFFFFF" '
        'font-family="Space Grotesk, Inter, Arial, sans-serif" '
        'font-size="20" font-weight="700">İY Labs</text>'
        if with_tag else ""
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 360" '
        'role="img" aria-label="KilitDepo">'
        '<rect width="360" height="360" rx="84" fill="#0F6E56"/>'
        f'<g transform="translate(58 58) scale(2.44)">{GLYPH_SVG}</g>'
        f"{tag}</svg>\n"
    )


def render_circle_safe_logo(px):
    """Daire maskesiyle gösterilen logolar (Android uyarlanabilir simge ön
    katmanı ve Android 12+ açılış ekranı), uygulama içi logoya benzer:
    kasa tam ortada, küçük "İY Labs" etiketi sağ altta.

    Başlatıcılar görünür alanı (tuvalin ortadaki 72/108'i) daireyle keser;
    karenin köşesi dairenin dışında kaldığı için etiket, görünür dairenin
    sağ alt (45°) kenarına, biraz içeride yerleştirilir. Kasa etikete
    değmeyecek boyuttadır (uygulama içi logo oranının ~%85'i). İki koşul
    da üretimde denetlenir."""
    big = px * SUPERSAMPLE
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c, circle_r = big / 2, big * 36 / 108  # görünür daire (72 dp)
    glyph = big * 0.38
    offset = (big - glyph) / 2
    draw_glyph(draw, (offset, offset), glyph / 100, WHITE, details=True)
    visible = big * 72 / 108
    d = circle_r * 0.95 / 2 ** 0.5
    # Uygulama içi logodaki etiket oranının biraz küçüğü (daireye sığsın).
    x0, y0, x1, y1 = draw_tag(
        img, visible, scale=0.06 / 0.075, corner_at=(c + d, c + d),
    )
    for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        if ((x - c) ** 2 + (y - c) ** 2) ** 0.5 > circle_r * 0.985:
            raise SystemExit("Etiket görünür dairenin dışında kaldı.")
    legs_bottom = offset + glyph * 0.87  # ayaklar + yuvarlak uç
    if y0 < legs_bottom:
        raise SystemExit("Etiket kasa çizimine değiyor.")
    return img.resize((px, px), Image.LANCZOS)


ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<!-- tool/generate_brand_assets.py tarafından üretildi. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

BACKGROUND_XML = """<?xml version="1.0" encoding="utf-8"?>
<!-- tool/generate_brand_assets.py tarafından üretildi. -->
<resources>
    <color name="ic_launcher_background">#0F6E56</color>
</resources>
"""


def main():
    brand = ROOT / "assets" / "brand"
    brand.mkdir(parents=True, exist_ok=True)
    # Etiketsiz logo üretilmez; eski etiketsiz dosyalar varsa silinir.
    for old in ("kilitdepo_icon.svg", "kilitdepo_icon_1024.png"):
        (brand / old).unlink(missing_ok=True)
    (brand / "kilitdepo_logo.svg").write_text(svg(True), encoding="utf-8")

    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios / "Contents.json").read_text())
    for image in contents["images"]:
        px = round(float(image["size"].split("x")[0]) * int(image["scale"][0]))
        render_icon(px, rounded=False, tag=True).save(ios / image["filename"])

    res = ROOT / "android/app/src/main/res"
    for folder, px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                       ("xxhdpi", 144), ("xxxhdpi", 192)):
        render_icon(px, rounded=True, tag=True).save(
            res / f"mipmap-{folder}" / "ic_launcher.png"
        )

    # Android 8+ uyarlanabilir simge (108 dp tuval).
    for folder, px in (("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                       ("xxhdpi", 324), ("xxxhdpi", 432)):
        render_circle_safe_logo(px).save(
            res / f"mipmap-{folder}" / "ic_launcher_foreground.png"
        )
        (res / f"mipmap-{folder}" / "ic_launcher_monochrome.png").unlink(
            missing_ok=True
        )
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML, encoding="utf-8")
    (res / "values" / "ic_launcher_background.xml").write_text(
        BACKGROUND_XML, encoding="utf-8"
    )

    # Açılış ekranı: kutucuklu logo (4x yoğunluk, ~192 dp) ve Android 12+
    # için daire maskesine sığan beyaz çizim (1152 px tuval).
    render_icon(768, rounded=True, tag=True).save(brand / "splash_logo.png")
    render_icon(1024, rounded=True, tag=True).save(brand / "kilitdepo_logo_1024.png")
    render_circle_safe_logo(1152).save(
        brand / "splash_android12.png"
    )

    print("Logo ve ikonlar üretildi.")


if __name__ == "__main__":
    main()

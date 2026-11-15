"""store/listing-tr.md içindeki mağaza metinlerinin Play sınırlarını kontrol eder.

    python3 tool/check_store_listing.py

Sınırlar: ad 30, kısa açıklama 80, tam açıklama 4000, sürüm notu 500 karakter.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIMITS = [("Uygulama adı", 30), ("Kısa açıklama", 80), ("Tam açıklama", 4000)]


def main():
    text = (ROOT / "store" / "listing-tr.md").read_text(encoding="utf-8")
    ok = True
    for title, limit in LIMITS:
        m = re.search(r"## " + re.escape(title) + r".*?```\n(.*?)\n```", text, re.S)
        if not m:
            print(f"BULUNAMADI: {title}")
            ok = False
            continue
        n = len(m.group(1))
        status = "tamam" if n <= limit else "SINIR AŞILDI"
        ok &= n <= limit
        print(f"{title}: {n}/{limit} {status}")
    # Sürüm notları: etiketler arasındaki metin en fazla 500 karakter.
    for i, m in enumerate(re.finditer(r"<tr-TR>\n(.*?)\n</tr-TR>", text, re.S), 1):
        n = len(m.group(1))
        status = "tamam" if n <= 500 else "SINIR AŞILDI"
        ok &= n <= 500
        print(f"Sürüm notu {i}: {n}/500 {status}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()

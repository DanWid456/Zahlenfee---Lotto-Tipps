#!/usr/bin/env python3
"""Erzeugt alle App-Symbole aus branding/icon.svg (Entwurf B2 "Zauberstab mit Lotto-Kugel").

Benötigt: pip install cairosvg pillow, Schrift "Inter" (ExtraBold) installiert.
Ausgabe unter branding/: Android (klassisch + adaptiv), iOS, Play Store.
"""
import io
import re
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent / 'branding'
SRC = (ROOT / 'icon.svg').read_text()
BG = '#0F4A31'

# Inhalt ohne Hintergrund-Rechteck
ART = re.sub(r'<rect [^>]*/>', '', re.search(r'<svg[^>]*>(.*)</svg>', SRC, re.S).group(1), count=1)


def svg(inner, bg=None, rx=0):
    rect = f'<rect width="512" height="512" rx="{rx}" fill="{bg}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">{rect}{inner}</svg>'


def render(svg_text, size):
    png = cairosvg.svg2png(bytestring=svg_text.encode(), output_width=size, output_height=size)
    return Image.open(io.BytesIO(png)).convert('RGBA')


def save(img, path, rgb=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    (img.convert('RGB') if rgb else img).save(path, optimize=True)


full_square = svg(ART, BG)  # iOS, Play Store: Ecken rundet das System
full_rounded = svg(ART, BG, rx=112)  # klassisches Android-Symbol
# Adaptives Android-Symbol: Motiv auf 66 % verkleinert und zentriert, damit es
# in der sicheren Zone (66 von 108 dp) bleibt, egal welche Maske das Gerät nutzt.
k = 0.66
cx, cy = 280, 243  # Mitte des Motivs
fg = svg(f'<g transform="translate({256 - cx * k} {256 - cy * k}) scale({k})">{ART}</g>')

# --- Android
dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
res = ROOT / 'android' / 'res'
for name, d in dens.items():
    s = round(48 * d)
    save(render(full_rounded, s), res / f'mipmap-{name}' / 'ic_launcher.png')
    rnd = render(full_square, s)
    mask = Image.new('L', (s, s), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, s - 1, s - 1), fill=255)
    rnd.putalpha(mask)
    save(rnd, res / f'mipmap-{name}' / 'ic_launcher_round.png')
    save(render(fg, round(108 * d)), res / f'mipmap-{name}' / 'ic_launcher_foreground.png')
(res / 'mipmap-anydpi-v26').mkdir(parents=True, exist_ok=True)
adaptive = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
for n in ('ic_launcher.xml', 'ic_launcher_round.xml'):
    (res / 'mipmap-anydpi-v26' / n).write_text(adaptive)
(res / 'values').mkdir(parents=True, exist_ok=True)
(res / 'values' / 'ic_launcher_background.xml').write_text(
    f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">{BG}</color>\n</resources>\n')

# --- iOS (Dateinamen wie in der Flutter-Vorlage, Contents.json bleibt)
ios = ROOT / 'ios' / 'AppIcon.appiconset'
for pt, scales in {20: (1, 2, 3), 29: (1, 2, 3), 40: (1, 2, 3), 60: (2, 3), 76: (1, 2), 83.5: (2,), 1024: (1,)}.items():
    for sc in scales:
        label = f'{pt:g}x{pt:g}'
        save(render(full_square, round(pt * sc)), ios / f'Icon-App-{label}@{sc}x.png', rgb=True)

# --- Play Store und Vorschau
save(render(full_square, 512), ROOT / 'play_store_512.png', rgb=True)
save(render(full_square, 1024), ROOT / 'icon_1024.png', rgb=True)
print('Symbole erzeugt in', ROOT)

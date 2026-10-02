"""
Génère les planches d'images du jeu dans assets/ :
  cards_1.png .. cards_3.png : illustrations des cartes (cases de 256 x 200, 4 x 5 par planche)
  icons_1.png, icons_2.png   : icônes de l'interface (cases de 256 x 256, 4 x 4 par planche)
et src/shared/ImageAtlas.luau (position de chaque image dans sa planche).

Usage : python3 tools/art/make_art.py [--preview]
Il faut numpy, pillow et scipy.
"""

import os
import re
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))

import cards_art  # noqa: E402
import icons_art  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "assets")

CARD_RE = re.compile(
    r'card\("(\w+)", "([^"]+)", "(\w+)", [\d.]+, rgb\((\d+), (\d+), (\d+)\), rgb\((\d+), (\d+), (\d+)\)(?:, "(\w+)")?\)'
)


def load_cards():
    src = open(os.path.join(ROOT, "src", "shared", "Cards.luau"), encoding="utf-8").read()
    out = []
    for m in CARD_RE.finditer(src):
        g = m.groups()
        out.append({
            "Id": g[0],
            "Name": g[1],
            "Rarity": g[2],
            "A": tuple(int(x) for x in g[3:6]),
            "B": tuple(int(x) for x in g[6:9]),
            "Season": g[9] or "-",
        })
    return out


def sheets(items, cw, ch, cols, rows, prefix):
    """items : liste de (clé, image). Renvoie {clé: (planche, x, y)}"""
    per = cols * rows
    rects = {}
    for s in range(0, len(items), per):
        sheet = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        n = s // per + 1
        for i, (key, img) in enumerate(items[s : s + per]):
            x, y = (i % cols) * cw, (i // cols) * ch
            sheet.paste(img, (x, y))
            rects[key] = (n, x, y)
        sheet.save(os.path.join(ASSETS, f"{prefix}_{n}.png"), optimize=True)
    return rects


def write_luau(card_rects, icon_rects):
    lines = [
        "-- Fichier généré par tools/art/make_art.py : ne pas modifier à la main.",
        "-- Position de chaque image dans sa planche (assets/*.png).",
        "-- Les IDs des planches uploadées se mettent dans Config.Images.",
        "",
        "local ImageAtlas = {}",
        "",
        "ImageAtlas.CardSize = Vector2.new(256, 200)",
        "ImageAtlas.IconSize = Vector2.new(256, 256)",
        "",
        "-- [id] = { planche, x, y }",
        "ImageAtlas.Cards = {",
    ]
    for k, (n, x, y) in card_rects.items():
        lines.append(f"\t{k} = {{ {n}, {x}, {y} }},")
    lines += ["}", "", "ImageAtlas.Icons = {"]
    for k, (n, x, y) in icon_rects.items():
        lines.append(f"\t{k} = {{ {n}, {x}, {y} }},")
    lines += ["}", "", "return ImageAtlas", ""]
    with open(os.path.join(ROOT, "src", "shared", "ImageAtlas.luau"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    os.makedirs(ASSETS, exist_ok=True)
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    cards = load_cards()
    assert len(cards) == 46, len(cards)
    if "--preview" in sys.argv:
        # aperçu rapide de quelques cartes / icônes
        pick = [c for c in cards if not only or c["Id"] in only]
        imgs = [cards_art.render(c) for c in pick]
        cols = min(6, len(imgs))
        rows = (len(imgs) + cols - 1) // cols
        sheet = Image.new("RGBA", (cols * 260, rows * 204), (30, 30, 40, 255))
        for i, im in enumerate(imgs):
            sheet.paste(im, ((i % cols) * 260, (i // cols) * 204), im)
        sheet.save(os.path.join(ROOT, "build", "art_preview.png"))
        return
    card_items = []
    for c in cards:
        print("carte", c["Id"], flush=True)
        card_items.append((c["Id"], cards_art.render(c)))
    icon_items = []
    for name in icons_art.ORDER:
        print("icône", name, flush=True)
        icon_items.append((name, icons_art.render(name)))
    card_rects = sheets(card_items, 256, 200, 4, 5, "cards")
    icon_rects = sheets(icon_items, 256, 256, 4, 4, "icons")
    write_luau(card_rects, icon_rects)
    print("ok")


if __name__ == "__main__":
    main()

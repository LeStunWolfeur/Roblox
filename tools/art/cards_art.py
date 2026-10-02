"""
Illustrations des 46 cartes (256 x 200 chacune).
Chaque carte a son propre personnage dessiné à la main avec artkit.
"""

import math
import random

import numpy as np

from artkit import ARC, BEZ, CAP, E, INK, RR, STAR, STROKE, WHITE, Canvas, cheeks, dark, eyes, hsv, light, mix, smile, sparkle

W, H = 256, 200
CX, CY = 128, 112

RARITY = {
    "Common": (180, 185, 195),
    "Uncommon": (90, 210, 120),
    "Rare": (70, 150, 255),
    "Epic": (170, 90, 255),
    "Legendary": (255, 180, 30),
    "Mythic": (255, 60, 110),
    "Secret": (20, 20, 20),
}
ORDER = {"Common": 1, "Uncommon": 2, "Rare": 3, "Epic": 4, "Legendary": 5, "Mythic": 6, "Secret": 7}

GOLD = (255, 200, 40)
SILVER = (205, 212, 225)
RED = (235, 50, 70)
PINK = (255, 120, 150)


# --------------------------------------------------------------- décor


def background(c, card):
    a, b = card["A"], card["B"]
    rar = card["Rarity"]
    order = ORDER[rar]
    yy, xx = np.mgrid[0 : c.H, 0 : c.W].astype(np.float32)
    cx, cy = CX * 4, 96 * 4
    r = np.sqrt((xx - cx) ** 2 + ((yy - cy) * 1.15) ** 2) / (c.W * 0.62)
    r = np.clip(r, 0, 1)[..., None]
    if rar == "Secret":
        inner, outer = np.array(mix(b, (0, 0, 0), 0.35), np.float32), np.array((8, 6, 14), np.float32)
    else:
        inner = np.array(light(a, 0.55), np.float32)
        outer = np.array(dark(mix(a, b, 0.55), 0.25), np.float32)
    c.rgb = inner * (1 - r) + outer * r
    c.a[:] = 1
    # rayons
    ang = np.arctan2(yy - cy, xx - cx)
    n = 9 if order < 5 else 12
    rays = (np.sin(ang * n + 0.3) > 0.25).astype(np.float32)
    fade = np.clip(1 - r[..., 0] * 0.9, 0, 1)
    ray_col = (255, 255, 255) if rar != "Secret" else mix(b, (255, 255, 255), 0.1)
    c.over(ray_col, rays * fade * (0.10 + 0.02 * order))
    # motifs de saison très discrets
    rnd = random.Random(card["Id"])
    season = card["Season"]
    if season != "-":
        for _ in range(7):
            x, y = rnd.uniform(10, 246), rnd.uniform(10, 190)
            if abs(x - CX) < 70 and y > 30:
                continue
            s = rnd.uniform(7, 12)
            motif(c, season, x, y, s, 0.28)
    # étoiles / poussière selon la rareté
    if order >= 3:
        for _ in range(4 + order * 2):
            x, y = rnd.uniform(8, 248), rnd.uniform(8, 192)
            if abs(x - CX) < 60 and 40 < y < 180:
                continue
            col = WHITE if rar != "Secret" else b
            sparkle(c, x, y, rnd.uniform(2.5, 5.5), col, 0.85)
    if order >= 6:
        # halo coloré derrière le personnage
        m = c.mask(E(CX, 104, 84, 74))
        c.glow(m, light(RARITY[rar], 0.3) if rar != "Secret" else b, 14, 0.35)
    # sol
    c.shadow(CX, 178, 62, 9, 0.3)


def motif(c, season, x, y, s, alpha):
    if season == "Halloween":
        c.flat(c.mask(E(x, y, s, s * 0.8)), (255, 140, 30), alpha)
        c.flat(c.mask(RR(x, y - s * 0.9, s * 0.25, s * 0.5, 1)), (60, 120, 40), alpha)
    elif season == "Winter":
        for k in range(3):
            c.flat(c.mask(RR(x, y, s * 2, s * 0.22, 1, k * 60)), WHITE, alpha + 0.1)
    elif season == "Spring":
        for k in range(5):
            a = math.radians(k * 72)
            c.flat(c.mask(E(x + math.cos(a) * s * 0.55, y + math.sin(a) * s * 0.55, s * 0.45)), (255, 190, 220), alpha + 0.1)
        c.flat(c.mask(E(x, y, s * 0.3)), (255, 230, 120), alpha + 0.1)
    elif season == "Summer":
        c.flat(c.mask(E(x, y, s * 0.6)), (255, 230, 90), alpha + 0.1)
        for k in range(8):
            c.flat(c.mask(RR(x, y, s * 1.9, s * 0.16, 1, k * 22.5)), (255, 230, 90), alpha * 0.8)


# ------------------------------------------------------------ membres


def feet(c, cx, y, gap, color, rx=13, ry=8):
    for s in (-1, 1):
        c.fill(c.mask(E(cx + s * gap, y, rx, ry)), color, gloss=0.3)


def arms(c, cx, y, gap, color, lift=(0, 0), length=22, r=6.5):
    """lift : (gauche, droite) en degrés, 0 = pendant, 90 = levé à l'horizontale"""
    for s, l in ((-1, lift[0]), (1, lift[1])):
        a = math.radians(90 + s * l)
        x1 = cx + s * gap
        x2 = x1 + math.cos(a) * length * s * (1 if l <= 90 else 1)
        y2 = y + math.sin(a) * length
        x2 = x1 + s * abs(math.cos(math.radians(90 - l))) * length
        y2 = y + math.cos(math.radians(l)) * length
        c.fill(c.mask(CAP(x1, y, x2, y2, r)), color, ol=2.6, gloss=0.25)


def standard_face(c, cx, cy, gap=16, r=9, mouth=9, blush=True, **kw):
    eyes(c, cx, cy, gap, r, **kw)
    smile(c, cx, cy + r + 8, mouth)
    if blush:
        cheeks(c, cx, cy + r + 4, gap + r * 0.9, 5)


def crown(c, cx, cy, w, color=GOLD, gem=RED, rot=0):
    pts = [(-w / 2, 0), (-w / 2, -w * 0.42), (-w * 0.27, -w * 0.18), (0, -w * 0.55), (w * 0.27, -w * 0.18), (w / 2, -w * 0.42), (w / 2, 0)]
    pts = [(cx + x * math.cos(math.radians(rot)) - y * math.sin(math.radians(rot)), cy + x * math.sin(math.radians(rot)) + y * math.cos(math.radians(rot))) for x, y in pts]
    c.fill(c.mask(pts), color, ol=2.6, gloss=0.6)
    c.fill(c.mask(E(cx, cy - w * 0.14, w * 0.08)), gem, ol=1.5, gloss=0.6)
    for s in (-1, 1):
        c.fill(c.mask(E(cx + s * w * 0.32, cy - w * 0.12, w * 0.055)), (90, 200, 255), ol=1.2, gloss=0.5)


def wings(c, cx, cy, span, color, feather=True, rot=18):
    for s in (-1, 1):
        x = cx + s * span
        m = c.mask(E(x, cy, span * 0.55, span * 0.32, s * -rot))
        for k in range(3):
            m |= c.mask(E(x + s * span * 0.08 * k, cy + span * 0.18 + k * span * 0.1, span * (0.45 - k * 0.09), span * 0.14, s * -rot))
        c.fill(m, color, ol=2.6, gloss=0.4)


def halo(c, cx, cy, rx, color=(255, 235, 120)):
    m = c.mask(E(cx, cy, rx, rx * 0.28), sub=[E(cx, cy, rx * 0.72, rx * 0.15)])
    c.glow(m, color, 4, 0.7)
    c.fill(m, color, ol=2, gloss=0.4)


def lightning(c, x, y, s, color=(255, 230, 60), rot=0):
    pts = [(0.1, -1), (-0.45, 0.1), (-0.02, 0.1), (-0.2, 1), (0.5, -0.2), (0.05, -0.2), (0.3, -1)]
    pts = [(x + (px * math.cos(math.radians(rot)) - py * math.sin(math.radians(rot))) * s, y + (px * math.sin(math.radians(rot)) + py * math.cos(math.radians(rot))) * s) for px, py in pts]
    m = c.mask(pts)
    c.glow(m, color, 3, 0.6)
    c.fill(m, color, ol=2.2, gloss=0.4)


def body_blob(c, cx, cy, w, h, color, **kw):
    m = c.mask(E(cx, cy, w, h))
    return c.fill(m, color, **kw)


# ---------------------------------------------------------- personnages
# Chaque fonction reçoit (c, card). a = couleur principale, b = secondaire.


def toastini(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 172, 20, dark(b, 0.1))
    crust = c.mask(E(CX - 26, 66, 30, 28), E(CX + 26, 66, 30, 28), RR(CX, 116, 108, 104, 22))
    c.fill(crust, b, ol=3.2)
    inner = c.mask(E(CX - 24, 70, 23, 21), E(CX + 24, 70, 23, 21), RR(CX, 118, 92, 90, 16))
    c.fill(inner, a, ol=0, gloss=0.45, rim=0.6)
    # beurre
    c.fill(c.mask(RR(CX + 18, 80, 30, 20, 5, -8)), (255, 238, 140), ol=2, gloss=0.7)
    arms(c, CX, 124, 54, b, lift=(30, 60))
    standard_face(c, CX, 112, 20, 10, 10)


def sockrates(c, k):
    a, b = k["A"], k["B"]
    sock = c.mask(RR(CX - 4, 82, 64, 110, 26), RR(CX + 18, 148, 100, 52, 26))
    c.fill(sock, a, ol=3.2)
    for i in range(3):
        c.flat(c.mask(RR(CX - 4, 46 + i * 13, 64, 6, 2)) & sock, b, 0.9)
    c.fill(c.mask(RR(CX - 4, 32, 70, 18, 8)), light(a, 0.1), ol=2.6)
    c.fill(c.mask(E(CX + 52, 150, 16, 22)) & sock, b, ol=0, gloss=0.3)
    # barbe de philosophe
    c.fill(c.mask(E(CX - 4, 132, 26, 22)), WHITE, ol=2.4, gloss=0.3)
    eyes(c, CX - 4, 98, 13, 8, sleepy=light(a, 0.05))
    c.flat(c.mask(RR(CX - 4, 120, 18, 4, 2)), INK)
    # petit parchemin
    c.fill(c.mask(RR(CX - 50, 132, 18, 34, 4, 12)), (250, 235, 195), ol=2.4, gloss=0.3)


def bloop(c, k):
    a, b = k["A"], k["B"]
    m = c.mask(E(CX, 128, 60, 48), E(CX, 96, 40, 44), [(CX - 14, 60), (CX, 34), (CX + 14, 60)])
    c.fill(m, a, ol=3.2, gloss=0.7)
    c.fill(c.mask(E(CX, 140, 34, 24)), light(a, 0.35), ol=0, gloss=0, rim=0)
    for x, y, r in ((CX - 70, 150, 6), (CX + 72, 140, 8), (CX + 60, 64, 5)):
        c.fill(c.mask(E(x, y, r)), light(a, 0.2), ol=2, gloss=0.8)
    standard_face(c, CX, 108, 18, 11, 10)


def pebblepete(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 172, 24, dark(a, 0.2))
    m = c.mask([(CX - 64, 150), (CX - 70, 110), (CX - 48, 72), (CX - 10, 58), (CX + 34, 64), (CX + 66, 96), (CX + 68, 140), (CX + 40, 168), (CX - 30, 170)])
    c.fill(m, a, ol=3.2, gloss=0.35)
    for x, y, r in ((CX - 36, 140, 6), (CX + 40, 84, 5), (CX + 46, 140, 7), (CX - 40, 90, 4)):
        c.fill(c.mask(E(x, y, r, r * 0.7)), dark(a, 0.18), ol=0, gloss=0, rim=0)
    # mousse
    c.fill(c.mask(E(CX - 20, 62, 22, 9), E(CX - 4, 56, 12, 8)), (110, 190, 80), ol=2.2, gloss=0.4)
    eyes(c, CX, 108, 18, 8, look=(0.3, 0.1))
    smile(c, CX, 128, 8, open_=False)


def mrnoodle(c, k):
    a, b = k["A"], k["B"]
    # nouilles qui débordent
    for i in range(6):
        x = CX - 40 + i * 16
        c.fill(c.mask(STROKE(BEZ((x, 72), (x + (8 if i % 2 else -8), 50), (x + 4, 36 + (i % 3) * 6)), 4.5)), a, ol=2, gloss=0.3, rim=0)
    cup = c.mask([(CX - 58, 68), (CX + 58, 68), (CX + 44, 172), (CX - 44, 172)])
    c.fill(cup, (250, 248, 240), ol=3.2, gloss=0.5)
    c.flat(c.mask(RR(CX, 92, 120, 22, 0)) & cup, b, 1)
    c.flat(c.mask(STAR(CX, 92, 9, 4, 5)), (255, 240, 200), 1)
    c.fill(c.mask(RR(CX, 68, 124, 14, 6)), (240, 238, 230), ol=2.6, gloss=0.4)
    # baguettes
    c.fill(c.mask(CAP(CX + 30, 70, CX + 80, 26, 3.5)), (190, 130, 70), ol=2)
    c.fill(c.mask(CAP(CX + 40, 72, CX + 92, 34, 3.5)), (190, 130, 70), ol=2)
    standard_face(c, CX, 128, 18, 9, 9)


def cardboardcarl(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 174, 24, dark(a, 0.3), 12, 7)
    c.fill(c.mask([(CX - 58, 70), (CX - 92, 50), (CX - 76, 40), (CX - 50, 62)]), dark(a, 0.08), ol=2.8, gloss=0.2)
    c.fill(c.mask([(CX + 58, 70), (CX + 92, 50), (CX + 76, 40), (CX + 50, 62)]), dark(a, 0.08), ol=2.8, gloss=0.2)
    box = c.mask(RR(CX, 118, 116, 104, 6))
    c.fill(box, a, ol=3.2, gloss=0.35)
    c.flat(c.mask(RR(CX, 74, 116, 10, 2)), (225, 200, 150), 0.9)
    c.flat(c.mask(RR(CX + 36, 152, 20, 14, 2)), dark(a, 0.25), 0.8)
    c.flat(c.mask(STROKE([(CX + 30, 152), (CX + 36, 158), (CX + 44, 146)], 1.6)), light(a, 0.3))
    arms(c, CX, 120, 60, dark(a, 0.1), lift=(20, 120), length=24)
    standard_face(c, CX, 108, 22, 10, 10)


def wobbles(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(E(CX, 172, 70, 12)), (240, 240, 250), ol=2.6, gloss=0.3)
    m = c.mask([(CX - 60, 168), (CX - 52, 92), (CX - 30, 66), (CX + 30, 66), (CX + 52, 92), (CX + 60, 168)], E(CX, 72, 34, 14))
    c.fill(m, a, ol=3.2, gloss=0.8, alpha=0.95)
    c.flat(c.mask(RR(CX, 140, 110, 4, 2)), light(a, 0.3), 0.7)
    c.fill(c.mask(E(CX, 56, 10)), RED, ol=2.2, gloss=0.8)
    c.flat(c.mask(STROKE(BEZ((CX, 48), (CX + 4, 36), (CX + 12, 32)), 1.6)), (70, 130, 40))
    eyes(c, CX, 106, 17, 9, look=(-0.2, 0.15))
    smile(c, CX, 128, 8)
    cheeks(c, CX, 122, 28, 5, b)


def spaghettron(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 174, 22, (130, 135, 150), 12, 7)
    c.fill(c.mask(CAP(CX, 34, CX, 54, 2.5)), (150, 155, 170), ol=2)
    c.fill(c.mask(E(CX, 30, 7)), b, ol=2, gloss=0.8)
    head = c.mask(RR(CX, 110, 108, 104, 22))
    c.fill(head, (190, 196, 210), ol=3.2, gloss=0.55)
    # spaghettis sur la tête
    for i in range(7):
        x = CX - 48 + i * 16
        c.fill(c.mask(STROKE(BEZ((x, 64), (x + 10, 84 + (i % 2) * 10), (x - 4, 96 + (i % 3) * 8)), 4)), a, ol=1.8, gloss=0.2, rim=0)
    c.fill(c.mask(E(CX - 8, 64, 40, 14)), a, ol=2.4, gloss=0.3)
    c.fill(c.mask(E(CX + 24, 58, 12)), b, ol=2.2, gloss=0.6)
    # visière
    c.fill(c.mask(RR(CX, 116, 86, 34, 14)), (30, 34, 50), ol=2.6, gloss=0.4)
    eyes(c, CX, 116, 20, 9, style="glow", color=(120, 255, 240))
    c.flat(c.mask(RR(CX, 146, 40, 6, 3)), (60, 64, 80))
    arms(c, CX, 128, 58, (150, 155, 170), lift=(20, 40))


def bananaut(c, k):
    a, b = k["A"], k["B"]
    # petit réacteur
    for x in (-14, 14):
        f = c.mask(E(CX + x - 16, 172, 7, 12))
        c.glow(f, (255, 160, 60), 3, 0.7)
        c.flat(f, (255, 200, 80))
    # banane
    m = c.mask(STROKE(BEZ((CX - 30, 160), (CX + 50, 130), (CX + 20, 50)), 24))
    c.fill(m, a, ol=3.2, gloss=0.5)
    c.fill(c.mask(E(CX + 20, 42, 6, 9)), (110, 80, 40), ol=2)
    # casque
    helm = c.mask(E(CX + 8, 104, 44, 40))
    c.fill(helm, (190, 230, 255), ol=3, gloss=0.9, alpha=0.45, rim=0)
    c.fill(c.mask(RR(CX + 8, 144, 72, 12, 6)), (200, 205, 220), ol=2.6)
    eyes(c, CX + 8, 100, 14, 8)
    smile(c, CX + 8, 118, 7)
    # drapeau
    c.fill(c.mask(CAP(CX - 70, 172, CX - 70, 92, 2.5)), (160, 165, 180), ol=2)
    c.fill(c.mask([(CX - 68, 94), (CX - 36, 102), (CX - 68, 114)]), b, ol=2.2)


def cactuso(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask([(CX - 50, 134), (CX + 50, 134), (CX + 40, 178), (CX - 40, 178)]), (215, 110, 70), ol=3)
    c.fill(c.mask(RR(CX, 134, 112, 14, 5)), (235, 130, 85), ol=2.6)
    m = c.mask(RR(CX, 92, 54, 104, 27), CAP(CX - 27, 104, CX - 50, 104, 11), CAP(CX - 50, 104, CX - 50, 72, 11), CAP(CX + 27, 92, CX + 48, 92, 11), CAP(CX + 48, 92, CX + 48, 66, 11))
    c.fill(m, a, ol=3.2, gloss=0.5)
    for x, y in ((CX - 14, 64), (CX + 16, 80), (CX - 18, 116), (CX + 12, 120), (CX - 50, 82), (CX + 48, 74)):
        c.flat(c.mask(STROKE([(x - 3, y - 3), (x + 3, y + 3)], 1)) | c.mask(STROKE([(x + 3, y - 3), (x - 3, y + 3)], 1)), light(a, 0.6))
    # fleur et sombrero
    c.fill(c.mask(E(CX, 40, 46, 9)), b, ol=2.6, gloss=0.3)
    c.fill(c.mask(E(CX, 32, 18, 14)), b, ol=2.6, gloss=0.4)
    c.flat(c.mask(RR(CX, 37, 36, 4, 2)), RED)
    eyes(c, CX, 84, 12, 7)
    smile(c, CX, 102, 7)


def duckmaster(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 22, b, 14, 6)
    c.fill(c.mask(E(CX, 140, 52, 36), [(CX + 40, 130), (CX + 72, 116), (CX + 52, 150)]), a, ol=3.2, gloss=0.4)
    c.fill(c.mask(E(CX - 30, 142, 22, 14, -20)), dark(a, 0.08), ol=2.4, gloss=0.2)
    c.fill(c.mask(E(CX - 6, 86, 36, 34)), a, ol=3.2, gloss=0.6)
    c.fill(c.mask(E(CX - 6, 108, 26, 10)), b, ol=2.6, gloss=0.5)
    eyes(c, CX - 6, 82, 14, 8, angry=True)
    # bandeau de karaté
    c.fill(c.mask(RR(CX - 6, 64, 70, 10, 4)), RED, ol=2.4, gloss=0.3)
    c.fill(c.mask(CAP(CX + 30, 64, CX + 52, 80, 4), CAP(CX + 30, 64, CX + 56, 66, 4)), RED, ol=2.2)
    c.fill(c.mask(RR(CX, 150, 70, 8, 3)), (30, 30, 36), ol=2)


def jellybyte(c, k):
    a, b = k["A"], k["B"]
    for i in range(5):
        x = CX - 36 + i * 18
        c.fill(c.mask(STROKE(BEZ((x, 120), (x + (10 if i % 2 else -10), 150), (x + 4, 178)), 4.5)), b, ol=2, gloss=0.2, rim=0)
    m = c.mask(E(CX, 96, 60, 52), sub=[RR(CX, 150, 140, 40, 0)])
    m |= c.mask(RR(CX, 124, 120, 12, 6))
    c.fill(m, a, ol=3.2, gloss=0.85, alpha=0.92)
    # circuits
    for x, y in ((CX - 34, 70), (CX + 30, 74), (CX - 14, 54)):
        c.flat(c.mask(E(x, y, 4)), b, 0.8)
    c.flat(c.mask(STROKE([(CX - 34, 70), (CX - 34, 60), (CX - 14, 54)], 1.4)), b, 0.8)
    eyes(c, CX, 98, 18, 9)
    smile(c, CX, 118, 7)


def captaincrumb(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 174, 22, (60, 40, 30), 13, 7)
    cookie = c.mask(E(CX, 116, 62, 58))
    c.fill(cookie, b, ol=3.2, gloss=0.45)
    rnd = random.Random(4)
    for _ in range(9):
        x, y = rnd.uniform(-44, 44), rnd.uniform(-32, 48)
        c.fill(c.mask(E(CX + x, 116 + y, rnd.uniform(4, 6.5), rnd.uniform(3, 5), rnd.uniform(0, 90))), (95, 55, 30), ol=0, gloss=0.2, rim=0)
    # bicorne de capitaine
    hat = c.mask(E(CX, 64, 62, 22), sub=[RR(CX, 76, 140, 24, 0)])
    c.fill(hat, a, ol=3, gloss=0.4)
    c.fill(c.mask(RR(CX, 64, 128, 8, 4)), GOLD, ol=2.2)
    c.fill(c.mask(STAR(CX, 52, 9, 4)), GOLD, ol=1.8)
    eyes(c, CX - 18, 106, 0, 9)
    c.fill(c.mask(E(CX + 20, 106, 13, 11)), INK, ol=1.5, gloss=0.3)
    c.flat(c.mask(CAP(CX + 8, 100, CX + 54, 84, 1.6)), INK)
    smile(c, CX, 134, 10, teeth=True)


def turbotortellini(c, k):
    a, b = k["A"], k["B"]
    for i in range(3):
        c.flat(c.mask(RR(CX - 92 + i * 6, 100 + i * 22, 34 - i * 6, 5, 2)), WHITE, 0.8)
    feet(c, CX, 176, 22, dark(b, 0.35), 13, 6)
    body = c.mask(E(CX - 34, 132, 34, 36, 20), E(CX + 34, 132, 34, 36, -20), E(CX, 120, 56, 44))
    c.fill(body, b, ol=3.2, gloss=0.5)
    c.fill(c.mask(E(CX, 158, 22, 14)), dark(b, 0.12), ol=2.4, gloss=0.2)
    c.fill(c.mask(E(CX, 158, 10, 6)), dark(b, 0.4), ol=0, gloss=0, rim=0)
    for x in (-40, 40):
        c.flat(c.mask(STROKE(BEZ((CX + x * 0.4, 168), (CX + x, 150), (CX + x * 1.2, 110)), 1.4)), dark(b, 0.2), 0.7)
    # casque de course
    helm = c.mask(E(CX, 78, 44, 36), sub=[RR(CX, 116, 120, 24, 0)])
    c.fill(helm, a, ol=3, gloss=0.8)
    c.flat(c.mask(RR(CX - 6, 64, 8, 34, 3)) & helm, WHITE, 0.9)
    c.flat(c.mask(RR(CX + 8, 64, 8, 34, 3)) & helm, WHITE, 0.9)
    c.fill(c.mask(RR(CX + 6, 92, 60, 14, 6)), (40, 50, 80), ol=2.4, gloss=0.6)
    eyes(c, CX, 120, 17, 8, angry=True)
    smile(c, CX, 140, 8, teeth=True)


def neonnana(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 174, 20, (90, 60, 120), 12, 7)
    c.fill(c.mask(RR(CX, 150, 80, 50, 22)), a, ol=3, gloss=0.4)
    head = c.mask(E(CX, 100, 46, 44))
    c.fill(c.mask(E(CX, 56, 22, 18), E(CX - 40, 84, 16), E(CX + 40, 84, 16)), (225, 225, 240), ol=3, gloss=0.4)
    c.fill(head, (255, 210, 180), ol=3.2, gloss=0.5)
    c.fill(c.mask(E(CX, 66, 40, 16)), (225, 225, 240), ol=2.4, gloss=0.4)
    # lunettes néon
    for s in (-1, 1):
        g = c.mask(RR(CX + s * 20, 100, 32, 22, 8))
        c.glow(g, b, 4, 0.7)
        c.fill(g, b, ol=2.4, gloss=0.6)
    c.flat(c.mask(RR(CX, 98, 10, 4, 2)), INK)
    smile(c, CX, 124, 9)
    cheeks(c, CX, 116, 30, 5)
    c.fill(c.mask(CAP(CX + 50, 176, CX + 56, 112, 3)), b, ol=2)
    c.fill(c.mask(E(CX + 56, 110, 7)), b, ol=2, gloss=0.6)


def sirpickles(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 20, dark(a, 0.3), 12, 6)
    m = c.mask(RR(CX, 116, 68, 124, 34))
    c.fill(m, a, ol=3.2, gloss=0.5)
    rnd = random.Random(7)
    for _ in range(10):
        c.fill(c.mask(E(CX + rnd.uniform(-24, 24), 116 + rnd.uniform(-50, 50), 3.2)), light(a, 0.2), ol=0, gloss=0.3, rim=0)
    # haut-de-forme
    c.fill(c.mask(RR(CX, 54, 76, 9, 4)), (30, 30, 36), ol=2.6, gloss=0.3)
    c.fill(c.mask(RR(CX, 32, 46, 40, 6)), (30, 30, 36), ol=2.6, gloss=0.4)
    c.flat(c.mask(RR(CX, 44, 46, 7, 0)), RED)
    eyes(c, CX - 14, 96, 0, 8)
    mono = c.mask(E(CX + 14, 96, 11), sub=[E(CX + 14, 96, 8.5)])
    c.fill(mono, GOLD, ol=1.6, gloss=0.4)
    eyes(c, CX + 14, 96, 0, 7)
    c.flat(c.mask(CAP(CX + 24, 102, CX + 30, 140, 1)), GOLD)
    # moustache
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 12, 116, 13, 5, s * -12)), (60, 40, 30), ol=1.8, gloss=0.2)
    c.fill(c.mask(RR(CX, 138, 30, 10, 4)), RED, ol=2)


def glitchygus(c, k):
    a, b = k["A"], k["B"]
    for dx, col, al in ((-6, (255, 40, 120), 0.6), (6, (40, 200, 255), 0.6)):
        c.flat(c.mask(RR(CX + dx, 110, 100, 100, 6)), col, al)
    m = c.mask(RR(CX, 110, 100, 100, 6))
    c.fill(m, b, ol=3.2, gloss=0.4)
    for i in range(5):
        for j in range(5):
            if (i * 7 + j * 3) % 4 == 0:
                c.flat(c.mask(RR(CX - 40 + i * 20, 70 + j * 20, 16, 16, 1)), a, 0.25)
    for s in (-1, 1):
        c.fill(c.mask(RR(CX + s * 22, 98, 20, 20, 1)), a, ol=0, gloss=0, rim=0)
        c.flat(c.mask(RR(CX + s * 22 + 4, 94, 6, 6, 0)), WHITE)
    c.fill(c.mask(RR(CX, 130, 40, 8, 0), RR(CX - 24, 124, 8, 8, 0), RR(CX + 24, 124, 8, 8, 0)), a, ol=0, gloss=0, rim=0)
    c.flat(c.mask(RR(CX + 60, 80, 34, 4, 0)), a, 0.8)
    c.flat(c.mask(RR(CX - 62, 140, 26, 4, 0)), (255, 40, 120), 0.8)


def pizzasaurus(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(STROKE(BEZ((CX - 40, 150), (CX - 90, 160), (CX - 100, 120)), 10)), b, ol=3, gloss=0.3)
    feet(c, CX, 174, 26, dark(b, 0.15), 15, 8)
    body = c.mask(E(CX, 138, 52, 38), E(CX + 14, 84, 40, 36))
    c.fill(body, b, ol=3.2, gloss=0.45)
    # pointes = parts de pizza
    for i, (x, y, r) in enumerate(((CX - 34, 108, -40), (CX - 10, 76, -20), (CX + 18, 54, 0))):
        pts = [(x - 12, y + 6), (x + 12, y + 6), (x, y - 20)]
        from artkit import rot_pts

        pts = rot_pts([(px - x, py - y) for px, py in pts], x, y, r)
        c.fill(c.mask(pts), a, ol=2.4, gloss=0.4)
        c.fill(c.mask(E(x, y - 2, 3.5)), RED, ol=0, gloss=0.4, rim=0)
    c.fill(c.mask(E(CX + 2, 146, 30, 22)), light(b, 0.35), ol=0, gloss=0, rim=0)
    eyes(c, CX + 18, 80, 14, 8)
    smile(c, CX + 24, 102, 10, teeth=True, fang=True)
    arms(c, CX, 128, 40, b, lift=(60, 70), length=14, r=5)


def roboraccoon(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(STROKE(BEZ((CX + 40, 156), (CX + 90, 150), (CX + 92, 100)), 13)), a, ol=3, gloss=0.3)
    for i in range(3):
        c.flat(c.mask(E(CX + 80 + i * 4, 140 - i * 16, 12, 4, -60)), b)
    feet(c, CX, 176, 20, b, 12, 6)
    c.fill(c.mask(RR(CX, 150, 70, 46, 18)), a, ol=3, gloss=0.4)
    c.fill(c.mask(RR(CX, 150, 30, 20, 4)), (40, 220, 255), ol=2, gloss=0.6)
    head = c.mask(RR(CX, 92, 104, 76, 30), [(CX - 50, 66), (CX - 40, 30), (CX - 18, 58)], [(CX + 50, 66), (CX + 40, 30), (CX + 18, 58)])
    c.fill(head, a, ol=3.2, gloss=0.55)
    c.fill(c.mask(RR(CX, 92, 92, 28, 14)), b, ol=0, gloss=0.2, rim=0)
    for x, y in ((CX - 40, 70), (CX + 40, 70), (CX - 44, 112), (CX + 44, 112)):
        c.fill(c.mask(E(x, y, 3)), (120, 125, 140), ol=1, gloss=0.6, rim=0)
    eyes(c, CX, 92, 22, 9, style="glow", color=(255, 80, 70))
    c.fill(c.mask(E(CX, 114, 7, 5)), INK, ol=0, gloss=0.4, rim=0)


def thundertaco(c, k):
    a, b = k["A"], k["B"]
    lightning(c, CX - 84, 64, 26, (255, 240, 90), -15)
    lightning(c, CX + 86, 58, 22, (255, 240, 90), 20)
    feet(c, CX, 176, 26, dark(a, 0.25), 13, 6)
    # garniture qui dépasse
    c.fill(c.mask(E(CX - 34, 86, 30, 16), E(CX + 30, 84, 32, 17), E(CX, 78, 28, 14)), (110, 200, 70), ol=2.6, gloss=0.3)
    for x, y in ((CX - 40, 78), (CX - 4, 72), (CX + 34, 76)):
        c.fill(c.mask(E(x, y, 11, 8)), RED, ol=2, gloss=0.6)
    c.fill(c.mask(E(CX + 16, 86, 22, 9), E(CX - 18, 88, 20, 8)), (150, 80, 50), ol=2, gloss=0.3)
    shell = c.mask(ARC(CX, 92, 0, 76, 0, 180, 60), RR(CX, 92, 152, 8, 4))
    c.fill(shell, a, ol=3.2, gloss=0.5)
    for x, y in ((CX - 46, 104), (CX + 50, 112), (CX - 30, 150), (CX + 30, 150)):
        c.fill(c.mask(E(x, y, 4, 3)), dark(a, 0.18), ol=0, gloss=0, rim=0)
    c.flat(c.mask(STROKE(BEZ((CX - 60, 112), (CX, 140), (CX + 60, 112)), 2)), b, 0.35)
    eyes(c, CX, 118, 19, 9, angry=True)
    smile(c, CX, 140, 9, teeth=True)


def moonmoo(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 174, 26, b, 12, 7)
    c.fill(c.mask(E(CX - 52, 62, 14, 8, -30), E(CX + 52, 62, 14, 8, 30)), a, ol=2.6)
    for s in (-1, 1):
        c.fill(c.mask(STROKE(BEZ((CX + s * 30, 66), (CX + s * 44, 40), (CX + s * 30, 30)), 4)), (255, 230, 150), ol=2.2)
    m = c.mask(E(CX, 118, 64, 58))
    c.fill(m, a, ol=3.2, gloss=0.5)
    for x, y, r in ((CX - 36, 92, 14), (CX + 34, 144, 16), (CX + 40, 88, 8), (CX - 26, 150, 9)):
        c.fill(c.mask(E(x, y, r)) & m, dark(a, 0.12), ol=0, gloss=0, rim=0)
        c.fill(c.mask(E(x - r * 0.15, y - r * 0.1, r * 0.75)) & m, dark(a, 0.2), ol=0, gloss=0, rim=0)
    c.fill(c.mask(E(CX, 134, 30, 18)), (255, 180, 200), ol=2.6, gloss=0.4)
    for s in (-1, 1):
        c.flat(c.mask(E(CX + s * 10, 134, 3.5, 5)), dark((255, 180, 200), 0.45))
    eyes(c, CX, 104, 20, 9, look=(0, -0.2))
    sparkle(c, CX + 78, 52, 6)
    c.fill(c.mask(E(CX - 80, 48, 12), sub=[E(CX - 74, 44, 11)]), (255, 240, 170), ol=2)


def kingcroissant(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(RR(CX, 150, 132, 50, 20)), b, ol=3, gloss=0.4)
    c.flat(c.mask(RR(CX, 172, 132, 8, 0)) & c.mask(RR(CX, 150, 132, 50, 20)), WHITE, 0.9)
    segs = [(-62, 132, 16, -35), (-40, 112, 22, -20), (0, 102, 32, 0), (40, 112, 22, 20), (62, 132, 16, 35)]
    for x, y, r, rot in segs:
        c.fill(c.mask(E(CX + x, y, r * 1.15, r, rot)), a, ol=3, gloss=0.5)
    eyes(c, CX, 98, 15, 8)
    smile(c, CX, 116, 8)
    cheeks(c, CX, 112, 26, 5)
    crown(c, CX, 74, 52)


def dragonfruitdrake(c, k):
    a, b = k["A"], k["B"]
    wings(c, CX, 86, 64, b, rot=24)
    feet(c, CX, 176, 22, dark(a, 0.2), 13, 7)
    body = c.mask(E(CX, 118, 52, 60))
    c.fill(body, a, ol=3.2, gloss=0.5)
    # écailles vertes
    for x, y in ((CX - 30, 84), (CX + 30, 90), (CX - 38, 132), (CX + 38, 128), (CX, 64)):
        c.fill(c.mask([(x - 9, y + 8), (x + 9, y + 8), (x, y - 12)]), b, ol=2.2, gloss=0.3)
    c.fill(c.mask(E(CX, 140, 28, 26)), WHITE, ol=0, gloss=0.2, rim=0.3)
    rnd = random.Random(3)
    for _ in range(12):
        c.flat(c.mask(E(CX + rnd.uniform(-22, 22), 140 + rnd.uniform(-20, 20), 1.8)), INK)
    eyes(c, CX, 104, 17, 9)
    smile(c, CX, 122, 8, fang=True)
    for s in (-1, 1):
        c.fill(c.mask([(CX + s * 14, 62), (CX + s * 24, 36), (CX + s * 28, 64)]), (255, 230, 150), ol=2.2)


def cybershiba(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 22, a, 12, 6)
    c.fill(c.mask(RR(CX, 152, 70, 44, 20)), a, ol=3, gloss=0.3)
    head = c.mask(E(CX, 102, 56, 48), [(CX - 52, 84), (CX - 44, 36), (CX - 16, 64)], [(CX + 52, 84), (CX + 44, 36), (CX + 16, 64)])
    c.fill(head, a, ol=3.2, gloss=0.5)
    for s in (-1, 1):
        c.fill(c.mask([(CX + s * 44, 78), (CX + s * 42, 48), (CX + s * 24, 66)]), (255, 210, 190), ol=0, gloss=0, rim=0)
    c.fill(c.mask(E(CX, 124, 34, 24), E(CX - 26, 108, 12), E(CX + 26, 108, 12)), (255, 245, 230), ol=0, gloss=0.2, rim=0.3)
    # visière cyber
    v = c.mask(RR(CX, 96, 104, 22, 10))
    c.glow(v, b, 4, 0.7)
    c.fill(v, (20, 30, 50), ol=2.6, gloss=0.6)
    c.flat(c.mask(RR(CX, 96, 92, 6, 3)), b)
    c.fill(c.mask(E(CX, 116, 8, 6)), INK, ol=0, gloss=0.5, rim=0)
    smile(c, CX, 128, 8)
    c.fill(c.mask(RR(CX, 148, 74, 8, 4)), b, ol=2)


def maestromeatball(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 22, (30, 30, 36), 13, 6)
    m = c.mask(E(CX, 118, 60, 56))
    c.fill(m, a, ol=3.2, gloss=0.45)
    rnd = random.Random(11)
    for _ in range(12):
        c.fill(c.mask(E(CX + rnd.uniform(-44, 44), 118 + rnd.uniform(-40, 40), rnd.uniform(3, 5))) & m, dark(a, 0.2), ol=0, gloss=0, rim=0)
    # sauce et basilic
    c.fill(c.mask(E(CX, 72, 46, 16), E(CX - 30, 84, 10, 14), E(CX + 22, 86, 8, 12)), RED, ol=2.6, gloss=0.6)
    c.fill(c.mask(E(CX + 10, 62, 12, 6, -30)), (70, 160, 60), ol=2, gloss=0.4)
    eyes(c, CX, 108, 18, 8, sleepy=a)
    for s in (-1, 1):
        c.fill(c.mask(STROKE(BEZ((CX, 130), (CX + s * 22, 122), (CX + s * 34, 134)), 4.5)), b, ol=2, gloss=0.3)
    c.fill(c.mask([(CX - 16, 160), (CX, 152), (CX + 16, 160), (CX + 16, 166), (CX, 158), (CX - 16, 166)]), (30, 30, 36), ol=1.6)
    # baguette de chef d'orchestre + notes
    c.fill(c.mask(CAP(CX + 56, 136, CX + 92, 84, 2.5)), WHITE, ol=2)
    for x, y in ((CX - 84, 70), (CX - 66, 50), (CX + 70, 50)):
        c.fill(c.mask(E(x, y, 6, 5, -20), CAP(x + 5, y, x + 5, y - 18, 1.5)), INK, ol=0, gloss=0.3, rim=0)


def galacticat(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(STROKE(BEZ((CX + 40, 160), (CX + 96, 150), (CX + 86, 92)), 9)), a, ol=3, gloss=0.3)
    feet(c, CX, 176, 20, a, 12, 6)
    c.fill(c.mask(RR(CX, 150, 74, 48, 22)), a, ol=3, gloss=0.3)
    head = c.mask(E(CX, 100, 58, 50), [(CX - 54, 82), (CX - 50, 30), (CX - 14, 58)], [(CX + 54, 82), (CX + 50, 30), (CX + 14, 58)])
    c.fill(head, a, ol=3.2, gloss=0.5)
    # nébuleuse
    for x, y, r, col in ((CX - 20, 80, 26, b), (CX + 26, 116, 22, (90, 140, 255)), (CX + 10, 150, 18, b)):
        c.flat(c.mask(E(x, y, r)) & (head | c.mask(RR(CX, 150, 74, 48, 22))), col, 0.45, blur=1.5)
    rnd = random.Random(5)
    for _ in range(14):
        x, y = CX + rnd.uniform(-48, 48), rnd.uniform(64, 164)
        sparkle(c, x, y, rnd.uniform(1.5, 3.2))
    for s in (-1, 1):
        c.fill(c.mask([(CX + s * 46, 74), (CX + s * 46, 42), (CX + s * 22, 60)]), b, ol=0, gloss=0, rim=0)
    eyes(c, CX, 102, 22, 11, color=(255, 240, 120), pupil=(30, 10, 60))
    c.fill(c.mask([(CX - 5, 120), (CX + 5, 120), (CX, 126)]), b, ol=1.4)
    smile(c, CX, 130, 6, open_=False)
    for s in (-1, 1):
        for d in (-6, 2):
            c.flat(c.mask(CAP(CX + s * 30, 124 + d, CX + s * 64, 120 + d * 1.6, 1)), WHITE, 0.9)
    halo(c, CX, 40, 34)


def overlordonion(c, k):
    a, b = k["A"], k["B"]
    # cape
    c.fill(c.mask([(CX - 50, 100), (CX + 50, 100), (CX + 80, 178), (CX - 80, 178)]), (120, 20, 40), ol=3, gloss=0.3)
    c.fill(c.mask([(CX - 50, 100), (CX + 50, 100), (CX + 70, 172), (CX - 70, 172)], sub=[E(CX, 178, 70, 40)]), (200, 40, 60), ol=0, gloss=0.2)
    m = c.mask(E(CX, 124, 54, 50), [(CX - 30, 90), (CX, 40), (CX + 30, 90)])
    c.fill(m, a, ol=3.2, gloss=0.5)
    for s in (-0.6, 0, 0.6):
        c.flat(c.mask(STROKE(BEZ((CX + s * 10, 52), (CX + s * 60, 110), (CX + s * 30, 170)), 1.6)) & m, dark(a, 0.25), 0.8)
    c.fill(c.mask(STROKE([(CX - 4, 44), (CX - 10, 26), (CX + 4, 30), (CX + 2, 14)], 3)), (110, 180, 70), ol=2)
    eyes(c, CX, 120, 20, 9, style="glow", color=(255, 60, 90))
    c.flat(c.mask(CAP(CX - 32, 104, CX - 10, 112, 2.5)), INK)
    c.flat(c.mask(CAP(CX + 32, 104, CX + 10, 112, 2.5)), INK)
    smile(c, CX, 142, 10, teeth=True)
    crown(c, CX - 30, 84, 30, (120, 120, 140), (160, 60, 255), -20)


def goldengoose(c, k):
    a, b = k["A"], k["B"]
    # oeufs d'or
    for x, y, r in ((CX - 70, 162, 14), (CX + 74, 164, 12), (CX + 56, 172, 9)):
        c.glow(c.mask(E(x, y, r * 0.8, r)), (255, 230, 120), 4, 0.5)
        c.fill(c.mask(E(x, y, r * 0.8, r)), GOLD, ol=2.4, gloss=0.8)
    feet(c, CX, 176, 18, (255, 150, 40), 14, 6)
    wings(c, CX, 120, 52, light(a, 0.2), rot=10)
    c.fill(c.mask(E(CX, 140, 50, 36), CAP(CX + 10, 120, CX + 10, 66, 14)), a, ol=3.2, gloss=0.6)
    c.fill(c.mask(E(CX + 10, 62, 26, 24)), a, ol=3.2, gloss=0.7)
    c.fill(c.mask([(CX + 30, 60), (CX + 62, 68), (CX + 30, 76)]), (255, 150, 40), ol=2.6, gloss=0.4)
    eyes(c, CX + 14, 56, 8, 6)
    c.fill(c.mask(RR(CX + 10, 92, 34, 8, 4)), b, ol=2.2)
    halo(c, CX + 10, 30, 22)
    sparkle(c, CX - 40, 70, 7)


def omegatoaster(c, k):
    a, b = k["A"], k["B"]
    for x in (-22, 22):
        t = c.mask(RR(CX + x, 46, 30, 40, 6))
        c.glow(t, b, 6, 0.8)
        c.fill(t, (60, 40, 30), ol=2.6, gloss=0.3)
        c.fill(c.mask(RR(CX + x, 40, 24, 26, 5)), (30, 20, 20), ol=0, gloss=0.2)
    feet(c, CX, 176, 34, (50, 50, 56), 13, 6)
    body = c.mask(RR(CX, 116, 128, 104, 24))
    c.fill(body, (60, 62, 72), ol=3.4, gloss=0.6)
    for x in (-22, 22):
        c.fill(c.mask(RR(CX + x, 66, 36, 8, 4)), (10, 10, 12), ol=1.6, gloss=0)
    c.fill(c.mask(RR(CX + 72, 124, 14, 30, 5)), (40, 40, 46), ol=2.4, gloss=0.4)
    c.fill(c.mask(RR(CX, 112, 96, 40, 14)), (15, 12, 18), ol=2.4, gloss=0.3)
    eyes(c, CX, 112, 22, 10, style="glow", color=b)
    c.flat(c.mask(CAP(CX - 38, 96, CX - 12, 104, 2.5)), b)
    c.flat(c.mask(CAP(CX + 38, 96, CX + 12, 104, 2.5)), b)
    c.flat(c.mask(STROKE([(CX - 30, 150), (CX - 18, 144), (CX - 6, 150), (CX + 6, 144), (CX + 18, 150), (CX + 30, 144)], 2)), b)
    c.glow(c.mask(RR(CX, 146, 70, 10, 4)), b, 5, 0.5)
    c.fill(c.mask(STAR(CX, 82, 7, 3, 4)), b, ol=1.5)


def cardzero(c, k):
    a, b = k["A"], k["B"]
    # orbes
    for i in range(6):
        ang = math.radians(i * 60 + 20)
        x, y = CX + math.cos(ang) * 92, 104 + math.sin(ang) * 66
        o = c.mask(E(x, y, 6))
        c.glow(o, WHITE, 4, 0.6)
        c.fill(o, (240, 240, 255), ol=1.6, gloss=0.8)
    card = c.mask(RR(CX, 104, 96, 134, 12, -8))
    c.glow(card, (255, 255, 255), 10, 0.45)
    c.fill(card, (14, 14, 18), ol=3.4, ink=(240, 240, 255), gloss=0.5)
    c.fill(c.mask(RR(CX, 104, 80, 118, 8, -8), sub=[RR(CX, 104, 74, 112, 6, -8)]), (220, 220, 235), ol=0, gloss=0)
    # zéro / oeil
    eye = c.mask(E(CX, 104, 26, 36, -8), sub=[E(CX, 104, 15, 24, -8)])
    c.glow(eye, WHITE, 5, 0.8)
    c.fill(eye, WHITE, ol=0, gloss=0)
    c.fill(c.mask(E(CX, 104, 7, 10, -8)), (255, 40, 60), ol=0, gloss=0.6)
    for x, y in ((CX - 30, 50), (CX + 30, 158)):
        c.flat(c.mask(E(x, y, 6, 8, -8), sub=[E(x, y, 3, 5, -8)]), WHITE)


def pumpking(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 26, (60, 120, 40), 13, 6)
    m = c.mask(E(CX - 30, 120, 36, 50), E(CX + 30, 120, 36, 50), E(CX, 118, 40, 54))
    c.fill(m, a, ol=3.2, gloss=0.5)
    for x in (-34, 34):
        c.flat(c.mask(STROKE(BEZ((CX + x * 0.5, 70), (CX + x, 120), (CX + x * 0.5, 168)), 1.6)), dark(a, 0.3), 0.8)
    c.fill(c.mask(CAP(CX, 70, CX + 6, 50, 6)), (90, 150, 50), ol=2.4)
    c.fill(c.mask(E(CX + 24, 56, 16, 7, -20)), (110, 180, 60), ol=2.2, gloss=0.4)
    glowc = (255, 230, 100)
    for s in (-1, 1):
        t = c.mask([(CX + s * 14, 112), (CX + s * 40, 112), (CX + s * 27, 92)])
        c.glow(t, glowc, 3, 0.7)
        c.fill(t, glowc, ol=2.2, gloss=0, rim=0)
    mouth = c.mask(E(CX, 136, 36, 16), sub=[RR(CX, 124, 90, 14, 0), RR(CX - 12, 150, 10, 8, 0), RR(CX + 12, 150, 10, 8, 0)])
    c.glow(mouth, glowc, 3, 0.7)
    c.fill(mouth, glowc, ol=2.2, gloss=0, rim=0)
    crown(c, CX - 22, 70, 32, GOLD, (160, 60, 255), -14)


def countspudula(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask([(CX - 54, 70), (CX - 90, 40), (CX - 70, 176), (CX + 70, 176), (CX + 90, 40), (CX + 54, 70)]), (25, 20, 30), ol=3, gloss=0.3)
    c.fill(c.mask([(CX - 50, 80), (CX - 76, 52), (CX - 62, 170), (CX + 62, 170), (CX + 76, 52), (CX + 50, 80)]), a, ol=0, gloss=0.2)
    m = c.mask(E(CX, 112, 48, 60, 6))
    c.fill(m, b, ol=3.2, gloss=0.45)
    for x, y in ((CX - 24, 80), (CX + 26, 140), (CX + 30, 86), (CX - 30, 146)):
        c.fill(c.mask(E(x, y, 3.5, 2.5)), dark(b, 0.25), ol=0, gloss=0, rim=0)
    c.fill(c.mask([(CX - 44, 72), (CX, 90), (CX + 44, 72), (CX + 40, 56), (CX, 70), (CX - 40, 56)]), (40, 30, 40), ol=2.4, gloss=0.3)
    eyes(c, CX, 104, 17, 8, style="glow", color=(255, 60, 70), angry=True)
    smile(c, CX, 128, 11, fang=True)
    c.fill(c.mask(STAR(CX, 162, 8, 3, 4)), RED, ol=1.6, gloss=0.5)


def ghostini(c, k):
    a, b = k["A"], k["B"]
    pts = [(CX - 52, 160)]
    for i in range(9):
        x = CX - 52 + i * 13
        pts.append((x + 6.5, 176 if i % 2 == 0 else 162))
    pts.append((CX + 52, 160))
    m = c.mask(E(CX, 96, 52, 52), RR(CX, 128, 104, 64, 0), pts)
    c.glow(m, b, 10, 0.5)
    c.fill(m, a, ol=3.2, ink=dark(b, 0.4), gloss=0.7, alpha=0.92)
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 18, 98, 11, 15)), (40, 25, 60), ol=0, gloss=0.4, rim=0)
        c.flat(c.mask(E(CX + s * 18 - 3, 92, 3.5)), WHITE)
    c.fill(c.mask(E(CX, 126, 10, 12)), (40, 25, 60), ol=0, gloss=0.3, rim=0)
    cheeks(c, CX, 116, 34, 6, b)
    # chapeau de magicien
    c.fill(c.mask(RR(CX + 6, 50, 64, 8, 4, 10)), (30, 25, 45), ol=2.6, gloss=0.3)
    c.fill(c.mask(RR(CX + 10, 30, 38, 36, 5, 10)), (30, 25, 45), ol=2.6, gloss=0.4)
    c.flat(c.mask(RR(CX + 8, 42, 38, 6, 0, 10)), b)
    sparkle(c, CX - 74, 64, 7, light(b, 0.4))
    sparkle(c, CX + 70, 120, 5, light(b, 0.4))


def witchywhiskers(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(STROKE(BEZ((CX + 40, 160), (CX + 96, 150), (CX + 86, 100)), 8)), a, ol=3, gloss=0.3)
    feet(c, CX, 176, 20, a, 12, 6)
    c.fill(c.mask(RR(CX, 150, 70, 46, 22)), a, ol=3, gloss=0.3)
    head = c.mask(E(CX, 106, 54, 46), [(CX - 50, 90), (CX - 46, 52), (CX - 18, 70)], [(CX + 50, 90), (CX + 46, 52), (CX + 18, 70)])
    c.fill(head, a, ol=3.2, gloss=0.5)
    eyes(c, CX, 108, 21, 11, color=b, pupil=INK)
    c.fill(c.mask([(CX - 5, 124), (CX + 5, 124), (CX, 130)]), PINK, ol=1.4)
    for s in (-1, 1):
        for d in (-5, 3):
            c.flat(c.mask(CAP(CX + s * 28, 128 + d, CX + s * 60, 124 + d * 1.6, 1)), light(a, 0.6), 0.9)
    # chapeau de sorcière
    c.fill(c.mask(E(CX - 6, 68, 64, 12, -6)), (40, 25, 60), ol=2.8, gloss=0.3)
    c.fill(c.mask([(CX - 40, 66), (CX + 30, 60), (CX + 14, 14), (CX + 36, 2)]), (40, 25, 60), ol=2.8, gloss=0.4)
    c.fill(c.mask([(CX - 38, 62), (CX + 30, 56), (CX + 28, 46), (CX - 34, 52)]), b, ol=0, gloss=0.3)
    c.fill(c.mask(RR(CX - 4, 54, 12, 12, 2, -6)), GOLD, ol=1.6)
    # potion
    c.fill(c.mask(E(CX - 64, 160, 14), RR(CX - 64, 142, 8, 12, 2)), b, ol=2.4, gloss=0.8)


def skeleboi(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 20, a, 12, 5)
    # côtes
    c.fill(c.mask(RR(CX, 160, 12, 34, 4)), a, ol=2.4)
    for i in range(3):
        c.fill(c.mask(RR(CX, 148 + i * 9, 54 - i * 8, 6, 3)), a, ol=2.2)
    skull = c.mask(E(CX, 90, 56, 50), RR(CX, 120, 64, 32, 10))
    c.fill(skull, a, ol=3.2, gloss=0.6)
    for s in (-1, 1):
        e = c.mask(E(CX + s * 22, 92, 15, 17))
        c.fill(e, b, ol=0, gloss=0.2, rim=0)
        c.glow(c.mask(E(CX + s * 22, 94, 5)), (120, 255, 200), 3, 0.9)
        c.flat(c.mask(E(CX + s * 22, 94, 4.5)), (180, 255, 220))
    c.fill(c.mask([(CX - 6, 116), (CX + 6, 116), (CX, 106)]), b, ol=0)
    for i in range(-2, 3):
        c.flat(c.mask(RR(CX + i * 9, 132, 2, 12, 1)), dark(a, 0.4))
    c.flat(c.mask(RR(CX, 132, 46, 2, 1)), dark(a, 0.4))
    # couronne d'os + éclair
    halo(c, CX, 34, 30, (120, 255, 200))
    c.fill(c.mask(CAP(CX + 52, 172, CX + 78, 110, 3.5), E(CX + 80, 106, 6), E(CX + 72, 108, 6)), a, ol=2.4)


def hollowcard(c, k):
    a, b = k["A"], k["B"]
    for i in range(8):
        ang = math.radians(i * 45)
        x, y = CX + math.cos(ang) * 88, 104 + math.sin(ang) * 66
        f = c.mask([(x, y - 9), (x + 6, y), (x, y + 9), (x - 6, y)])
        c.glow(f, b, 3, 0.6)
        c.flat(f, b)
    card = c.mask(RR(CX, 104, 96, 134, 12, 8))
    c.glow(card, b, 12, 0.5)
    c.fill(card, (24, 8, 34), ol=3.4, ink=b, gloss=0.5)
    hole = c.mask(E(CX, 104, 34, 44, 8))
    c.fill(hole, (0, 0, 0), ol=2.4, ink=b, gloss=0, rim=0)
    c.glow(c.mask(E(CX, 104, 14, 18)), b, 10, 0.5)
    for s in (-1, 1):
        e = c.mask(E(CX + s * 14, 98, 7, 5, s * 15))
        c.glow(e, b, 3, 0.9)
        c.flat(e, (255, 200, 120))
    c.flat(c.mask(STROKE([(CX - 14, 120), (CX - 6, 116), (CX, 122), (CX + 6, 116), (CX + 14, 120)], 1.6)), b)


def frostbitefred(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 24, b, 13, 6)
    cube = c.mask(RR(CX, 112, 112, 112, 20, -4))
    c.fill(cube, a, ol=3.2, ink=dark(b, 0.4), gloss=0.9, alpha=0.95)
    c.flat(c.mask(RR(CX - 30, 80, 14, 40, 6, 20)), WHITE, 0.5)
    c.flat(c.mask(RR(CX + 36, 146, 22, 6, 3)), WHITE, 0.5)
    # neige sur le dessus
    c.fill(c.mask(E(CX - 20, 62, 34, 12), E(CX + 22, 60, 30, 13), E(CX, 56, 22, 12)), WHITE, ol=2.6, ink=dark(b, 0.4), gloss=0.3)
    eyes(c, CX, 110, 20, 9, pupil=dark(b, 0.5))
    smile(c, CX, 132, 8)
    cheeks(c, CX, 128, 32, 5, (150, 190, 255))
    # écharpe
    c.fill(c.mask(RR(CX, 160, 100, 14, 6), RR(CX + 32, 176, 14, 28, 4, -10)), RED, ol=2.6, gloss=0.3)


def jinglejelly(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(E(CX, 174, 72, 12)), (240, 240, 250), ol=2.6, gloss=0.3)
    m = c.mask([(CX - 58, 170), (CX - 50, 96), (CX - 26, 72), (CX + 26, 72), (CX + 50, 96), (CX + 58, 170)], E(CX, 78, 32, 14))
    c.fill(m, a, ol=3.2, gloss=0.85, alpha=0.95)
    for i in range(3):
        c.flat(c.mask(RR(CX, 106 + i * 22, 120, 7, 3)) & m, WHITE, 0.55)
    # houx et clochette
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 16, 60, 16, 8, s * 30)), b, ol=2.2, gloss=0.4)
    for x in (-6, 6, 0):
        c.fill(c.mask(E(CX + x, 58 - (x == 0) * 6, 6)), RED, ol=1.8, gloss=0.7)
    c.fill(c.mask(E(CX + 54, 120, 13, 15), RR(CX + 54, 106, 6, 6, 2)), GOLD, ol=2.4, gloss=0.7)
    c.fill(c.mask(E(CX + 54, 134, 4)), dark(GOLD, 0.4), ol=0)
    eyes(c, CX, 112, 17, 9)
    smile(c, CX, 134, 8)


def snowmancer(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(E(CX, 146, 52, 36)), a, ol=3.2, ink=dark(b, 0.5), gloss=0.5)
    head = c.mask(E(CX, 94, 38, 34))
    c.fill(head, a, ol=3.2, ink=dark(b, 0.5), gloss=0.6)
    for y in (134, 152):
        c.fill(c.mask(E(CX, y, 4)), INK, ol=0, gloss=0.4, rim=0)
    # chapeau de mage
    c.fill(c.mask(E(CX, 66, 48, 9)), b, ol=2.8, gloss=0.3)
    c.fill(c.mask([(CX - 30, 66), (CX + 30, 66), (CX + 20, 30), (CX + 44, 14)]), b, ol=2.8, gloss=0.5)
    for x, y in ((CX - 6, 48), (CX + 12, 34)):
        c.fill(c.mask(STAR(x, y, 5, 2)), WHITE, ol=0)
    eyes(c, CX, 92, 13, 6, style="glow", color=light(b, 0.4))
    c.fill(c.mask([(CX - 2, 100), (CX + 2, 104), (CX + 28, 104)]), (255, 140, 40), ol=2)
    smile(c, CX, 114, 5, open_=False)
    # bâton de glace
    c.fill(c.mask(CAP(CX - 62, 176, CX - 70, 84, 3)), (150, 110, 70), ol=2)
    cr = c.mask([(CX - 70, 58), (CX - 60, 76), (CX - 70, 92), (CX - 80, 76)])
    c.glow(cr, (150, 220, 255), 4, 0.8)
    c.fill(cr, (190, 240, 255), ol=2.2, gloss=0.8)


def polarpudding(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(E(CX, 172, 78, 12)), (220, 230, 245), ol=2.6, gloss=0.3)
    m = c.mask([(CX - 64, 168), (CX - 52, 84), (CX + 52, 84), (CX + 64, 168)], E(CX, 84, 52, 18))
    c.fill(m, a, ol=3.2, gloss=0.6)
    sauce = c.mask(E(CX, 80, 54, 20), E(CX - 40, 98, 9, 18), E(CX - 6, 104, 8, 20), E(CX + 30, 100, 9, 16))
    c.fill(sauce, b, ol=2.6, gloss=0.8)
    # bonnet d'ours polaire
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 40, 62, 13)), WHITE, ol=2.6, gloss=0.4)
        c.fill(c.mask(E(CX + s * 40, 62, 6)), (255, 200, 220), ol=0)
    eyes(c, CX, 126, 18, 9)
    c.fill(c.mask(E(CX, 142, 7, 5)), INK, ol=0, gloss=0.5, rim=0)
    smile(c, CX, 152, 6, open_=False)
    cheeks(c, CX, 140, 32, 5)
    halo(c, CX, 42, 30, (190, 240, 255))


def petalpup(c, k):
    a, b = k["A"], k["B"]
    feet(c, CX, 176, 20, dark(a, 0.1), 12, 6)
    c.fill(c.mask(RR(CX, 152, 66, 42, 20)), a, ol=3, gloss=0.3)
    for i in range(8):
        ang = math.radians(i * 45)
        c.fill(c.mask(E(CX + math.cos(ang) * 56, 104 + math.sin(ang) * 50, 18, 13, i * 45)), b if i % 2 else light(b, 0.3), ol=2.6, gloss=0.4)
    head = c.mask(E(CX, 104, 46, 42))
    c.fill(head, a, ol=3.2, gloss=0.5)
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 44, 102, 12, 24, s * -20)), dark(a, 0.15), ol=2.6, gloss=0.3)
    c.fill(c.mask(E(CX, 122, 22, 15)), light(a, 0.4), ol=0, gloss=0.2, rim=0.3)
    eyes(c, CX, 100, 16, 9)
    c.fill(c.mask(E(CX, 116, 6, 4.5)), INK, ol=0, gloss=0.5, rim=0)
    smile(c, CX, 128, 6)


def bunnybun(c, k):
    a, b = k["A"], k["B"]
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 20, 48, 13, 34, s * 10)), a, ol=3, gloss=0.4)
        c.fill(c.mask(E(CX + s * 20, 52, 6, 24, s * 10)), b, ol=0, gloss=0.2, rim=0)
    m = c.mask(E(CX, 124, 62, 52))
    c.fill(m, a, ol=3.2, gloss=0.5)
    # glaçage de brioche
    c.fill(c.mask(E(CX, 98, 50, 24), E(CX - 30, 110, 10, 12), E(CX + 24, 112, 10, 14)), b, ol=2.6, gloss=0.8)
    rnd = random.Random(9)
    for _ in range(10):
        x, y = CX + rnd.uniform(-38, 38), 96 + rnd.uniform(-12, 10)
        c.flat(c.mask(RR(x, y, 6, 2.4, 1, rnd.uniform(0, 180))), hsv(rnd.random(), 0.6, 1))
    eyes(c, CX, 132, 18, 8)
    c.fill(c.mask(E(CX, 146, 5, 3.5)), PINK, ol=1.2)
    smile(c, CX, 156, 6)
    cheeks(c, CX, 148, 30, 5)


def bloomlord(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask(CAP(CX, 176, CX, 130, 8)), b, ol=3, gloss=0.3)
    for s in (-1, 1):
        c.fill(c.mask(E(CX + s * 30, 158, 24, 10, s * -25)), b, ol=2.6, gloss=0.4)
    for i in range(10):
        ang = math.radians(i * 36)
        c.fill(c.mask(E(CX + math.cos(ang) * 50, 96 + math.sin(ang) * 46, 24, 15, i * 36)), a if i % 2 else light(a, 0.3), ol=2.8, gloss=0.5)
    face = c.mask(E(CX, 96, 40))
    c.fill(face, (255, 220, 100), ol=3.2, gloss=0.5)
    eyes(c, CX, 92, 14, 8)
    smile(c, CX, 110, 8)
    cheeks(c, CX, 104, 24, 5)
    crown(c, CX, 52, 40, GOLD, (90, 200, 120))


def surfslug(c, k):
    a, b = k["A"], k["B"]
    # vague
    crest = [(CX - 130 + i * 10, 166 + 6 * math.sin(i * 0.9)) for i in range(28)]
    water = c.mask(crest + [(CX + 140, 210), (CX - 140, 210)])
    c.fill(water, (60, 170, 255), ol=2.6, gloss=0, rim=0.3)
    for i in range(5):
        c.flat(c.mask(E(CX - 100 + i * 50, 186 + (i % 2) * 6, 14, 2.5)), WHITE, 0.6)
    c.fill(c.mask(E(CX - 6, 156, 86, 12, -4)), b, ol=3, gloss=0.6)
    c.flat(c.mask(RR(CX - 6, 156, 150, 3, 1, -4)), RED)
    m = c.mask(E(CX - 6, 136, 60, 20), CAP(CX + 30, 134, CX + 36, 82, 20))
    c.fill(m, a, ol=3.2, gloss=0.6)
    for s in (-1, 1):
        c.fill(c.mask(CAP(CX + 36 + s * 8, 70, CX + 36 + s * 14, 50, 2.2)), a, ol=2)
        c.fill(c.mask(E(CX + 36 + s * 14, 48, 5)), light(a, 0.3), ol=2, gloss=0.6)
    # lunettes de soleil
    for s in (-1, 1):
        c.fill(c.mask(RR(CX + 36 + s * 12, 84, 18, 12, 5)), INK, ol=1.8, gloss=0.7)
    c.flat(c.mask(RR(CX + 36, 82, 8, 3, 1)), INK)
    smile(c, CX + 36, 102, 7)


def sunnysundae(c, k):
    a, b = k["A"], k["B"]
    cup = c.mask([(CX - 50, 120), (CX + 50, 120), (CX + 16, 160), (CX - 16, 160)])
    c.fill(c.mask(RR(CX, 174, 60, 10, 4), RR(CX, 164, 12, 16, 3)), light((180, 220, 255), 0.4), ol=2.6, gloss=0.6)
    for x, y, r, col in ((CX - 28, 106, 26, a), (CX + 28, 104, 26, (255, 245, 220)), (CX, 82, 30, a)):
        c.fill(c.mask(E(x, y, r, r * 0.86)), col, ol=3, gloss=0.6)
    c.fill(cup, light((180, 220, 255), 0.4), ol=3, gloss=0.8, alpha=0.9)
    c.fill(c.mask(E(CX, 62, 18, 8), E(CX - 14, 70, 6, 10), E(CX + 12, 72, 6, 9)), b, ol=2.4, gloss=0.7)
    c.fill(c.mask(E(CX + 4, 46, 9)), RED, ol=2, gloss=0.8)
    c.flat(c.mask(STROKE(BEZ((CX + 4, 38), (CX + 8, 26), (CX + 18, 22)), 1.6)), (70, 130, 40))
    eyes(c, CX, 86, 14, 7)
    smile(c, CX, 102, 6)
    cheeks(c, CX, 98, 22, 4)
    # soleil
    s = c.mask(E(CX + 84, 44, 16))
    c.glow(s, (255, 220, 80), 6, 0.6)
    c.fill(s, (255, 210, 60), ol=2.4, gloss=0.5)


def lavalamp(c, k):
    a, b = k["A"], k["B"]
    c.fill(c.mask([(CX - 40, 178), (CX + 40, 178), (CX + 26, 150), (CX - 26, 150)]), (90, 95, 110), ol=3, gloss=0.4)
    c.fill(c.mask([(CX - 22, 34), (CX + 22, 34), (CX + 14, 18), (CX - 14, 18)]), (90, 95, 110), ol=3, gloss=0.4)
    glass = c.mask([(CX - 26, 150), (CX + 26, 150), (CX + 44, 96), (CX + 22, 34), (CX - 22, 34), (CX - 44, 96)])
    c.glow(glass, a, 10, 0.5)
    c.fill(glass, light(b, 0.25), ol=3.2, gloss=0.8)
    for x, y, r in ((CX - 6, 130, 18), (CX + 12, 70, 12), (CX - 12, 54, 8), (CX + 18, 106, 9)):
        c.fill(c.mask(E(x, y, r, r * 1.1)) & glass, a, ol=0, gloss=0.6, rim=0.4)
    eyes(c, CX, 94, 14, 8, sleepy=light(b, 0.25))
    smile(c, CX, 112, 6)
    c.fill(c.mask(RR(CX, 30, 60, 5, 2)), INK, ol=0)


DRAW = {name: fn for name, fn in globals().items() if callable(fn) and name in (
    "toastini sockrates bloop pebblepete mrnoodle cardboardcarl wobbles spaghettron bananaut cactuso duckmaster jellybyte "
    "captaincrumb turbotortellini neonnana sirpickles glitchygus pizzasaurus roboraccoon thundertaco moonmoo kingcroissant "
    "dragonfruitdrake cybershiba maestromeatball galacticat overlordonion goldengoose omegatoaster cardzero pumpking countspudula "
    "ghostini witchywhiskers skeleboi hollowcard frostbitefred jinglejelly snowmancer polarpudding petalpup bunnybun bloomlord "
    "surfslug sunnysundae lavalamp"
).split()}
DRAW["lavalamp"] = lavalamp


def render(card):
    c = Canvas(W, H)
    background(c, card)
    DRAW[card["Id"]](c, card)
    return c.image()

"""
Icônes de l'interface (256 x 256), style autocollant brillant.
Les icônes "teintables" (crate, cardpack, bolt, arrowup, plus) sont dessinées
en blanc / gris : le jeu les colore avec ImageColor3.
"""

import math

from artkit import ARC, BEZ, CAP, E, INK, RR, STAR, STROKE, WHITE, Canvas, dark, light, rot_pts

N = 256
C = 128
OL = 7

RED = (235, 50, 62)
GOLD = (255, 200, 40)
ORANGE = (255, 150, 30)
GREEN = (90, 205, 90)
BLUE = (60, 140, 255)
PURPLE = (150, 70, 240)
TINT = (238, 240, 246)

ORDER = [
    "rebirth", "book", "basket", "ticket", "gift", "cardpack", "crate", "cash",
    "cashpile", "clover", "bolt", "house", "arrowup", "snowflake", "flask", "calendar",
    "people", "crown", "clock", "magnet", "cards", "treadmill", "cases", "plus", "trophy",
]


def arrow_ring(c, cx, cy, r, w, a0, a1, color, head=1.0):
    """arc fléché (sens horaire de a0 à a1, degrés, y vers le bas)"""
    band = c.mask(ARC(cx, cy, r - w / 2, r + w / 2, a0, a1, 60))
    ang = math.radians(a1)
    tx, ty = cx + math.cos(ang) * r, cy + math.sin(ang) * r
    # direction de la tangente
    dx, dy = -math.sin(ang), math.cos(ang)
    nx, ny = math.cos(ang), math.sin(ang)
    L, Wd = w * 1.25 * head, w * 1.15 * head
    tip = (tx + dx * L, ty + dy * L)
    p1 = (tx + nx * Wd, ty + ny * Wd)
    p2 = (tx - nx * Wd, ty - ny * Wd)
    m = band | c.mask([p1, tip, p2])
    return m


def rebirth(c):
    m1 = arrow_ring(c, C, C, 76, 34, 200, 335, RED)
    m2 = arrow_ring(c, C, C, 76, 34, 20, 155, WHITE)
    c.fill(m1, RED, ol=OL, gloss=0.55)
    c.fill(m2, (245, 246, 252), ol=OL, gloss=0.4)
    s = c.mask(STAR(C, C + 2, 34, 15, 5))
    c.glow(s, (255, 230, 120), 4, 0.6)
    c.fill(s, GOLD, ol=OL - 1, gloss=0.6)


def book(c):
    rot = -8
    c.fill(c.mask(RR(C + 6, C + 6, 150, 186, 18, rot)), dark(BLUE, 0.35), ol=OL, gloss=0)
    c.fill(c.mask(RR(C + 10, C + 2, 136, 172, 10, rot)), (250, 246, 232), ol=OL - 2, gloss=0, rim=0.4)
    for i in range(4):
        c.flat(c.mask(RR(C + 12 + 64, C + 2 - 70 + i * 46, 3, 30, 1, rot)), (215, 205, 180), 0.8)
    cover = c.mask(RR(C - 4, C - 4, 146, 180, 18, rot))
    c.fill(cover, BLUE, ol=OL, gloss=0.6)
    c.fill(c.mask(RR(C - 62, C - 4, 18, 180, 8, rot)), dark(BLUE, 0.25), ol=0, gloss=0.2, rim=0)
    # étiquette avec carte
    c.fill(c.mask(RR(C + 6, C - 30, 84, 108, 12, rot)), light(BLUE, 0.75), ol=OL - 2, gloss=0.3)
    c.fill(c.mask(STAR(C + 6, C - 30, 30, 13, 5, -98)), GOLD, ol=OL - 2, gloss=0.6)
    c.fill(c.mask(RR(C + 40, C + 94, 18, 46, 4, rot)), RED, ol=OL - 2, gloss=0.3)


def basket(c):
    c.fill(c.mask(ARC(C, 104, 58, 74, 180, 360, 50)), (210, 215, 228), ol=OL, gloss=0.5)
    body = c.mask([(C - 96, 104), (C + 96, 104), (C + 76, 212), (C - 76, 212)])
    c.fill(body, RED, ol=OL, gloss=0.5)
    for i in range(-2, 3):
        c.flat(c.mask(RR(C + i * 32, 162, 14, 64, 6)), dark(RED, 0.35), 1)
    c.fill(c.mask(RR(C, 104, 214, 30, 12)), dark(RED, 0.12), ol=OL, gloss=0.5)


def ticket(c):
    rot = -16
    outer = c.mask(RR(C, C, 220, 128, 18, rot), sub=[E(*rot_pts([(-110, 0)], C, C, rot)[0], 22), E(*rot_pts([(110, 0)], C, C, rot)[0], 22)])
    c.fill(outer, GOLD, ol=OL, gloss=0.55)
    inner = c.mask(RR(C + 14, C + 3, 120, 76, 12, rot))
    c.fill(inner, light(GOLD, 0.45), ol=OL - 3, gloss=0, rim=0.3)
    for i in range(-2, 3):
        x, y = rot_pts([(-62, i * 22)], C, C, rot)[0]
        c.flat(c.mask(RR(x, y, 8, 12, 3, rot)), dark(GOLD, 0.3))
    c.fill(c.mask(STAR(*rot_pts([(14, 3)], C, C, rot)[0], 32, 14, 5, -90 + rot)), (255, 120, 40), ol=OL - 2, gloss=0.5)


def gift(c):
    c.fill(c.mask(RR(C, 160, 170, 116, 14)), PURPLE, ol=OL, gloss=0.4)
    c.fill(c.mask(RR(C, 96, 196, 46, 14)), light(PURPLE, 0.25), ol=OL, gloss=0.55)
    c.fill(c.mask(RR(C, 160, 34, 116, 0)), GOLD, ol=0, gloss=0.3, rim=0.3)
    c.fill(c.mask(RR(C, 96, 34, 46, 0)), GOLD, ol=0, gloss=0.3, rim=0.3)
    for s in (-1, 1):
        c.fill(c.mask(E(C + s * 34, 56, 36, 22, s * 25), sub=[E(C + s * 34, 58, 16, 9, s * 25)]), GOLD, ol=OL, gloss=0.6)
    c.fill(c.mask(E(C, 68, 20, 18)), ORANGE, ol=OL - 1, gloss=0.6)


def cardpack(c):
    rot = -8
    body = c.mask(RR(C, C, 150, 210, 12, rot))
    c.fill(body, TINT, ol=OL, gloss=0.6)
    for y in (-96, 96):
        x0, y0 = rot_pts([(0, y)], C, C, rot)[0]
        c.fill(c.mask(RR(x0, y0, 154, 24, 4, rot)), light(TINT, 0.5), ol=OL - 2, gloss=0.3)
    c.fill(c.mask(E(C, C, 52, 52)), WHITE, ol=OL - 2, gloss=0, rim=0)
    c.fill(c.mask(STAR(C, C + 2, 40, 17, 5, -90 + rot)), dark(TINT, 0.3), ol=OL - 2, gloss=0.6)


def crate(c):
    box = c.mask(RR(C, C + 6, 190, 180, 16))
    c.fill(box, TINT, ol=OL, gloss=0.5)
    for y in (-46, 46):
        c.fill(c.mask(RR(C, C + 6 + y, 190, 14, 2)), dark(TINT, 0.18), ol=0, gloss=0, rim=0)
    c.fill(c.mask(CAP(C - 70, C + 76, C + 70, C - 64, 12)), dark(TINT, 0.1), ol=OL - 3, gloss=0.2)
    for x, y in ((-80, -72), (80, -72), (-80, 84), (80, 84)):
        c.fill(c.mask(E(C + x, C + 6 + y * 0.98, 7)), dark(TINT, 0.35), ol=0, gloss=0.5, rim=0)


def bill(c, cx, cy, w, h, rot, col=GREEN):
    m = c.mask(RR(cx, cy, w, h, 10, rot))
    c.fill(m, col, ol=OL, gloss=0.4)
    c.fill(c.mask(RR(cx, cy, w - 26, h - 22, 8, rot)), light(col, 0.18), ol=0, gloss=0, rim=0)
    c.fill(c.mask(E(cx, cy, h * 0.32, h * 0.32)), dark(col, 0.2), ol=0, gloss=0, rim=0)
    dollar(c, cx, cy, h * 0.26, light(col, 0.75))


def dollar(c, cx, cy, s, col):
    pts = BEZ((cx + s * 0.6, cy - s * 0.55), (cx - s * 1.2, cy - s * 0.9), (cx, cy)) + BEZ((cx, cy), (cx + s * 1.2, cy + s * 0.9), (cx - s * 0.6, cy + s * 0.55))
    c.flat(c.mask(STROKE(pts, s * 0.17)), col)
    c.flat(c.mask(RR(cx, cy, s * 0.2, s * 2.0, s * 0.1)), col)


def cash(c):
    bill(c, C + 6, C + 40, 210, 104, 8, dark(GREEN, 0.1))
    bill(c, C - 4, C + 10, 210, 104, -4)
    bill(c, C, C - 24, 210, 104, -12, light(GREEN, 0.06))
    c.fill(c.mask(RR(C, C - 24, 40, 108, 2, -12)), (255, 225, 120), ol=OL - 2, gloss=0.4)


def coin(c, x, y, r):
    c.fill(c.mask(E(x, y, r)), GOLD, ol=OL - 1, gloss=0.65)
    c.fill(c.mask(E(x, y, r * 0.7)), light(GOLD, 0.2), ol=0, gloss=0, rim=0.5)
    dollar(c, x, y, r * 0.48, dark(GOLD, 0.35))


def cashpile(c):
    for i in range(4):
        bill(c, C - 30, 196 - i * 30, 170, 74, -4 + i * 3, GREEN if i % 2 == 0 else dark(GREEN, 0.12))
    coin(c, C + 72, 190, 36)
    coin(c, C + 56, 136, 32)
    coin(c, C + 82, 96, 26)


def clover(c):
    c.fill(c.mask(STROKE(BEZ((C, C + 10), (C + 10, C + 70), (C + 50, C + 104)), 9)), dark(GREEN, 0.25), ol=OL - 1, gloss=0.3)
    for i in range(4):
        a = math.radians(-45 + i * 90)
        dx, dy = math.cos(a), math.sin(a)
        m = c.mask(E(C + dx * 44 - dy * 18, C - 10 + dy * 44 + dx * 18, 34), E(C + dx * 44 + dy * 18, C - 10 + dy * 44 - dx * 18, 34), [(C, C - 10), (C + dx * 60 - dy * 40, C - 10 + dy * 60 + dx * 40), (C + dx * 60 + dy * 40, C - 10 + dy * 60 - dx * 40)])
        c.fill(m, GREEN, ol=OL, gloss=0.5)
        c.flat(c.mask(CAP(C, C - 10, C + dx * 52, C - 10 + dy * 52, 3)), light(GREEN, 0.45), 0.9)


def bolt(c):
    pts = [(0.15, -1), (-0.5, 0.12), (-0.04, 0.12), (-0.25, 1), (0.52, -0.22), (0.06, -0.22), (0.36, -1)]
    m = c.mask([(C + x * 100, C + y * 104) for x, y in pts])
    c.fill(m, TINT, ol=OL, gloss=0.6)


def house(c):
    c.fill(c.mask(RR(C + 52, 64, 26, 50, 4)), (200, 90, 70), ol=OL, gloss=0.3)
    c.fill(c.mask(RR(C, 162, 160, 112, 10)), (252, 244, 226), ol=OL, gloss=0.4)
    roof = c.mask([(C - 112, 124), (C, 30), (C + 112, 124), (C + 92, 134), (C, 58), (C - 92, 134)])
    c.fill(roof, BLUE, ol=OL, gloss=0.55)
    c.fill(c.mask(RR(C, 186, 46, 66, 12)), (170, 100, 55), ol=OL - 2, gloss=0.3)
    c.fill(c.mask(E(C + 14, 188, 5)), GOLD, ol=0, gloss=0.5, rim=0)
    for x in (-52, 52):
        c.fill(c.mask(RR(C + x, 154, 38, 36, 6)), (150, 220, 255), ol=OL - 2, gloss=0.8)


def arrowup(c):
    m = c.mask([(C, 22), (C + 96, 124), (C + 44, 124), (C + 44, 228), (C - 44, 228), (C - 44, 124), (C - 96, 124)])
    c.fill(m, TINT, ol=OL, gloss=0.6)


def snowflake(c):
    col = (150, 220, 255)
    shapes = []
    for i in range(6):
        a = math.radians(i * 60 - 90)
        dx, dy = math.cos(a), math.sin(a)
        shapes.append(CAP(C, C, C + dx * 96, C + dy * 96, 12))
        for d, l in ((54, 32), (80, 22)):
            bx, by = C + dx * d, C + dy * d
            for s in (-1, 1):
                b = a + s * math.radians(50)
                shapes.append(CAP(bx, by, bx + math.cos(b) * l, by + math.sin(b) * l, 9))
    m = c.mask(*shapes, E(C, C, 26))
    c.fill(m, col, ol=OL, gloss=0.5)
    c.fill(c.mask(STAR(C, C, 24, 12, 6)), WHITE, ol=0, gloss=0, rim=0)


def flask(c):
    c.fill(c.mask(RR(C, 50, 54, 46, 10)), (235, 245, 255), ol=OL, gloss=0.5)
    c.fill(c.mask(RR(C, 32, 64, 22, 8)), (190, 120, 70), ol=OL, gloss=0.4)
    body = c.mask(E(C, 160, 84, 80))
    c.fill(body, (225, 240, 255), ol=OL, gloss=0)
    liq = c.mask(E(C, 160, 76, 72), sub=[RR(C, 104, 200, 60, 0)])
    c.fill(liq, (80, 220, 255), ol=0, gloss=0.5)
    for x, y, r in ((C - 24, 170, 10), (C + 22, 150, 7), (C + 6, 196, 6)):
        c.fill(c.mask(E(x, y, r)), WHITE, ol=0, gloss=0, rim=0, alpha=0.8)
    c.flat(c.mask(E(C - 40, 130, 14, 26, 25)), WHITE, 0.6)


def calendar(c):
    rot = -6
    c.fill(c.mask(RR(C, C + 14, 196, 190, 20, rot)), (250, 250, 255), ol=OL, gloss=0.3)
    top = c.mask(RR(*rot_pts([(0, -62)], C, C + 14, rot)[0], 196, 66, 20, rot), sub=[RR(*rot_pts([(0, -24)], C, C + 14, rot)[0], 200, 10, 0, rot)])
    c.fill(top, RED, ol=OL, gloss=0.5)
    for x in (-50, 50):
        px, py = rot_pts([(x, -96)], C, C + 14, rot)[0]
        c.fill(c.mask(RR(px, py, 18, 40, 9, rot)), (70, 72, 86), ol=OL - 2, gloss=0.4)
    for r in range(3):
        for k in range(4):
            px, py = rot_pts([(-66 + k * 44, 2 + r * 36)], C, C + 14, rot)[0]
            col = RED if (r == 2 and k == 2) else (200, 205, 220)
            c.fill(c.mask(RR(px, py, 30, 24, 6, rot)), col, ol=0, gloss=0.3, rim=0)


def people(c):
    for x, y, col, sc in ((C - 44, 0, BLUE, 0.92), (C + 40, 10, GREEN, 1.0)):
        c.fill(c.mask(RR(x, 180 + y, 96 * sc, 92 * sc, 40 * sc)), col, ol=OL, gloss=0.5)
        c.fill(c.mask(E(x, 96 + y, 40 * sc)), (255, 214, 160), ol=OL, gloss=0.55)
        c.fill(c.mask(E(x, 70 + y, 36 * sc, 18 * sc)), (90, 60, 40), ol=0, gloss=0.3, rim=0)


def crown(c):
    pts = [(-100, 60), (-100, -50), (-52, 0), (0, -80), (52, 0), (100, -50), (100, 60)]
    m = c.mask([(C + x, C + 10 + y) for x, y in pts])
    c.fill(m, GOLD, ol=OL, gloss=0.6)
    c.fill(c.mask(RR(C, C + 58, 206, 34, 10)), dark(GOLD, 0.08), ol=OL, gloss=0.4)
    for x, y in ((-100, -56), (0, -88), (100, -56)):
        c.fill(c.mask(E(C + x, C + 10 + y, 14)), light(GOLD, 0.6), ol=OL - 2, gloss=0.6)
    c.fill(c.mask(E(C, C + 58, 15, 13)), RED, ol=OL - 2, gloss=0.7)
    for s, col in ((-1, BLUE), (1, GREEN)):
        c.fill(c.mask(E(C + s * 58, C + 58, 11, 10)), col, ol=OL - 2, gloss=0.7)


def clock(c):
    c.fill(c.mask(RR(C, 34, 40, 30, 6)), (230, 60, 70), ol=OL, gloss=0.5)
    c.fill(c.mask(CAP(C + 72, 66, C + 86, 52, 10)), (230, 60, 70), ol=OL, gloss=0.4)
    c.fill(c.mask(E(C, 144, 98)), GOLD, ol=OL, gloss=0.55)
    c.fill(c.mask(E(C, 144, 76)), (252, 252, 255), ol=OL - 2, gloss=0.2, rim=0.5)
    for i in range(12):
        a = math.radians(i * 30)
        c.flat(c.mask(CAP(C + math.cos(a) * 58, 144 + math.sin(a) * 58, C + math.cos(a) * 66, 144 + math.sin(a) * 66, 3.2 if i % 3 == 0 else 2)), (120, 125, 140))
    c.flat(c.mask(CAP(C, 144, C, 92, 6)), INK)
    c.flat(c.mask(CAP(C, 144, C + 36, 160, 6)), INK)
    c.fill(c.mask(E(C, 144, 10)), RED, ol=0, gloss=0.5, rim=0)


def magnet(c):
    m = c.mask(ARC(C, 120, 34, 94, 0, 180, 60), RR(C - 64, 82, 60, 84, 0), RR(C + 64, 82, 60, 84, 0))
    c.fill(m, RED, ol=OL, gloss=0.5)
    for s in (-1, 1):
        c.fill(c.mask(RR(C + s * 64, 46, 60, 42, 4)), (225, 230, 240), ol=OL, gloss=0.6)


def cards(c):
    for i, (col, rot, dx) in enumerate(((BLUE, -18, -46), (PURPLE, 0, 0), ((255, 180, 30), 18, 46))):
        cx, cy = C + dx, C + (abs(dx) * 0.35)
        c.fill(c.mask(RR(cx, cy, 108, 152, 14, rot)), WHITE, ol=OL, gloss=0.2)
        c.fill(c.mask(RR(cx, cy, 88, 132, 10, rot)), col, ol=0, gloss=0.5)
        c.fill(c.mask(STAR(cx, cy, 24, 10, 5, -90 + rot)), WHITE, ol=0, gloss=0, rim=0, alpha=0.9)


def treadmill(c):
    # montant + console
    c.fill(c.mask(CAP(C + 60, 190, C + 76, 62, 13)), (200, 205, 218), ol=OL, gloss=0.4)
    c.fill(c.mask(CAP(C + 70, 104, C + 6, 112, 9)), (200, 205, 218), ol=OL, gloss=0.4)
    con = c.mask(RR(C + 74, 56, 96, 52, 14, 20))
    c.fill(con, BLUE, ol=OL, gloss=0.6)
    c.fill(c.mask(RR(C + 74, 56, 64, 26, 6, 20)), (150, 235, 255), ol=OL - 3, gloss=0.6)
    # plateau et tapis
    deck = c.mask(RR(C - 10, 196, 236, 54, 27, -8))
    c.fill(deck, (55, 58, 72), ol=OL, gloss=0.5)
    belt = c.mask(RR(C - 12, 184, 210, 16, 8, -8))
    c.glow(belt, (120, 255, 150), 4, 0.5)
    c.fill(belt, (90, 230, 120), ol=0, gloss=0.4, rim=0)
    for x in (-60, -10, 40):
        c.flat(c.mask(STROKE([(C + x, 178 - x * 0.14), (C + x + 12, 184 - x * 0.14 - 1.5), (C + x, 190 - x * 0.14)], 3.5)), WHITE, 0.85)
    for x in (-98, 86):
        c.fill(c.mask(E(C + x, 206 - x * 0.14, 17)), (150, 155, 170), ol=OL - 2, gloss=0.6)

def cases(c):
    c.fill(c.mask(E(C, 214, 96, 22)), (60, 64, 80), ol=OL, gloss=0.2)
    c.fill(c.mask(RR(C, 186, 150, 50, 14)), (235, 238, 248), ol=OL, gloss=0.4)
    c.fill(c.mask(RR(C, 160, 168, 18, 9)), GOLD, ol=OL, gloss=0.5)
    c.glow(c.mask(RR(C, 160, 168, 18, 9)), (255, 230, 120), 5, 0.4)
    c.fill(c.mask(RR(C, 82, 96, 130, 12, 8)), WHITE, ol=OL, gloss=0.2)
    c.fill(c.mask(RR(C, 82, 78, 112, 8, 8)), (255, 120, 60), ol=0, gloss=0.5)
    c.fill(c.mask(STAR(C, 82, 22, 9, 5, -82)), WHITE, ol=0, gloss=0, rim=0)


def plus(c):
    m = c.mask(RR(C, C, 200, 70, 18), RR(C, C, 70, 200, 18))
    c.fill(m, TINT, ol=OL, gloss=0.6)


def trophy(c):
    c.fill(c.mask(ARC(C - 66, 96, 18, 34, 90, 270, 40)), GOLD, ol=OL, gloss=0.4)
    c.fill(c.mask(ARC(C + 66, 96, 18, 34, -90, 90, 40)), GOLD, ol=OL, gloss=0.4)
    cup = c.mask(E(C, 80, 74, 20), [(C - 74, 80), (C + 74, 80), (C + 54, 132), (C, 150), (C - 54, 132)], E(C, 126, 56, 30))
    c.fill(cup, GOLD, ol=OL, gloss=0.6)
    c.fill(c.mask(RR(C, 168, 30, 40, 6)), dark(GOLD, 0.1), ol=OL, gloss=0.4)
    c.fill(c.mask(RR(C, 206, 120, 40, 10)), (150, 90, 50), ol=OL, gloss=0.4)
    c.fill(c.mask(RR(C, 206, 70, 16, 4)), light(GOLD, 0.3), ol=0, gloss=0.3, rim=0)
    c.fill(c.mask(STAR(C, 104, 26, 11, 5)), light(GOLD, 0.65), ol=0, gloss=0, rim=0)


DRAW = {name: globals()[name] for name in ORDER}


def render(name):
    c = Canvas(N, N)
    DRAW[name](c)
    return c.image()

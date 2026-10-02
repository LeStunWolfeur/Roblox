"""
Petite boîte à outils de dessin "autocollant" (contour sombre, volume, reflet)
pour générer les images du jeu : illustrations des cartes et icônes.

Tout est dessiné en coordonnées logiques puis rendu S fois plus grand
(sur-échantillonnage) et réduit à la fin, ce qui donne des bords lisses.
"""

import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

S = 4
INK = (28, 22, 40)
WHITE = (255, 255, 255)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def light(c, t=0.3):
    return mix(c, WHITE, t)


def dark(c, t=0.3):
    return mix(c, (0, 0, 0), t)


def hsv(h, s, v):
    import colorsys

    r, g, b = colorsys.hsv_to_rgb(h % 1, s, v)
    return (int(r * 255), int(g * 255), int(b * 255))


# --------------------------------------------------------------- formes


def E(cx, cy, rx, ry=None, rot=0, n=72):
    """ellipse (points)"""
    ry = rx if ry is None else ry
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = math.cos(a) * rx, math.sin(a) * ry
        pts.append((cx + x * c - y * s, cy + x * s + y * c))
    return pts


def RR(cx, cy, w, h, r, rot=0, n=10):
    """rectangle arrondi (points)"""
    r = min(r, w / 2, h / 2)
    pts = []
    corners = [(w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)]
    for x0, y0, a0 in corners:
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((x0 + math.cos(a) * r, y0 + math.sin(a) * r))
    return rot_pts(pts, cx, cy, rot)


def rot_pts(pts, cx, cy, rot):
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    return [(cx + x * c - y * s, cy + x * s + y * c) for x, y in pts]


def CAP(x1, y1, x2, y2, r, r2=None):
    """capsule entre deux points (membres, tiges)"""
    r2 = r if r2 is None else r2
    a = math.atan2(y2 - y1, x2 - x1)
    pts = []
    for i in range(19):
        t = a + math.pi / 2 + math.pi * i / 18
        pts.append((x1 + math.cos(t) * r, y1 + math.sin(t) * r))
    for i in range(19):
        t = a - math.pi / 2 + math.pi * i / 18
        pts.append((x2 + math.cos(t) * r2, y2 + math.sin(t) * r2))
    return pts


def STAR(cx, cy, r1, r2, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        a = math.radians(rot + 180 * i / n)
        r = r1 if i % 2 == 0 else r2
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def ARC(cx, cy, r1, r2, a0, a1, n=40):
    """bande d'anneau entre deux angles (degrés)"""
    pts = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((cx + math.cos(a) * r2, cy + math.sin(a) * r2))
    for i in range(n, -1, -1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((cx + math.cos(a) * r1, cy + math.sin(a) * r1))
    return pts


def BEZ(p0, p1, p2, n=24):
    out = []
    for i in range(n + 1):
        t = i / n
        out.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    return out


def STROKE(pts, r):
    """trait épais le long d'une suite de points (réunion de capsules)"""
    return [("cap", pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], r) for i in range(len(pts) - 1)]


# ------------------------------------------------------------- toile


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.W, self.H = w * S, h * S
        self.rgb = np.zeros((self.H, self.W, 3), np.float32)
        self.a = np.zeros((self.H, self.W), np.float32)

    # --- masques
    def mask(self, *shapes, sub=()):
        m = Image.new("L", (self.W, self.H), 0)
        d = ImageDraw.Draw(m)
        for sh in shapes:
            self._draw(d, sh, 255)
        for sh in sub:
            self._draw(d, sh, 0)
        return np.asarray(m) > 127

    def _draw(self, d, sh, v):
        if isinstance(sh, np.ndarray):
            img = Image.fromarray((sh * 255).astype(np.uint8))
            d.bitmap((0, 0), img, fill=v)
        elif isinstance(sh, list) and sh and isinstance(sh[0], tuple) and len(sh[0]) == 6 and sh[0][0] == "cap":
            for c in sh:
                self._draw(d, CAP(*c[1:]), v)
        elif isinstance(sh, tuple) and sh and sh[0] == "cap":
            self._draw(d, CAP(*sh[1:]), v)
        else:
            d.polygon([(x * S, y * S) for x, y in sh], fill=v)

    # --- composition
    def over(self, color_arr, alpha):
        """alpha : tableau 0..1 ; color_arr : HxWx3 ou couleur"""
        if not isinstance(color_arr, np.ndarray):
            color_arr = np.array(color_arr, np.float32)
        al = alpha[..., None]
        self.rgb = self.rgb * (1 - al) + color_arr * al
        self.a = self.a + alpha * (1 - self.a)

    def flat(self, m, color, alpha=1.0, blur=0):
        al = m.astype(np.float32) * alpha
        if blur:
            al = ndimage.gaussian_filter(al, blur * S)
        self.over(color, al)

    def outline(self, m, width, color=INK, alpha=1.0):
        if width <= 0:
            return
        y0, y1, x0, x1 = bbox(m, int(width * S) + 4, self.H, self.W)
        sub = m[y0:y1, x0:x1]
        d = ndimage.distance_transform_edt(~sub)
        ring = np.zeros_like(self.a)
        ring[y0:y1, x0:x1] = np.clip(width * S - d + 0.5, 0, 1)
        self.over(color, ring * alpha)

    def fill(self, m, color, ol=3.0, shade=1.0, gloss=0.5, ink=INK, rim=1.0, top=0.28, bottom=0.26, alpha=1.0, glossy=None):
        """remplit avec volume : dégradé vertical + bord assombri + reflet"""
        if not m.any():
            return m
        self.outline(m, ol, ink, alpha)
        y0, y1, x0, x1 = bbox(m, 2, self.H, self.W)
        sub = m[y0:y1, x0:x1]
        h, w = sub.shape
        base = np.array(color, np.float32)
        hi = np.array(light(color, top), np.float32)
        lo = np.array(dark(color, bottom), np.float32)
        ys = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
        col = hi * (1 - ys) + lo * ys
        col = col * np.ones((1, w, 1), np.float32)
        col = col * shade + base * (1 - shade)
        if rim:
            d = ndimage.distance_transform_edt(sub)
            k = max(2.0, 0.22 * min(h, w))
            edge = np.clip(1 - d / k, 0, 1) ** 1.7
            xs = np.linspace(-1, 1, w, dtype=np.float32)[None, :]
            yy = np.linspace(-1, 1, h, dtype=np.float32)[:, None]
            side = np.clip(0.55 + 0.35 * xs + 0.45 * yy, 0, 1)
            amt = (edge * side * 0.38 * rim)[..., None]
            col = col * (1 - amt) + np.array(dark(color, 0.55), np.float32) * amt
        full = np.zeros((self.H, self.W, 3), np.float32)
        full[y0:y1, x0:x1] = col
        al = np.zeros_like(self.a)
        al[y0:y1, x0:x1] = sub.astype(np.float32) * alpha
        self.over(full, al)
        if gloss:
            g = glossy if glossy is not None else self.gloss_mask(sub, (y0, x0))
            self.over(WHITE, g * gloss * alpha)
        return m

    def gloss_mask(self, sub, off):
        h, w = sub.shape
        y0, x0 = off
        d = ndimage.distance_transform_edt(sub)
        inner = d > max(2, 0.07 * min(h, w))
        img = Image.new("L", (w, h), 0)
        ImageDraw.Draw(img).polygon(E(w * 0.36, h * 0.24, w * 0.24, h * 0.12, -18), fill=255)
        hl = (np.asarray(img) > 127) & inner
        hl = ndimage.gaussian_filter(hl.astype(np.float32), 0.6 * S)
        full = np.zeros_like(self.a)
        full[y0:y0 + h, x0:x0 + w] = hl
        return full

    def shadow(self, cx, cy, rx, ry, alpha=0.35):
        m = self.mask(E(cx, cy, rx, ry))
        self.flat(m, (0, 0, 0), alpha, blur=2.5)

    def glow(self, m, color, radius=8, alpha=0.8):
        al = ndimage.gaussian_filter(m.astype(np.float32), radius * S)
        al = np.clip(al * 2.2, 0, 1)
        self.over(color, al * alpha)

    def image(self):
        rgb = np.clip(self.rgb, 0, 255)
        arr = np.dstack([rgb, np.clip(self.a, 0, 1) * 255]).astype(np.uint8)
        # passage en "prémultiplié" pour réduire sans halo puis retour
        img = Image.fromarray(arr, "RGBA")
        pre = img.convert("RGBa").resize((self.w, self.h), Image.LANCZOS)
        return pre.convert("RGBA")


def bbox(m, pad, H, W):
    ys = np.where(m.any(axis=1))[0]
    xs = np.where(m.any(axis=0))[0]
    if len(ys) == 0:
        return 0, 1, 0, 1
    return max(0, ys[0] - pad), min(H, ys[-1] + pad + 1), max(0, xs[0] - pad), min(W, xs[-1] + pad + 1)


# ------------------------------------------------------------- visages


def eyes(c, cx, cy, gap, r, style="round", look=(0.15, 0.1), color=WHITE, pupil=INK, ol=2.5, angry=False, sleepy=False):
    for side in (-1, 1):
        ex = cx + side * gap
        if style == "dot":
            c.fill(c.mask(E(ex, cy, r * 0.55, r * 0.7)), pupil, ol=0, gloss=0, rim=0, shade=0)
            c.flat(c.mask(E(ex - r * 0.15, cy - r * 0.3, r * 0.2)), WHITE, 0.95)
            continue
        if style == "glow":
            m = c.mask(E(ex, cy, r, r * 0.8))
            c.glow(m, color, 3, 0.9)
            c.fill(m, color, ol=ol, gloss=0, rim=0, shade=0)
            c.flat(c.mask(E(ex, cy, r * 0.55, r * 0.45)), WHITE, 0.9)
            continue
        m = c.mask(E(ex, cy, r, r * 1.08))
        c.fill(m, color, ol=ol, gloss=0, rim=0.6, shade=0.2)
        px, py = ex + look[0] * r, cy + look[1] * r
        c.fill(c.mask(E(px, py, r * 0.56, r * 0.62)), pupil, ol=0, gloss=0, rim=0, shade=0)
        c.flat(c.mask(E(px - r * 0.2, py - r * 0.25, r * 0.22)), WHITE, 1)
        c.flat(c.mask(E(px + r * 0.22, py + r * 0.25, r * 0.1)), WHITE, 0.9)
        if sleepy:
            c.fill(c.mask(E(ex, cy - r * 0.55, r * 1.12, r * 0.62)), sleepy, ol=ol * 0.8, gloss=0, rim=0.3)
        if angry:
            brow = CAP(ex - side * r * 1.0, cy - r * 1.35, ex + side * r * 0.6, cy - r * 0.75, r * 0.2)
            c.flat(c.mask(brow), INK, 1)


def smile(c, cx, cy, w, open_=True, tongue=(255, 110, 120), teeth=False, fang=False):
    if open_:
        m = c.mask(E(cx, cy, w, w * 0.62), sub=[RR(cx, cy - w * 0.6, w * 2.4, w * 1.2, 0)])
        c.fill(m, (90, 25, 40), ol=2.2, gloss=0, rim=0, shade=0.2)
        t = c.mask(E(cx, cy + w * 0.5, w * 0.62, w * 0.36)) & m
        c.flat(t, tongue)
        if teeth:
            c.flat(c.mask(RR(cx, cy + w * 0.08, w * 1.3, w * 0.22, w * 0.08)) & m, WHITE)
        if fang:
            for s in (-1, 1):
                c.fill(c.mask([(cx + s * w * 0.55, cy - 1), (cx + s * w * 0.3, cy - 1), (cx + s * w * 0.43, cy + w * 0.55)]), WHITE, ol=1.2, gloss=0, rim=0)
    else:
        c.flat(c.mask(STROKE(BEZ((cx - w, cy - w * 0.15), (cx, cy + w * 0.7), (cx + w, cy - w * 0.15)), 1.6)), INK)


def cheeks(c, cx, cy, gap, r=6, color=(255, 120, 150)):
    for s in (-1, 1):
        c.flat(c.mask(E(cx + s * gap, cy, r, r * 0.6)), color, 0.55, blur=0.6)


def sparkle(c, cx, cy, r, color=WHITE, alpha=1.0):
    m = c.mask(STAR(cx, cy, r, r * 0.22, 4, -90))
    c.glow(m, color, r * 0.18, 0.6 * alpha)
    c.flat(m, color, alpha)

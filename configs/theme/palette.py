#!/usr/bin/env python3
"""palette.py -- derive a dark colour palette from a wallpaper.

    palette.py <image> [--out theme.conf]        wallpaper -> theme.conf
    palette.py --render theme.conf templates/ generated/   theme.conf -> per-app files

theme.conf is the ONE source of truth for colours: plain `key = #rrggbb`
lines (plus `wallpaper = <path>`). Every app config includes a file that is
rendered from it, so editing theme.conf by hand and running
`theme-apply --render` works exactly like picking a new wallpaper.

Only needs Pillow for the wallpaper step; --render is pure standard library.
"""
import colorsys
import math
import os
import re
import sys


# ---------------------------------------------------------------- colour math
def hsl_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb((h % 360) / 360.0, min(max(l, 0), 1), min(max(s, 0), 1))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def dominant_hue(path):
    """Return (hue 0-360, saturation 0-1) of the wallpaper's dominant accent."""
    from PIL import Image

    img = Image.open(path).convert("RGB")
    img.thumbnail((160, 160))
    bins = [0.0] * 36
    sat_sum = [0.0] * 36
    total_w = 0.0
    rs = gs = bs = 0.0
    n = 0
    pixels = img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()
    for r, g, b in pixels:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        rs, gs, bs, n = rs + r, gs + g, bs + b, n + 1
        # favour vivid, mid-bright pixels; ignore near-black/white/grey
        w = (s ** 1.5) * (1 - abs(v - 0.65)) if (s > 0.18 and 0.15 < v < 0.98) else 0.0
        if w <= 0:
            continue
        i = int(h * 36) % 36
        bins[i] += w
        sat_sum[i] += w * s
        total_w += w
    if total_w < n * 0.002:  # (almost) monochrome image: use its average tint
        h, s, _ = colorsys.rgb_to_hsv(rs / n / 255, gs / n / 255, bs / n / 255)
        return h * 360, min(s, 0.25)
    # smooth over neighbouring bins so one noisy bin doesn't win
    smooth = [bins[i - 1] * 0.5 + bins[i] + bins[(i + 1) % 36] * 0.5 for i in range(36)]
    best = max(range(36), key=lambda i: smooth[i])
    # circular weighted mean around the winning bin for sub-bin accuracy
    x = y = 0.0
    for d in (-1, 0, 1):
        j = (best + d) % 36
        ang = math.radians((j + 0.5) * 10)
        x += bins[j] * math.cos(ang)
        y += bins[j] * math.sin(ang)
    hue = math.degrees(math.atan2(y, x)) % 360
    sat = sat_sum[best] / bins[best] if bins[best] else 0.5
    return hue, sat


def build_palette(hue, sat):
    tint = 0.18 + 0.22 * min(sat / 0.6, 1.0)        # how much colour leaks into the greys
    accent_s = 0.55 + 0.30 * min(sat / 0.6, 1.0)
    p = {}
    p["bg"] = hsl_hex(hue, tint, 0.075)
    p["bg_alt"] = hsl_hex(hue, tint, 0.105)
    p["surface"] = hsl_hex(hue, tint, 0.15)
    p["overlay"] = hsl_hex(hue, tint * 0.9, 0.24)
    p["fg"] = hsl_hex(hue, 0.30, 0.90)
    p["fg_dim"] = hsl_hex(hue, 0.15, 0.66)
    p["primary"] = hsl_hex(hue, accent_s, 0.68)
    p["primary_dim"] = hsl_hex(hue, accent_s * 0.8, 0.45)
    p["secondary"] = hsl_hex(hue + 35, accent_s, 0.70)
    p["tertiary"] = hsl_hex(hue - 35, accent_s, 0.70)
    # ANSI: fixed semantic hues (so red still means red), tinted by the theme
    fixed = {"red": 5, "green": 130, "yellow": 45, "blue": 215, "magenta": 300, "cyan": 180}
    for name, base in fixed.items():
        # nudge 12% toward the wallpaper hue so they sit in the same family
        d = ((hue - base + 180) % 360) - 180
        h = base + d * 0.12
        p[name] = hsl_hex(h, 0.55 + 0.1 * min(sat / 0.6, 1.0), 0.66)
        p["bright_" + name] = hsl_hex(h, 0.65, 0.74)
    p["black"] = p["surface"]
    p["bright_black"] = p["overlay"]
    p["white"] = hsl_hex(hue, 0.15, 0.80)
    p["bright_white"] = p["fg"]
    return p


# ------------------------------------------------------------------ theme.conf
KEY_ORDER = ["bg", "bg_alt", "surface", "overlay", "fg", "fg_dim", "primary", "primary_dim",
             "secondary", "tertiary"] + [
    n for c in ("black", "red", "green", "yellow", "blue", "magenta", "cyan", "white")
    for n in (c, "bright_" + c)
]


def write_conf(path, palette, wallpaper):
    lines = [
        "# theme.conf -- the single colour palette every config reads.",
        "# Regenerate from a wallpaper:  theme-apply <image>   |   theme-apply --random",
        "# Or edit the colours below and run:  theme-apply --render",
        "wallpaper = %s" % wallpaper,
    ]
    lines += ["%s = %s" % (k, palette[k]) for k in KEY_ORDER]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def read_conf(path):
    d = {}
    with open(path) as f:
        for line in f:
            if line.lstrip().startswith("#"):
                continue
            m = re.match(r"\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$", line)
            if m:
                d[m.group(1)] = m.group(2)
    return d


# -------------------------------------------------------------------- rendering
def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def render(conf, tpl_dir, out_dir):
    pal = read_conf(conf)
    os.makedirs(out_dir, exist_ok=True)
    pat = re.compile(r"\{\{\s*([a-z_]+)(?:\.(nohash|rgb|rgbcsv))?\s*\}\}")

    def sub(m):
        key, mod = m.group(1), m.group(2)
        if key == "wallpaper":
            return pal.get("wallpaper", "")
        v = pal[key]
        if mod == "nohash":
            return v.lstrip("#")
        if mod == "rgb":
            return "rgb(%d, %d, %d)" % hex_to_rgb(v)
        if mod == "rgbcsv":
            return "%d, %d, %d" % hex_to_rgb(v)
        return v

    for name in sorted(os.listdir(tpl_dir)):
        if not name.endswith(".tpl"):
            continue
        with open(os.path.join(tpl_dir, name)) as f:
            text = f.read()
        with open(os.path.join(out_dir, name[:-4]), "w") as f:
            f.write(pat.sub(sub, text))


def main(argv):
    if len(argv) >= 2 and argv[0] == "--render":
        render(argv[1], argv[2], argv[3])
        return 0
    if not argv:
        print(__doc__)
        return 1
    image, out = argv[0], "theme.conf"
    if "--out" in argv:
        out = argv[argv.index("--out") + 1]
    hue, sat = dominant_hue(image)
    write_conf(out, build_palette(hue, sat), os.path.abspath(image))
    print("hue %.0f  sat %.2f -> %s" % (hue, sat, out))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

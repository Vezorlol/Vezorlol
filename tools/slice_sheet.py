#!/usr/bin/env python3
"""
Режет лист 3x3 из ChatGPT на 9 подарков, убирает фон и кладёт в Assets.xcassets.
  pip install pillow
  python tools/slice_sheet.py sheet_03.png heart bear giftbox rose cake bouquet rocket champagne trophy
(id идут слева направо, сверху вниз — ровно в порядке из BATCH_PROMPTS.md)
Опции: --cols 3 --rows 3 --tol 40 (допуск удаления фона).
"""
import argparse, json, os
from collections import deque
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = f"{ROOT}/App/Resources/Assets.xcassets"

def remove_bg(im, tol):
    im = im.convert("RGBA")
    px = im.load(); w, h = im.size
    if min(px[x, y][3] for x in (0, w - 1) for y in (0, h - 1)) < 250:   # уже прозрачный фон
        return im
    bg = px[0, 0][:3]
    def close(c): return sum(abs(c[i] - bg[i]) for i in range(3)) <= tol * 3
    seen = [[False] * h for _ in range(w)]
    q = deque((x, y) for x in range(w) for y in (0, h - 1)); q.extend((x, y) for y in range(h) for x in (0, w - 1))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[x][y] or not close(px[x, y][:3]): continue
        seen[x][y] = True; px[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return im

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("sheet"); ap.add_argument("ids", nargs="+")
    ap.add_argument("--cols", type=int, default=3); ap.add_argument("--rows", type=int, default=3); ap.add_argument("--tol", type=int, default=40)
    a = ap.parse_args()
    sheet = Image.open(a.sheet); W, H = sheet.size; cw, ch = W // a.cols, H // a.rows
    for i, name in enumerate(a.ids):
        r, c = divmod(i, a.cols)
        cell = remove_bg(sheet.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)), a.tol)
        box = cell.getbbox()
        if box: cell = cell.crop(box)
        side = max(cell.size); sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        sq.paste(cell, ((side - cell.width) // 2, (side - cell.height) // 2))
        sq = sq.resize((408, 408), Image.LANCZOS)
        d = f"{ASSETS}/gift_{name}.imageset"; os.makedirs(d, exist_ok=True)
        sq.save(f"{d}/{name}.png")
        json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "3x"}], "info": {"author": "xcode", "version": 1}}, open(f"{d}/Contents.json", "w"), indent=2)
        print("saved", name)
main()

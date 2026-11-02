#!/usr/bin/env python3
"""Рендерит PNG-графику подарков (Noto Color Emoji, OFL/Apache) в App/Resources/Assets.xcassets/gift_<id>.imageset."""
import json, os, re, sys
from PIL import Image, ImageDraw, ImageFont
FONT = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cat = json.load(open(f"{ROOT}/Core/Sources/GiftCasesCore/Resources/gifts_catalog.json"))
sys.path.insert(0, ROOT)
emoji_table = {}
src = open(f"{ROOT}/Core/Sources/GiftCasesCore/CollectionEmoji.swift").read()
for k, v in re.findall(r'"(\w+)": "([^"]+)"', src): emoji_table[k] = v
font = ImageFont.truetype(FONT, 109)
out = f"{ROOT}/App/Resources/Assets.xcassets"
def render(name, emoji):
    im = Image.new("RGBA", (136, 128), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((0, 0), emoji, font=font, embedded_color=True)
    im = im.resize((408, 384), Image.LANCZOS)
    d = f"{out}/gift_{name}.imageset"; os.makedirs(d, exist_ok=True)
    im.save(f"{d}/{name}.png")
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "3x"}], "info": {"author": "xcode", "version": 1}},
              open(f"{d}/Contents.json", "w"), indent=2)
n = 0
for r in cat["regularGifts"]:
    render(r["id"], r["name"].split(" ")[0]); n += 1
for c in cat["collectibles"]:
    render(c["id"], emoji_table.get(c["id"], "🎁")); n += 1
print("rendered", n)

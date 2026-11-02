#!/usr/bin/env python3
"""
Массовая генерация арта подарков через OpenAI Images API (нужен ваш API-ключ, платно по картинкам).
  pip install openai pillow
  export OPENAI_API_KEY=sk-...            (Windows: set OPENAI_API_KEY=sk-...)
  python generate_gift_art_openai.py --dry-run                 # только показать, что будет сгенерировано и сколько
  python generate_gift_art_openai.py --base --limit 10         # 10 базовых картинок коллекций (проба)
  python generate_gift_art_openai.py --base                    # все 124 + 11 обычных
  python generate_gift_art_openai.py --variants                # по картинке на КАЖДУЮ модель (нужен telegram_gift_attributes.json)
Скрипт возобновляемый: уже готовые файлы пропускает. Результат: App/Resources/Assets.xcassets/gift_*.imageset
"""
import argparse, base64, json, os, re, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = f"{ROOT}/App/Resources/Assets.xcassets"
CAT = json.load(open(f"{ROOT}/Core/Sources/GiftCasesCore/Resources/gifts_catalog.json"))

STYLE = ("Glossy 3D-rendered collectible toy icon, soft studio lighting with subtle rim light, rounded friendly shapes, "
         "rich saturated colors, a few tiny sparkles and small stars floating around it like items orbiting a treasure case, "
         "single object centered, fully transparent background, no text, no watermark, no logos. "
         "Original artwork: do not copy any existing brand, character or Telegram's official gift art.")

def slug(s): return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")

def jobs(args):
    out = []
    if args.base:
        for r in CAT["regularGifts"]:
            name = re.sub(r"^\S+\s", "", r["name"])
            out.append((r["id"], f"{name} (a cute gift item). {STYLE}"))
        for c in CAT["collectibles"]:
            out.append((c["id"], f"A collectible gift called \"{c['name']}\". Invent a charming, instantly readable object that fits the name. {STYLE}"))
    if args.variants:
        data = json.load(open(f"{ROOT}/telegram_gift_attributes.json"))
        by_title = {slug(v["title"] or ""): v for v in data["collections"].values()}
        for c in CAT["collectibles"]:
            v = by_title.get(slug(c["name"]))
            if not v: continue
            for m in v["models"]:
                if m.get("crafted"): continue
                out.append((f"{c['id']}__{slug(m['name'])}",
                            f"The collectible \"{c['name']}\", variant named \"{m['name']}\": same object and pose as the base design, "
                            f"but restyled to match the variant name (colors, outfit, material, small themed details). {STYLE}"))
    return out

def save(name, png_bytes):
    d = f"{ASSETS}/gift_{name}.imageset"; os.makedirs(d, exist_ok=True)
    open(f"{d}/{name}.png", "wb").write(png_bytes)
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "3x"}], "info": {"author": "xcode", "version": 1}},
              open(f"{d}/Contents.json", "w"), indent=2)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", action="store_true"); ap.add_argument("--variants", action="store_true")
    ap.add_argument("--limit", type=int); ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--quality", default="medium", choices=["low", "medium", "high"])
    ap.add_argument("--overwrite", action="store_true")
    a = ap.parse_args()
    if not (a.base or a.variants): ap.error("укажите --base и/или --variants")
    todo = [(n, p) for n, p in jobs(a) if a.overwrite or not os.path.exists(f"{ASSETS}/gift_{n}.imageset/{n}.png")]
    if a.limit: todo = todo[:a.limit]
    print(f"к генерации: {len(todo)} картинок (качество {a.quality}). Ориентир по цене: low≈$0.01, medium≈$0.04, high≈$0.17 за картинку.")
    if a.dry_run:
        for n, p in todo[:5]: print(" -", n)
        return
    from openai import OpenAI
    client = OpenAI()
    for i, (n, p) in enumerate(todo, 1):
        for attempt in range(4):
            try:
                r = client.images.generate(model="gpt-image-1", prompt=p, size="1024x1024",
                                           background="transparent", output_format="png", quality=a.quality)
                save(n, base64.b64decode(r.data[0].b64_json)); print(f"[{i}/{len(todo)}] {n}"); break
            except Exception as e:
                print("retry", n, type(e).__name__, e, file=sys.stderr); time.sleep(5 * (attempt + 1))

main()

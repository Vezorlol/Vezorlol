#!/usr/bin/env python3
"""
Из telegram_gift_attributes.json строит промпты для ручной генерации ВАРИАНТОВ улучшения (моделей) в ChatGPT
и готовые команды нарезки. Результат: docs/VARIANT_PROMPTS.md
  python tools/build_variant_prompts.py [--only plush_pepe durovs_cap] [--per-sheet 9]
Приоритет: сначала самые дорогие коллекции (их чаще всего видно в игре).
"""
import argparse, json, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def slug(s): return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")
ap = argparse.ArgumentParser(); ap.add_argument("--only", nargs="*"); ap.add_argument("--per-sheet", type=int, default=9)
a = ap.parse_args()
cat = json.load(open(f"{ROOT}/Core/Sources/GiftCasesCore/Resources/gifts_catalog.json"))
data = json.load(open(f"{ROOT}/telegram_gift_attributes.json"))
by_title = {slug(v["title"] or ""): v for v in data["collections"].values()}
STYLE = ("Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, "
         "rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, "
         "only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.")
out = ["# Промпты вариантов улучшения (модели)\n",
       "Для каждой коллекции: 1) в том же чате отправьте базовую картинку коллекции и напишите «это базовый дизайн», 2) вставьте промпт листа, "
       "3) скачайте и выполните команду нарезки под ним.\n"]
cols = sorted(cat["collectibles"], key=lambda c: -c["floor"])
total = 0
for c in cols:
    if a.only and c["id"] not in a.only: continue
    v = by_title.get(slug(c["name"]))
    if not v: continue
    models = [m for m in v["models"] if not m.get("crafted")]
    out.append(f"## {c['name']} ({len(models)} моделей)\n")
    for i in range(0, len(models), a.per_sheet):
        chunk = models[i:i + a.per_sheet]; n = i // a.per_sheet + 1
        rows = (len(chunk) + 2) // 3
        names = "\n".join(f"{k+1}. {m['name']}" for k, m in enumerate(chunk))
        ids = " ".join(f"{c['id']}__{slug(m['name'])}" for m in chunk)
        out.append(f"### {c['name']} — лист {n}\n```\nCreate ONE image: a 3x{rows} grid sheet of {len(chunk)} variants of the collectible \"{c['name']}\". {STYLE}\n"
                   f"Variant names, left-to-right, top-to-bottom:\n{names}\n```\n```\npython tools/slice_sheet.py {c['id']}_v{n}.png --rows {rows} {ids}\n```\n")
        total += 1
open(f"{ROOT}/docs/VARIANT_PROMPTS.md", "w").write("\n".join(out))
print("листов:", total)

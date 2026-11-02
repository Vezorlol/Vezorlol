#!/usr/bin/env python3
"""telegram_gift_attributes.json -> Core/.../Resources/gift_attributes.json (компактный формат для игры).
Крафтовые модели исключаются (их выдаёт только крафт)."""
import json, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
slug = lambda s: re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")
src = json.load(open(f"{ROOT}/telegram_gift_attributes.json", encoding="utf-8"))
cat = json.load(open(f"{ROOT}/Core/Sources/GiftCasesCore/Resources/gifts_catalog.json"))
by = {slug(v["title"] or ""): v for v in src["collections"].values()}
out = {"backdrops": [[b["id"], b["name"], b["center"], b["edge"], b["pattern"], b["text"], b["permille"]] for b in src["backdrops"]],
       "collections": {}}
for c in cat["collectibles"]:
    v = by[slug(c["name"])]
    models, seen = [], {}
    for m in v["models"]:
        if m["crafted"] or not m["permille"]: continue
        n = m["name"]; seen[n] = seen.get(n, 0) + 1
        models.append([n if seen[n] == 1 else f"{n} {seen[n]}", m["permille"]])   # в данных бывают одинаковые названия
    out["collections"][c["id"]] = {
        "models": models,
        "patterns": [[p["name"], p["permille"]] for p in v["patterns"]]}
path = f"{ROOT}/Core/Sources/GiftCasesCore/Resources/gift_attributes.json"
json.dump(out, open(path, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print(os.path.getsize(path) // 1024, "KB;", sum(len(x["models"]) for x in out["collections"].values()), "моделей")

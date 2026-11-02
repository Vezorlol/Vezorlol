#!/usr/bin/env python3
"""
Выгружает из официального API Telegram ВСЕ подарки и ВСЕ их улучшения (модели, узоры, фоны + редкость в ‰).
Запускать вам, под своим аккаунтом (метод доступен только пользователям, не ботам).

Подготовка:
  1) Зайдите на https://my.telegram.org -> API development tools -> получите api_id и api_hash.
  2) pip install -U telethon        (нужен свежий Telethon, где есть payments.GetStarGiftUpgradeAttributesRequest)
  3) python export_telegram_attributes.py
     Введите номер телефона и код из Telegram (сессия сохранится только у вас в файле export.session).
Результат: telegram_gift_attributes.json — положите его в корень репозитория и пришлите мне.
Никогда не отправляйте api_hash, файл .session и коды входа другим людям.
"""
import asyncio, json, os, sys
from telethon import TelegramClient, functions

API_ID = int(os.environ.get("TG_API_ID") or input("api_id: "))
API_HASH = os.environ.get("TG_API_HASH") or input("api_hash: ")

def rarity_permille(a):
    r = getattr(a, "rarity", None)
    return getattr(r, "permille", None), (type(r).__name__ if r is not None else None)

async def main():
    async with TelegramClient("export", API_ID, API_HASH) as client:
        res = await client(functions.payments.GetStarGiftsRequest(hash=0))
        gifts = res.gifts
        out = {"backdrops": {}, "collections": {}}
        for g in gifts:
            if not getattr(g, "upgrade_stars", None) and not getattr(g, "can_upgrade", True):
                pass
            try:
                attrs = (await client(functions.payments.GetStarGiftUpgradeAttributesRequest(gift_id=g.id))).attributes
            except Exception as e:  # подарок без улучшения / FLOOD_WAIT
                print("skip", g.id, getattr(g, "title", ""), type(e).__name__, e, file=sys.stderr)
                await asyncio.sleep(1)
                continue
            col = {"gift_id": g.id, "title": getattr(g, "title", None), "stars": getattr(g, "stars", None),
                   "models": [], "patterns": []}
            for a in attrs:
                kind = type(a).__name__
                pm, tier = rarity_permille(a)
                if kind == "StarGiftAttributeModel":
                    col["models"].append({"name": a.name, "permille": pm, "tier": tier,
                                          "crafted": bool(getattr(a, "crafted", False))})
                elif kind == "StarGiftAttributePattern":
                    col["patterns"].append({"name": a.name, "permille": pm, "tier": tier})
                elif kind == "StarGiftAttributeBackdrop":
                    out["backdrops"][a.backdrop_id] = {
                        "id": a.backdrop_id, "name": a.name, "center": a.center_color, "edge": a.edge_color,
                        "pattern": a.pattern_color, "text": a.text_color, "permille": pm, "tier": tier}
            out["collections"][str(g.id)] = col
            print("ok", col["title"], len(col["models"]), "models", len(col["patterns"]), "patterns")
            await asyncio.sleep(0.4)
        out["backdrops"] = list(out["backdrops"].values())
        json.dump(out, open("telegram_gift_attributes.json", "w"), ensure_ascii=False, indent=1)
        print("saved telegram_gift_attributes.json")

asyncio.run(main())

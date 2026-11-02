# Промпт для ChatGPT: графика и редизайн Starbox

## Часть 1. Общий стиль (отправить первой, дождаться ответа)

```
You are a senior mobile UI/UX and 3D illustration artist. I am building an iOS app
"Starbox: Case Simulator": an offline simulator where you open cases and collect virtual
collectible gifts (virtual stars, no real money). The UI must feel like modern iOS / Telegram:
clean, airy, rounded cards (radius 14), SF Pro typography, soft shadows, accent #2AABEE,
star gradient #FFD43B -> #F5A623, success #34C759, danger #FF3B30, rarity colors:
Common #8E8E93, Uncommon #34C759, Rare #2AABEE, Epic #AF52DE, Legendary #FF9500.
Support light and dark themes.

ART STYLE for all gift illustrations: glossy 3D-rendered toy-like objects, soft studio lighting,
subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles, transparent
background, centered, 1024x1024 PNG, no text, no watermark, no logos.
IMPORTANT: everything must be ORIGINAL artwork. Do not copy or imitate any existing brand,
Telegram's official gift stickers or animations, or any trademarked characters.

Confirm you understood the style, then wait for my next message.
```

## Часть 2. Подарки (по одному или пачкой)

```
Create original glossy 3D icons, transparent background, 1024x1024, in the agreed style, for
these gifts. One image each, object centered with small sparkles around it:
heart, teddy bear, gift box with ribbon, red rose, birthday cake, bouquet, rocket,
champagne bottle, golden trophy, engagement ring, diamond.
```

Для коллекционных (124 штуки) проще генерировать по темам, по 6–9 в сетке 3x3 на одном листе:
«Make a 3x3 sheet of 9 separate original glossy 3D collectible icons on transparent background:
[вставить названия из каталога]. Equal spacing, no text.»

## Часть 3. Кейсы с летающими подарками

```
Create 10 case illustrations for the app, 1024x1024, transparent background, same glossy 3D style.
Each: a closed, slightly open glowing treasure-chest-like case in the center (unique shape and
color per case), with the gifts of that case FLOATING AND ORBITING around it at different sizes
and depths (depth-of-field blur for far ones), little stars and light rays coming out of the lid.
Rarity of the case = glow color (cheap: soft white/blue; expensive: gold/orange/purple aura).

1. "Сердечный" - pink case, floating hearts and teddy bears
2. "Новичок" - blue starter case, gift boxes, roses, cakes, rockets
3. "Праздничный" - festive red/gold case, champagne, cake, confetti, candy canes, santa hat
4. "Любовь" - rose-gold case, rings, roses, bouquets, cupid hearts
5. "Хэллоуин" - dark purple case, pumpkins, witch hat, potion, evil eye, bats
6. "Магия" - indigo case, glowing crystal ball, potions, lamps, amulets, mystic runes
7. "Стиль" - black and chrome case, watch, rings, top hat, perfume, sneakers
8. "Дуров" - dark blue case with a paper plane motif, caps, glasses, helmets (original, no real person)
9. "Легенды" - golden-diamond case, legendary trophies, cups, crowns, huge orange aura
10. "Pepe" - emerald-green case, floating frog-themed collectibles, golden aura

Do not add text. Each image should look good as a 300x300 thumbnail on a white AND a dark background.
```

## Часть 4. Редизайн интерфейса и иконки

```
Now redesign the UI. Create high-fidelity iPhone 15 Pro mockups (light + dark) for these screens:
1) Cases grid (2 columns, free-case banner with timer, locked cases with lock + "Доступно с ур. N")
2) Case opening: horizontal roulette of ~60 gift cards, center pointer line, confetti of stars
3) Result sheet (bottom sheet, gift card, "Забрать" and "Продать за N" buttons)
4) Inventory (3-column grid, segmented control Все / Коллекционные / Обычные, selection mode)
5) Gift detail sheet (collectible card with radial gradient backdrop and ring pattern of symbols,
   table: Модель, Фон, Узор, Тираж, Стоимость, chart of 30-day index)
6) Games list + Crash graph screen + Coin Flip with 3D coin
7) Profile (avatar with initials on gradient, hexagonal level badge, piggy bank ring, daily bonus row)
Tab bar: Кейсы, Игры, Подарки, Маркет, Профиль with translucent material background.

Also create:
- App icon 1024x1024 (a glossy gold star on a blue gradient, original design, rounded square)
- A consistent set of 24 tab/action line icons (SF Symbols weight "medium", 2px stroke)
- A custom star currency icon (5-point, rounded tips, gold gradient) in 3 sizes
Keep the design system consistent: spacing 16, card radius 14, buttons height 50 radius 12.
Return an annotated spec (colors, sizes, fonts) I can hand to a developer.
```

## Как потом подключить картинки
1. Подарки: сохранить как `gift_<id>.png` (id из `gifts_catalog.json`, например `gift_heart.png`) и положить в `App/Resources/Assets.xcassets/gift_<id>.imageset/`. Приложение подхватит их автоматически вместо эмодзи.
2. Кейсы: `case_1.png`...`case_9.png`, `case_pepe.png` — попросите меня подключить, я добавлю показ в сетке кейсов.
3. Иконка приложения: заменить `AppIcon.appiconset/icon-1024.png`.

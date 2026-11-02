# Gift Cases — офлайн-симулятор кейсов с коллекционными подарками (iOS)

Неофициальный фан-симулятор. Не связан с Telegram. Звёзды и подарки игровые и не имеют реальной ценности.
Полное ТЗ — [`docs/SPEC.md`](docs/SPEC.md).

## Структура

| Папка | Что внутри | Проверено |
|---|---|---|
| `Core/` | Swift-пакет `GiftCasesCore`: каталог, экономика, кейсы, Coin Flip, Crash, Крафт, Апгрейд, Маркет/Магазин, provably fair (HMAC-SHA256), доверенное время, игровой движок с атомарными транзакциями. Без UI, собирается на macOS и Linux. | **52 юнит-теста** (`cd Core && swift test -c release`) |
| `App/` | SwiftUI-приложение (iOS 17+): 5 вкладок, графика подарков (PNG, `tools/gen_gift_art.py`), RU/EN локализация, иконка. | CI на macOS (`.github/workflows/ios.yml`) собирает и выдаёт неподписанный `.ipa` |

Весь баланс — в JSON: `gifts_catalog.json` (каталог, кейсы, уровни) и `economy_rules.json` (ставки, множители, лимиты, индекс, крафт и т. д.).

## Запуск приложения

```bash
brew install xcodegen
cd App && xcodegen generate && open GiftCases.xcodeproj
```

## Тесты ядра

```bash
cd Core && swift test -c release
```

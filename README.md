# Scales

iOS-приложение (SwiftUI + SwiftData) для чтения веса с безымянных BLE-весов
OKOK-совместимого протокола. Без рекламы, без аккаунтов.

## Что умеет
- Читает вес прямо из BLE-рекламы весов (подключение не требуется).
- Показывает текущий вес крупно.
- Сохраняет замеры в историю (SwiftData).
- Несколько пользователей (логин по имени, без пароля).

## Требования
- iOS 17.0+ на устройстве (требование SwiftData).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) для генерации проекта
  (или создайте проект вручную, см. ниже).

## Сборка без Mac (рекомендуется)
Собрать `.ipa` можно в облаке через GitHub Actions, а установить на iPhone —
через AltStore с бесплатным Apple ID.

1. Создайте **публичный** репозиторий на GitHub и запушьте этот код.
2. Вкладка **Actions** → дождитесь зелёного прогона `Build unsigned IPA`.
3. Скачайте артефакт **Scales-unsigned** (файл `Scales.ipa`).
4. На Windows установите [AltServer](https://altstore.io), а через него — AltStore
   на iPhone (нужен iTunes/драйвер Apple и подключение по USB).
5. Загрузите `Scales.ipa` в AltStore на телефоне (например, через «Файлы» или
   перетаскивание) — он подпишет приложение вашим Apple ID и установит его.

Ограничения бесплатного Apple ID: подпись живёт **7 дней** (AltStore продлевает
по Wi-Fi автоматически, пока AltServer запущен в той же сети), максимум
3 приложения одновременно.

> `.github/workflows/build.yml` собирает **неподписанный** `.ipa`
> (`CODE_SIGNING_ALLOWED=NO`). Подписью занимается AltStore на телефоне.

## Сборка на Mac

### Вариант A — XcodeGen
```bash
brew install xcodegen
xcodegen generate
open Scales.xcodeproj
```
Затем выберите свой iPhone, доверьтесь подписи (Signing & Capabilities) и нажмите Run.

### Вариант B — вручную
1. В Xcode: File → New → Project → iOS App (SwiftUI), имя `Scales`.
2. Удалите автоматически созданный `ContentView.swift`.
3. Добавьте папку `Sources` в таргет (Add Files…).
4. В Info.plist добавьте ключ `NSBluetoothAlwaysUsageDescription`
   (например: «Доступ к Bluetooth нужен для чтения данных с весов.»).
5. Добавьте папку `Tests` в тестовый таргет.

## Как это работает
Весы OKOK передают вес в рекламных пакетах BLE (manufacturer-specific data),
без GATT-подключения. Парсер `OKOKAdvertisementParser` разбирает 4 варианта
протокола (V20, V11, VF0, C0). Подробности — в `PROTOCOL.md`.

## Структура
```
Sources/
  ScalesApp.swift            точка входа
  Models/                    SwiftData-модели (профили, замеры)
  Bluetooth/
    OKOKAdvertisementParser  разбор рекламы
    ScaleScanner              сканирование CoreBluetooth
  Views/                     экраны (весы, история, профили)
Tests/
  OKOKAdvertisementParserTests.swift
```

## Ограничения (v1)
- Сохранение замеров: вес > 0 считается стабильным по флагу в пакете
  (V20/C0) или по 3 одинаковым подряд (V11/VF0). Сессия сбрасывается при
  нулевом весе.
- Состав тела (жир/мышцы/вода) ещё не считается — формулы есть в `PROTOCOL.md`
  и готовы к переносу.

# Протокол OKOK-совместимых весов (BLE)

Источник: реверс-инжиниринг openScale (GPL v3), файл `OkOkHandler.kt`,
`OkOkV2Lib.kt`. Ссылка на оригинал:
https://github.com/oliexdev/openScale/tree/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth

## Ключевой факт
Весы OKOK работают в режиме **BROADCAST_ONLY** — они НЕ требуют GATT-подключения.
Данные веса приходят в **рекламных пакетах BLE** (manufacturer-specific data).
Значит приложение просто сканирует (пассивно) и разбирает рекламу — ни подключение,
ни характеристики не нужны.

## iOS: откуда брать данные
`CBCentralManager.scanForPeripherals` → `advertisementData[CBAdvertisementDataManufacturerDataKey]` → `NSData`.

Структура `NSData`:
```
[0..1]  Company ID (uint16, LITTLE-endian)
[2...]  payload (массив, индексы ниже считаются от payload[0])
```

Пример: company ID `0x20CA` в пакете лежит байтами `CA 20`.

## Распознавание устройства (по имени)
Считаем устройство OKOK, если имя пустое или одно из:
- `""` (пустое / безымянное)
- `"ADV"`
- `"Chipsea-BLE"`
- `"Yoda0*"` / `"Yoda1*"` (префикс, регистронезависимо)

## Варианты протокола (по company ID)

### V20 — company ID 0x20CA, payload 19 байт
| idx | поле |
|-----|------|
| 6   | flags: bit0 = финальный (стабильный) замер; bit2 = делитель |
| 8   | вес MSB (big-endian) |
| 9   | вес LSB |
| 10  | импеданс MSB |
| 11  | импеданс LSB |
| 12  | XOR-контрольная сумма |

- Сумма: `checksum = 0x20`, затем `checksum ^= payload[i]` для `i in 0..<12`.
  Должна совпасть с `payload[12]`.
- `divider = (flags & 0x04) != 0 ? 100 : 10`
- `weightKg = u16be(payload[8], payload[9]) / divider`
- `impedance = u16be(payload[10], payload[11]) / 10` (Ом)

### V11 — company ID 0x11CA, payload 23 байта
| idx | поле |
|-----|------|
| 3   | вес MSB |
| 4   | вес LSB |
| 9   | body properties |
| 16  | XOR-контрольная сумма |

- Сумма: `checksum = 0xCA ^ 0x11`, затем `checksum ^= payload[i]` для `i in 0..<16`.
- `props = payload[9]`
- `divider` по `(props >> 1) & 0x3`: 0→10, 1→1, 2→100, иначе 10
- unit по `(props >> 3) & 0x3`:
  - 0 (KG): `weight = u16be / divider`
  - 1 (JIN): `weight = u16be / (divider * 2)`
  - 2 (LB): `weight = (u16be / divider) / 2.204623`
  - 3 (ST:LB): `stones = u16be >> 8; pounds = (u16be & 0xFF) / divider; kg = stones*6.350293 + pounds*0.453592`

### VF0 — company ID 0xF0FF, payload >= 4 байта
- `weightKg = u16be(payload[3], payload[2]) / 10`  (внимание: MSB=3, LSB=2)

### C0 — любой company ID с младшим байтом == 0xC0, payload >= 13 байт
| idx | поле |
|-----|------|
| 0   | вес MSB |
| 1   | вес LSB |
| 2   | импеданс MSB |
| 3   | импеданс LSB |
| 6   | attrib |

- `attrib = payload[6]`; стабильный замер, если `(attrib & 0x01) != 0`
- `divider` по `(attrib >> 1) & 0x3`: 0→10, 1→1, 2→100, иначе 10
- unit по `(attrib >> 3) & 0x3` (аналогично V11)
- `impedance = u16be(payload[2], payload[3]) / 10`

## Состав тела (из импеданса)
Вычисляется по формулам `OkOkV2Lib` (вес, импеданс, пол, рост, возраст).
Полный список формул — в `OkOkV2Lib.kt` (см. ссылку выше). Перенести в Swift
для фичи «состав тела» (жир, мышцы, вода, кости, висцеральный жир, BMR, белок,
метаболический возраст).

# nfUI — Survivors Edit

Неофициальная доработка [nfUI](https://github.com/nfmous/nfui_AZSRV) для **Azeroth Survivors**: компактный интерфейс с упором на читаемость в толпе и игру в группе. Подробное описание исходного аддона находится [ниже](#nfui).

> Это не официальный релиз nfUI. По вопросам этой сборки пишите в Issues этого репозитория, а не автору оригинала.

## Структура репозитория

- `nfUI/` — исходный код аддона.
- `web/` — готовый архив и инструкция для браузерной версии.

## Статус

Сборка настроена на экране **3440×1440** с русским клиентом. Раскладка сама подстраивается под разрешение и масштаб интерфейса: центральные блоки держатся у центра, остальное у своих углов, а размеры следуют за высотой экрана. Подгонка проверена расчётом и автоматическими одиночными забегами, кооператив так не проверялся. Часть функций помечена ниже как непроверенная.

## Установка

1. Скачайте `nfUI-survivors-edit.zip` со страницы [Releases](../../releases).
2. Удалите старую папку `nfUI`, если она была.
3. Распакуйте архив так, чтобы получилось `benilla-config/AddOns/nfUI`.
4. Включите **nfUI** в списке аддонов и начните забег.

**В браузерной версии** ([wow.aethus.pl](https://wow.aethus.pl/)) распаковывать ничего не нужно:

1. Скачайте [`web/nfUI-survivors-edit.zip`](https://github.com/Notker367/nfui-survivors-edit/raw/main/web/nfUI-survivors-edit.zip).
2. В игре откройте **Настройки → AddOns → Install AddOns** и выберите этот файл.
3. Аддон загрузится со следующего забега. Он хранится в этом браузере, на другом устройстве его нужно ставить заново.

Подробности: [`web/README.md`](../web/README.md).

При первом запуске раскладка заменит прежнюю настройку nfUI. Двигать элементы можно через `/nfui` → **Movers**.

## Что изменено

**Исправления**
- Падение `Plates.lua` с `out of Lua stack` при большом числе врагов.
- Ошибки `Font not set` в счётчике забега, полосках боссов и цифрах урона.
- Определение щитов и элиток на русском клиенте.

**Панели героя и цели**
- Компактные зеркальные панели с портретами, плавным здоровьем и следом потерянного здоровья.
- Щит внутри полоски здоровья, с числом поверх неё.
- Цель цели и красная обводка, когда цель смотрит на вас.

**Скилы и предметы**
- Заблокированная панель скилов, цифры перезарядки у всех умений, ранг и DPS под каждым скилом.
- Панель бижутерии с пустыми ячейками и подсказками.
- Пул ещё не выбранных скилов; когда выбраны все 6, значки становятся бледнее.
- Значок сундука, когда на него хватает золота.

**Полоски над персонажами**
- Враги и союзники одновременно, полупрозрачные, строго над моделью.
- Цвета по рангу врага и классу союзника, дебаффы цели и союзников.
- Метры справа от полоски каждого врага и красная обводка у тех, кто подошёл вплотную.

**Группа и бой**
- Значки скилов в панелях DPS. Панель DPS группы с лучшим скилом каждого героя, подробности при наведении.
- При выборе союзника показываются его скилы и бижутерия.
- Короткие цифры урона со значками: удары объединяются и расходятся веером.
- Панели таймера, боссов, убийств и золота из самой игры вместо версий аддона.
- Окно персонажа на русском со всеми параметрами.

## Что пока не проверено

- Живые портреты: камера на лицо может работать не у всех моделей.
- Долгие забеги с боссами и большой толпой: автоматические забеги длились до 3 минут и шли на английском клиенте.
- Панель группы и данные союзников при автоматических проверках: они работают только в кооперативе.
- Заблокированные карты в пуле скилов не отмечаются: игра не отдаёт эти данные напрямую.

## Авторство и лицензия

Исходный nfUI создан [nfmous](https://github.com/nfmous). Этот репозиторий является форком, а уведомления о стороннем коде сохранены в [`nfUI/Resources/licenses`](nfUI/Resources/licenses).

У репозитория оригинала нет отдельной лицензии на весь аддон, поэтому и здесь она не добавлена. Права на оригинальный код остаются у его автора. Связаться по вопросам этой сборки можно через Issues.

---

# nfUI
## LESS CLUTTER. MORE GAME.

A clean, customizable HUD for **Azeroth Survivors**. Built to keep the information you need in view—and the rest out of your way.

## ✨ THE GOOD STUFF

- **MINIMAL CLUTTER** — Thin bars, clean icons and compact panels.
- **HIGHLY CUSTOMIZABLE** — Move, resize, recolor and tune your UI.
- **LIGHTWEIGHT BY DESIGN** — Compact Lua modules, shared UI helpers and reusable display elements.
- **READY TO PLAY** — Starts with our curated layout, adapted to your screen and UI scale.
- **YOUR SETTINGS STAY YOURS** — Updates keep your existing layout.

## 🧭 A COMPASS THAT KEEPS UP

- **Heading at a glance.** A smooth, Skyrim-style direction strip.
- **Map landmarks in view.** Supported map markers appear along the compass.
- **Lost the marker? Follow the edge.** Icons stick to the nearest side until you turn toward them.
- **Thin bar. Big icons. Your call.** Adjust bar height, icon size and labels separately.
- **Top or bottom.** Choose your anchor and width.

### ⚠️ BATTLEGROUND CACHES

**THE COMPASS CANNOT TRACK BATTLEGROUND CACHES: THEIR POSITIONS ARE NOT EXPOSED TO ADDONS THROUGH THE API.**

- **Cache tracking is planned if the API adds that information.**
- Cache counters and costs do **not** provide a cache's location.

## 🎯 THE REST OF YOUR HUD, CLEANED UP

- **Player & target frames** — Compact health, power and shield displays. Hide your name or change health-text placement.
- **Smart nameplates** — Visibility limits, collision handling and upward-first stacking with smooth transitions.
- **Borderless minimap** — Adjustable feathering and zoom buttons that appear on hover.
- **Run progress** — A grey-to-green timer strip with boss-spawn ticks.
- **Run Stats & DPS** — Compact panels that unfold upward. Expand or collapse them when you need them.
- **Character stats** — Choose the stats you care about. Zero values stay hidden.
- **Combat text** — Icon text, compact numbers, native text or off.
- **Chat & tooltips** — Adjustable chat backdrop and movable tooltip placement.

## 🛠️ MAKE IT YOURS

- Type **`/nfui`**. Everything starts in settings.
- **Unlock Movers** to drag your HUD into place.
- **Snap to the grid** for clean alignment. Hold **Shift** to bypass it.
- **Right-click a mover** for fine adjustments and **Width Match / Height Match**.
- **Type exact numbers** into adjustment fields. Use **+ / −** for small changes.
- **Resize the settings window** with its bottom-right grip.

## 🚀 GET STARTED

1. Download the install ZIP and extract its **`nfUI`** folder into your **AddOns** directory.
   Using GitHub’s source archive? Open its outer repository folder and copy **`nfUI`** from inside it.
2. Enable **nfUI** in your addon list.
3. Play—or open **`/nfui`** and make it yours.

**Updating? Use `/reload` after replacing the files.**

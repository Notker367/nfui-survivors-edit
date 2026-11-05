# nfUI Survivors Edit

**A readable HUD for Azeroth Survivors: see what is hitting you, what your run is worth and what can still come up, even in a swarm.**

An unofficial edit of [nfUI](https://github.com/nfmous/nfui_AZSRV) by nfmous. Everything can be moved, resized, folded and switched off.

[Русская версия](README.ru.md) · [What's new](../CHANGELOG.md) · [Original nfUI readme](ORIGINAL-README.md)

![The HUD at 3:00 of a real run, with numbered parts](media/overview.jpg)

## What is on the screen

| # | Part | What it does |
|---|---|---|
| 1 | Hero frame | Current health as a number, level on the portrait, shield amount, a chest icon when you can afford one |
| 2 | Skill bar | Cooldown numbers on every skill, with rank and DPS under each |
| 3 | Bosses | Countdown to every boss of the run: yellow under 30 sec, red under 10, the final boss in violet |
| 4 | Guardians | Each lair: countdown until its guardian appears, then asleep or its health. The `>` marks the one the game points at |
| 5 | Damage taken | What has hurt you this run: enemy or boss, melee, spell or area, with shares |
| 6 | History | Your DPS now against your last and best run with the same class in the same zone, **at the same moment of the run** |
| 7 | Skill pool | Picked skills on top in a green edge, what can still come up below. Dims when all 6 are picked |
| 8 | Jewelry pool | Every ring, trinket and amulet. Rings and trinkets dim once both slots are full. Hover to read them |
| 9 | Chat | A clear narrow font, even margins, tabs always visible, the input box above it |
| 10 | Enemy bars | Level coloured as in classic WoW (grey, green, yellow, orange, red), current health, distance in metres, a red edge on enemies next to you. Health drains smoothly and leaves a trail. Pale bars are enemies beyond the game's own nameplates |
| 11 | Damage numbers | Bigger hits are larger and stay longer. Hits that cannot be placed merge into one number instead of a pile |
| 12 | Damage you take | One slow column rising above your health and dissolving; bigger hits are larger |
| 13 | DPS meter | Click to expand: every skill with its icon, and the party's in co-op |

## What you can do

**Move and lock anything.** Open `/nfui` and press **Movers**, then drag a panel. Right-click one for exact sizes and **Lock**: a locked panel turns red and stays put.

![Movers with the right-click menu](media/movers.jpg)

**Fold what you do not need.** Click a panel's `[-]` title; the panels below move up.

![The same panels open and folded](media/panels-fold.jpg)

**Mark banished cards.** Click any icon in a pool. It is crossed out and listed at the top right with a count, for this run. The game does not tell addons about banishes, so this is by hand.

![Banished cards at the top right](media/banished.jpg)

**Switch things off.** Every on/off choice is in one place, the **Switches** tab. Sizes of the new panels and fonts are in **Blocks**.

| Switches | Blocks |
|---|---|
| ![Switches tab](media/switches.jpg) | ![Blocks tab](media/blocks.jpg) |

**Reset safely.** `Reset section`, `Reset all` and `Reset positions` return to this edit's layout, fitted to your screen. Your run history is kept.

## Install

1. Download `nfUI-survivors-edit.zip` from [Releases](../../../releases).
2. Delete any old `nfUI` folder.
3. Unzip so that you get `benilla-config/AddOns/nfUI`.
4. Enable **nfUI** in the addon list and restart the game fully.

The first start replaces an earlier nfUI layout with this one. It fits your screen and UI scale by itself.

**Browser version** ([wow.aethus.pl](https://wow.aethus.pl/)): see [web/README.md](../web/README.md). No unzipping needed.

## Update

The game gives addons no network or file access, so nothing can update from inside it. In the game, `/nfui` > **Switches** > **Check for updates** shows your version and the link. To update in one step, put [`tools/update-nfUI.bat`](../tools/update-nfUI.bat) next to `benilla-config` and run it: it checks the latest release, keeps a copy of the old version and leaves your settings alone.

## What has and has not been tested

Tested with automatic runs on the desktop game, all without errors: 14 client language settings, all 9 classes, 5 window shapes from 4:3 to ultrawide, `/reload`, and upgrades from the original nfUI and from earlier builds. The longest run reached the first boss at 3:00.

Not tested yet, so tell me if something looks wrong:

- **Co-op:** two clients connect, but a run together has not been played. Ally levels and panels are unverified.
- **Browser:** installation is checked, a full run is not.
- **Chinese, Japanese, Korean clients:** the addon falls back safely if the game's font is missing, and runs without errors in that state. Whether the fonts load on a real client of these languages is unverified.
- **Late game:** runs past a few minutes, later bosses, killed guardians returning.

Other limits: 19 pieces of jewelry show only their name and slot rule, because the game's table has no text for their effect. Bars for far enemies have no level, and show the health last seen on a real plate (guardians and bosses show their real health). In-game text is Russian or English; other languages get English.

## Credits and license

The original nfUI is by [nfmous](https://github.com/nfmous). This repository is a fork, and the notices for third-party code are kept in [`nfUI/Resources/licenses`](../nfUI/Resources/licenses). The original has no license for the whole addon, so none is added here, and the rights to the original code stay with its author. The colours follow [Catppuccin](https://catppuccin.com/) Mocha.

Found a bug? Mention it in the thread in the game's Discord where you found this build, with a screenshot.

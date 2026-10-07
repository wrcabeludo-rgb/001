# Авторы и лицензии

Всё чужое, что есть в игре, с источником и лицензией. Этот же список показывает
экран «Авторы» в главном меню (`game/scripts/core/credits.gd`) — меняя одно, меняй и другое.

## Музыка

Kevin MacLeod, [incompetech.com](https://incompetech.com).
Лицензия: [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/) —
можно использовать бесплатно, в том числе в продаваемой игре, если указать автора (указан в игре).
Файлы скачивает и обрабатывает `tools/music_import.py` (обрезка тишины по краям, выравнивание громкости).

| Где звучит | Файл | Трек |
|---|---|---|
| Главное меню | `music/menu.ogg` | «Gearhead» |
| 1-1 Трущобы | `music/zone_1_1.ogg` | «Neolith» |
| 1-2 Затопленное метро | `music/zone_1_2.ogg` | «Zap Beat» |
| 1-3 Главный сток | `music/zone_1_3.ogg` | «Noise Attack» |
| Босс | `music/boss.ogg` | «Summon the Rawk» |
| Лавка | `music/shop.ogg` | «RetroFuture Dirty» |

## Звуки

Записи из бесплатных наборов, все под лицензией
[CC0](https://creativecommons.org/publicdomain/zero/1.0/) (можно всё, упоминать не обязательно).
Какой звук игры из какого файла — `SOUNDS` в `tools/sfx_import.py`, он же их скачивает и обрабатывает.

| Набор | Автор | Что из него |
|---|---|---|
| [Impact Sounds](https://kenney.nl/assets/impact-sounds), [Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds), [RPG Audio](https://kenney.nl/assets/rpg-audio), [Interface Sounds](https://kenney.nl/assets/interface-sounds), [Digital Audio](https://kenney.nl/assets/digital-audio) | Kenney | выстрелы винтовки, удары, шаги, двери, огнемёт, лазеры, подбор предметов, меню |
| [80 CC0 creature SFX #2](https://opengameart.org/content/80-cc0-creture-sfx-2) | Dread Knight | голоса мутантов |
| [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack) | qubodup | взмахи меча, второй прыжок |
| [20 Sword Sound Effects](https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes) | MedicineStorm | тяжёлый удар, блок |
| [40 CC0 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx) | rockseller | всплеск, плевок босса |
| [25 CC0 bang / firework SFX](https://opengameart.org/content/25-cc0-bang-firework-sfx) | Snabisch | взрыв бочки |
| [25 CC0 mud SFX](https://opengameart.org/content/25-cc0-mud-sfx) | Bonsaiheldin | попадание по мутанту |
| [Gunshots](https://opengameart.org/content/gunshots) | LarkPay | дробовик |
| [CC0 Deep Monster Roar](https://opengameart.org/content/cc0-deep-monster-roar) | OpenGameArt | рёв босса |

Смерть героя и мелодия конца зоны синтезированы для игры (`tools/audio_synth.py`).

## Шрифты

Russo One и Exo 2 — [SIL Open Font License](https://openfontlicense.org) (тексты лицензий в `game/assets/fonts`).

## Графика

Сгенерирована для игры (ChatGPT) по промптам из `ART_WORLD1.md` и `ART_GUIDE.md`.

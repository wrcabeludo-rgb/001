# Библия стиля и задания для генерации

> Как делать графику и звук для игры так, чтобы всё выглядело единым и сразу подходило проекту.
> Картинки генерируются в **ChatGPT**, музыка — в **Suno** или **Udio** (ChatGPT музыку не делает).

---

## 1. Как работать с ChatGPT

1. **Один чат на одну серию.** Всех героев делай в одном чате «Герои», фоны в другом — так ChatGPT помнит стиль и облик.
2. **Каждый промпт начинай с «Блока стиля»** (раздел 2). Это главное правило единого вида.
3. **Удачную картинку прикладывай как референс** к следующим запросам: «keep exactly the same character / same style as the attached image».
4. **Промпты на английском** — ChatGPT понимает русский, но английский даёт более точный и стабильный результат. Пояснения к каждому промпту — на русском.
5. **Прозрачный фон** для героев, предметов и элементов интерфейса: в конце промпта всегда «transparent background, PNG».
6. **Форматы ChatGPT:** квадрат 1024×1024, горизонталь 1536×1024, вертикаль 1024×1536. Указывай нужный: «landscape 3:2» или «portrait 2:3».
7. **Текст на картинках ИИ рисует плохо, особенно кириллицу.** Надписи (название, меню) делаем шрифтом в игре, а не генерацией.
8. Сохраняй **все удачные варианты**, не только лучший, — пригодятся для сравнения.

---

## 2. Блок стиля (вставлять в начало каждого промпта)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.
```

---

## 3. Палитра

| Роль | Цвет | HEX |
|---|---|---|
| Глубокий фон, ночное небо | тёмно-синий | `#0E1018` |
| Тени | графит | `#1B1F2B` |
| Бетон, камень | холодный серый | `#4A4F5C` |
| Ржавчина, металл | ржавый | `#8A4B2A` |
| **Стрелок**, его выстрелы | неоновый циан | `#2DE2E6` |
| **Мечник**, его клинок | неоновый оранжевый | `#FF8A3D` |
| Вывески, корпорация | неоновый маджента | `#FF2E88` |
| Кислота, мутанты | токсичный зелёный | `#8CFF4F` |
| Опасность, предупреждения | сигнальный жёлтый | `#FFC93C` |

Правило: **циан — всегда стрелок, оранжевый — всегда мечник.** Даже на заглушках герои уже окрашены так, и игрок с первой секунды различит, кто где.

---

## 4. Герои — концепт-арт

Сейчас нужен **облик**, а не анимация. Из утверждённого концепта позже нарежем части для cutout-анимации,
поэтому важно: ровный свет, руки и ноги не перекрывают туловище, оружие отдельно читается.

### 4.1 Стрелок

**Образ:** лёгкий, быстрый мусорщик-разведчик. Длинный рваный плащ или пончо с высоким воротом,
дыхательная маска со светящимися **циановыми** линзами, самодельная винтовка из лома с циановой энергоячейкой.

```
[Блок стиля — вставь сюда текст из раздела 2]
Character design sheet of "the Gunner", a lean agile scavenger: tattered long hooded coat with high collar,
respirator mask with glowing cyan visor lenses, light patched armor, utility belts, worn boots,
improvised scrap-built rifle with a glowing cyan energy cell. Cyan (#2DE2E6) is his accent color.
Show three views side by side: front view, side view facing right, back view. Neutral standing pose,
arms slightly away from the body, full body, flat even lighting, same scale in all views,
transparent background, PNG. Landscape 3:2.
```

### 4.2 Мечник

**Образ:** тяжелее и крепче. Броня из найденных пластин (дорожные знаки, детали машин), механическая рука бывшего
охранника корпорации, шарф, длинный клинок из рессоры с раскалённой **оранжевой** кромкой.

```
[Блок стиля]
Character design sheet of "the Swordsman", a sturdy warrior in armor scavenged from road signs and car parts,
one mechanical prosthetic arm from a former corporate security exosuit, long scarf, heavy boots,
a long single-edged blade forged from a car leaf spring with a glowing hot orange edge.
Orange (#FF8A3D) is his accent color. Show three views side by side: front view, side view facing right,
back view. Neutral standing pose, arms slightly away from the body, full body, flat even lighting,
same scale in all views, transparent background, PNG. Landscape 3:2.
```

### 4.3 Пара вместе (проверка, что они смотрятся командой)

```
[Блок стиля]
The Gunner and the Swordsman from the attached images standing side by side, side view facing right,
same scale, full body, the Swordsman slightly taller and broader. Transparent background, PNG. Landscape 3:2.
```

**Пропорции:** в игре стрелок сейчас 48×96 пикселей (ширина × рост). Мечник может быть чуть выше и шире —
скажи, если на концептах он получится заметно крупнее, подстрою размер.

---

## 5. Дальние фоны (параллакс)

Дальние слои не зависят от уровней — их можно делать уже сейчас. Каждый слой — отдельная картинка,
**бесшовная по горизонтали** (левый и правый края стыкуются), чтобы фон можно было повторять.

### 5.1 Небо (самый дальний слой)

```
[Блок стиля]
Background layer for parallax: night sky over a ruined megacity, heavy low clouds lit from below
by distant magenta and cyan city glow, faint moon behind smog. No buildings, no ground.
Seamless horizontally tileable. Landscape 3:2.
```

### 5.2 Силуэты далёких небоскрёбов

```
[Блок стиля]
Background layer for parallax: distant skyline silhouettes of broken skyscrapers and leaning towers,
very dark navy silhouettes, a few dim neon signs and windows, fog at the bottom. Only the bottom
two thirds are filled, the top is transparent. Seamless horizontally tileable, transparent background, PNG.
Landscape 3:2.
```

### 5.3 Средний план мира 1 (трущобы, мутанты)

```
[Блок стиля]
Background layer for parallax: mid-distance slums built on top of ruins — shacks from scrap metal,
hanging cables, flickering neon signs, toxic green puddles glowing (#8CFF4F), smoke. Darker than the
foreground, slightly blurred. Only the bottom half is filled, the top is transparent.
Seamless horizontally tileable, transparent background, PNG. Landscape 3:2.
```

---

## 6. Логотип и обложка

Название пишем **шрифтом в игре**, а от ИИ берём эмблему и фон для главного меню.

```
[Блок стиля]
Game title screen background: the Gunner and the Swordsman seen from behind, standing on a rooftop edge,
looking at a ruined neon megacity at night, cyan and orange rim light on them, rain, empty space in the
upper third for the game title. No text. Landscape 3:2.
```

```
[Блок стиля]
Game emblem: a stylized emblem combining a rifle and a blade crossed over a broken neon ring,
cyan and orange glow, clean bold shapes, centered, no text, transparent background, PNG. Square 1:1.
```

---

## 7. Шрифты

Бесплатные (лицензия OFL), с кириллицей, скачиваются с Google Fonts:

| Назначение | Шрифт | Ссылка |
|---|---|---|
| Название игры, заголовки | **Russo One** | https://fonts.google.com/specimen/Russo+One |
| Меню, HUD, подсказки | **Exo 2** | https://fonts.google.com/specimen/Exo+2 |

Скачай оба (кнопка «Get font» → «Download all») и пришли архивы или положи в `game/assets/fonts/`.

---

## 8. Музыка (Suno / Udio)

Жанр: **синтвейв / дарксинт**. Инструментал, без вокала. Длина 2–3 минуты, чтобы трек можно было зациклить.

| Трек | Промпт |
|---|---|
| Главное меню | `dark synthwave, instrumental, slow 85 bpm, melancholic, wide analog pads, distant arpeggio, rain ambience, cinematic, no vocals` |
| Мир 1, уровни | `darksynth, instrumental, 110 bpm, driving bassline, gritty analog synths, tense and energetic, industrial percussion, loopable, no vocals` |
| Мир 1, босс | `aggressive darksynth, instrumental, 140 bpm, distorted bass, pounding drums, dramatic, boss battle, no vocals` |
| Магазин между уровнями | `chill retro synth, instrumental, 90 bpm, warm pads, relaxed, lo-fi texture, loopable, no vocals` |

---

## 9. Звуки интерфейса

Не нужно генерировать — есть готовые бесплатные наборы (CC0, можно использовать как угодно):
- **Kenney — Interface Sounds:** https://kenney.nl/assets/interface-sounds
- **Kenney — Sci-fi Sounds:** https://kenney.nl/assets/sci-fi-sounds

Звуки выстрелов, ударов и врагов подберём на этапе 2–4, когда бой будет готов.

---

## 10. Куда класть и как называть

```
game/assets/
  art/
    heroes/       gunner_concept_01.png, swordsman_concept_01.png
    backgrounds/  bg_sky_01.png, bg_skyline_01.png, bg_world1_mid_01.png
    ui/           title_bg_01.png, emblem_01.png
  fonts/          RussoOne-Regular.ttf, Exo2-*.ttf
  music/          menu_theme_01.mp3, world1_level_01.mp3, world1_boss_01.mp3
  sfx/ui/         …
```

- Имена латиницей, маленькими буквами, через `_`, с номером варианта.
- Картинки — PNG, музыка — MP3 или OGG.
- Можно просто присылать файлы мне в чат — я разложу сам.

---

## 11. Порядок работы

1. Сгенерируй **концепты героев** (4.1, 4.2) по 3–4 варианта каждого → выбираем лучший.
2. По выбранным — **пара вместе** (4.3) → утверждаем облик.
3. **Фоны** 5.1–5.3 и **обложка** (6).
4. **Шрифты** и **музыка** — в любой момент.

Утверждённое фиксируем здесь, в разделе «Утверждено».

## Утверждено

_Пока ничего._

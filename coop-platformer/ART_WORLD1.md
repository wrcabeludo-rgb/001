# Графика для мира 1 — что сгенерировать в ChatGPT

> Начиная с раздела 1.7 промпты даются **целиком** (стиль, внешность героя, поза, технические требования) — копируй блок как есть.
> Порядок важен: сверху — то, что сильнее всего меняет вид игры. Присылай картинки пачками, как получатся,
> я сразу встраиваю. Перед каждым промптом вставляй **Блок стиля** из [ART_GUIDE.md](ART_GUIDE.md), раздел 2.
> Нарезку, прозрачность, бесшовность и анимацию делаю я — от тебя только картинки.
>
> **Статус: вся графика мира 1 получена и встроена в игру.** Промпты оставлены как образец для мира 2.

## Общие правила

- **Персонажи, враги, предметы:** вид строго **сбоку**, ровный свет, **белый фон** (прозрачный ChatGPT делает плохо,
  белый я убираю сам). Ничего не обрезано краем картинки.
- **Герои:** прикладывай утверждённый концепт (`art_source/concepts/...`) и пиши
  «keep exactly the same character design as the attached image».
- **Текстуры и фоны:** без людей и врагов, без текста.
- Один чат на одну серию: «Герои», «Враги мира 1», «Тайлы мира 1», «Предметы», «Фоны мира 1».

---

## 1. Герои для анимации (самое важное)

Анимацию делаю «куклой»: режу героя на части (голова, туловище, руки, ноги, оружие) и двигаю их в игре.
Для этого нужна **одна чистая поза сбоку**, где руки и ноги не перекрывают друг друга.

### 1.1 Стрелок
```
[Блок стиля]
Keep exactly the same character design as the attached image (the Gunner).
Full body, strict side view facing right, neutral standing pose for a cutout animation rig:
legs slightly apart and both fully visible, the far arm hidden behind the body, the near arm
holding the rifle level and pointing right, the coat hanging straight down, nothing overlapping
the legs. Flat even lighting, white background, nothing cropped. Portrait 2:3.
```

### 1.2 Мечник
```
[Блок стиля]
Keep exactly the same character design as the attached image (the Swordsman).
Full body, strict side view facing right, neutral standing pose for a cutout animation rig:
legs slightly apart and both fully visible, the mechanical arm in front holding the blade
pointing forward and slightly down, the other arm relaxed behind the body, nothing overlapping
the legs. Flat even lighting, white background, nothing cropped. Portrait 2:3.
```

Если ChatGPT упорно перекрывает руки и ноги — пришли как есть, я скажу, что поправить.

### 1.3 Позы действий (рисунки вместо «куклы»)

Сейчас эти позы игра собирает из «куклы»: присед, пинок, три разных удара мечом, удар вверх, блок,
скольжение по стене, лестница. Нарисованная поза сразу заменит кукольную — это заметно красивее.
Каждая поза — **отдельная картинка**. Прикладывай вид героя сбоку из игры
(`art_source/heroes/gunner_side_original.png` или `swordsman_side_original.png`) и начинай так:

```
[Блок стиля]
Keep exactly the same character design, colours and proportions as the attached image.
Full body, side view facing right, the same scale as the attached image, flat even lighting,
white background, nothing cropped, no motion lines, no effects. Pose: ...
```

Дальше — одна строка позы. Присылай с именем, например «gunner_kick_1».

| Имя | Поза |
|---|---|
| `gunner_crouch_1` | `Crouching low on one knee, aiming the rifle forward at knee height.` |
| `gunner_kick_1` | `A strong front kick: the near leg kicked straight forward at waist height, leaning back, the rifle held up in both hands.` |
| `gunner_wall_1` | `Sliding down a wall that is on the right: one hand and one boot pressed against the wall, the coat flying up, looking down.` |
| `gunner_climb_1`, `gunner_climb_2` | `Back view in a climbing pose, the rifle on his back, NO ladder drawn: the hands grip nothing, as if holding invisible rungs; frame 1: left hand and right foot up; frame 2: right hand and left foot up.` |
| `swordsman_crouch_1` | `Crouching low in a wide stance, the blade held low and forward, ready to strike.` |
| `swordsman_block_1` | `Defensive stance: the mechanical arm raised in front of the face and chest like a shield, the blade held back, knees bent.` |
| `swordsman_slash_down_1` | `Mid-swing of a quick downward diagonal cut, the blade low in front, the body turning into the cut.` |
| `swordsman_slash_rising_1` | `Mid-swing of a quick rising cut, the blade swept up in front above the head, weight on the back leg.` |
| `swordsman_slash_finisher_1`, `swordsman_slash_finisher_2` | `A heavy two-handed finishing blow; frame 1: the blade raised high behind the head, leaning back; frame 2: a deep lunge, the blade slammed down low in front.` |
| `swordsman_slash_overhead_1` | `Sweeping the blade in an arc above the head, looking up.` |
| `swordsman_wall_1` | `Sliding down a wall that is on the right: the mechanical hand gripping the wall, one boot against it.` |
| `swordsman_climb_1`, `swordsman_climb_2` | `Back view in a climbing pose, the blade on his back, NO ladder drawn: the hands grip nothing, as if holding invisible rungs; frame 1: left hand and right foot up; frame 2: right hand and left foot up.` |

Лестницу в позе лазания рисовать **не надо**: в игре своя лестница, а нарисованную от героя не отрезать.
Если ChatGPT всё равно рисует лестницу, допиши: `If you draw a ladder, make it pure flat bright green (#00FF00).`
Стену в позе у стены рисовать можно (справа) — её я отрезаю.

Готово: все позы обоих героев.

### 1.4 Бег (анимация ходьбы)

Сейчас бег — это «кукла»: ноги качаются, а руки и плащ неподвижны. Нужен настоящий цикл бега:
**4 кадра** на одной картинке, слева направо, все фигуры одного размера и на одной линии земли.
Прикладывай вид героя сбоку (как для поз) и пиши:

```
[Блок стиля]
Keep exactly the same character design, colours and proportions as the attached image.
A run cycle sprite sheet: 4 frames side by side in one row, the same character in each, side view
facing right, the same scale, all feet on the same ground line, evenly spaced, nothing overlapping.
Frame 1: contact — right leg forward touching the ground, left leg back.
Frame 2: passing — right leg under the body bearing weight, left knee lifted forward.
Frame 3: contact — left leg forward touching the ground, right leg back.
Frame 4: passing — left leg under the body, right knee lifted forward.
Arms swing opposite to the legs. Flat even lighting, white background, nothing cropped. Landscape 16:9.
```

Дополнение для **стрелка**: `The rifle is held in both hands at chest height, pointing forward; the cape and scarf flow behind.`
Дополнение для **мечника**: `He carries ONLY ONE sword, and it is ALWAYS in his right (mechanical) hand in every frame: the glowing blade held low, pointing back and down. There is NO sheath, NO scabbard and NO second sword on his belt, back or hip — the belt has only pouches. The free left arm swings, fist closed.`
Если нейросеть всё равно рисует второй меч на поясе — добавь в конце: `Check every frame: exactly one sword, in the hand. Remove any sword from the belt.`

Имена: `gunner_run`, `swordsman_run`. Если 4 кадра не помещаются ровно — пришли как есть, разрежу сам.

Готово: бег обоих героев; прыжок, падение и рывок мечника (новый бег мечника — с одним мечом). Ещё нужно: `gunner_jump_1`, `gunner_fall_1`.

### 1.5 Прыжок, падение, рывок

Пока их нет, игра берёт подходящие кадры бега (колено поднято — прыжок, широкий шаг — падение и рывок).
Промпт — как для поз (раздел 1.3), строка позы:

| Имя | Поза |
|---|---|
| `gunner_jump_1` | `Jumping up: both knees pulled up, the rifle held across the chest, the cape flying down behind.` |
| `gunner_fall_1` | `Falling: legs stretched down ready to land, arms out for balance holding the rifle, the cape flying up.` |
| `swordsman_jump_1` | `Jumping up: knees pulled up, the glowing blade held back and low, the free arm raised.` |
| `swordsman_fall_1` | `Falling: legs down ready to land, the blade held out to the side, the scarf flying up.` |
| `swordsman_dash_1` | `A fast forward dash: body low and leaning far forward, the blade held back along the body, one leg stretched behind, the scarf streaming back.` |

### 1.6 Оружие из лавки (иконки для магазина)

Дробовик и тяжёлый клинок в руках героя пока те же, что обычные: их отличают выстрел/взмах, звук и эффекты.
Иконки для лавки — **отдельные предметы без героя**, вид сбоку:

| Имя | Промпт |
|---|---|
| `weapon_shotgun` | `A brutal sawed-off double-barrel shotgun made of scrap: thick barrels wrapped in wire, a pump grip of rusty pipe, red shells strapped to the stock, warm orange glow at the muzzle. Side view, pointing right.` |
| `weapon_heavy_blade` | `A huge two-handed cleaver forged from a railway rail: wide dark steel blade with molten red cracks glowing from inside, a long wrapped grip, chains on the guard. Side view, edge pointing right.` |
| `weapon_rifle` | `The Gunner's plasma rifle: long rusty barrel with glowing cyan energy cells, scope, leather sling. Side view, pointing right.` |
| `weapon_blade` | `The Swordsman's glowing orange serrated blade with dash-shaped vents along it, a mechanical hilt. Side view, edge pointing right.` |


### 1.7 Полные промпты мечника (копировать целиком)

Каждый промпт — целиком, ничего добавлять не нужно. К каждому прикладывай картинку, указанную над ним.

**`swordsman_run`** — Attach `art_source/heroes/swordsman_side_original.png`. Landscape 16:9.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Swordsman):
short messy brown hair, short beard, thick black knitted scarf, dark riveted plate armour with glowing
orange seams, a mechanical right arm with an orange glowing joint, armoured boots with straps, a belt
with leather pouches. He carries ONLY ONE sword: a long curved serrated blade glowing orange with
dash-shaped vents, ALWAYS held in his right (mechanical) hand. There is NO sheath, NO scabbard and NO
second sword on his belt, back or hip — the belt has only pouches.

A run cycle sprite sheet: 4 frames side by side in one row, the same character in each, side view
facing right, the same scale, all feet on the same ground line, evenly spaced with clear white space
between the figures, nothing overlapping.
Frame 1: contact — right leg forward, heel touching the ground, left leg stretched back.
Frame 2: passing — right leg under the body bearing the weight, left knee lifted forward.
Frame 3: contact — left leg forward touching the ground, right leg stretched back.
Frame 4: passing — left leg under the body, right knee lifted forward.
The sword hand stays low at his right side in every frame, the glowing blade pointing back and down
along the leg; the free left arm swings opposite to the legs, fist closed. The scarf ends flow back.
Landscape 16:9.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no text.
Check every figure: exactly one sword, in his hand; remove any sword from the belt.
```

**`swordsman_jump_1`** — Attach `art_source/heroes/swordsman_side_original.png`. Portrait 2:3.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Swordsman):
short messy brown hair, short beard, thick black knitted scarf, dark riveted plate armour with glowing
orange seams, a mechanical right arm with an orange glowing joint, armoured boots with straps, a belt
with leather pouches. He carries ONLY ONE sword: a long curved serrated blade glowing orange with
dash-shaped vents, ALWAYS held in his right (mechanical) hand. There is NO sheath, NO scabbard and NO
second sword on his belt, back or hip — the belt has only pouches.

Full body, side view facing right, the same scale as the attached image.
Pose: jumping up — both knees pulled up, the body slightly curled, the glowing blade held back and low
in his right hand, the free left arm raised for balance, the scarf ends flying down behind. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no text.
Check every figure: exactly one sword, in his hand; remove any sword from the belt.
```

**`swordsman_fall_1`** — Attach `art_source/heroes/swordsman_side_original.png`. Portrait 2:3.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Swordsman):
short messy brown hair, short beard, thick black knitted scarf, dark riveted plate armour with glowing
orange seams, a mechanical right arm with an orange glowing joint, armoured boots with straps, a belt
with leather pouches. He carries ONLY ONE sword: a long curved serrated blade glowing orange with
dash-shaped vents, ALWAYS held in his right (mechanical) hand. There is NO sheath, NO scabbard and NO
second sword on his belt, back or hip — the belt has only pouches.

Full body, side view facing right, the same scale as the attached image.
Pose: falling — legs stretched down and slightly apart, ready to land, the glowing blade held out to the
side and back in his right hand, the free left arm out for balance, the scarf ends flying up. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no text.
Check every figure: exactly one sword, in his hand; remove any sword from the belt.
```

**`swordsman_dash_1`** — Attach `art_source/heroes/swordsman_side_original.png`. Landscape 3:2.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Swordsman):
short messy brown hair, short beard, thick black knitted scarf, dark riveted plate armour with glowing
orange seams, a mechanical right arm with an orange glowing joint, armoured boots with straps, a belt
with leather pouches. He carries ONLY ONE sword: a long curved serrated blade glowing orange with
dash-shaped vents, ALWAYS held in his right (mechanical) hand. There is NO sheath, NO scabbard and NO
second sword on his belt, back or hip — the belt has only pouches.

Full body, side view facing right, the same scale as the attached image.
Pose: a very fast forward dash — the body low and leaning far forward, the right leg bent in front,
the left leg stretched far behind, the glowing blade held back along the body in his right hand,
the free left fist forward, the scarf streaming straight back. Landscape 3:2.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no text.
Check every figure: exactly one sword, in his hand; remove any sword from the belt.
```

---

## 2. Враги мира 1 (все — мутанты)

Мир 1 — мутанты, поэтому роботов-заглушек переодеваем: дрон → летучая тварь, турель → плевун, тяжёлый → громила.
Каждого — **отдельной картинкой**, вид сбоку, смотрит **влево**, белый фон, квадрат 1:1.
Общая приписка ко всем: `mutated by glowing toxic green sludge (#8CFF4F), side view facing left, full body, white background, nothing cropped. Square 1:1.`

| Файл | Кто | Промпт (после Блока стиля) |
|---|---|---|
| `enemy_walker` | Ходок | `A hunched mutant scavenger, thin limbs, tattered clothes fused with skin, glowing green pustules, long claws.` |
| `enemy_flyer` | Летун (вместо дрона) | `A flying mutant bat-like creature with torn membrane wings, bloated glowing green belly, small claws.` |
| `enemy_spitter` | Плевун (вместо турели) | `A stationary mutant growth rooted into the ground, a bulbous sac with a wide mouth that spits sludge, tentacle roots.` |
| `enemy_brute` | Громила (вместо тяжёлого) | `A huge hulking mutant brute with one oversized arm made of fused scrap and flesh, small head, heavy stance.` |
| `enemy_charger` | Рывковый | `A low four-legged mutant dog-like beast with a bony armored head for ramming, glowing green eyes.` |
| `enemy_ambusher` | Засадник | `A dark spider-like mutant with long thin legs, clinging pose, dim glowing eyes, almost black.` |
| `boss_sludge_master` | Хозяин стока | `A giant boss mutant rising from a sewer drain, a mass of sludge, pipes and bones, huge maw, two massive arms, glowing green core in the chest. Very large and imposing.` |

---

## 3. Тайлы и текстуры зон

Каждая — **квадрат 1:1, бесшовная** (края стыкуются), плоский вид спереди, без перспективы.
Приписка ко всем: `Seamless tileable square texture, flat front view, no perspective, no objects, no text. Square 1:1.`

| Файл | Зона | Промпт |
|---|---|---|
| `tile_1-1_ground` | 1-1 Трущобы | `Cracked concrete and packed dirt ground with rusty scrap pieces, dark, wet.` |
| `tile_1-1_wall` | 1-1 Трущобы | `Wall of stacked corrugated rusty metal sheets and bricks, slum shack wall.` |
| `tile_1-2_ground` | 1-2 Метро | `Old subway station tiled floor, cracked dirty ceramic tiles, puddles.` |
| `tile_1-2_wall` | 1-2 Метро | `Subway tunnel wall: dark concrete segments, cables, grime, faded tiles.` |
| `tile_1-3_ground` | 1-3 Сток | `Sewer floor: slimy dark bricks with streaks of glowing green sludge.` |
| `tile_1-3_wall` | 1-3 Сток | `Sewer wall: old wet bricks, rusty pipe fragments, green slime drips.` |
| `tile_platform` | все | `A horizontal strip of rusty metal grating catwalk, seen from the front.` (здесь `Landscape 3:2`) |

---

## 4. Фоны зон 1-2 и 1-3 (параллакс)

Как в ART_GUIDE, раздел 5: **бесшовные по горизонтали**, горизонталь 3:2.

| Файл | Промпт |
|---|---|
| `bg_far_1-2` | `Background layer for parallax: a huge flooded underground subway hall, dark arches and columns fading into darkness, faint green glow on the water. Seamless horizontally tileable. Landscape 3:2.` |
| `bg_mid_1-2` | `Background layer for parallax: abandoned subway trains and platforms, broken lamps, cables. Only the bottom half is filled, the top is white. Seamless horizontally tileable. Landscape 3:2.` |
| `bg_far_1-3` | `Background layer for parallax: a vast sewer cistern with giant pipes, waterfalls of glowing green sludge in the darkness. Seamless horizontally tileable. Landscape 3:2.` |
| `bg_mid_1-3` | `Background layer for parallax: sewer pipes, valves, ladders and catwalks, dripping green sludge. Only the bottom half is filled, the top is white. Seamless horizontally tileable. Landscape 3:2.` |

---

## 5. Предметы и механики

Каждый — отдельной картинкой, вид сбоку/спереди, белый фон, квадрат 1:1, `nothing cropped`.

| Файл | Промпт |
|---|---|
| `prop_barrel` | `An explosive rusty red fuel barrel with a yellow hazard stripe and a glowing warning light.` |
| `prop_cover` | `A barricade of stacked scrap metal sheets, sandbags and a tire, chest-high.` |
| `prop_crate` | `A wooden and metal scrap crate.` |
| `prop_door` | `A heavy industrial sliding door, rusty metal with rivets, tall and narrow, front view.` |
| `prop_gate` | `A heavy arena gate of welded rebar and sheet metal with red warning lights, tall and narrow, front view.` |
| `prop_lever` | `A big industrial wall lever switch on a metal post, yellow handle.` |
| `prop_checkpoint` | `A makeshift lamp post with a glowing mint-green neon lamp, wires wrapped around, standing on the ground.` |
| `prop_exit` | `A glowing mint-green neon doorway in a ruined wall, the way out.` |
| `prop_ladder` | `A tall rusty metal ladder, front view, straight vertical.` (Portrait 2:3) |
| `prop_flamethrower` | `A makeshift wall-mounted flamethrower turret made of pipes and a gas tank, nozzle pointing right.` |
| `prop_spikes` | `A row of rusty metal spikes and rebar sticking up from the ground.` (Landscape 3:2) |
| `prop_lift` | `A small industrial lift platform: metal grating floor with yellow-black hazard edges, front view, flat and wide.` (Landscape 3:2) |
| `pickup_health` | `A small medkit made of scrap with a red cross, game pickup icon.` |
| `pickup_ammo` | `A small bundle of glowing cyan energy cells, game pickup icon.` |
| `pickup_scrap` | `A small pile of shiny scrap metal bolts and gears, game pickup icon.` |
| `npc_trader` | `A friendly old scavenger trader sitting behind a counter made of scrap, many gadgets and weapons hanging around, side view facing left.` |

---

## 6. Комикс конца мира 1

Сценарий и промпты — в [STORY.md](STORY.md). Если промптов для конца мира 1 там нет, скажи — допишу.

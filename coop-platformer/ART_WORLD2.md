# Арт для мира 2 — «Заводы „Люмена"»

Каждый промпт — **целиком**: стиль, описание, поза, технический блок. Копируй блок как есть.
Картинку из скобок прикладывай к промпту (кроме случаев «без приложения»). Готовый файл называй как
в заголовке и присылай в чат — фон вырежу, нарежу и встрою сам.

**Порядок** (сверху — то, что сильнее меняет вид игры): тайлы → конвейер и механизмы → враги →
фоны → босс → комиксы → иконки. Удобно вести отдельные чаты: «Тайлы мира 2», «Механизмы мира 2»,
«Роботы мира 2», «Фоны мира 2», «Комиксы».

Общая проверка для всего: **никаких надписей и букв** (ChatGPT любит писать «LUMEN» — просим без слов),
белый фон у спрайтов, ничего не обрезано краем.

Пока картинок нет, уровни работают на заглушках — рисовать можно в любом порядке.

---

## 2.1 Тайлы зон

Земля — то, по чему ходят (верх платформ и пол). Стена — массив, внутренности уровня.
Приложи к каждому `art_source/tiles/tile_1-3_ground_original.png` — только как образец **стиля и яркости**.

**`tile_2-1_ground`** — 2-1 Сборочный цех, пол

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Factory floor of an assembly hall: thick riveted steel floor plates with diamond tread pattern, worn bolts, oil stains, faint scratched yellow-and-black hazard paint on some plates, dark cold steel.

Seamless tileable square texture: all four edges join perfectly when repeated.
Flat front view, no perspective, no vanishing point, even lighting, no objects standing out,
no characters, no text, no letters. Darker and less contrasty than characters, so heroes stay
readable on top of it. Square 1:1.
```

**`tile_2-1_wall`** — 2-1 Сборочный цех, стена

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Inner factory wall: large dark steel panels with rivets and seams, thin pipes and cable bundles running across, small vent grilles, grime and oil streaks, cold blue-grey.

Seamless tileable square texture: all four edges join perfectly when repeated.
Flat front view, no perspective, no vanishing point, even lighting, no objects standing out,
no characters, no text, no letters. Darker and less contrasty than characters, so heroes stay
readable on top of it. Square 1:1.
```

**`tile_2-2_ground`** — 2-2 Литейная, пол

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Foundry floor: heat-blackened cast iron plates with cracks, dried drips of solidified metal, scattered slag and soot, a faint warm orange glow seeping from a few cracks.

Seamless tileable square texture: all four edges join perfectly when repeated.
Flat front view, no perspective, no vanishing point, even lighting, no objects standing out,
no characters, no text, no letters. Darker and less contrasty than characters, so heroes stay
readable on top of it. Square 1:1.
```

**`tile_2-2_wall`** — 2-2 Литейная, стена

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Foundry wall: soot-covered refractory firebrick blocks and cast iron frames, heat-stained, dark brown and charcoal, faint orange reflections.

Seamless tileable square texture: all four edges join perfectly when repeated.
Flat front view, no perspective, no vanishing point, even lighting, no objects standing out,
no characters, no text, no letters. Darker and less contrasty than characters, so heroes stay
readable on top of it. Square 1:1.
```

**`tile_2-3_ground`** — 2-3 Насосная станция, пол

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Pumping station floor: heavy steel grating over dark pipes below, through the gaps a faint glow of toxic green sludge (#8CFF4F) in the pipes, wet metal.

Seamless tileable square texture: all four edges join perfectly when repeated.
Flat front view, no perspective, no vanishing point, even lighting, no objects standing out,
no characters, no text, no letters. Darker and less contrasty than characters, so heroes stay
readable on top of it. Square 1:1.
```

**`tile_2-3_wall`** — 2-3 Насосная станция, стена

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Pumping station wall: curved concrete and steel panels with large bolted pipe flanges, pressure gauges silhouettes, condensation, faint green sludge stains and drips.

Seamless tileable square texture: all four edges join perfectly when repeated.
Flat front view, no perspective, no vanishing point, even lighting, no objects standing out,
no characters, no text, no letters. Darker and less contrasty than characters, so heroes stay
readable on top of it. Square 1:1.
```

**`tile_2_platform`** — тонкая платформа-мостик для всех зон мира 2

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A horizontal strip of an industrial steel catwalk seen strictly from the front: open metal grating floor, a thin yellow-and-black hazard stripe along the top edge, riveted side beam, no railings.

Seamless tileable horizontally: the left and right edges join perfectly. Flat front view, no perspective, even lighting, no characters, no text. Pure white background above and below the strip. Landscape 3:2.
```


---

## 2.2 Конвейер и механизмы

Это главное новое в мире 2. Каждый — отдельной картинкой, на **белом фоне**.


**`prop_conveyor`** — Лента конвейера (повторяется по горизонтали; полосы на ленте я анимирую сам)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A long horizontal section of an industrial conveyor belt seen strictly from the side: a black rubber belt with raised cross ribs on top, running over a row of steel rollers inside a dark steel frame, yellow-and-black hazard stripes along the frame, bolts, oil stains. Straight and level.

Seamless tileable horizontally: the left and right edges join perfectly, no end caps, no legs at the ends. Flat even lighting, pure white background above and below, no shadow, no text. Landscape 3:1.
```

**`prop_conveyor_end`** — Торец конвейера (большой ролик-барабан на краю ленты)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

The end drum of an industrial conveyor belt seen strictly from the side: a big round steel drum with a hub and spokes, the black ribbed rubber belt wrapping around it, a bolted steel bracket holding it, a red warning lamp on top, a hazard-striped edge. The belt continues off to the LEFT edge of the picture.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Square 1:1.
```

**`prop_press`** — Пресс (тяжёлый поршень, падает сверху)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A heavy industrial stamping press head hanging from above: a thick polished steel piston rod coming down from the top edge of the picture, ending in a massive wide flat steel stamping block with yellow-and-black hazard stripes on its sides, scratched and dented from use, hydraulic hoses along the rod, a red warning lamp on the block.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and only the piston rod may touch the top edge, the stamping block is fully visible.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Portrait 1:2.
```

**`prop_crate_lumen`** — Ящик «Люмена» (падает с верхней ленты)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A sturdy industrial shipping crate: dark steel frame with corner guards, grey-blue metal panels, a simple magenta geometric corporate emblem (a stylised glowing ring, no letters), hazard tape on one corner, scratches.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Square 1:1.
```

**`prop_crane`** — Кран: тележка на рельсе с тросом и подвесной платформой

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

An overhead crane trolley with a hanging platform: at the top a short piece of a yellow steel I-beam rail with a small wheeled trolley on it, two steel cables hanging down from the trolley, at the bottom a flat rectangular steel grating platform with yellow-and-black hazard edges hanging level on the cables, a big hook-shaped bracket.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Portrait 2:3.
```

**`prop_steam_vent`** — Паровой клапан (струю пара рисую сам)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A floor steam vent: a short thick vertical steel pipe coming out of the floor, ending in a round grated nozzle facing up, a big red valve wheel on its side, a pressure gauge, rivets, heat discoloration, a few drops of condensation. No steam.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Square 1:1.
```

**`prop_electro_floor`** — Электропол (решётка, по которой бежит ток; разряды рисую сам)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A horizontal strip of electrified floor plating seen from the front: dark steel grating with copper conductor rails running along it, ceramic insulators, small blue indicator lights, yellow-and-black hazard stripes at both ends, a faint blue sheen on the copper. No lightning.

Seamless tileable horizontally except for the hazard-striped ends. Flat front view, even lighting, pure white background above and below, no shadow, no text. Landscape 3:1.
```

**`prop_molten_vat`** — Край ванны расплава (сам металл рисую я — светящийся, с паром)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

The side wall of a foundry vat holding molten metal, seen strictly from the side: a long low trough of thick black cast iron with riveted bands, heat-glowing orange edges at the rim, drips of solidified metal down its sides. The vat is empty: no molten metal shown, the top is open.

Seamless tileable horizontally. Flat side view, even lighting, pure white background, no shadow, no text. Landscape 3:1.
```

**`prop_checkpoint_factory`** — Контрольная точка мира 2

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A factory checkpoint beacon: a slim steel post bolted to the floor, on top a round industrial lamp in a protective cage glowing mint-green neon, a small control box with a hazard-striped lever on the post, cables wrapped around it.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Portrait 2:3.
```

**`prop_exit_factory`** — Выход из зоны

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A large factory exit door: heavy steel double blast doors slightly open, a bright mint-green neon light pouring out from the gap, a hazard-striped frame, a green signal lamp above the door, no sign with words.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Portrait 2:3.
```

**`prop_gate_factory`** — Ворота арены (закрываются, пока идёт бой)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A tall narrow industrial blast shutter gate seen from the front: thick horizontal steel slats, yellow-and-black hazard stripes at the bottom edge, two red rotating warning lamps on top, hydraulic rails on both sides.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Portrait 1:2.
```


---

## 2.3 Роботы и дроны

Каждого — **отдельной картинкой**, вид строго сбоку, смотрит **влево**, белый фон.
Без приложения (или приложи `art_source/enemies/enemy_brute_original.png` как образец **стиля и детализации**, не формы).
Анимацию (шаги, замах, вспышки) делаю сам из одной картинки — поэтому поза **нейтральная, но живая**.


**`enemy_welder`** — Сварщик — основной пехотинец (их много)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A humanoid factory welding robot, about human height, hunched forward: a boxy steel torso with a scratched number plate (no digits), a dome head with a single glowing red visor slit and a dark welding mask flap, one arm ends in a gripping claw, the other arm is a welding torch with a small blue-white flame at the tip, thin hydraulic legs with wide feet, a small gas cylinder on its back, hazard stripes on the shoulders. Stance: walking forward, torch arm slightly raised.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```

**`enemy_shield_guard`** — Щитоносец — охранный робот с ростовым щитом (спереди неуязвим)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A heavy corporate security robot holding a tall rectangular riot shield in front of it: the shield is thick dark steel with a vertical glowing magenta light strip and a narrow armoured viewing slit, almost as tall as the robot. Behind the shield: a broad armoured torso, a small head with a red horizontal visor, a stun baton in the other hand held low. Strong stance, one foot forward. The shield faces LEFT and covers the front of the body.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```

**`enemy_scout_drone`** — Дрон-разведчик — летает, стреляет лазером

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A small hovering surveillance drone: a round armoured body like a flattened sphere, one large glowing red lens eye facing left with a laser emitter under it, four small rotor fans on short arms (seen from the side, two visible), a short antenna, a magenta status light, hazard stripes on the arms. Hovering, slightly tilted forward.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```

**`enemy_ceiling_turret`** — Потолочная турель — висит вниз головой

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A ceiling-mounted factory security turret hanging upside down: a bolted steel mounting plate at the TOP edge of the picture, a rotating armoured ball joint under it, a compact twin-barrel gun pointing down-left, a red targeting lens, ammo belt, hazard stripes on the mount. The mounting plate is flat on top as if screwed into a ceiling.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```

**`enemy_kamikaze`** — Камикадзе — маленький робот-колесо, катится и взрывается

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A small rolling bomb robot about knee-high: a single thick rubber wheel with a ribbed tread, inside it a round steel core with a big blinking red warning light and yellow-and-black hazard stripes, a short antenna with a red bulb, exposed wires and a small explosive canister strapped on top. Compact and cute but dangerous.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```

**`enemy_repair_drone`** — Ремонтный дрон — чинит других роботов

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A small flying maintenance drone: a slim rounded white-and-steel body with a green cross-shaped indicator light, two little rotor fans on top, two thin mechanical arms hanging below holding a repair tool that emits a soft green beam emitter (no beam drawn), a small toolbox compartment, a green lens eye facing left. Friendly-looking but robotic.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```

**`enemy_loader_brute`** — Погрузчик-громила — тяжёлый, бьёт манипулятором

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A heavy industrial cargo loader robot, twice human size: a wide low armoured body on two short thick legs, a small armoured cockpit-like head with a red visor, one huge hydraulic manipulator arm ending in a two-pronged forklift claw held forward to the LEFT, the other arm short with a clamp, exhaust pipes on the back puffing smoke, yellow-and-black hazard paint on the claw, warning lamp on top. Heavy, leaning forward.

A single game character sprite: only this one robot, full body, strict side view, facing LEFT.
It must read clearly on a very dark background: bright steel-blue and light grey metal highlights,
glowing red eye(s), yellow-and-black hazard stripes, a small magenta Lumen light. Old, scratched and
oil-stained but still working; no rust holes, no flesh, no slime, no humans inside.
Flat even lighting, pure white background, no shadow under the feet, no glow halo spreading onto the
background, nothing cropped by the image edge, no text. Square 1:1.
```


---

## 2.4 Босс — Гигантский погрузчик

Две картинки: сам босс и его «открытый реактор» для третьей фазы. Приложи готовый `enemy_loader_brute`,
когда он будет, — чтобы босс был из той же серии, но огромный.


**`boss_loader`** — гигантский погрузчик (погоня и бой)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A colossal automated cargo loader machine, as tall as a two-storey building, the boss of the factory: a massive armoured chassis on huge caterpillar tracks, a front cab with a wide red glowing visor slit like angry eyes, two gigantic forklift prongs at the front lowered to the LEFT and scraped from smashing walls, one enormous hydraulic manipulator arm with a three-fingered claw raised high above, smoke stacks on the back puffing black smoke, yellow-and-black hazard stripes everywhere, magenta Lumen lights along the sides, chains and torn cables hanging from it. On its back a closed round armoured hatch with a faint orange glow around its rim. Menacing, leaning forward as if charging.

A single game boss sprite: only this machine, the whole machine fully visible, strict side view, facing LEFT. Bright steel highlights and glowing red eyes so it reads on a dark background. Flat even lighting, pure white background, no ground, no shadow, no glow halo spreading onto the background, nothing cropped by the image edge, no text. Landscape 3:2.
```

**`boss_loader_core`** — открытый реактор на спине (бить можно только в него)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A close-up of an open reactor core of a giant industrial machine: a round armoured hatch blown open, inside a pulsing glowing core of white-hot orange and toxic green (#8CFF4F) energy held by steel clamps and thick cables, sparks, cracked glass casing. Seen from the side.

A single game sprite: only this one object, no characters, no background scenery, no floor.
Strict side view, flat even lighting, the object is centred and nothing is cropped by the image edge.
Pure white background, no shadow under the object, no glow halo spreading onto the background,
no frame, no text. Square 1:1.
```


---

## 2.5 Фоны зон (параллакс)

Для каждой зоны — **дальний** слой (вся картинка) и **средний** (только нижняя половина, верх белый —
я сделаю его прозрачным). Слои должны быть **темнее и туманнее** игрового поля — помнишь, герои терялись
на фоне мира 1; здесь сразу просим приглушённый фон.


**`bg_far_2-1`** — 2-1 Сборочный цех, дальний

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A vast dim assembly hall inside a megafactory: endless rows of identical robot assembly lines fading into fog, giant robotic arms hanging from the ceiling, unfinished robot torsos on hooks moving along overhead rails, tall windows with magenta glow from outside, beams of dusty light.

Background layer for parallax scrolling, seen from the side: no characters, no robots in the foreground,
no text. Darker, bluer, foggier and lower in contrast than the playing field, so the heroes and enemies in
front of it stay clearly readable. Seamless horizontally tileable: the left and right edges join perfectly. The whole picture is filled. Landscape 3:2.
```

**`bg_mid_2-1`** — 2-1 Сборочный цех, средний

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Mid-distance factory machinery: assembly stations, robotic arms frozen mid-motion, stacked crates, a catwalk with railings, cables hanging, a few red warning lamps, steam.

Background layer for parallax scrolling, seen from the side: no characters, no robots in the foreground,
no text. Darker, bluer, foggier and lower in contrast than the playing field, so the heroes and enemies in
front of it stay clearly readable. Seamless horizontally tileable: the left and right edges join perfectly. Only the bottom half of the picture is filled; the top half is pure white. Landscape 3:2.
```

**`bg_far_2-2`** — 2-2 Литейная, дальний

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

An enormous foundry hall: huge crucibles pouring rivers of glowing orange molten metal in the distance, red-orange glow reflected on smoke, silhouettes of giant ladles hanging from cranes, sparks rising like fireflies, dark iron columns.

Background layer for parallax scrolling, seen from the side: no characters, no robots in the foreground,
no text. Darker, bluer, foggier and lower in contrast than the playing field, so the heroes and enemies in
front of it stay clearly readable. Seamless horizontally tileable: the left and right edges join perfectly. The whole picture is filled. Landscape 3:2.
```

**`bg_mid_2-2`** — 2-2 Литейная, средний

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Mid-distance foundry structures: casting moulds, cooling ingots glowing dull red, chains and hooks, iron staircases, pipes, heat haze, the orange light coming from below.

Background layer for parallax scrolling, seen from the side: no characters, no robots in the foreground,
no text. Darker, bluer, foggier and lower in contrast than the playing field, so the heroes and enemies in
front of it stay clearly readable. Seamless horizontally tileable: the left and right edges join perfectly. Only the bottom half of the picture is filled; the top half is pure white. Landscape 3:2.
```

**`bg_far_2-3`** — 2-3 Насосная станция, дальний

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

A gigantic underground pumping station: colossal pipes as thick as buildings running into darkness, huge pump turbines, the pipes glow faintly toxic green (#8CFF4F) from the sludge inside through small windows, at the far end a distant magenta glow of the corporate tower coming through a giant vent.

Background layer for parallax scrolling, seen from the side: no characters, no robots in the foreground,
no text. Darker, bluer, foggier and lower in contrast than the playing field, so the heroes and enemies in
front of it stay clearly readable. Seamless horizontally tileable: the left and right edges join perfectly. The whole picture is filled. Landscape 3:2.
```

**`bg_mid_2-3`** — 2-3 Насосная станция, средний

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, abandoned automated megafactory of the Lumen corporation that still runs
on its own. Moody low-key lighting, cold steel and black iron, deep navy and charcoal shadows,
yellow-and-black hazard stripes, orange glow of molten metal, white welding sparks, red warning lamps,
magenta (#FF2E88) Lumen corporate neon as an accent. Strong readable silhouettes, clean edges,
no photorealism, no pixel art, no 3D render look, no text, no letters, no logos with words, no watermark.

Mid-distance pump machinery: pipe junctions with big valve wheels, pressure tanks, leaking green sludge drips, catwalks, blinking control panels with no text.

Background layer for parallax scrolling, seen from the side: no characters, no robots in the foreground,
no text. Darker, bluer, foggier and lower in contrast than the playing field, so the heroes and enemies in
front of it stay clearly readable. Seamless horizontally tileable: the left and right edges join perfectly. Only the bottom half of the picture is filled; the top half is pure white. Landscape 3:2.
```


---

## 2.6 Комиксы

Перед каждым кадром — блок стиля для комиксов (уже внутри промптов). К кадрам с героями прикладывай
**оба концепта**: `art_source/concepts/gunner_concept_approved.png` и `art_source/concepts/swordsman_concept_approved.png`.
Подписи внизу кадра добавлю сам — в картинке текста быть не должно.


**`world2_intro_01`** — Начало мира 2, кадр 1 — «Цеха работают сами. Двадцать лет — без единого человека.» (приложить оба концепта)

```
Style: dark painterly 2D illustration, cinematic comic panel, post-apocalyptic cyberpunk,
ruined neon megacity, deep navy and charcoal shadows, rusted metal, fog, ash in the air,
selective neon light (cyan, magenta, orange, toxic green). Same style as the attached images.
No text, no speech bubbles, no captions, no watermark. Landscape 3:2.

The Gunner and the Swordsman, seen from behind and slightly from the side, stepping through a torn opening in a huge factory wall into a gigantic assembly hall. Below them endless conveyor lines with robots assembling robots, sparks of welding, robotic arms moving, magenta Lumen lights, smoke. The heroes are small against the scale of the factory. Keep both characters exactly as in the attached images.
```

**`world2_intro_02`** — Начало мира 2, кадр 2 — «Охранный робот узнал пропуск Мечника… и пропустил его.» (приложить оба концепта)

```
Style: dark painterly 2D illustration, cinematic comic panel, post-apocalyptic cyberpunk,
ruined neon megacity, deep navy and charcoal shadows, rusted metal, fog, ash in the air,
selective neon light (cyan, magenta, orange, toxic green). Same style as the attached images.
No text, no speech bubbles, no captions, no watermark. Landscape 3:2.

A tall corporate security robot with a riot shield scanning the Swordsman with a red laser grid across his face; the Swordsman stands still, tense, an old corporate ID tag on his chest lit by the scan; the Gunner behind him has his rifle half-raised. The robot's visor light changes from red to green. Tense close-medium shot inside the factory. Keep both characters exactly as in the attached images.
```

**`world2_end_02`** — После мира 2, кадр 2 — «Осталась последняя дорога — наверх.» (приложить оба концепта и `art_source/comics/world2_end_01.png` (стиль))

```
Style: dark painterly 2D illustration, cinematic comic panel, post-apocalyptic cyberpunk,
ruined neon megacity, deep navy and charcoal shadows, rusted metal, fog, ash in the air,
selective neon light (cyan, magenta, orange, toxic green). Same style as the attached images.
No text, no speech bubbles, no captions, no watermark. Landscape 3:2.

Low-angle shot of the colossal corporate tower piercing the smog, searchlights sweeping the sky, armed corporate guards on platforms, the glowing magenta core at its base, the two heroes small at its foot seen from behind. Keep both characters exactly as in the attached images.
```


---

## 2.7 Иконки нового оружия для лавки

Пока иконок нет, в витрине показывается оружие в руках — игре они не мешают.


**`weapon_flamethrower`** — приложить `art_source/ui/weapon_rifle_original.png` (тот же стиль и материалы)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

A scavenged industrial flamethrower in the same rusty style as the attached rifle: a short wide nozzle
of blackened copper with a ring of small vents, a tiny blue pilot flame at the very tip, a riveted
steel body, a pistol grip and a front grip made of pipe, a dented red fuel tank with yellow-and-black
hazard stripes mounted under the body, a coiled black rubber hose running from the tank to the nozzle,
a small round pressure gauge, heat-darkened metal near the nozzle. Side view, nozzle pointing right.
Exactly one weapon, no second tank, no backpack.

A single game shop icon: only this one object, no hands, no character, no background scenery.
The object is centred, fills about 85% of the picture, nothing cropped by the image edge.
Flat even lighting, pure white background, no shadow under the object, no glow halo spreading
onto the background, no frame, no text, no letters. Square 1:1.
```

**`weapon_shock_baton`** — приложить `art_source/ui/weapon_blade_original.png` (тот же стиль и материалы)

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

A heavy one-handed electric stun baton, a former factory security tool, in the same rusty style as
the attached sword: a thick dark steel rod about as long as a forearm and a half, wrapped with copper
coils along its length, two short metal prongs at the tip with a small bright blue-white electric arc
jumping between them, a few thin blue sparks crawling along the coils, a ribbed rubber grip with a
worn yellow-and-black hazard band, a round guard disc, a battery pack with a glowing cyan charge
indicator at the pommel. Side view, laid diagonally from bottom-left to top-right, the tip at the top
right. Exactly one baton, no sword, no blade.

A single game shop icon: only this one object, no hands, no character, no background scenery.
The object is centred, fills about 85% of the picture, nothing cropped by the image edge.
Flat even lighting, pure white background, no shadow under the object, no glow halo spreading
onto the background, no frame, no text, no letters. Square 1:1.
```


---

## 2.8 Музыка

Как в мире 1 — подберу сам из бесплатной библиотеки (Kevin MacLeod, индастриал-рок в духе Comix Zone):
по треку на зону и отдельный на погоню. От тебя ничего не нужно.

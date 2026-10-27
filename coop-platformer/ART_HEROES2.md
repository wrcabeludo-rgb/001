# Позы героев и усилители — недостающие спрайты

Каждый промпт — целиком, ничего добавлять не нужно. К позам прикладывай исходную картинку героя:
стрелку — `art_source/heroes/gunner_side_original.png`, мечнику — `art_source/heroes/swordsman_side_original.png`.
Имя файла — как в заголовке; присылай в чат, дальше вырежу и подключу сам.

## Герои: ранение и гибель

Сейчас при ударе герой только мигает, а погибнув — исчезает.

**1. `gunner_hurt_1`** — стрелок — отброшен ударом. Приложить `gunner_side_original.png`. Portrait 2:3.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Gunner):
a long tattered sand-beige hooded coat with torn hem and holes, a long ragged dark-red scarf wrapped
around the neck and hanging behind, a respirator mask with glowing cyan lenses inside the hood,
riveted steel shoulder and forearm plates, dark quilted trousers with steel knee plates, tall brown
buckled boots, a belt with pouches and two glowing cyan energy cells. He holds ONLY ONE weapon: the
same long rusty scavenged rifle — skeletal stock, scope on top, two glowing cyan energy cells along
the body, dark-red cloth wrapped around the barrel, a perforated muzzle, a brown leather sling.

Full body, side view facing right, the same scale as the attached image.
Pose: hit hard from the front and knocked back — the body bent backwards, the head thrown back, the hood
slipping, both feet just leaving the ground, the arms flung out, the rifle still gripped in his right hand
but swung away from the body, the coat and scarf flying forward. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one rifle, held in his hands (or just dropped next to him where the pose says so).
```

**2. `gunner_death_1`** — стрелок — падает без сил. Приложить `gunner_side_original.png`. Landscape 3:2.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Gunner):
a long tattered sand-beige hooded coat with torn hem and holes, a long ragged dark-red scarf wrapped
around the neck and hanging behind, a respirator mask with glowing cyan lenses inside the hood,
riveted steel shoulder and forearm plates, dark quilted trousers with steel knee plates, tall brown
buckled boots, a belt with pouches and two glowing cyan energy cells. He holds ONLY ONE weapon: the
same long rusty scavenged rifle — skeletal stock, scope on top, two glowing cyan energy cells along
the body, dark-red cloth wrapped around the barrel, a perforated muzzle, a brown leather sling.

Full body, side view facing right, the same scale as the attached image.
Pose: collapsed on the ground after a defeat — lying on his side along the ground line, knees slightly bent,
one arm under the head, the rifle dropped on the ground just in front of his hand, the coat spread
around him, the cyan mask lenses dim. Not gory — he looks knocked out, not dead. Landscape 3:2.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one rifle, held in his hands (or just dropped next to him where the pose says so).
```

**3. `swordsman_hurt_1`** — мечник — отброшен ударом. Приложить `swordsman_side_original.png`. Portrait 2:3.

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
dash-shaped vents, held in his right (mechanical) hand. There is NO sheath, NO scabbard and NO
second sword on his belt, back or hip — the belt has only pouches.

Full body, side view facing right, the same scale as the attached image.
Pose: hit hard from the front and knocked back — the body bent backwards, teeth clenched, both feet just
leaving the ground, the free left arm flung out, the glowing blade still held in his right hand and swung
back away from the body, the scarf flying forward. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one sword, in his hand (or just dropped next to him where the pose says so); no sword on the belt.
```

**4. `swordsman_death_1`** — мечник — падает без сил. Приложить `swordsman_side_original.png`. Landscape 3:2.

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
dash-shaped vents, held in his right (mechanical) hand. There is NO sheath, NO scabbard and NO
second sword on his belt, back or hip — the belt has only pouches.

Full body, side view facing right, the same scale as the attached image.
Pose: collapsed on the ground after a defeat — lying on his side along the ground line, knees slightly bent,
the glowing sword dropped on the ground just in front of his open right hand, its glow fading.
Not gory — he looks knocked out, not dead. Landscape 3:2.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one sword, in his hand (or just dropped next to him where the pose says so); no sword on the belt.
```

## Стрелок: стрельба вверх и по диагонали

Стрелок стреляет в 8 сторон, а нарисован только с винтовкой вперёд.

**5. `gunner_aim_up_1`** — стрелок — ствол строго вверх. Приложить `gunner_side_original.png`. Portrait 2:3.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Gunner):
a long tattered sand-beige hooded coat with torn hem and holes, a long ragged dark-red scarf wrapped
around the neck and hanging behind, a respirator mask with glowing cyan lenses inside the hood,
riveted steel shoulder and forearm plates, dark quilted trousers with steel knee plates, tall brown
buckled boots, a belt with pouches and two glowing cyan energy cells. He holds ONLY ONE weapon: the
same long rusty scavenged rifle — skeletal stock, scope on top, two glowing cyan energy cells along
the body, dark-red cloth wrapped around the barrel, a perforated muzzle, a brown leather sling.

Full body, side view facing right, the same scale as the attached image.
Pose: standing firmly, feet apart, aiming the rifle straight up at the sky — the rifle vertical, the stock
pressed to his right shoulder, both hands on it, the head tilted back looking up along the barrel,
the muzzle at the very top of the picture with space above it. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one rifle, held in his hands (or just dropped next to him where the pose says so).
```

**6. `gunner_aim_diag_up_1`** — стрелок — ствол по диагонали вверх-вперёд. Приложить `gunner_side_original.png`. Portrait 2:3.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Gunner):
a long tattered sand-beige hooded coat with torn hem and holes, a long ragged dark-red scarf wrapped
around the neck and hanging behind, a respirator mask with glowing cyan lenses inside the hood,
riveted steel shoulder and forearm plates, dark quilted trousers with steel knee plates, tall brown
buckled boots, a belt with pouches and two glowing cyan energy cells. He holds ONLY ONE weapon: the
same long rusty scavenged rifle — skeletal stock, scope on top, two glowing cyan energy cells along
the body, dark-red cloth wrapped around the barrel, a perforated muzzle, a brown leather sling.

Full body, side view facing right, the same scale as the attached image.
Pose: standing firmly, feet apart, aiming the rifle diagonally up and forward at 45 degrees — the stock
at his right shoulder, both hands on the rifle, the masked face looking along the barrel. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one rifle, held in his hands (or just dropped next to him where the pose says so).
```

**7. `gunner_aim_diag_down_1`** — стрелок — в прыжке, ствол по диагонали вниз-вперёд. Приложить `gunner_side_original.png`. Portrait 2:3.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

Keep exactly the same character design, colours and proportions as the attached image (the Gunner):
a long tattered sand-beige hooded coat with torn hem and holes, a long ragged dark-red scarf wrapped
around the neck and hanging behind, a respirator mask with glowing cyan lenses inside the hood,
riveted steel shoulder and forearm plates, dark quilted trousers with steel knee plates, tall brown
buckled boots, a belt with pouches and two glowing cyan energy cells. He holds ONLY ONE weapon: the
same long rusty scavenged rifle — skeletal stock, scope on top, two glowing cyan energy cells along
the body, dark-red cloth wrapped around the barrel, a perforated muzzle, a brown leather sling.

Full body, side view facing right, the same scale as the attached image.
Pose: in mid-air, knees pulled up, aiming the rifle diagonally down and forward at 45 degrees — both hands on
the rifle, the masked face looking down along the barrel, the coat and scarf flying up behind. Portrait 2:3.

Flat even lighting on the character, pure white background, nothing cropped by the image edge,
no motion lines, no glow halos around the figure, no shadow on the ground, no blood, no text.
Check: exactly one rifle, held in his hands (or just dropped next to him where the pose says so).
```

## Усилители (подбираются из врагов)

Сейчас это светящиеся шарики с буквой. Без приложения.

**8. `power_rage`** — «Ярость» — двойной урон, цвет красный.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

A small glowing power-up capsule for a game pickup: a riveted steel capsule with a cracked glass window, inside it
a furious swirling red-orange energy like a tiny fire storm, a red glowing claw-mark emblem (no letters) on the
front plate, small sparks.

A single game pickup icon: only this one object, no hands, no character, no background scenery.
The object is centred, fills about 80% of the picture, nothing cropped by the image edge.
Flat even lighting, pure white background, no shadow, no glow halo spreading onto the background,
no frame, no text, no letters. Square 1:1.
```

**9. `power_shield`** — «Щит» — неуязвимость, цвет светло-голубой.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

A small glowing power-up capsule for a game pickup: a riveted steel capsule with a glass window, inside it a calm
pale-blue energy, a hexagonal force-field grid glowing light blue around it, a shield-shaped emblem (no letters)
on the front plate.

A single game pickup icon: only this one object, no hands, no character, no background scenery.
The object is centred, fills about 80% of the picture, nothing cropped by the image edge.
Flat even lighting, pure white background, no shadow, no glow halo spreading onto the background,
no frame, no text, no letters. Square 1:1.
```

**10. `power_haste`** — «Скорость» — быстрее бег и атака, цвет жёлтый.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

A small glowing power-up capsule for a game pickup: a riveted steel capsule with a glass window, inside it a bright
yellow crackling energy, a lightning-bolt emblem (no letters) on the front plate, little yellow sparks streaming
back as if moving fast.

A single game pickup icon: only this one object, no hands, no character, no background scenery.
The object is centred, fills about 80% of the picture, nothing cropped by the image edge.
Flat even lighting, pure white background, no shadow, no glow halo spreading onto the background,
no frame, no text, no letters. Square 1:1.
```

## Дополнительная жизнь (спрятана в тайниках, по 2 на мир)

**11. `pickup_life`** — «+1 жизнь». Файл назвать `pickup_life_original.png`.

```
Style: dark painterly 2D game art for a side-scrolling platformer, hand-painted digital illustration,
post-apocalyptic cyberpunk, ruined neon megacity after a catastrophe. Moody low-key lighting,
deep navy and charcoal shadows, rusted metal and cracked concrete, thin fog, rain-wet surfaces,
selective neon accents (cyan, magenta, orange) as the main light sources. Strong readable silhouettes,
clean edges, no photorealism, no pixel art, no 3D render look, no text, no watermark.

A small precious game pickup: a glowing magenta-pink neon heart made of bent glass tube, held inside a scratched
round steel locket-frame with four rivets, a soft warm inner light pulsing in the heart, a few tiny pink sparks.
It must read instantly as "an extra life" even at a very small size.

A single game pickup icon: only this one object, no hands, no character, no background scenery.
The object is centred, fills about 80% of the picture, nothing cropped by the image edge.
Flat even lighting, pure white background, no shadow, no glow halo spreading onto the background,
no frame, no text, no letters, no numbers. Square 1:1.
```

Проверка: ровно одно сердце, без надписей «+1» (цифру игра рисует сама, если нужно), белый фон.

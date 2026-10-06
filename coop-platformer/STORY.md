# «Неон и пепел» — сюжет

> Подача: короткие комиксы между мирами (3–4 кадра), текст — подписи внизу кадра шрифтом игры.
> Картинки кадров генерируются в ChatGPT по промптам ниже, надписей на самих картинках нет.

## Логлайн

Город жив, пока горит неон. Но тот же свет порождает мутантов. Двое идут к сердцу города, чтобы решить:
погасить последние огни — или оставить их гореть.

## Мир

- **Двадцать лет назад** корпорация **«Люмен»** запустила под своей Башней неоновый реактор **«Сердце»** —
  бесконечный источник света и энергии для всего мегаполиса.
- **Ночь Вспышки:** реактор сорвался. Город выгорел дотла — отсюда пепел на улицах и вечный смог.
  Но «Сердце» не погасло: оно до сих пор питает вывески, фонари и машины.
- **Цена света:** вместе с энергией реактор выбрасывает **зелёную жижу**. Она течёт по трубам в трущобы,
  и всё живое, что к ней прикасается, мутирует.
- **Сегодня:** люди живут в трущобах на руинах, тянутся к теплу неона и медленно меняются.
  Заводы «Люмена» работают сами по себе — роботы до сих пор выполняют приказы мёртвой корпорации.
  На вершине Башни остатки охраны «Люмена» стерегут «Сердце».

## Герои

| | Стрелок | Мечник |
|---|---|---|
| Кто | Мусорщик-разведчик из трущоб | Бывший охранник «Люмена» |
| Цвет | Циан | Оранжевый |
| Зачем идёт | Его посёлок мутирует; он ищет, откуда течёт жижа, и хочет это остановить | В ночь Вспышки он стоял на посту у «Сердца». Механическая рука — то, что осталось от его экзокостюма. Он знает дорогу и хочет исправить то, что не смог предотвратить |
| Характер | Недоверчивый, быстрый, почти не говорит | Тяжёлый, спокойный, говорит коротко, о прошлом молчит |

Имена пока не даём — в комиксах и интерфейсе герои зовутся «Стрелок» и «Мечник». Можно добавить позже.

## Путь через три мира

| Мир | Место | Враги | Босс | Что узнают герои |
|---|---|---|---|---|
| 1 | Трущобы на руинах | Мутанты | Арена: огромный мутант из главного стока жижи | Жижа течёт по трубам с заводов |
| 2 | Заводы «Люмена» | Роботы и дроны | Погоня: гигантский погрузчик крушит цех за героями | Заводы качают жижу от «Сердца»; мечник был там в ночь Вспышки |
| 3 | Башня «Люмена» | Охрана корпорации | Арена: командир охраны в полном экзокостюме | Как выключить «Сердце» и что будет с городом |

## Финал: выбор

У «Сердца» два рубильника.

- **Погасить.** Неон гаснет навсегда. Город погружается во тьму и пепел, но жижа больше не течёт — мутации остановятся.
  Финальный кадр: первые звёзды над тёмным городом, люди разжигают костры.
- **Оставить.** Свет продолжает гореть, город живёт как прежде — и жижа течёт дальше.
  Финальный кадр: неоновый город сияет, а в трущобах из зелёных луж поднимаются новые тени.

**Вдвоём:** каждый игрок стоит у своего рубильника, и решение срабатывает, только когда оба выбрали одно и то же.
**Один игрок:** выбор делает он сам.

---

## Комиксы

### Блок стиля для кадров (вставлять перед каждым промптом)

```
Style: dark painterly 2D illustration, cinematic comic panel, post-apocalyptic cyberpunk,
ruined neon megacity, deep navy and charcoal shadows, rusted metal, fog, ash in the air,
selective neon light (cyan, magenta, orange, toxic green). Same style as the attached images.
No text, no speech bubbles, no captions, no watermark. Landscape 3:2.
```

К кадрам с героями прикладывать **утверждённые концепты** и писать «keep both characters exactly as in the attached images».

### Вступление (перед миром 1)

| # | Подпись | Промпт (после блока стиля) |
|---|---|---|
| 1 | Двадцать лет назад «Люмен» зажёг «Сердце». Город сиял ярче звёзд. | `Wide shot of a gleaming futuristic megacity at night before the catastrophe, endless neon, a colossal tower in the center with a glowing core at its base.` |
| 2 | Потом была Вспышка. | `The same megacity at the moment of catastrophe: a blinding white-magenta blast from the base of the central tower, shockwave, skyscrapers breaking, fire.` |
| 3 | Город сгорел. Но свет не погас. И вместе со светом пришла жижа. | `Ruined slums at night, broken neon signs still glowing, a rusted pipe pouring glowing toxic green sludge into a puddle, a mutated silhouette rising from it.` |
| 4 | Двое идут туда, где всё началось. | `The Gunner and the Swordsman seen from behind, standing on a ruined rooftop, looking at the distant central tower with a faint glowing core at the horizon, ash falling.` |

### После мира 1

| # | Подпись | Промпт |
|---|---|---|
| 1 | Трубы ведут на заводы «Люмена». Они всё ещё работают. | `A giant pipeline leading from the slums to huge factories with glowing windows and smoke stacks, robots silhouettes on the walkways.` |
| 2 | — Я здесь уже был, — сказал Мечник. | `Close-up of the Swordsman looking at the factories, the orange glow of his mechanical arm on his face, troubled expression.` |

### После мира 2

Готово: кадр 1 — `art_source/comics/world2_end_01.png` (встроится вместе с миром 2).

| # | Подпись | Промпт |
|---|---|---|
| 1 | В ночь Вспышки он стоял на посту у «Сердца». | `Flashback, desaturated: a corporate security guard in a full exosuit standing at a reactor door as a white-magenta blast erupts behind it.` |
| 2 | Осталась последняя дорога — наверх. | `Low-angle shot of the colossal tower piercing the smog, searchlights, corporate guards on platforms, the two heroes small at its base.` |

### Финалы

Готово: «Погасить» — `art_source/comics/ending_off.png`, «Оставить» — `art_source/comics/ending_keep.png`.

| Концовка | Подпись | Промпт |
|---|---|---|
| Погасить | Неон погас. Впервые за двадцать лет над городом зажглись звёзды. | `The dark ruined megacity with all neon lights off, a clear night sky full of stars, small campfires in the slums, the two heroes sitting on a rooftop.` |
| Оставить | Город сияет. А в трущобах снова поднимаются тени. | `The ruined megacity glowing brightly with neon, but in the foreground slums new mutated silhouettes rise from glowing green puddles.` |

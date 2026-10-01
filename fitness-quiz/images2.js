// Дополнительные схемы (собственные SVG). Цвета берутся из CSS-переменных и подходят светлой и тёмной теме.
(function () {
  const ST = 'fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"';
  const P = (...pts) => 'M' + pts.map(p => p.join(' ')).join('L');
  // человечек сбоку: p = {h, s, hip, k, a, t, e, w}
  function fig(p, extra) {
    let d = `<circle cx="${p.h[0]}" cy="${p.h[1]}" r="10" ${ST}/>`;
    d += `<path d="${P(p.s, p.hip, p.k, p.a, p.t)}" ${ST}/>`;
    if (p.e) d += `<path d="${P(p.s, p.e, p.w)}" ${ST}/>`;
    return d + (extra || '');
  }
  const bar = (x, y, w = 24) => `<path d="M${x - w} ${y}H${x + w}" stroke="var(--c-orange)" stroke-width="4" stroke-linecap="round"/><circle cx="${x - w}" cy="${y}" r="6" fill="var(--c-orange)"/><circle cx="${x + w}" cy="${y}" r="6" fill="var(--c-orange)"/>`;
  const pose = (x, label, body) => `<g transform="translate(${x},0)">${body}<text x="70" y="214" text-anchor="middle" font-size="12" fill="currentColor">${label}</text></g>`;
  const wrap = (vb, label, inner) => `<svg viewBox="${vb}" role="img" aria-label="${label}">${inner}</svg>`;
  const txt = (x, y, s, o = '') => `<text x="${x}" y="${y}" ${o.includes('font-size') ? '' : 'font-size="11.5"'} ${o.includes('fill=') ? '' : 'fill="currentColor"'} ${o}>${s}</text>`;
  const floor = `<path d="M5 192H135" stroke="var(--c-line,#999)" stroke-width="2"/>`;

  window.IMG = window.IMG || {};
  Object.assign(window.IMG, {
    // ---------- упражнения ----------
    squat: wrap('0 0 300 225', 'Приседание: исходное и нижнее положение',
      pose(5, 'Исходное положение', floor + fig({ h: [60, 28], s: [60, 52], hip: [60, 110], k: [62, 152], a: [60, 190], t: [76, 190], e: [72, 66], w: [66, 52] }, bar(60, 52, 22))) +
      pose(155, 'Нижняя точка', floor + fig({ h: [90, 64], s: [82, 88], hip: [48, 130], k: [96, 142], a: [62, 190], t: [78, 190], e: [92, 98], w: [84, 86] }, bar(82, 86, 22)))),
    deadlift: wrap('0 0 300 225', 'Становая тяга: старт и верхняя точка',
      pose(5, 'Старт', floor + fig({ h: [96, 72], s: [84, 86], hip: [42, 116], k: [74, 152], a: [62, 190], t: [78, 190], e: [76, 128], w: [72, 168] }, bar(72, 172, 22) )) +
      pose(155, 'Верхняя точка', floor + fig({ h: [58, 34], s: [58, 58], hip: [54, 116], k: [56, 154], a: [56, 190], t: [72, 190], e: [62, 90], w: [64, 128] }, bar(64, 134, 22)))),
    bench: wrap('0 0 300 225', 'Жим штанги лёжа: нижнее и верхнее положение',
      '<g transform="translate(5,0)"><path d="M12 150H132" stroke="var(--c-line,#999)" stroke-width="6"/><path d="M30 154v36M116 154v36" stroke="var(--c-line,#999)" stroke-width="4"/>' +
      `<circle cx="22" cy="134" r="10" ${ST}/><path d="${P([36, 140], [104, 140], [128, 128], [124, 176])}" ${ST}/><path d="${P([42, 140], [60, 128], [48, 128])}" ${ST}/>${bar(48, 128, 14)}` +
      txt(70, 214, 'Нижнее положение', 'text-anchor="middle"') + '</g>' +
      '<g transform="translate(155,0)"><path d="M12 150H132" stroke="var(--c-line,#999)" stroke-width="6"/><path d="M30 154v36M116 154v36" stroke="var(--c-line,#999)" stroke-width="4"/>' +
      `<circle cx="22" cy="134" r="10" ${ST}/><path d="${P([36, 140], [104, 140], [128, 128], [124, 176])}" ${ST}/><path d="${P([42, 140], [46, 116], [46, 96])}" ${ST}/>${bar(46, 94, 14)}` +
      txt(70, 214, 'Верхнее положение', 'text-anchor="middle"') + '</g>'),
    pulldown: wrap('0 0 300 225', 'Тяга вертикального блока: верх и низ',
      pose(5, 'Верх (руки вытянуты)', `<path d="M60 4V30" stroke="var(--c-line,#999)" stroke-width="2"/>` + fig({ h: [56, 56], s: [56, 80], hip: [56, 138], k: [100, 138], a: [100, 190], t: [116, 190], e: [62, 50], w: [66, 30] }, bar(66, 30, 30) + '<path d="M5 138H70" stroke="var(--c-line,#999)" stroke-width="4"/>')) +
      pose(155, 'Низ (гриф к груди)', fig({ h: [52, 56], s: [54, 80], hip: [56, 138], k: [100, 138], a: [100, 190], t: [116, 190], e: [38, 96], w: [66, 84] }, bar(66, 84, 30) + '<path d="M5 138H70" stroke="var(--c-line,#999)" stroke-width="4"/>'))),
    lunge: wrap('0 0 300 225', 'Выпад: исходное и нижнее положение',
      pose(5, 'Исходное положение', floor + fig({ h: [60, 28], s: [60, 52], hip: [60, 110], k: [62, 152], a: [60, 190], t: [76, 190], e: [60, 82], w: [60, 112] })) +
      pose(155, 'Нижняя точка', floor + fig({ h: [60, 56], s: [60, 80], hip: [62, 136], k: [98, 148], a: [98, 190], t: [114, 190], e: [60, 110], w: [60, 138] }, `<path d="M62 136L36 170L18 190" ${ST}/>`))),
    crunch: wrap('0 0 300 225', 'Скручивание: исходное положение и сгибание',
      pose(5, 'Исходное положение', `<path d="M5 182H135" stroke="var(--c-line,#999)" stroke-width="2"/><circle cx="22" cy="168" r="10" ${ST}/><path d="${P([34, 174], [92, 178], [118, 146], [140, 178])}" ${ST}/><path d="${P([36, 172], [22, 150], [30, 160])}" ${ST}/>`) +
      pose(155, 'Лопатки оторваны', `<path d="M5 182H135" stroke="var(--c-line,#999)" stroke-width="2"/><circle cx="46" cy="130" r="10" ${ST}/><path d="${P([56, 142], [92, 178], [118, 146], [140, 178])}" ${ST}/><path d="${P([58, 142], [52, 122], [46, 126])}" ${ST}/>`)),
    grips: wrap('0 0 340 130', 'Виды хвата',
      [['Прямой', 'пронация: от себя', 0], ['Обратный', 'супинация: к себе', 1], ['Нейтральный', 'ладони друг к другу', 2]].map(([a, b, i]) => {
        const x = 10 + i * 108;
        const hand = i === 0 ? `<rect x="${x + 22}" y="22" width="56" height="34" rx="8" ${ST}/><path d="M${x + 22} 40H${x + 78}" stroke="var(--c-orange)" stroke-width="5"/>`
          : i === 1 ? `<rect x="${x + 22}" y="22" width="56" height="34" rx="8" ${ST}/><path d="M${x + 22} 38H${x + 78}" stroke="var(--c-blue)" stroke-width="5"/><path d="M${x + 36} 22v-10m14 10v-14m14 14v-10" ${ST}/>`
            : `<rect x="${x + 38}" y="12" width="26" height="54" rx="8" ${ST}/><path d="M${x + 38} 40H${x + 64}" stroke="var(--c-green)" stroke-width="5"/>`;
        return hand + txt(x + 50, 92, a, 'text-anchor="middle" font-weight="700"') + txt(x + 50, 108, b, 'text-anchor="middle" font-size="10"');
      }).join('')),

    // ---------- анатомия ----------
    shoulder: wrap('0 0 440 260', 'Плечевой сустав',
      `<path d="M150 20H250" ${ST}/><path d="M250 20L282 40" ${ST}/><path d="M150 20Q120 40 138 90Q150 118 160 120L168 78Q172 50 150 20Z" fill="none" stroke="currentColor" stroke-width="2.5"/>` +
      `<circle cx="168" cy="132" r="26" fill="none" stroke="var(--c-blue)" stroke-width="3"/><path d="M146 150Q166 214 150 252" ${ST}/><path d="M192 152Q204 214 196 252" ${ST}/>` +
      `<path d="M170 60Q210 66 238 96" stroke="var(--c-orange)" stroke-width="3" fill="none" stroke-dasharray="5 3"/>` +
      txt(180, 12, 'Ключица · акромион') + txt(20, 60, 'Лопатка', '') + txt(20, 74, '(суставная впадина)') +
      txt(208, 124, 'Головка плечевой кости', 'font-weight="700"') + txt(208, 140, 'шаровидный сустав') +
      txt(246, 94, 'Клювовидно-', 'fill="var(--c-orange)"') + txt(246, 108, 'акромиальная связка', 'fill="var(--c-orange)"') +
      txt(212, 190, 'Ротаторная манжета:') + txt(212, 205, 'надостная, подостная,') + txt(212, 220, 'малая круглая,') + txt(212, 235, 'подлопаточная')),
    knee: wrap('0 0 460 300', 'Коленный сустав, вид спереди',
      `<path d="M150 8Q150 100 134 112Q150 130 180 126Q210 130 226 112Q210 100 210 8Z" fill="none" stroke="currentColor" stroke-width="2.5"/>` +
      `<path d="M128 150H232L224 292H136Z" fill="none" stroke="currentColor" stroke-width="2.5"/>` +
      `<ellipse cx="146" cy="138" rx="22" ry="8" fill="none" stroke="var(--c-green)" stroke-width="3"/><ellipse cx="214" cy="138" rx="22" ry="8" fill="none" stroke="var(--c-green)" stroke-width="3"/>` +
      `<circle cx="180" cy="86" r="18" fill="none" stroke="var(--c-orange)" stroke-width="3"/>` +
      `<path d="M168 118L196 148M192 118L164 148" stroke="var(--c-red)" stroke-width="3.5"/>` +
      `<path d="M136 112V150M224 112V150" stroke="var(--c-blue)" stroke-width="3"/>` +
      txt(236, 20, 'Бедренная кость', 'font-weight="700"') + txt(236, 34, '(медиальный и латеральный мыщелки)') +
      txt(204, 88, '', '') + txt(236, 88, 'Надколенник', 'fill="var(--c-orange)"') +
      txt(236, 128, 'Мениски (амортизация)', 'fill="var(--c-green)"') +
      txt(236, 170, 'Крестообразные связки:', 'fill="var(--c-red)"') + txt(236, 184, 'ПКС и ЗКС (перекрёст)', 'fill="var(--c-red)"') +
      txt(236, 214, 'Боковые связки', 'fill="var(--c-blue)"') + txt(236, 228, '(коллатеральные)', 'fill="var(--c-blue)"') +
      txt(236, 266, 'Большеберцовая кость', 'font-weight="700"')),
    elbow: wrap('0 0 440 270', 'Локтевой сустав',
      `<path d="M150 8V90Q128 110 152 126H206Q232 110 210 90V8Z" fill="none" stroke="currentColor" stroke-width="2.5"/>` +
      `<path d="M176 132L168 262H196L204 132Z" fill="none" stroke="currentColor" stroke-width="2.5"/><path d="M128 132L112 262H150L158 132Z" fill="none" stroke="currentColor" stroke-width="2.5"/>` +
      txt(230, 40, 'Плечевая кость', 'font-weight="700"') + txt(230, 54, '(блок, головчатое', '') + txt(230, 68, 'возвышение, надмыщелки)') +
      txt(230, 140, 'Локтевая кость', 'font-weight="700"') + txt(8, 160, 'Лучевая кость', 'font-weight="700"') +
      txt(230, 168, '3 сустава в 1 капсуле:') + txt(230, 184, '· плечелоктевой (блок)', 'fill="var(--c-blue)"') + txt(230, 199, '· плечелучевой (шар)', 'fill="var(--c-green)"') + txt(230, 214, '· лучелоктевой (цилиндр)', 'fill="var(--c-orange)"')),
    brain: wrap('0 0 440 270', 'Отделы головного мозга',
      `<path d="M70 120Q64 40 150 28Q250 14 290 70Q320 112 290 150Q250 170 160 164Q80 166 70 120Z" fill="none" stroke="currentColor" stroke-width="3"/>` +
      `<ellipse cx="120" cy="82" rx="40" ry="26" fill="none" stroke="var(--c-blue)" stroke-width="2.5" stroke-dasharray="4 3"/>` +
      `<path d="M200 178Q250 170 262 198Q250 226 200 222Q184 200 200 178Z" fill="none" stroke="var(--c-green)" stroke-width="3"/>` +
      `<path d="M150 164V250M170 164V250" stroke="currentColor" stroke-width="3" fill="none"/><path d="M150 200H170M150 220H170" stroke="currentColor" stroke-width="2"/>` +
      txt(8, 14, 'Конечный мозг (кора):', 'font-weight="700"') + txt(180, 14, 'мышление, память,') + txt(180, 28, 'произвольные движения') +
      txt(8, 140, 'Промежуточный:', 'fill="var(--c-blue)"') + txt(8, 154, 'таламус, гипоталамус', 'fill="var(--c-blue)"') + '<path d="M60 128L100 100" stroke="var(--c-blue)" stroke-width="1"/>' +
      txt(270, 206, 'Мозжечок:', 'fill="var(--c-green)"') + txt(270, 220, 'координация,', 'fill="var(--c-green)"') + txt(270, 234, 'равновесие', 'fill="var(--c-green)"') +
      txt(184, 196, '') + txt(8, 186, 'Средний мозг', '') + txt(8, 212, 'Мост', '') + txt(8, 242, 'Продолговатый мозг:') + txt(8, 256, 'дыхание, кровообращение') + `<path d="M100 180H148M60 210H148M120 240H148" stroke="currentColor" stroke-width="1" opacity=".5"/>`),
    cell: wrap('0 0 380 270', 'Клетка и её органеллы',
      `<ellipse cx="190" cy="132" rx="170" ry="112" fill="none" stroke="currentColor" stroke-width="3"/>` +
      `<circle cx="150" cy="120" r="34" fill="none" stroke="var(--c-blue)" stroke-width="3"/><circle cx="150" cy="120" r="9" fill="var(--c-blue)"/>` +
      `<ellipse cx="260" cy="84" rx="30" ry="15" fill="none" stroke="var(--c-orange)" stroke-width="3"/><path d="M240 84q8 -10 16 0t16 0" stroke="var(--c-orange)" fill="none" stroke-width="2"/>` +
      `<path d="M215 150q16 -12 32 0t32 0M215 164q16 -12 32 0t32 0" stroke="var(--c-green)" fill="none" stroke-width="3"/>` +
      `<path d="M105 180q20 -14 40 0t40 0M105 194q20 -14 40 0t40 0" stroke="var(--c-red)" fill="none" stroke-width="3"/>` +
      `<circle cx="290" cy="196" r="9" fill="none" stroke="currentColor" stroke-width="2.5"/><circle cx="106" cy="76" r="2.5" fill="currentColor"/><circle cx="120" cy="66" r="2.5" fill="currentColor"/><circle cx="96" cy="92" r="2.5" fill="currentColor"/>` +
      txt(8, 30, 'Клеточная мембрана', 'font-weight="700"') + txt(112, 172, 'Ядро (ДНК)', 'fill="var(--c-blue)" font-weight="700"') +
      txt(236, 56, 'Митохондрия: АТФ', 'fill="var(--c-orange)" font-weight="700"') + txt(222, 188, 'Аппарат Гольджи', 'fill="var(--c-green)" font-weight="700"') +
      txt(86, 224, 'ЭПС (транспорт, синтез)', 'fill="var(--c-red)" font-weight="700"') + txt(268, 224, 'Лизосома') + txt(52, 62, 'Рибосомы')),
    resp: wrap('0 0 420 280', 'Дыхательная система',
      `<path d="M190 8V86" stroke="currentColor" stroke-width="10" stroke-linecap="round"/><path d="M190 86L150 130M190 86L230 130" stroke="currentColor" stroke-width="7" stroke-linecap="round"/>` +
      `<path d="M138 70Q70 80 76 180Q86 240 150 226Q164 190 156 130Q150 90 138 70Z" fill="none" stroke="var(--c-blue)" stroke-width="3"/>` +
      `<path d="M242 70Q310 80 304 180Q294 240 230 226Q216 190 224 130Q230 90 242 70Z" fill="none" stroke="var(--c-blue)" stroke-width="3"/>` +
      `<path d="M60 250Q190 220 320 250" fill="none" stroke="var(--c-orange)" stroke-width="4"/>` +
      txt(204, 22, 'Гортань и трахея') + txt(8, 100, 'Правое лёгкое', '') + txt(8, 114, '(3 доли)') + txt(290, 100, 'Левое лёгкое') + txt(290, 114, '(2 доли)') +
      txt(204, 40, 'Бронхи → бронхиолы', 'fill="var(--c-blue)" font-weight="700"') + txt(204, 56, '→ альвеолы', 'fill="var(--c-blue)" font-weight="700"') + txt(40, 272, 'Диафрагма — главная дыхательная мышца', 'fill="var(--c-orange)"')),
    kidney: wrap('0 0 440 280', 'Выделительная система',
      `<path d="M120 40Q70 40 76 100Q82 150 130 140Q108 90 120 40Z" fill="none" stroke="var(--c-red)" stroke-width="3"/><path d="M240 40Q290 40 284 100Q278 150 230 140Q252 90 240 40Z" fill="none" stroke="var(--c-red)" stroke-width="3"/>` +
      `<path d="M124 120Q150 190 176 218M236 120Q210 190 184 218" fill="none" stroke="currentColor" stroke-width="3"/>` +
      `<circle cx="180" cy="236" r="22" fill="none" stroke="var(--c-blue)" stroke-width="3"/><path d="M180 258V276" stroke="currentColor" stroke-width="3"/>` +
      txt(20, 24, 'Почки: фильтрация крови, образование мочи', 'font-weight="700" fill="var(--c-red)"') + txt(250, 160, 'Мочеточники', '') + txt(210, 240, 'Мочевой пузырь', 'fill="var(--c-blue)"') + txt(194, 274, 'Мочеиспускательный канал') +
      txt(8, 170, 'Нефрон — единица') + txt(8, 186, 'почки: клубочек,') + txt(8, 202, 'канальцы') + txt(8, 218, '(фильтрация,') + txt(8, 234, 'реабсорбция,') + txt(8, 250, 'секреция)')),
    endocrine: wrap('0 0 460 300', 'Железы внутренней секреции',
      `<circle cx="100" cy="30" r="20" ${ST}/><path d="M100 50V170M100 70L58 120M100 70L142 120M100 170L80 250M100 170L120 250" ${ST}/>` +
      [[100, 26, 'Гипофиз и эпифиз'], [100, 58, 'Щитовидная и паращитовидные'], [100, 80, 'Тимус (вилочковая)'], [92, 112, 'Надпочечники'], [106, 124, 'Поджелудочная'], [100, 172, 'Половые железы']].map(([x, y, t], i) => {
        const ty = 28 + i * 44; return `<circle cx="${x}" cy="${y}" r="4" fill="var(--c-red)"/><path d="M${x + 6} ${y}L205 ${ty - 4}" stroke="var(--c-red)" stroke-width="1" opacity=".6"/>` + txt(208, ty, t);
      }).join('')),

    // ---------- метаболизм, шкалы, структура ----------
    glycolysis: wrap('0 0 380 300', 'Пути метаболизма глюкозы',
      (function () {
        const b = (x, y, w, t, c) => `<rect x="${x}" y="${y}" width="${w}" height="30" rx="8" fill="none" stroke="${c}" stroke-width="2.5"/>${txt(x + w / 2, y + 19, t, 'text-anchor="middle" font-weight="700"')}`;
        const a = (d, c) => `<path d="${d}" stroke="${c}" stroke-width="2" fill="none"/>`;
        return b(10, 20, 100, 'Гликоген', 'var(--c-orange)') + b(140, 20, 100, 'Глюкоза', 'var(--c-blue)') + b(270, 20, 100, 'Лактат', 'var(--c-red)') +
          a('M60 50V76M56 70l4 6l4 -6', 'var(--c-orange)') + a('M120 35H140M133 31l7 4l-7 4', 'var(--c-orange)') +
          b(140, 100, 100, 'Пируват', 'var(--c-blue)') + a('M190 50V100M186 94l4 6l4 -6', 'var(--c-blue)') + a('M240 115H320V50M316 56l4 -6l4 6', 'var(--c-red)') +
          b(140, 180, 100, 'Ацетил-КоА', 'var(--c-green)') + a('M190 130V180M186 174l4 6l4 -6', 'var(--c-green)') +
          b(115, 240, 150, 'Цикл Кребса → CO₂', 'var(--c-green)') + a('M190 210V240M186 234l4 6l4 -6', 'var(--c-green)') +
          txt(8, 96, 'Гликогенолиз ↑', 'fill="var(--c-orange)"') + txt(8, 110, 'Гликогенез ↓', 'fill="var(--c-orange)"') +
          txt(196, 76, 'Гликолиз (цитоплазма)', 'fill="var(--c-blue)"') + txt(250, 100, 'без O₂ (ЛДГ)', 'fill="var(--c-red)"') + txt(196, 164, 'с O₂', 'fill="var(--c-green)"') + txt(280, 262, 'митохондрия', 'fill="var(--c-green)"') +
          txt(262, 170, 'Глюконеогенез:') + txt(262, 184, 'лактат, глицерин,') + txt(262, 198, 'аминокислоты →') + txt(262, 212, 'глюкоза (печень,') + txt(262, 226, 'почки)');
      })()),
    session: wrap('0 0 390 160', 'Структура тренировочного занятия',
      `<rect x="10" y="20" width="80" height="40" rx="8" fill="var(--c-orange)"/><rect x="94" y="20" width="200" height="40" rx="8" fill="var(--c-green)"/><rect x="298" y="20" width="80" height="40" rx="8" fill="var(--c-blue)"/>` +
      txt(50, 45, 'Разминка', 'text-anchor="middle" fill="#fff" font-weight="700"') + txt(194, 45, 'Основная часть', 'text-anchor="middle" fill="#fff" font-weight="700"') + txt(338, 45, 'Заминка', 'text-anchor="middle" fill="#fff" font-weight="700"') +
      txt(50, 78, '5–15 мин', 'text-anchor="middle"') + txt(194, 78, '30–60 мин', 'text-anchor="middle"') + txt(338, 78, '5–10 мин', 'text-anchor="middle"') +
      txt(10, 108, 'Разминка: разогрев, подводящие подходы') + txt(10, 126, 'Основная: силовая, кардио, функциональная работа') + txt(10, 144, 'Заминка: кардио, растяжка, расслабление')),
    period: wrap('0 0 380 210', 'Макроцикл, мезоцикл, микроцикл',
      `<rect x="8" y="8" width="364" height="194" rx="14" fill="none" stroke="var(--c-blue)" stroke-width="3"/><rect x="30" y="52" width="320" height="130" rx="12" fill="none" stroke="var(--c-green)" stroke-width="3"/><rect x="52" y="96" width="276" height="72" rx="10" fill="none" stroke="var(--c-orange)" stroke-width="3"/>` +
      txt(20, 34, 'Макроцикл: полугодие – год', 'font-weight="700" fill="var(--c-blue)"') + txt(42, 78, 'Мезоцикл: 3–6 микроциклов (1–2 месяца)', 'font-weight="700" fill="var(--c-green)"') + txt(64, 122, 'Микроцикл: неделя', 'font-weight="700" fill="var(--c-orange)"') + txt(64, 140, '(несколько занятий)') + txt(64, 156, 'Тренировка — часть микроцикла')),
    zones: wrap('0 0 380 150', 'Пульсовые зоны',
      [['50–60', 'Восстановление', '#6aa3d8', 0], ['60–70', 'Аэробная (жиросжигание)', '#3f9d6b', 1], ['70–80', 'Развитие выносливости', '#d9b13b', 2], ['80–90', 'Анаэробный порог', '#e07b39', 3], ['90–100', 'Максимум', '#c0392b', 4]]
        .map(([p, n, c, i]) => `<rect x="${10 + i * 72}" y="20" width="70" height="40" fill="${c}"/>` + txt(45 + i * 72, 45, p + '%', 'text-anchor="middle" fill="#fff" font-weight="700"')).join('') +
      txt(10, 84, '% от ЧССmax; ЧССmax = 220 − возраст') + txt(10, 104, 'Целевая зона 60–85%, оптимальная 60–80%') + txt(10, 124, 'Пример: 30 лет → ЧССmax 190, зона 114–152')),
    bmi: wrap('0 0 380 140', 'Шкала индекса массы тела',
      [['&lt; 18,5', 'Дефицит', '#6aa3d8'], ['18,5–24,9', 'Норма', '#3f9d6b'], ['25–29,9', 'Избыток', '#d9b13b'], ['30–34,9', 'Ожирение I', '#e07b39'], ['35–39,9', 'Ожирение II', '#d1542c'], ['≥ 40', 'Ожирение III', '#a82f25']]
        .map(([r, n, c], i) => `<rect x="${8 + i * 61}" y="16" width="60" height="42" fill="${c}"/>` + txt(38 + i * 61, 35, r, 'text-anchor="middle" fill="#fff" font-size="10.5" font-weight="700"') + txt(38 + i * 61, 77 + (i % 2) * 14, n, 'text-anchor="middle" font-size="10.5"')).join('') +
      txt(8, 118, 'ИМТ = масса (кг) ÷ рост² (м²). Не отличает жир от мышц.', '')),
    ph: wrap('0 0 380 120', 'Шкала pH крови',
      `<rect x="10" y="24" width="360" height="22" fill="#e07b39"/><rect x="195" y="24" width="45" height="22" fill="#3f9d6b"/><rect x="240" y="24" width="130" height="22" fill="#6aa3d8"/>` +
      txt(10, 18, '6,8', '') + txt(190, 18, '7,35', '') + txt(236, 18, '7,45', '') + txt(352, 18, '7,8', '') +
      txt(60, 66, 'Ацидоз (&lt; 7,35)', 'fill="var(--c-orange)" font-weight="700"') + txt(168, 84, 'Норма', 'fill="var(--c-green)" font-weight="700"') + txt(262, 66, 'Алкалоз (&gt; 7,45)', 'fill="var(--c-blue)" font-weight="700"') +
      txt(10, 108, 'Закисление = рост H⁺: лактат + H⁺, CO₂, кетоновые тела')),
    motorunit: wrap('0 0 440 200', 'Двигательная единица',
      `<circle cx="40" cy="100" r="20" fill="none" stroke="var(--c-blue)" stroke-width="3"/><path d="M60 100H150" stroke="var(--c-blue)" stroke-width="3"/>` +
      [40, 80, 120, 160].map(y => `<path d="M150 100L200 ${y}" stroke="var(--c-blue)" stroke-width="2"/><rect x="200" y="${y - 7}" width="140" height="14" rx="7" fill="none" stroke="var(--c-red)" stroke-width="2.5"/>`).join('') +
      txt(10, 138, 'α-мотонейрон', 'fill="var(--c-blue)" font-weight="700"') + txt(10, 154, '(спинной мозг)') + txt(206, 188, 'Мышечные волокна одной ДЕ', 'fill="var(--c-red)" font-weight="700"') + txt(10, 20, 'ДЕ = мотонейрон + все его волокна. «Всё или ничего».', ''))
  });
})();

(function () {
  const T = (x, y, s, o = '') => `<text x="${x}" y="${y}" font-size="11.5" ${o.includes('fill=') ? '' : 'fill="currentColor"'} ${o}>${s}</text>`;
  const bone = 'stroke="currentColor" stroke-opacity=".35" stroke-linecap="round" fill="none"';
  const org = (x, y, c) => `<circle cx="${x}" cy="${y}" r="5" fill="${c}"/>`;
  const ins = (x, y, c) => `<rect x="${x - 5}" y="${y - 5}" width="10" height="10" fill="${c}"/>`;
  const line = (d, c) => `<path d="${d}" fill="none" stroke="${c}" stroke-width="3" stroke-linecap="round"/>`;
  const legend = (y) => `<circle cx="14" cy="${y}" r="5" fill="currentColor"/>` + T(24, y + 4, 'начало') + `<rect x="84" y="${y - 5}" width="10" height="10" fill="currentColor"/>` + T(100, y + 4, 'прикрепление');
  const wrap = (vb, label, body) => `<svg viewBox="${vb}" role="img" aria-label="${label}">${body}</svg>`;
  const G = 'var(--c-green)', B = 'var(--c-blue)', O = 'var(--c-orange)', R = 'var(--c-red)';
  Object.assign(window.IMG, {
    m_back: wrap('0 0 560 346', 'Мышцы спины: начало и прикрепление',
      `<path d="M150 40V300" ${bone} stroke-width="10"/><circle cx="150" cy="22" r="14" ${bone} stroke-width="4"/>
       <path d="M200 90L262 82L268 150L205 170Z" ${bone} stroke-width="5"/><path d="M268 90L340 235" ${bone} stroke-width="10"/><path d="M80 300H220" ${bone} stroke-width="8"/>` +
      line('M150 50Q200 55 262 84', G) + org(150, 50, G) + ins(262, 84, G) +
      line('M150 130Q175 118 205 118', B) + org(150, 130, B) + ins(205, 118, B) +
      line('M150 285Q260 270 322 160', O) + org(150, 285, O) + ins(322, 160, O) +
      T(280, 40, 'Трапеция', `font-weight="700" fill="${G}"`) + T(280, 56, 'выйная связка, C7–Th12 →') + T(280, 70, 'ключица, акромион, ость лопатки') +
      T(8, 150, 'Ромбовидные', `font-weight="700" fill="${B}"`) + T(8, 166, 'C6–Th4 →') + T(8, 180, 'край лопатки') +
      T(230, 296, 'Широчайшая', `font-weight="700" fill="${O}"`) + T(230, 310, 'Th7–крестец, подвздошный гребень →') + T(230, 324, 'малый бугорок плечевой кости') + legend(336)),
    m_arm: wrap('0 0 520 336', 'Мышцы плеча: начало и прикрепление',
      `<path d="M60 40Q90 30 105 60L95 110Q70 100 60 40Z" ${bone} stroke-width="5"/><path d="M105 95L170 215" ${bone} stroke-width="12"/><path d="M170 220L300 262" ${bone} stroke-width="9"/><path d="M175 215L268 285" ${bone} stroke-width="6"/>` +
      line('M80 62Q150 120 190 200Q240 230 290 258', O) + org(80, 62, O) + ins(290, 258, O) +
      line('M92 108Q165 140 185 205Q180 220 176 222', B) + org(92, 108, B) + ins(176, 222, B) +
      T(220, 60, 'Двуглавая плеча', `font-weight="700" fill="${O}"`) + T(220, 76, 'лопатка (клювовидный отросток,') + T(220, 90, 'надсуставной бугорок) → бугристость лучевой') +
      T(220, 130, 'Трёхглавая плеча', `font-weight="700" fill="${B}"`) + T(220, 146, 'подсуставной бугорок лопатки,') + T(220, 160, 'плечевая кость → локтевой отросток') +
      T(8, 190, 'Лопатка', '') + T(8, 230, 'Плечевая кость') + T(8, 304, 'Предплечье: лучевая и локтевая кости') + legend(326)),
    m_trunk: wrap('0 0 500 340', 'Мышцы груди и живота: начало и прикрепление',
      `<path d="M170 60V150" ${bone} stroke-width="10"/><path d="M170 62Q240 60 305 78" ${bone} stroke-width="6"/><path d="M305 80L345 190" ${bone} stroke-width="10"/><ellipse cx="170" cy="150" rx="75" ry="70" ${bone} stroke-width="3"/><path d="M95 310H245" ${bone} stroke-width="8"/>` +
      line('M172 75Q240 90 330 110', R) + org(172, 75, R) + ins(330, 110, R) +
      line('M163 300V160', G) + org(163, 300, G) + ins(163, 160, G) +
      line('M130 190L105 300', B) + org(130, 190, B) + ins(105, 300, B) +
      T(250, 40, 'Большая грудная', `font-weight="700" fill="${R}"`) + T(250, 54, 'ключица, грудина, рёбра → плечо') +
      T(260, 250, 'Прямая живота', `font-weight="700" fill="${G}"`) + T(260, 266, 'лобковая кость → хрящи 5–7 рёбер') + T(260, 280, 'и мечевидный отросток') +
      T(8, 230, 'Наружная косая', `font-weight="700" fill="${B}"`) + T(8, 246, 'рёбра 5–12 →') + T(8, 260, 'гребень подвздошной') + legend(332)),
    m_leg: wrap('0 0 470 380', 'Мышцы бедра: начало и прикрепление',
      `<path d="M80 30Q120 20 150 55L135 95L90 105Z" ${bone} stroke-width="5"/><path d="M125 100L135 235" ${bone} stroke-width="14"/><path d="M135 245L138 350" ${bone} stroke-width="10"/><path d="M150 250L152 345" ${bone} stroke-width="5"/><circle cx="152" cy="238" r="9" ${bone} stroke-width="3"/>` +
      line('M150 58Q172 120 160 235Q162 250 150 262', O) + org(150, 58, O) + ins(150, 262, O) +
      line('M92 104Q100 170 108 215Q122 235 140 262', B) + org(92, 104, B) + ins(142, 262, B) +
      line('M84 62Q100 110 122 145', G) + org(84, 62, G) + ins(122, 145, G) +
      T(215, 70, 'Квадрицепс', `font-weight="700" fill="${O}"`) + T(215, 86, 'прямая: нижняя передняя ость;') + T(215, 100, 'остальные — бедро → бугристость') + T(215, 114, 'большеберцовой (через надколенник)') +
      T(215, 190, 'Двуглавая бедра', `font-weight="700" fill="${B}"`) + T(215, 206, 'седалищный бугор → головка') + T(215, 220, 'малоберцовой кости') +
      T(215, 290, 'Большая ягодичная', `font-weight="700" fill="${G}"`) + T(215, 306, 'подвздошная, крестец → ягодичная') + T(215, 320, 'бугристость бедра') + legend(368))
  });
})();

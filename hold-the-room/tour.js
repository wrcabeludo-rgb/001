'use strict';

// =====================================================================
//  Тур: акты, карта с развилками, события, реликвии, «Слава», дерево души,
//  ежедневный вызов. Только данные и чистые функции, без DOM.
//  Номера залов совпадают с CONFIG.levels в game.js.
// =====================================================================
const TOUR = {
  acts: [
    { name: 'Бары', venues: [0, 1], boss: { kind: 'critic', venue: 1, name: 'Критик журнала «Звук»' } },
    { name: 'Клубы', venues: [2, 3], boss: { kind: 'rival', venue: 3, name: 'Бывший друг' } },
    { name: 'Большая сцена', venues: [3, 4], boss: { kind: 'fear', venue: 4, name: 'Страх' } },
  ],
  rows: [5, 7],            // вечеров в акте до босса
  rowWidth: [2, 3],        // точек в ряду карты
  nodeWeights: { concert: 0.6, event: 0.27, market: 0.13 },
  rowDifficulty: 0.05,     // +5% к спаду интереса за каждый следующий вечер акта
  actDifficulty: [0, 0.2, 0.35], // и ещё столько за номер акта
  pinSlots: 3,             // сколько карт можно закрепить в стартовый набор
  marketPrices: [120, 260],
  // «Слава» за тур: 1 за каждые perViewers удержанных зрителей, плюс за боссов и победу
  fame: { perViewers: 10, boss: 15, victory: 30 },
};

// ---------------------------------------------------------------------
//  Реликвии — бонусы до конца тура
// ---------------------------------------------------------------------
const RELICS = {
  mediator: { name: 'Медиатор Михалыча', desc: 'Аура души даёт +1 интереса в секунду.', apply: m => { m.auraGain += 1; } },
  scarf: { name: 'Мамин шарф', desc: 'Зал начинает песню с интересом на 5 выше.', apply: m => { m.startInterest += 5; } },
  pedal: { name: 'Педаль эффектов', desc: 'Перезарядка активных карт на 10% быстрее.', apply: m => { m.cooldownMul *= 0.9; } },
  strings: { name: 'Новые струны', desc: 'Струна больше не рвётся.', apply: m => { m.noString = true; } },
  flashlight: { name: 'Фонарик', desc: 'Когда выключают свет, круг света вдвое больше.', apply: m => { m.blackoutLightMul *= 2; } },
  badge: { name: 'Бейдж охраны', desc: 'Дебошир успокаивается вдвое быстрее.', apply: m => { m.drunkCalmMul *= 2; } },
  tape: { name: 'Кассета группы', desc: 'В начале каждого концерта — одна карта на выбор.', apply: m => { m.freeCard = true; } },
  sneakers: { name: 'Кеды', desc: 'Душа летает на 12% быстрее.', apply: m => { m.speedMul += 0.12; } },
  poster: { name: 'Старая афиша', desc: 'Драйв с эмоций +10%.', apply: m => { m.driveMul *= 1.1; } },
  coin: { name: 'Монетка на удачу', desc: 'Касса каждого концерта +15%.', apply: m => { m.moneyMul *= 1.15; } },
  thermos: { name: 'Термос с чаем', desc: 'Разогрев длиннее на 6 секунд.', apply: m => { m.warmupBonus += 6; } },
  headphones: { name: 'Мониторные наушники', desc: 'Радиус сбора эмоций +10.', apply: m => { m.pickup += 10; } },
};
const RELIC_IDS = Object.keys(RELICS);

// ---------------------------------------------------------------------
//  Дерево способностей души и облики (за «Славу», навсегда)
// ---------------------------------------------------------------------
const SOUL_TREE = [
  { id: 'warm', name: 'Тёплая душа', cost: [20, 40, 70], desc: l => `Аура даёт +${l} интереса в секунду.`, apply: (m, l) => { m.auraGain += l; } },
  { id: 'wide', name: 'Широкая душа', cost: [25, 50, 80], desc: l => `Радиус ауры +${l * 12}%.`, apply: (m, l) => { m.auraRadiusMul *= 1 + 0.12 * l; } },
  { id: 'light', name: 'Лёгкая душа', cost: [20, 40, 70], desc: l => `Душа летает на ${l * 8}% быстрее.`, apply: (m, l) => { m.speedMul += 0.08 * l; } },
  { id: 'keen', name: 'Чуткость', cost: [20, 40, 70], desc: l => `Радиус сбора эмоций +${l * 6}.`, apply: (m, l) => { m.pickup += 6 * l; } },
  { id: 'spark', name: 'Вдохновение', cost: [30, 60, 90], desc: l => `Зал начинает с интересом на ${l * 3} выше.`, apply: (m, l) => { m.startInterest += 3 * l; } },
  { id: 'hands', name: 'Память рук', cost: [120], desc: () => 'Можно закрепить 4 карты вместо 3.', apply: () => {} },
  { id: 'charm', name: 'Талисман', cost: [100], desc: () => 'Каждый тур начинается со случайной реликвией.', apply: () => {} },
];

const SOUL_SKINS = [
  { id: 'neon', name: 'Неон', cost: 0, colors: ['#3de0ff', '#5dff9e', '#ff3d8b', '#ffd23d'] },
  { id: 'sunset', name: 'Закат', cost: 30, colors: ['#ff9a3d', '#ff6f3d', '#ff3d6e', '#ffd23d'] },
  { id: 'ghost', name: 'Призрак', cost: 40, colors: ['#b8d8ff', '#d6e8ff', '#eef4ff', '#ffffff'] },
  { id: 'emerald', name: 'Изумруд', cost: 40, colors: ['#3dffb0', '#5dff7a', '#b6ff3d', '#ffe23d'] },
];

function treeLevel(save, id) { return (save.tree && save.tree[id]) || 0; }

function treePrice(save, id) {
  const n = SOUL_TREE.find(x => x.id === id), l = treeLevel(save, id);
  return n && l < n.cost.length ? n.cost[l] : null;
}

function buyTree(save, id) {
  const price = treePrice(save, id);
  if (price == null || save.fame < price) return false;
  save.fame -= price;
  save.tree[id] = treeLevel(save, id) + 1;
  return true;
}

function buySkin(save, id) {
  const sk = SOUL_SKINS.find(x => x.id === id);
  if (!sk || save.skins.owned.includes(id) || save.fame < sk.cost) return false;
  save.fame -= sk.cost;
  save.skins.owned.push(id);
  save.skins.selected = id;
  return true;
}

function pinSlots(save) { return TOUR.pinSlots + (treeLevel(save, 'hands') ? 1 : 0); }

// Модификаторы для newGame(): дерево души + реликвии тура + особые условия вечера
function soulMods(save) {
  const m = {
    auraGain: 0, speedMul: 1, startInterest: 0, pickup: 0, perViewer: 0, incidentMul: 1, repairMul: 1, freeCard: false,
    cooldownMul: 1, driveMul: 1, moneyMul: 1, warmupBonus: 0, noString: false, blackoutLightMul: 1, drunkCalmMul: 1,
    auraRadiusMul: 1, decayMul: 1, startCards: [], boss: null, duration: null,
  };
  for (const n of SOUL_TREE) { const l = treeLevel(save, n.id); if (l) n.apply(m, l); }
  return m;
}

function tourMods(save, tour, node) {
  const m = soulMods(save);
  for (const id of tour.relics) RELICS[id].apply(m);
  m.startCards = tour.pinned.slice();
  const act = TOUR.acts[tour.act];
  m.decayMul *= 1 + TOUR.rowDifficulty * (node.row + 1) + TOUR.actDifficulty[tour.act] + (tour.nextDecay || 0);
  if (node.type === 'boss') { m.boss = act.boss.kind; m.duration = 180; }
  return m;
}

// ---------------------------------------------------------------------
//  Карта акта: ряды точек, последний ряд — босс. Переходы — к соседним точкам.
// ---------------------------------------------------------------------
function rint(rnd, a, b) { return a + Math.floor(rnd() * (b - a + 1)); }

function pickType(rnd) {
  const w = TOUR.nodeWeights;
  let x = rnd() * (w.concert + w.event + w.market);
  if ((x -= w.concert) < 0) return 'concert';
  if ((x -= w.event) < 0) return 'event';
  return 'market';
}

function genAct(rnd, actIdx) {
  const act = TOUR.acts[actIdx];
  const nRows = rint(rnd, TOUR.rows[0], TOUR.rows[1]);
  const rows = [];
  let markets = 0;
  for (let r = 0; r < nRows; r++) {
    const w = rint(rnd, TOUR.rowWidth[0], TOUR.rowWidth[1]);
    const row = [];
    for (let i = 0; i < w; i++) {
      // первый ряд — всегда концерты; барахолок не больше одной в ряду и двух за акт
      let type = r === 0 ? 'concert' : pickType(rnd);
      if (type === 'market' && (markets >= 2 || row.some(n => n.type === 'market'))) type = 'event';
      if (type === 'market') markets++;
      const venue = act.venues[r < nRows / 2 ? 0 : 1];
      row.push({ row: r, col: i, x: (i + 0.5) / w, type, venue: type === 'concert' ? (rnd() < 0.25 ? act.venues[1 - act.venues.indexOf(venue)] : venue) : null });
    }
    rows.push(row);
  }
  // хотя бы одна барахолка на акт (не в первом ряду)
  if (!rows.some(row => row.some(n => n.type === 'market'))) {
    const r = rint(rnd, 1, nRows - 1), n = rows[r][rint(rnd, 0, rows[r].length - 1)];
    n.type = 'market'; n.venue = null;
  }
  rows.push([{ row: nRows, col: 0, x: 0.5, type: 'boss', venue: act.boss.venue }]);
  // переходы: к точкам следующего ряда, близким по горизонтали; минимум один
  for (let r = 0; r < rows.length - 1; r++) {
    for (const n of rows[r]) {
      const next = rows[r + 1];
      n.next = next.filter(m => Math.abs(m.x - n.x) <= 0.34).map(m => m.col);
      if (!n.next.length) {
        const near = next.slice().sort((a, b) => Math.abs(a.x - n.x) - Math.abs(b.x - n.x))[0];
        n.next = [near.col];
      }
    }
    // у каждой точки следующего ряда должен быть вход
    for (const m of rows[r + 1]) {
      if (!rows[r].some(n => n.next.includes(m.col))) {
        const near = rows[r].slice().sort((a, b) => Math.abs(a.x - m.x) - Math.abs(b.x - m.x))[0];
        near.next.push(m.col);
      }
    }
  }
  return rows;
}

// Куда можно пойти сейчас
function availableNodes(tour) {
  const rows = tour.map;
  if (tour.row < 0) return rows[0];
  const cur = rows[tour.row][tour.col];
  return (cur.next || []).map(c => rows[tour.row + 1][c]);
}

function newTour(save, seed) {
  const rnd = mulberry32Tour(seed);
  const tour = {
    seed, act: 0, row: -1, col: null, map: genAct(rnd, 0),
    money: 0, relics: [], pinned: [], bond: 0, nextDecay: 0,
    nights: 0, kept: 0, bosses: 0, flags: {}, path: [],
  };
  if (treeLevel(save, 'charm')) tour.relics.push(RELIC_IDS[Math.floor(rnd() * RELIC_IDS.length)]);
  return tour;
}

function enterNode(tour, node) {
  tour.row = node.row; tour.col = node.col;
  tour.path.push(`${tour.act}:${node.row}:${node.col}`);
}

// Итог концерта в туре. passed — удержано больше половины зала.
function settleConcert(tour, node, res) {
  const money = Math.round(res.money * (res.passed ? 1 : 0.5));
  tour.money += money;
  tour.nights++;
  tour.kept += res.left;
  tour.nextDecay = 0;
  const share = res.total ? res.left / res.total : 0;
  const bondGain = Math.round(share * 10) / 10;
  tour.bond = Math.round((tour.bond + bondGain) * 10) / 10;
  return { money, bondGain };
}

// Переход в следующий акт после победы над боссом
function nextAct(tour, seedShift) {
  tour.bosses++;
  tour.act++;
  if (tour.act >= TOUR.acts.length) return false;
  tour.map = genAct(mulberry32Tour(tour.seed + 7919 * tour.act + (seedShift || 0)), tour.act);
  tour.row = -1; tour.col = null;
  return true;
}

function tourFame(tour, victory) {
  const F = TOUR.fame;
  return Math.floor(tour.kept / F.perViewers) + tour.bosses * F.boss + (victory ? F.victory : 0);
}

function marketOffer(tour, rnd) {
  const pool = RELIC_IDS.filter(id => !tour.relics.includes(id));
  const out = [];
  while (out.length < 3 && pool.length) {
    const id = pool.splice(Math.floor(rnd() * pool.length), 1)[0];
    const [a, b] = TOUR.marketPrices;
    out.push({ id, price: Math.round((a + rnd() * (b - a)) / 10) * 10 });
  }
  return out;
}

function randomRelic(tour, rnd) {
  const pool = RELIC_IDS.filter(id => !tour.relics.includes(id));
  if (!pool.length) return null;
  const id = pool[Math.floor(rnd() * pool.length)];
  tour.relics.push(id);
  return id;
}

// ---------------------------------------------------------------------
//  События. text и choices получают g(м, ж) — форма слова по герою.
//  effect меняет тур и возвращает текст результата.
// ---------------------------------------------------------------------
// Выдать реликвию, если её ещё нет; вернуть строку для текста результата
function giveRelic(t, id) {
  if (!id || t.relics.includes(id)) return '';
  t.relics.push(id);
  return ` Новая реликвия: «${RELICS[id].name}» — ${RELICS[id].desc.charAt(0).toLowerCase()}${RELICS[id].desc.slice(1)}`;
}

// effect(t, rnd, g): t — тур, rnd — случайность, g(м, ж) — форма слова по герою
const EVENTS = [
  {
    id: 'producer', title: 'Пьяный продюсер',
    text: () => 'После концерта к стойке подсаживается человек в дорогом пиджаке. «Я тебя слышал. Ну, почти. Давай контракт подпишем? Только аванс с тебя — сто рублей, на оформление».',
    choices: [
      { label: 'Заплатить 100 ₽', cost: 100, effect: (t, rnd) => rnd() < 0.5
        ? 'Продюсер исчезает с деньгами, но на столе остаётся монетка. «На удачу», — подмигивает Михалыч.' + giveRelic(t, 'coin')
        : 'Продюсер исчезает вместе с деньгами. Михалыч молча наливает чай.' },
      { label: 'Выпить с ним', effect: (t, rnd) => {
        if (rnd() < 0.5) { t.money += 150; return 'К утру продюсер оплатил весь бар и ещё сунул 150 ₽ «на струны».'; }
        t.nextDecay = 0.1;
        return 'Голова гудит. Следующий концерт будет тяжелее: зал устанет на 10% быстрее.';
      } },
      { label: 'Вежливо отказаться', effect: () => '«Правильно, — кивает Михалыч. — Такие каждый вторник приходят».' },
    ],
  },
  {
    id: 'tape', title: 'Мама нашла кассету',
    text: () => 'Звонит мама: «Разбирала антресоль. Тут кассета, подписано твоей рукой: „Фестиваль. Не слушать“. Выбросить?»',
    choices: [
      { label: 'Попросить прислать', effect: t => { t.flags.tape = true; return 'Кассета приходит в конверте. На записи — шум толпы и тишина там, где должна быть песня.' + giveRelic(t, 'tape'); } },
      { label: 'Пусть лежит', effect: t => '«Ладно, — вздыхает мама. — Я тебе шарф связала, заберёшь».' + giveRelic(t, 'scarf') },
    ],
  },
  {
    id: 'office', title: 'Начальник просит субботу',
    text: () => 'В офисе начальник ловит у кулера: «Слушай, в субботу аврал. Выйдешь? Заплачу двойные». Суббота — это концерт.',
    choices: [
      { label: 'Согласиться', effect: t => { t.money += 200; t.nextDecay = 0.1; return '+200 ₽. Но вечером тело еле стоит на сцене: следующий зал устанет на 10% быстрее.'; } },
      { label: 'Отказаться', effect: t => { t.bond += 1; return 'Начальник поджимает губы: «Ну, как знаешь». А на сцене тело будто стоит ровнее. Связь тела и души +1.'; } },
      { label: 'Сказаться больным', effect: (t, rnd) => {
        if (rnd() < 0.5) return 'Поверил. Даже пожелал выздоравливать.';
        t.money = Math.max(0, t.money - 80);
        return 'Не поверил. Пришлось извиняться тортом за 80 ₽.';
      } },
    ],
  },
  {
    id: 'amp', title: 'Хрипит усилитель',
    text: () => 'Усилитель в баре хрипит и щёлкает. Знакомый мастер берётся всё перебрать и заодно поставить новые струны — за 120 ₽.',
    choices: [
      { label: 'Починить за 120 ₽', cost: 120, effect: t => 'Звук чистый, как в студии.' + giveRelic(t, 'strings') },
      { label: 'Сойдёт и так', effect: () => '«Главное — душа», — говорит Михалыч и стучит по усилителю кулаком. Тот замолкает.' },
    ],
  },
  {
    id: 'blogger', title: 'Блогерша с камерой',
    text: g => `Девушка с телефоном на палке: «Я веду канал про городскую музыку. Говорят, ты ${g('играл', 'играла')} в той самой группе. Расскажешь, почему вы распались?»`,
    choices: [
      { label: 'Рассказать правду', effect: (t, rnd) => {
        t.flags.blogger = true;
        const pool = RELIC_IDS.filter(id => !t.relics.includes(id));
        const id = pool.length ? pool[Math.floor(rnd() * pool.length)] : null;
        return 'Ты начинаешь говорить и замолкаешь на полуслове. «Нормально, — улыбается она, — так даже честнее». Видео набирает просмотры.' + giveRelic(t, id);
      } },
      { label: '«Без комментариев»', effect: () => '«Ясно. Значит, правда та, что в сети», — говорит она и уходит. Какая правда?' },
    ],
  },
  {
    id: 'mikhalych', title: 'Михалыч наливает',
    text: () => 'Бар закрывается. Михалыч ставит на стойку два стакана. Второй он двигает в пустоту — туда, где парит душа.',
    choices: [
      { label: '«Ты меня видишь?»', effect: t => { t.flags.mikhalych = true; return '«Двадцать лет за стойкой. Я много чего вижу». Он кладёт на стойку старый медиатор.' + giveRelic(t, 'mediator'); } },
      { label: 'Просто посидеть', effect: t => { t.bond += 1; return 'Тишина. На сцене тело музыканта впервые за вечер поднимает голову. Связь тела и души +1.'; } },
    ],
  },
  {
    id: 'busker', title: 'Уличный музыкант',
    text: g => `У метро парень играет на расстроенной гитаре. Шапка пустая. Он поёт твою песню — ту, которую ты никому не ${g('показывал', 'показывала')}.`,
    choices: [
      { label: 'Бросить 50 ₽', cost: 50, effect: t => '«Спасибо! Эту песню мне один музыкант показал. Говорит, сам написал». Парень отдаёт тебе свёрнутую старую афишу.' + giveRelic(t, 'poster') },
      { label: 'Сыграть вместе', effect: t => { t.money += 100; return 'Вы играете вдвоём, и шапка наполняется. Твоя доля — 100 ₽. Откуда он знает эту песню?'; } },
    ],
  },
  {
    id: 'dream', title: 'Сон о фестивале',
    text: () => 'Снится огромная сцена. Свет бьёт в глаза, тысячи лиц. Ты подходишь к микрофону — и не можешь вспомнить ни одной ноты.',
    choices: [
      { label: 'Досмотреть сон', effect: (t, rnd, g) => { t.flags.dream = true; t.bond += 1; return `В конце сна кто-то из толпы кричит твоё имя. Ты ${g('просыпаешься спокойным', 'просыпаешься спокойной')}. Связь тела и души +1.`; } },
      { label: 'Проснуться', effect: () => 'Будильник. Офис. Обычный вторник. Но пальцы сами отбивают ритм по столу.' },
    ],
  },
  {
    id: 'friend', title: 'Сообщение от старого друга',
    text: () => 'Телефон вибрирует. Имя, которого ты десять лет не видишь в уведомлениях: «Слышал, ты снова играешь. Увидимся на фестивале?»',
    choices: [
      { label: 'Ответить «Увидимся»', effect: t => { t.flags.friend = true; return 'Три точки «печатает…» появляются и исчезают. Ответа нет.'; } },
      { label: 'Удалить, не читая', effect: () => 'Палец сам нажимает «удалить». Почему так колотится сердце?' },
    ],
  },
];

// ---------------------------------------------------------------------
//  Михалыч между турами: история раскрывается постепенно, по номеру разговора.
//  Улики указывают на три версии того, почему ушла душа; ответа пока нет (см. DESIGN.md).
// ---------------------------------------------------------------------
const BAR_TALKS = [
  { lose: g => `«Опять ${g('пришёл', 'пришла')}? — Михалыч протирает стакан. — Знаешь, сколько я таких видел? Душа уходит, тело остаётся. А ты вот возвращаешься. Это редкость».`,
    win: g => `«Фестиваль, значит, — Михалыч улыбается в усы. — Только скажи честно: ты ${g('вспомнил', 'вспомнила')}, почему ушла душа?»` },
  { lose: g => `«Ты ${g('спрашивал', 'спрашивала')}, почему я тебя вижу. Потому что сам когда-то вот так же летал над этим залом. Только своё тело я так и не догнал».`,
    win: () => '«Видел твоего бывшего друга по телевизору. Хорошая песня у него. Очень знакомая», — Михалыч долго смотрит на тебя.' },
  { lose: g => `«Мама твоя заходила. Спрашивала, не видел ли я старую кассету. Сказала: „${g('Он думает', 'Она думает')}, что тогда всё испортил${g('', 'а')}. А это не так“». Что это значит?`,
    win: () => '«Десять лет назад ты стоял на этой сцене и молчал. Весь фестиваль молчал вместе с тобой. Знаешь, что было потом? Тебе ещё рано знать».' },
  { lose: () => '«Твой друг, — Михалыч понижает голос, — приходил сюда той ночью. Один. Сидел до утра и всё повторял: „Это я виноват“. В чём — не сказал».',
    win: () => '«Каждый раз, когда ты доходишь до конца, тело становится чуточку живее. Ещё немного — и вы снова будете одним целым».' },
  { lose: g => `«Кассета, которую ты боишься слушать… Там не твоя ошибка. Там то, что было после. Но ты ${g('должен', 'должна')} сам${g('', 'а')} до этого дойти».`,
    win: () => '«Знаешь, почему я здесь двадцать лет? Жду, пока кто-нибудь из вас дойдёт до конца. Похоже, ты ближе всех».' },
];

// ---------------------------------------------------------------------
//  Ежедневный вызов: один зал и одна раздача для всех в этот день
// ---------------------------------------------------------------------
const DAILY_MODS = [
  { id: 'phones', name: 'Все смотрят в телефоны', desc: 'Интерес падает на 15% быстрее.', apply: m => { m.decayMul *= 1.15; } },
  { id: 'short', name: 'Публика торопится', desc: 'Разогрев короче на 8 секунд.', apply: m => { m.warmupBonus -= 8; } },
  { id: 'generous', name: 'Щедрая публика', desc: 'Драйв с эмоций +25%, но зал устаёт на 10% быстрее.', apply: m => { m.driveMul *= 1.25; m.decayMul *= 1.1; } },
  { id: 'chaos', name: 'Беспокойный вечер', desc: 'Все происшествия точно случатся.', apply: m => { m.incidentMul *= 2; } },
  { id: 'warm', name: 'Свои люди', desc: 'Зал начинает с интересом на 8 выше, но залы пятничные: спад +10%.', apply: m => { m.startInterest += 8; m.decayMul *= 1.1; } },
];

function dayKey(date) {
  const d = date || new Date();
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function dailyChallenge(date, levelsCount) {
  const key = dayKey(date);
  const seed = Number(key.replace(/-/g, ''));
  const rnd = mulberry32Tour(seed);
  rnd(); // перемешать
  return {
    key, seed,
    levelNo: Math.floor(rnd() * (levelsCount || 5)),
    mod: DAILY_MODS[Math.floor(rnd() * DAILY_MODS.length)],
  };
}

function mulberry32Tour(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

if (typeof module !== 'undefined') {
  module.exports = {
    TOUR, RELICS, RELIC_IDS, SOUL_TREE, SOUL_SKINS, EVENTS, BAR_TALKS, DAILY_MODS, giveRelic,
    treeLevel, treePrice, buyTree, buySkin, pinSlots, soulMods, tourMods,
    genAct, availableNodes, newTour, enterNode, settleConcert, nextAct, tourFame, marketOffer, randomRelic,
    dayKey, dailyChallenge, mulberry32Tour,
  };
}

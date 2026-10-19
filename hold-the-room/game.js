'use strict';

// =====================================================================
//  «Удержи зал» — прототип. Все числа для баланса собраны в CONFIG.
//  Единицы расстояния — условные пиксели мира шириной 360.
// =====================================================================
const CONFIG = {
  songDuration: 120, // секунд (концерт босса будет 180)
  worldWidth: 360,
  worldHeightMin: 600,
  worldHeightMax: 780,

  // Уровни по нарастанию сложности. decayMul умножает спад интереса из decayPhases.
  // Музыка: Kevin MacLeod (incompetech.com), CC BY 4.0 — см. music/CREDITS.txt
  // bpm и beatOffset пока нужны только для пульса зала; пригодятся, если вернём ритм как усиление.
  levels: [
    { name: 'Пустой вторник', desc: 'Свои люди, никто не торопится домой.', viewers: 36, startInterest: 65, decayMul: 0.80,
      music: './music/level1-bossa-antigua.mp3', bpm: 140, beatOffset: 0.410, track: 'Bossa Antigua' },
    { name: 'Пятничный бар', desc: 'Обычный вечер: публика добрая, но не бесконечно.', viewers: 40, startInterest: 60, decayMul: 1.00,
      music: './music/level2-backbay-lounge.mp3', bpm: 120, beatOffset: 0.480, track: 'Backbay Lounge' },
    { name: 'Студенческая вечеринка', desc: 'Народу больше, внимание короче.', viewers: 44, startInterest: 60, decayMul: 1.18,
      music: './music/level3-funkorama.mp3', bpm: 101, beatOffset: 0.585, track: 'Funkorama' },
    { name: 'Клуб для своих', desc: 'Тут слышали всё. Удивить сложно.', viewers: 44, startInterest: 55, decayMul: 1.30,
      music: './music/level4-hep-cats.mp3', bpm: 90, beatOffset: 0.325, track: 'Hep Cats' },
    { name: 'Городской фестиваль', desc: 'Огромный зал, и все смотрят в телефоны.', viewers: 48, startInterest: 55, decayMul: 1.45,
      music: './music/level5-volatile-reaction.mp3', bpm: 155, beatOffset: 0.380, track: 'Volatile Reaction' },
  ],

  viewers: {
    decayVariance: 0.25,   // личный множитель спада: 1 ± 0.25
    happyThreshold: 60,    // выше — зритель доволен и выпускает эмоции
    boredThreshold: 25,    // ниже — серый и бредёт к выходу
    boredDriftSpeed: 5,    // скорость дрейфа скучающих к выходу
    wanderRadius: 16,
    wanderSpeed: 12,
    leaveSpeed: 55,
  },

  // Базовый спад интереса в секунду по фазам песни
  decayPhases: [
    { until: 20, rate: 0.30, banner: '' },
    { until: 60, rate: 0.95, banner: 'Куплет: зал привыкает' },
    { until: 100, rate: 1.35, banner: 'Внимание тает быстрее!' },
    { until: 120, rate: 1.80, banner: 'Финал! Держи их!' },
  ],

  // Первые секунды зал благожелателен: эмоции идут и от «нейтральных»
  warmup: { duration: 20, emitThreshold: 45 },

  // Душа музыканта: следует за пальцем по залу.
  player: {
    speed: 230,
    touchOffset: 55,   // душа держится выше пальца, чтобы его не закрывать
    auraRadius: 48,    // присутствие души рядом
    auraGain: 5,       // +интерес/с зрителям в ауре
  },

  // Бис: если к концу песни в зале столько и больше — ещё немного музыки и ливень эмоций
  // moneyBonus — прибавка к кассе за бис; её наращивают перки души и реликвии
  encore: { threshold: 0.9, duration: 20, emitMin: 0.4, emitMax: 0.9, moneyBonus: 0.2 },

  emotion: {
    intervalMin: 3.0,  // как часто довольный зритель выпускает эмоцию
    intervalMax: 6.0,
    life: 4.5,         // секунд до исчезновения
    baseDrive: 1.0,
    maxDriveBonus: 1.5, // при интересе 100 драйв = base * (1 + bonus)
    sizeMin: 8,
    sizeMax: 16,
    pickupRadius: 26,
    floatSpeed: 7,
  },

  // Сколько драйва нужно на каждый следующий уровень
  // (по симуляции: ~4-7 уровней за 2-минутную песню, 1-2 из них в разогреве)
  drive: { thresholds: [28, 50, 75, 105, 140, 180, 225, 275], extraPerLevel: 55 },

  slots: { active: 4, passive: 4 },

  cards: {
    solo: { cooldown: [3.0, 2.7, 2.4], radius: [80, 95, 110], gain: [9, 12, 16] },
    smoke: { radius: [65, 80, 95], decayMul: [0.5, 0.35, 0.2] },
    chorus: { cooldown: [4.0, 3.6, 3.2], targets: [3, 5, 7], gain: [16, 20, 25], range: 230 },
    pyro: { cooldown: [12, 11, 10], gain: [22, 30, 38], reach: [110, 140, 175] },
    costume: { radiusMul: [1.15, 1.3, 1.45] },
    charisma: { gainMul: [1.15, 1.3, 1.5] },
    amp: { cooldownMul: [0.88, 0.78, 0.68] },
    mic: { pickupBonus: [14, 28, 42], driveMul: [1.15, 1.3, 1.5] },
  },

  money: { perViewer: 10, halfBonus: 100 },

  // Боссы концертов тура
  bosses: {
    // критик: один особый зритель, теряет интерес быстрее и не даёт эмоций; должен остаться до конца
    critic: { decayMul: 2.0 },
    // соперник и страх летают по залу и гасят интерес вокруг; касание души отгоняет их
    rival: { speed: 45, radius: 70, drain: 5.0, touch: 34, stun: 2.5, retarget: 2.5, start: 12 },
    fear: { speed: 68, radius: 82, drain: 7.5, touch: 34, stun: 2.0, retarget: 2.0, start: 10 },
  },

  // Происшествия во время песни. count — сколько их запланировано на уровне,
  // каждое случается с вероятностью chance (её снижает «Знакомый техник»).
  incidents: {
    count: [1, 1, 2, 2, 3],
    chance: 0.8,
    window: [25, 105],   // в какие секунды песни могут начаться
    minGap: 18,
    // струну чинит душа, вернувшись к телу на сцене
    string: { spot: { x: 180, y: 150 }, radius: 26, repairTime: 1.5 },
    blackout: { duration: 10, decayMul: 1.7, light: 85 },
    drunk: { speed: 26, radius: 60, drain: 4, calmRadius: 32, calmTime: 1.8, maxTime: 40 },
  },
};

// Модификаторы от постоянных улучшений (будущее дерево способностей души).
// В туре их собирает tour.js: дерево души, реликвии, концерт босса.
const DEFAULT_MODS = {
  auraGain: 0, speedMul: 1, startInterest: 0, pickup: 0,
  perViewer: 0, incidentMul: 1, repairMul: 1, freeCard: false,
  cooldownMul: 1, driveMul: 1, moneyMul: 1, encoreBonus: 0, warmupBonus: 0, noString: false,
  blackoutLightMul: 1, drunkCalmMul: 1, auraRadiusMul: 1, decayMul: 1,
  startCards: [],   // закреплённые карты: выдаются на 1-м уровне в начале песни
  boss: null,       // 'critic' | 'rival' | 'fear'
  duration: null,   // длина песни, если не стандартная (концерт босса — 180 с)
};

const INCIDENT_NAMES = {
  string: 'Порвалась струна!',
  blackout: 'Вырубило свет!',
  drunk: 'Пьяный дебошир!',
};

// ---------------------------------------------------------------------
//  Карты
// ---------------------------------------------------------------------
const C = CONFIG.cards;
const CARD_DEFS = {
  solo: {
    type: 'active', name: 'Соло', color: '#3de0ff',
    desc: l => `Каждые ${f1(C.solo.cooldown[l])} с волна вокруг тебя: +${C.solo.gain[l]} интереса всем в радиусе ${C.solo.radius[l]}.`,
  },
  smoke: {
    type: 'active', name: 'Дым-машина', color: '#b49cff',
    desc: l => `Облако дыма вокруг тебя (радиус ${C.smoke.radius[l]}): интерес внутри падает на ${pct(1 - C.smoke.decayMul[l])} медленнее.`,
  },
  chorus: {
    type: 'active', name: 'Подпевка', color: '#5dff9e',
    desc: l => `Каждые ${f1(C.chorus.cooldown[l])} с ${C.chorus.targets[l]} ближайших зрителей подпевают: +${C.chorus.gain[l]} интереса.`,
  },
  pyro: {
    type: 'active', name: 'Пиротехника', color: '#ff7a3d',
    desc: l => `Раз в ${C.pyro.cooldown[l]} с взрыв над сценой: +${C.pyro.gain[l]} интереса сцене и ближним рядам.`,
  },
  costume: {
    type: 'passive', name: 'Костюм', color: '#ffd23d',
    desc: l => `Радиус всех эффектов и ауры +${pct(C.costume.radiusMul[l] - 1)}.`,
  },
  charisma: {
    type: 'passive', name: 'Харизма', color: '#ff3d8b',
    desc: l => `Любой получаемый зрителями интерес +${pct(C.charisma.gainMul[l] - 1)}.`,
  },
  amp: {
    type: 'passive', name: 'Усилитель', color: '#ffb03a',
    desc: l => `Перезарядка активных карт −${pct(1 - C.amp.cooldownMul[l])}.`,
  },
  mic: {
    type: 'passive', name: 'Микрофон', color: '#7fd0ff',
    desc: l => `Радиус подбора эмоций +${C.mic.pickupBonus[l]}, драйв с эмоции +${pct(C.mic.driveMul[l] - 1)}.`,
  },
};
const CARD_IDS = Object.keys(CARD_DEFS);

function f1(n) { return String(Math.round(n * 10) / 10).replace('.', ','); }
function pct(x) { return Math.round(x * 100) + '%'; }
function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
function dist(ax, ay, bx, by) { return Math.hypot(ax - bx, ay - by); }

function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---------------------------------------------------------------------
//  Состояние игры
// ---------------------------------------------------------------------
let G = null;

function makeLayout(worldH) {
  const W = CONFIG.worldWidth;
  const H = worldH;
  return {
    W, H,
    hudH: 44,
    wallBottom: 112,
    stageBottom: 172,
    hallTop: 182,
    hallBottom: H - 62,
    panelTop: H - 56,
    exit: { x: W - 16, y: H - 100 },
  };
}

function newGame(seed, worldH, levelIndex, mods) {
  const M = Object.assign({}, DEFAULT_MODS, mods);
  const levelNo = clamp(levelIndex | 0, 0, CONFIG.levels.length - 1);
  const LV = CONFIG.levels[levelNo];
  const rnd = mulberry32(seed == null ? (Math.random() * 1e9) | 0 : seed);
  const L = makeLayout(worldH || 680);
  const V = CONFIG.viewers;
  const viewers = [];
  const cols = 8, rows = Math.ceil(LV.viewers / cols);
  const cellW = (L.W - 40) / cols;
  const cellH = (L.hallBottom - L.hallTop - 30) / rows;
  const shirts = ['#ff5d8f', '#3de0ff', '#ffb03a', '#9b7bff', '#5dff9e', '#ff7a3d', '#ffd23d'];
  const skins = ['#f1c9a5', '#d9a47a', '#a8714d', '#7a4e33', '#f5d6c0'];
  for (let i = 0; i < LV.viewers; i++) {
    const c = i % cols, r = Math.floor(i / cols);
    const x = 20 + cellW * (c + 0.5) + (rnd() - 0.5) * cellW * 0.6;
    const y = L.hallTop + 20 + cellH * (r + 0.5) + (rnd() - 0.5) * cellH * 0.6;
    viewers.push({
      id: i, x, y, homeX: x, homeY: y, tx: x, ty: y,
      interest: Math.min(100, LV.startInterest + M.startInterest),
      decayMul: 1 + (rnd() * 2 - 1) * V.decayVariance,
      emitTimer: 0.5 + rnd() * CONFIG.emotion.intervalMax,
      wanderTimer: rnd() * 2,
      phase: rnd() * Math.PI * 2,
      shirt: shirts[(rnd() * shirts.length) | 0],
      skin: skins[(rnd() * skins.length) | 0],
      leaving: false, gone: false, flash: 0,
    });
  }
  G = {
    rnd, L,
    levelNo, lv: LV, total: LV.viewers, mods: M,
    t: 0, over: false,
    viewers,
    emotions: [],
    // душа стартует перед сценой, тело музыканта стоит в центре сцены (только рисуется)
    player: { x: L.W / 2, y: L.hallTop + 30, tx: L.W / 2, ty: L.hallTop + 30, dir: 1, moving: false },
    beat: { bpm: LV.bpm, offset: LV.beatOffset, period: 60 / LV.bpm },
    musicTime: 0,       // позиция в треке, секунды; браузер подставляет время из аудио
    externalClock: false,
    encore: null, encored: false,
    drive: 0, level: 0, pendingLevelUps: 0,
    driveBySource: {},
    levelUpTimes: [],
    cards: {},          // id -> уровень 1..3
    cardOrder: [],
    timers: {},         // id -> секунд до срабатывания
    choice: null,       // массив вариантов, когда открыт выбор
    phaseIndex: 0,
    events: [],         // визуальные события для рендера за последний кадр
    emotionsSpawned: 0, emotionsCollected: 0,
    duration: M.duration || CONFIG.songDuration,
    incidentPlan: null,
    incident: null,     // текущее происшествие
    incidentsHappened: [],
    boss: M.boss,
    critic: null,       // зритель-критик на концерте босса
    antagonist: null,   // соперник или страх
  };
  G.incidentPlan = planIncidents(rnd, levelNo, M);
  // закреплённые в туре карты — сразу в игре на 1-м уровне
  for (const id of M.startCards) if (CARD_DEFS[id] && !G.cards[id]) giveCard(id);
  // реликвия «Кассета группы»: одна карта на выбор сразу на старте
  if (M.freeCard) G.pendingLevelUps = 1;
  if (M.boss === 'critic') {
    const c = viewers.slice().sort((a, b) => dist(a.x, a.y, L.W / 2, L.hallTop + 50) - dist(b.x, b.y, L.W / 2, L.hallTop + 50))[0];
    c.critic = true; c.decayMul = CONFIG.bosses.critic.decayMul;
    G.critic = c;
  } else if (M.boss === 'rival' || M.boss === 'fear') {
    G.antagonist = { kind: M.boss, x: L.W - 40, y: L.hallTop + 20, tx: L.W / 2, ty: (L.hallTop + L.hallBottom) / 2, stun: 0, retarget: 0, active: false };
  }
  return G;
}

// ---------------------------------------------------------------------
//  Модификаторы от карт
// ---------------------------------------------------------------------
function lvl(id) { return G.cards[id] || 0; }
function radiusMul() { const l = lvl('costume'); return l ? C.costume.radiusMul[l - 1] : 1; }
function gainMul() { const l = lvl('charisma'); return l ? C.charisma.gainMul[l - 1] : 1; }
function cooldownMul() { const l = lvl('amp'); return (l ? C.amp.cooldownMul[l - 1] : 1) * G.mods.cooldownMul; }
function pickupRadius() { const l = lvl('mic'); return CONFIG.emotion.pickupRadius + G.mods.pickup + (l ? C.mic.pickupBonus[l - 1] : 0); }
function emotionDriveMul() { const l = lvl('mic'); return l ? C.mic.driveMul[l - 1] : 1; }
function auraRadius() { return CONFIG.player.auraRadius * radiusMul() * G.mods.auraRadiusMul; }
function warmupDuration() { return Math.max(5, CONFIG.warmup.duration + G.mods.warmupBonus); }
function smokeRadius() { const l = lvl('smoke'); return l ? C.smoke.radius[l - 1] * radiusMul() : 0; }

// Фазы песни растягиваются под её длину (концерт босса длиннее)
function currentPhase() {
  const ph = CONFIG.decayPhases, k = G.duration / CONFIG.songDuration;
  for (let i = 0; i < ph.length; i++) if (G.t < ph[i].until * k) return i;
  return ph.length - 1;
}

function driveThreshold(level) {
  const th = CONFIG.drive.thresholds;
  if (level < th.length) return th[level];
  return th[th.length - 1] + (level - th.length + 1) * CONFIG.drive.extraPerLevel;
}

function gainInterest(v, amount) {
  if (v.leaving) return;
  v.interest = Math.min(100, v.interest + amount * gainMul());
}

// Единая точка входа для драйва. source: 'emotion' сейчас, позже — 'rhythm'.
function addDrive(amount, source) {
  if (G.over || amount <= 0) return;
  G.drive += amount;
  G.driveBySource[source] = (G.driveBySource[source] || 0) + amount;
  while (G.drive >= driveThreshold(G.level)) {
    G.drive -= driveThreshold(G.level);
    G.level++;
    G.pendingLevelUps++;
    G.levelUpTimes.push(G.t);
  }
}

function inHall(v) { return !v.leaving; }
function viewersInHall() { let n = 0; for (const v of G.viewers) if (!v.leaving) n++; return n; }

// ---------------------------------------------------------------------
//  Выбор карт
// ---------------------------------------------------------------------
function rollChoice() {
  let act = 0, pas = 0;
  for (const id of G.cardOrder) (CARD_DEFS[id].type === 'active' ? act++ : pas++);
  const cand = CARD_IDS.filter(id => {
    const l = lvl(id);
    if (l >= 3) return false;
    if (l === 0) {
      if (CARD_DEFS[id].type === 'active' && act >= CONFIG.slots.active) return false;
      if (CARD_DEFS[id].type === 'passive' && pas >= CONFIG.slots.passive) return false;
    }
    return true;
  });
  for (let i = cand.length - 1; i > 0; i--) {
    const j = (G.rnd() * (i + 1)) | 0;
    [cand[i], cand[j]] = [cand[j], cand[i]];
  }
  return cand.slice(0, 3);
}

function giveCard(id) {
  const l = lvl(id);
  G.cards[id] = l + 1;
  if (l === 0) {
    G.cardOrder.push(id);
    // первое срабатывание вскоре, чтобы было видно, что карта работает
    if (id === 'solo' || id === 'chorus') G.timers[id] = 0.6;
    if (id === 'pyro') G.timers[id] = 2.0;
  }
}

function chooseCard(id) {
  if (!G.choice || !G.choice.includes(id)) return;
  giveCard(id);
  G.choice = null;
  G.pendingLevelUps--;
}

function skipChoice() { G.choice = null; G.pendingLevelUps--; }

// ---------------------------------------------------------------------
//  Обновление
// ---------------------------------------------------------------------
function update(dt) {
  G.events = [];
  if (G.over || G.choice) return;
  if (G.pendingLevelUps > 0) {
    const opts = rollChoice();
    if (opts.length) { G.choice = opts; G.events.push({ type: 'levelup' }); return; }
    G.pendingLevelUps = 0;
  }

  G.t += dt;
  if (!G.externalClock) G.musicTime += dt;
  if (G.encore) {
    G.encore.t += dt;
    if (G.encore.t >= CONFIG.encore.duration) { G.over = true; G.events.push({ type: 'end' }); return; }
  } else if (G.t >= G.duration) {
    G.t = G.duration;
    if (viewersInHall() >= G.total * CONFIG.encore.threshold) {
      G.encore = { t: 0 };
      G.encored = true;
      G.events.push({ type: 'encore' });
    } else { G.over = true; G.events.push({ type: 'end' }); return; }
  }

  const ph = currentPhase();
  if (ph !== G.phaseIndex) {
    G.phaseIndex = ph;
    if (CONFIG.decayPhases[ph].banner) G.events.push({ type: 'banner', text: CONFIG.decayPhases[ph].banner });
  }

  updatePlayer(dt);
  updateIncidents(dt);
  updateAntagonist(dt);
  updateCards(dt);
  updateViewers(dt, ph);
  updateEmotions(dt);
}

function updatePlayer(dt) {
  const p = G.player, L = G.L;
  p.tx = clamp(p.tx, 14, L.W - 14);
  p.ty = clamp(p.ty, L.wallBottom + 8, L.hallBottom - 6);
  const dx = p.tx - p.x, dy = p.ty - p.y, d = Math.hypot(dx, dy);
  const step = CONFIG.player.speed * G.mods.speedMul * dt;
  p.moving = d > 1;
  if (d <= step) { p.x = p.tx; p.y = p.ty; } else { p.x += dx / d * step; p.y += dy / d * step; }
  if (Math.abs(dx) > 2) p.dir = dx > 0 ? 1 : -1;
}

function updateCards(dt) {
  const p = G.player;
  const cdm = cooldownMul();
  if (stringBroken()) return; // без струны активные карты молчат
  for (const id of ['solo', 'chorus', 'pyro']) {
    const l = lvl(id);
    if (!l) continue;
    G.timers[id] = (G.timers[id] == null ? C[id].cooldown[l - 1] : G.timers[id]) - dt;
    if (G.timers[id] > 0) continue;
    G.timers[id] += C[id].cooldown[l - 1] * cdm;
    if (G.timers[id] < 0) G.timers[id] = 0;

    if (id === 'solo') {
      const r = C.solo.radius[l - 1] * radiusMul();
      for (const v of G.viewers) if (inHall(v) && dist(v.x, v.y, p.x, p.y) <= r) { gainInterest(v, C.solo.gain[l - 1]); v.flash = 0.5; }
      G.events.push({ type: 'solo', x: p.x, y: p.y, r });
    } else if (id === 'chorus') {
      const range = C.chorus.range * radiusMul();
      const list = G.viewers.filter(inHall)
        .map(v => ({ v, d: dist(v.x, v.y, p.x, p.y) }))
        .filter(o => o.d <= range)
        .sort((a, b) => a.d - b.d)
        .slice(0, C.chorus.targets[l - 1]);
      for (const o of list) { gainInterest(o.v, C.chorus.gain[l - 1]); o.v.flash = 0.6; }
      G.events.push({ type: 'chorus', x: p.x, y: p.y, targets: list.map(o => ({ x: o.v.x, y: o.v.y })) });
    } else if (id === 'pyro') {
      const edge = G.L.stageBottom + C.pyro.reach[l - 1] * radiusMul();
      for (const v of G.viewers) if (inHall(v) && v.y <= edge) { gainInterest(v, C.pyro.gain[l - 1]); v.flash = 0.7; }
      G.events.push({ type: 'pyro', edge });
    }
  }
}

function updateViewers(dt, ph) {
  const V = CONFIG.viewers, L = G.L, p = G.player;
  const blackout = G.incident && G.incident.type === 'blackout';
  const baseRate = CONFIG.decayPhases[ph].rate * G.lv.decayMul * G.mods.decayMul * (blackout ? CONFIG.incidents.blackout.decayMul : 1);
  const dr = G.incident && G.incident.type === 'drunk' && !G.incident.leaving ? G.incident : null;
  const auraGain = stringBroken() ? 0 : CONFIG.player.auraGain + G.mods.auraGain;
  const smokeR = smokeRadius();
  const smokeMul = smokeR ? C.smoke.decayMul[lvl('smoke') - 1] : 1;
  const auraR = auraRadius();
  const warm = G.t < warmupDuration();
  const encore = !!G.encore;
  const emitThr = warm || encore ? CONFIG.warmup.emitThreshold : V.happyThreshold;

  for (const v of G.viewers) {
    if (v.gone) continue;
    v.flash = Math.max(0, v.flash - dt);
    if (v.leaving) {
      const dx = L.exit.x - v.x, dy = L.exit.y - v.y, d = Math.hypot(dx, dy);
      const step = V.leaveSpeed * dt;
      if (d <= step) v.gone = true; else { v.x += dx / d * step; v.y += dy / d * step; }
      continue;
    }
    const d = dist(v.x, v.y, p.x, p.y);
    let rate = encore ? 0 : baseRate * v.decayMul;
    if (smokeR && d <= smokeR) rate *= smokeMul;
    v.interest -= rate * dt;
    if (dr && dist(v.x, v.y, dr.x, dr.y) <= CONFIG.incidents.drunk.radius) v.interest -= CONFIG.incidents.drunk.drain * dt;
    if (d <= auraR && auraGain) gainInterest(v, auraGain * dt);
    if (v.interest <= 0) {
      v.interest = 0; v.leaving = true;
      G.events.push({ type: 'leave', x: v.x, y: v.y });
      continue;
    }

    // скучающие понемногу пробираются к выходу
    if (v.interest < V.boredThreshold) {
      const ex = L.exit.x - v.homeX, ey = L.exit.y - v.homeY, ed = Math.hypot(ex, ey);
      if (ed > 30) { v.homeX += ex / ed * V.boredDriftSpeed * dt; v.homeY += ey / ed * V.boredDriftSpeed * dt; }
    }
    v.wanderTimer -= dt;
    if (v.wanderTimer <= 0) {
      v.wanderTimer = 1.5 + G.rnd() * 2.5;
      const a = G.rnd() * Math.PI * 2, r = G.rnd() * V.wanderRadius;
      v.tx = clamp(v.homeX + Math.cos(a) * r, 12, L.W - 12);
      v.ty = clamp(v.homeY + Math.sin(a) * r, L.hallTop + 8, L.hallBottom - 6);
    }
    const wx = v.tx - v.x, wy = v.ty - v.y, wd = Math.hypot(wx, wy);
    const ws = V.wanderSpeed * dt * (v.interest < V.boredThreshold ? 1.5 : 1);
    if (wd > ws) { v.x += wx / wd * ws; v.y += wy / wd * ws; }

    v.emitTimer -= dt;
    if (v.emitTimer <= 0) {
      const E = CONFIG.emotion;
      v.emitTimer = encore
        ? CONFIG.encore.emitMin + G.rnd() * (CONFIG.encore.emitMax - CONFIG.encore.emitMin)
        : E.intervalMin + G.rnd() * (E.intervalMax - E.intervalMin);
      if (v.interest > emitThr && !v.critic) {
        const k = clamp((v.interest - emitThr) / (100 - emitThr), 0, 1);
        G.emotions.push({
          x: v.x, y: v.y - 22,
          kind: (G.rnd() * 3) | 0, // 0 сердце, 1 нота, 2 хлопок
          size: E.sizeMin + (E.sizeMax - E.sizeMin) * k,
          drive: E.baseDrive * (1 + E.maxDriveBonus * k),
          life: E.life, age: 0,
          drift: (G.rnd() - 0.5) * 10,
        });
        G.emotionsSpawned++;
      }
    }
  }
}

function updateEmotions(dt) {
  const p = G.player, pr = pickupRadius(), dm = emotionDriveMul();
  const E = CONFIG.emotion;
  for (let i = G.emotions.length - 1; i >= 0; i--) {
    const e = G.emotions[i];
    e.age += dt;
    e.y -= E.floatSpeed * dt;
    e.x += e.drift * dt * 0.3;
    if (dist(e.x, e.y, p.x, p.y - 10) <= pr + e.size * 0.5) {
      addDrive(e.drive * dm * G.mods.driveMul, 'emotion');
      G.emotionsCollected++;
      G.events.push({ type: 'pickup', x: e.x, y: e.y, kind: e.kind });
      G.emotions.splice(i, 1);
    } else if (e.age >= e.life) {
      G.emotions.splice(i, 1);
    }
  }
}

// ---------------------------------------------------------------------
//  Происшествия
// ---------------------------------------------------------------------
function planIncidents(rnd, levelNo, M) {
  const I = CONFIG.incidents;
  const n = I.count[levelNo] || 0;
  const types = M.noString ? ['blackout', 'drunk'] : ['string', 'blackout', 'drunk'];
  const plan = [];
  for (let i = 0; i < n; i++) {
    if (rnd() >= I.chance * M.incidentMul) continue;
    // по возможности без повторов
    const pool = types.filter(t => !plan.some(p => p.type === t));
    const type = (pool.length ? pool : types)[(rnd() * (pool.length || types.length)) | 0];
    plan.push({ type, t: 0 });
  }
  // равномерно раскладываем по окну песни с небольшим разбросом
  const k = (M.duration || CONFIG.songDuration) / CONFIG.songDuration;
  const a = I.window[0] * k, b = I.window[1] * k;
  const step = (b - a) / Math.max(1, plan.length);
  plan.forEach((p, i) => { p.t = a + step * i + rnd() * Math.max(0, step - I.minGap); });
  return plan;
}

function stringBroken() { return !!(G.incident && G.incident.type === 'string'); }

function startIncident(type) {
  const L = G.L;
  const inc = { type, age: 0, progress: 0 };
  if (type === 'drunk') {
    inc.x = L.exit.x - 10; inc.y = L.exit.y;
    inc.tx = L.W / 2; inc.ty = (L.hallTop + L.hallBottom) / 2;
    inc.leaving = false;
  }
  G.incident = inc;
  G.incidentsHappened.push(type);
  G.events.push({ type: 'incident', kind: type, text: INCIDENT_NAMES[type] });
}

function endIncident(text) {
  G.events.push({ type: 'incidentEnd', kind: G.incident.type, text });
  G.incident = null;
}

function updateIncidents(dt) {
  const I = CONFIG.incidents, p = G.player, L = G.L;
  if (!G.incident && !G.encore && G.incidentPlan.length && G.t >= G.incidentPlan[0].t) startIncident(G.incidentPlan.shift().type);
  const inc = G.incident;
  if (!inc) return;
  inc.age += dt;
  if (inc.type === 'string') {
    const S = I.string;
    if (dist(p.x, p.y, S.spot.x, S.spot.y) <= S.radius) inc.progress += dt * G.mods.repairMul / S.repairTime;
    else inc.progress = Math.max(0, inc.progress - dt);
    if (inc.progress >= 1) endIncident('Струна на месте!');
  } else if (inc.type === 'blackout') {
    if (inc.age >= I.blackout.duration) endIncident('Свет дали!');
  } else if (inc.type === 'drunk') {
    const D = I.drunk;
    if (!inc.leaving) {
      if (dist(p.x, p.y, inc.x, inc.y) <= D.calmRadius) inc.progress += dt * G.mods.drunkCalmMul / D.calmTime;
      else inc.progress = Math.max(0, inc.progress - dt * 0.5);
      if (inc.progress >= 1 || inc.age >= D.maxTime) {
        inc.leaving = true;
        G.events.push({ type: 'banner', text: inc.progress >= 1 ? 'Дебошира успокоили' : 'Дебошир ушёл сам' });
      }
      // бродит по залу
      if (dist(inc.x, inc.y, inc.tx, inc.ty) < 6) {
        inc.tx = 30 + G.rnd() * (L.W - 60);
        inc.ty = L.hallTop + 20 + G.rnd() * (L.hallBottom - L.hallTop - 40);
      }
    } else {
      inc.tx = L.exit.x; inc.ty = L.exit.y;
      if (dist(inc.x, inc.y, inc.tx, inc.ty) < 6) { G.incident = null; return; }
    }
    const dx = inc.tx - inc.x, dy = inc.ty - inc.y, d = Math.hypot(dx, dy) || 1;
    const sp = D.speed * (inc.leaving ? 2 : 1) * dt;
    inc.x += dx / d * Math.min(sp, d); inc.y += dy / d * Math.min(sp, d);
  }
}

// ---------------------------------------------------------------------
//  Боссы: соперник и страх летают по залу и гасят интерес; душа отгоняет их касанием
// ---------------------------------------------------------------------
function updateAntagonist(dt) {
  const A = G.antagonist;
  if (!A) return;
  const B = CONFIG.bosses[A.kind], p = G.player, L = G.L;
  if (!A.active) {
    if (G.t < B.start || G.encore) return;
    A.active = true;
    G.events.push({ type: 'banner', text: A.kind === 'rival' ? 'Соперник уводит зал!' : 'Страх выходит на сцену…' });
  }
  if (G.encore) return;
  A.stun = Math.max(0, A.stun - dt);
  A.retarget -= dt;
  if (!A.stun && A.retarget <= 0) {
    // летит к самым увлечённым: им есть что терять
    let best = null;
    for (let i = 0; i < 8; i++) {
      const v = G.viewers[(G.rnd() * G.viewers.length) | 0];
      if (!v.leaving && (!best || v.interest > best.interest)) best = v;
    }
    if (best) { A.tx = best.x; A.ty = best.y; }
    A.retarget = B.retarget;
  }
  const dx = A.tx - A.x, dy = A.ty - A.y, d = Math.hypot(dx, dy) || 1;
  const sp = B.speed * (A.stun ? 2.2 : 1) * dt;
  A.x += dx / d * Math.min(sp, d); A.y += dy / d * Math.min(sp, d);
  if (A.stun) return;
  for (const v of G.viewers) {
    if (!v.leaving && dist(v.x, v.y, A.x, A.y) <= B.radius) v.interest -= B.drain * dt;
  }
  if (dist(p.x, p.y, A.x, A.y) <= B.touch) {
    A.stun = B.stun;
    // отлетает в противоположную от души сторону зала
    A.tx = p.x < L.W / 2 ? L.W - 30 : 30;
    A.ty = p.y < (L.hallTop + L.hallBottom) / 2 ? L.hallBottom - 30 : L.hallTop + 30;
    A.retarget = B.stun;
    G.events.push({ type: 'repel', x: A.x, y: A.y, kind: A.kind });
  }
}

function results() {
  const left = viewersInHall();
  const total = G.total;
  const bonus = left > total / 2 ? CONFIG.money.halfBonus : 0;
  const encoreBonus = G.encored ? CONFIG.encore.moneyBonus + G.mods.encoreBonus : 0;
  return {
    left, total, bonus,
    perViewer: CONFIG.money.perViewer + G.mods.perViewer,
    money: Math.round((left * (CONFIG.money.perViewer + G.mods.perViewer) + bonus) * (1 + encoreBonus) * G.mods.moneyMul),
    encored: G.encored, encoreBonus,
    incidents: G.incidentsHappened.slice(),
    cards: G.cardOrder.map(id => ({ id, level: G.cards[id] })),
    levels: G.level,
    levelNo: G.levelNo,
    passed: bonus > 0,
    boss: G.boss,
    criticStayed: G.critic ? !G.critic.leaving : null,
    // босс побеждён: зал удержан, а критик (если он есть) остался до конца
    bossBeaten: !!G.boss && bonus > 0 && (!G.critic || !G.critic.leaving),
  };
}

if (typeof module !== 'undefined') {
  module.exports = {
    CONFIG, CARD_DEFS, CARD_IDS, DEFAULT_MODS, newGame, update, addDrive, chooseCard, skipChoice, results,
    get G() { return G; }, viewersInHall, pickupRadius, auraRadius, smokeRadius, radiusMul, giveCard,
  };
}

// =====================================================================
//  Браузер: рендер, ввод, интерфейс
// =====================================================================
if (typeof window !== 'undefined') (function () {
  const PAL = {
    bg: '#140c08', wall: '#1d110b', wallBrick: '#24150d',
    stage: '#4a2c18', stagePlank: '#3b2213', stageEdge: '#2a160c',
    floor: '#21150e', floorTile: '#271a11', panel: '#1a0f09',
    pink: '#ff3d8b', cyan: '#3de0ff', amber: '#ffb03a', green: '#4dff88',
    text: '#f6e7d0', dim: '#a08a70', gray: '#5b5a60',
  };

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const $ = id => document.getElementById(id);
  let dpr = 1, scale = 1, offX = 0, offY = 0, cssW = 0, cssH = 0;
  let state = 'start'; // start | loading | play | levelup | ending | results
  let fx = [], particles = [], smoke = [], banners = [];
  let lastTs = 0, clock = 0, shake = 0;

  function worldHeightFor(w, h) {
    return clamp(Math.round(h / w * CONFIG.worldWidth), CONFIG.worldHeightMin, CONFIG.worldHeightMax);
  }

  function resize() {
    cssW = window.innerWidth; cssH = window.innerHeight;
    dpr = Math.min(window.devicePixelRatio || 1, 3);
    canvas.width = Math.round(cssW * dpr); canvas.height = Math.round(cssH * dpr);
    canvas.style.width = cssW + 'px'; canvas.style.height = cssH + 'px';
    const H = G ? G.L.H : worldHeightFor(cssW, cssH);
    scale = Math.min(cssW / CONFIG.worldWidth, cssH / H);
    offX = (cssW - CONFIG.worldWidth * scale) / 2;
    offY = (cssH - H * scale) / 2;
    placeSoundButton();
  }

  // ---------- сохранения ----------
  function storage() { try { return window.localStorage; } catch (_) { return null; } }
  let SAVE = loadSave(storage());
  const persist = () => writeSave(storage(), SAVE);

  // ---------- аудио: музыка, часы ритма, звуки ----------
  // Музыка играет через элемент <audio>: в установленном PWA на iOS Web Audio часто молчит.
  // Файл берётся обычным fetch (его отдаёт кэш service worker'а, музыка работает офлайн)
  // и подставляется как blob-ссылка — так Safari не спотыкается о Range-запросы к кэшу.
  // Часы для пульса зала — currentTime самого элемента.
  const MUSIC_VOLUME = 0.55;
  const player = new Audio();
  player.loop = true;
  player.preload = 'auto';
  player.setAttribute('playsinline', '');
  let musicToken = 0, playing = false, fadeTimer = null, unlocked = false;
  const blobs = {}; // url трека → blob-ссылка

  // Короткая тишина: «разблокирует» элемент первым касанием, дальше play() можно звать без жеста
  const SILENCE = (() => {
    const n = 800, b = new DataView(new ArrayBuffer(44 + n));
    const str = (o, s) => { for (let i = 0; i < s.length; i++) b.setUint8(o + i, s.charCodeAt(i)); };
    str(0, 'RIFF'); b.setUint32(4, 36 + n, true); str(8, 'WAVEfmt ');
    b.setUint32(16, 16, true); b.setUint16(20, 1, true); b.setUint16(22, 1, true);
    b.setUint32(24, 8000, true); b.setUint32(28, 8000, true); b.setUint16(32, 1, true); b.setUint16(34, 8, true);
    str(36, 'data'); b.setUint32(40, n, true);
    for (let i = 0; i < n; i++) b.setUint8(44 + i, 128);
    return URL.createObjectURL(new Blob([b], { type: 'audio/wav' }));
  })();

  // iOS: категория «воспроизведение» — музыку слышно и при включённом бесшумном режиме
  try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (_) { /* старые браузеры */ }

  function wakeAudio() {
    if (!unlocked && (!player.src || player.src === SILENCE)) {
      unlocked = true;
      player.src = SILENCE;
      const p = player.play();
      if (p) p.catch(() => { unlocked = false; });
    }
    // iOS может прервать звук (звонок, сворачивание PWA); возобновляем при касании
    if (playing && player.paused && SAVE.settings.music && state !== 'levelup') resumeMusic();
  }
  document.addEventListener('pointerdown', wakeAudio, true);

  function loadTrack(url) {
    if (blobs[url]) return Promise.resolve(blobs[url]);
    return fetch(url)
      .then(r => { if (!r.ok) throw new Error(r.status); return r.blob(); })
      .then(blob => (blobs[url] = URL.createObjectURL(blob)));
  }

  function setVolume(v) { try { player.volume = v; } catch (_) { /* на iOS громкость только системная */ } }
  function fadeTo(target, sec, done) {
    clearInterval(fadeTimer);
    const from = player.volume, t0 = performance.now();
    fadeTimer = setInterval(() => {
      const k = Math.min(1, (performance.now() - t0) / (sec * 1000));
      setVolume(from + (target - from) * k);
      if (k >= 1) { clearInterval(fadeTimer); if (done) done(); }
    }, 50);
  }

  function stopMusic() {
    musicToken++;
    clearInterval(fadeTimer);
    playing = false;
    player.pause();
  }

  // Загружает и запускает трек уровня. Промис выполняется, когда музыка заиграла
  // (или когда стало ясно, что её не будет).
  function playMusic(levelNo) {
    stopMusic();
    if (!SAVE.settings.music) return Promise.resolve(false);
    const token = musicToken;
    return loadTrack(CONFIG.levels[levelNo].music).then(src => {
      if (token !== musicToken) return false;
      if (player.src !== src) player.src = src;
      player.currentTime = 0;
      setVolume(0);
      return player.play().then(() => {
        if (token !== musicToken) { player.pause(); return false; }
        playing = true;
        fadeTo(MUSIC_VOLUME, 1.0);
        return true;
      });
    }).catch(() => false);
  }

  function fadeOutMusic(sec) {
    if (!playing) return;
    const token = ++musicToken;
    playing = false;
    fadeTo(0, sec, () => { if (token === musicToken) player.pause(); });
  }

  function pauseMusic() { if (playing) player.pause(); }
  function resumeMusic() {
    if (playing && SAVE.settings.music) { const p = player.play(); if (p) p.catch(() => {}); }
  }

  // Позиция в треке; null — музыка не играет
  function musicPos() {
    if (!playing || player.paused) return null;
    return player.currentTime;
  }

  document.addEventListener('visibilitychange', () => {
    if (document.hidden) pauseMusic(); else if (state === 'play' || state === 'ending') resumeMusic();
  });

  const soundBtn = $('btn-sound');
  function syncSoundButton() {
    soundBtn.classList.toggle('off', !SAVE.settings.music);
    soundBtn.setAttribute('aria-label', SAVE.settings.music ? 'Выключить музыку' : 'Включить музыку');
  }
  function placeSoundButton() {
    // в верхней плашке HUD между полосой песни и счётчиком зрителей
    const size = Math.max(32, 30 * scale);
    soundBtn.style.width = soundBtn.style.height = size + 'px';
    soundBtn.style.left = (offX + 222 * scale - size / 2) + 'px';
    soundBtn.style.top = (offY + 22 * scale - size / 2) + 'px';
  }
  soundBtn.addEventListener('click', () => {
    SAVE.settings.music = !SAVE.settings.music;
    persist();
    syncSoundButton();
    if (!SAVE.settings.music) { stopMusic(); if (G) G.externalClock = false; }
    else if (G && (state === 'play' || state === 'levelup')) playMusic(G.levelNo);
  });
  syncSoundButton();

  // ---------- запуск песни ----------
  let mode = 'free';        // free — тренировка, tour — тур, daily — вызов дня
  let tourNode = null;      // точка карты тура, которую сейчас играем
  let lifeFloor = 0;        // в туре тело тем живее, чем крепче связь с душой
  let dailyNow = null;

  function startGame(levelNo, opts) {
    opts = opts || {};
    mode = opts.mode || 'free';
    tourNode = opts.node || null;
    newGame(opts.seed == null ? null : opts.seed, worldHeightFor(window.innerWidth, window.innerHeight), levelNo, opts.mods);
    fx = []; particles = []; smoke = []; banners = [];
    lifeFloor = mode === 'tour' && SAVE.tour ? Math.min(0.45, SAVE.tour.bond / 30) : 0;
    bodyLife = lifeFloor;
    resize();
    state = 'loading';
    show(null);
    const head = mode === 'tour' ? (tourNode.type === 'boss' ? `Босс: ${TOUR.acts[SAVE.tour.act].boss.name}` : `Акт ${SAVE.tour.act + 1} · ${G.lv.name}`)
      : mode === 'daily' ? `Вызов дня · ${G.lv.name}` : `${G.levelNo + 1}. ${G.lv.name}`;
    banners.push({ text: head, t: 0, life: 2.6, color: PAL.pink });
    // песня стартует, когда трек заиграл: пульс зала идёт от музыки
    const go = () => {
      if (state !== 'loading') return;
      state = 'play';
      const hint = G.boss === 'critic' ? 'Критик должен остаться до конца!' : 'Разогрев: собирай эмоции!';
      banners.push({ text: hint, t: 0, life: 2.6 });
    };
    playMusic(levelNo).then(go);
    setTimeout(go, 4000); // если трек не грузится, играем без музыки
  }

  const LEVEL_COLORS = ['#5dff9e', '#3de0ff', '#ffd23d', '#ff7a3d', '#ff3d8b'];
  const VENUE_SHORT = ['Вторник', 'Пятница', 'Студенты', 'Клуб', 'Фестиваль'];
  const esc = t => String(t).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const starsHtml = n => [0, 1, 2].map(i => `<span class="star${i < n ? '' : ' off'}">&#9733;&#xFE0E;</span>`).join('');
  const g = (m, f) => (heroIsF() ? f : m); // форма слова по герою
  const cleanMods = () => Object.assign({}, DEFAULT_MODS, { startCards: [] });

  function levelButton(i, meta, onClick) {
    const lv = CONFIG.levels[i];
    const b = document.createElement('button');
    b.className = 'lvl';
    b.style.setProperty('--c', LEVEL_COLORS[i % LEVEL_COLORS.length]);
    b.innerHTML = `<span class="lvl-num">${i + 1}</span><span><div class="lvl-name">${esc(lv.name)}</div>` +
      `<div class="lvl-desc">${esc(lv.desc)} Зрителей: ${lv.viewers}. Музыка: ${esc(lv.track)}.</div>${meta ? `<div class="lvl-meta">${meta}</div>` : ''}</span>`;
    b.addEventListener('click', onClick);
    return b;
  }

  function buildLevelMenu() {
    const box = $('levels');
    box.innerHTML = '';
    CONFIG.levels.forEach((lv, i) => {
      const r = SAVE.records.levels[i];
      const meta = r ? `Рекорд: ${r.bestLeft} из ${r.total} ${starsHtml(r.bestStars)}` : '';
      box.appendChild(levelButton(i, meta, () => startGame(i, { mode: 'free', mods: cleanMods() })));
    });
  }

  // Экран с текстом и кнопками: вступление, события, разговоры с Михалычем, итоги тура
  function story(o) {
    $('story-title').textContent = o.title || '';
    $('story-speaker').textContent = o.speaker || '';
    const box = $('story-text');
    box.innerHTML = '';
    for (const p of o.paras || []) { const el = document.createElement('p'); el.textContent = p; box.appendChild(el); }
    if (o.result) { const el = document.createElement('p'); el.className = 'result'; el.textContent = o.result; box.appendChild(el); }
    const bx = $('story-buttons');
    bx.innerHTML = '';
    for (const b of o.buttons) {
      const el = document.createElement('button');
      el.className = 'btn choice ' + (b.cls || '');
      el.innerHTML = esc(b.label) + (b.sub ? `<small>${esc(b.sub)}</small>` : '');
      el.disabled = !!b.disabled;
      el.addEventListener('click', b.onClick);
      bx.appendChild(el);
    }
    show('overlay-story');
  }

  function openMenu() {
    const t = SAVE.tour;
    $('tour-sub').textContent = t ? `акт ${t.act + 1} «${TOUR.acts[t.act].name}» · ${t.money} ₽` : (SAVE.records.tours ? 'новый тур' : 'начать путь');
    const d = dailyChallenge(new Date(), CONFIG.levels.length), best = SAVE.daily[d.key];
    $('daily-sub').textContent = `${CONFIG.levels[d.levelNo].name} · ${d.mod.name}` + (best ? ` · рекорд ${best.left}/${best.total}` : '');
    $('soul-sub').textContent = `«Слава»: ${SAVE.fame}`;
    show('overlay-start');
  }

  function openRecords() {
    const R = SAVE.records;
    let html = '<div class="rec-head">Туры</div>';
    for (const [k, v] of [['Туров сыграно', R.tours], ['Побед на фестивале', R.wins], ['«Славы» заработано', R.fameTotal]]) {
      html += `<div class="rec-row"><span>${k}</span><b>${v}</b></div>`;
    }
    html += '<div class="rec-head">Лучший результат по залам</div>';
    CONFIG.levels.forEach((lv, i) => {
      const r = R.levels[i];
      html += `<div class="rec-row"><span>${i + 1}. ${esc(lv.name)}<small>${r ? 'сыграно ' + r.plays : 'ещё не играл'}</small></span>` +
        `<b>${r ? `${r.bestLeft}/${r.total} ${starsHtml(r.bestStars)}` : '—'}</b></div>`;
    });
    html += `<div class="rec-head">Всего</div><div class="rec-row"><span>Концертов</span><b>${R.gigs}</b></div>`;
    $('records').innerHTML = html;
    show('overlay-records');
  }

  // ---------- тур ----------
  function openTour() {
    if (!SAVE.profile.hero) { show('overlay-hero'); return; }
    if (SAVE.tour) { openMap(); return; }
    SAVE.tour = newTour(SAVE, (Math.random() * 1e9) | 0);
    persist();
    const relic = SAVE.tour.relics[0];
    const paras = SAVE.story.intro ? [
      'Новый тур. Михалыч ставит на стойку чай и кивает на сцену: «Ну что, ещё раз?»',
      'Тело снова стоит под лампой, серое и тихое. Душа поднимается над залом.',
    ] : [
      `Вторник. Бар «Подвал». ${g('Ему', 'Ей')} тридцать пять, днём — офис, вечером — гитара и полупустой зал.`,
      `Тело стоит на сцене и играет на автопилоте. А душа… душа давно ушла. Десять лет назад, на городском фестивале, что-то случилось — и с тех пор ${g('он', 'она')} играет, но никто не слушает.`,
      'Сегодня душа вернулась. Только она умеет достучаться до людей в зале. Удержи их — и, может быть, тело вспомнит, зачем выходило на сцену.',
    ];
    SAVE.story.intro = true;
    persist();
    story({
      title: 'Акт 1. Бары', paras,
      result: relic ? `Талисман души: «${RELICS[relic].name}» — ${RELICS[relic].desc}` : '',
      buttons: [{ label: 'К карте тура', onClick: openMap }],
    });
  }

  function setHero(h) { SAVE.profile.hero = h; persist(); openTour(); }
  $('hero-m').addEventListener('click', () => setHero('m'));
  $('hero-f').addEventListener('click', () => setHero('f'));

  function nodeLabel(n) {
    if (n.type === 'concert') return ['&#9834;&#xFE0E;', VENUE_SHORT[n.venue]];
    if (n.type === 'event') return ['?', 'Событие'];
    if (n.type === 'market') return ['&#8381;', 'Барахолка'];
    return ['&#9733;&#xFE0E;', 'Босс: ' + TOUR.acts[SAVE.tour.act].boss.name];
  }

  function openMap() {
    const t = SAVE.tour;
    if (!t) { openMenu(); return; }
    const act = TOUR.acts[t.act];
    $('map-title').textContent = `Акт ${t.act + 1}. ${act.name}`;
    const pinned = t.pinned.map(id => CARD_DEFS[id].name).join(', ') || 'нет';
    $('map-stats').innerHTML = `<span class="chip">Деньги <b>${t.money} ₽</b></span><span class="chip">Связь <b>${t.bond}</b></span>` +
      `<span class="chip">Вечеров <b>${t.nights}</b></span><span class="chip">Закреплены: <b>${esc(pinned)}</b></span>`;
    const rel = $('map-relics');
    rel.innerHTML = '';
    for (const id of t.relics) {
      const c = document.createElement('span');
      c.className = 'chip'; c.textContent = RELICS[id].name; c.title = RELICS[id].desc;
      c.addEventListener('click', () => { c.textContent = c.textContent === RELICS[id].name ? RELICS[id].desc : RELICS[id].name; });
      rel.appendChild(c);
    }
    const open = availableNodes(t);
    const box = $('map-rows');
    box.innerHTML = '';
    for (let r = t.map.length - 1; r >= 0; r--) {
      const row = document.createElement('div');
      row.className = 'map-row';
      for (const n of t.map[r]) {
        const b = document.createElement('button');
        const isOpen = open.includes(n), here = r === t.row && n.col === t.col;
        b.className = `node ${n.type}` + (isOpen ? ' open' : here ? ' here' : r <= t.row ? ' done' : ' dim');
        const [ico, label] = nodeLabel(n);
        b.innerHTML = `<span class="ico">${ico}</span>${esc(label)}`;
        b.disabled = !isOpen;
        if (isOpen) b.addEventListener('click', () => onNode(n));
        row.appendChild(b);
      }
      box.appendChild(row);
    }
    show('overlay-map');
    const first = box.querySelector('.node.open');
    if (first) first.scrollIntoView({ block: 'center' });
  }

  function onNode(n) {
    const t = SAVE.tour;
    if (n.type === 'concert') { startGame(n.venue, { mode: 'tour', node: n, mods: tourMods(SAVE, t, n) }); return; }
    if (n.type === 'boss') { bossIntro(n); return; }
    enterNode(t, n);
    persist();
    if (n.type === 'event') runEvent();
    else openMarket(true);
  }

  const BOSS_INTRO = {
    critic: () => [`В зале — критик журнала «Звук». Тот самый, что десять лет назад написал: «Сцена не для ${g('него', 'неё')}».`, 'Он скучает быстрее остальных и не хлопает. Если он уйдёт — провал, даже при полном зале.'],
    rival: () => ['На соседней сцене — бывший друг. Сегодня у него сольный концерт, и он уводит твой зал к себе.', 'Его тень летает над залом и гасит интерес. Коснись её душой — она отлетит.'],
    fear: () => ['Городской фестиваль. Та самая сцена. Свет бьёт в глаза, и где-то в темноте шевелится Страх.', 'Он летает по залу и уводит людей. Не дай ему забрать их — касайся его душой.'],
  };
  function bossIntro(n) {
    const act = TOUR.acts[SAVE.tour.act];
    story({
      title: `Босс: ${act.boss.name}`, paras: BOSS_INTRO[act.boss.kind](),
      buttons: [
        { label: 'На сцену', sub: 'концерт 3 минуты', onClick: () => startGame(n.venue, { mode: 'tour', node: n, mods: tourMods(SAVE, SAVE.tour, n) }) },
        { label: 'Назад к карте', cls: 'ghost', onClick: openMap },
      ],
    });
  }

  function runEvent() {
    const t = SAVE.tour;
    t.seen = t.seen || [];
    let pool = EVENTS.filter(e => !t.seen.includes(e.id));
    if (!pool.length) { t.seen = []; pool = EVENTS; }
    const ev = pool[(Math.random() * pool.length) | 0];
    t.seen.push(ev.id);
    persist();
    story({
      title: ev.title, paras: [ev.text(g)],
      buttons: ev.choices.map(c => ({
        label: c.label, sub: c.cost ? `−${c.cost} ₽ · у тебя ${t.money} ₽` : '', disabled: c.cost && t.money < c.cost,
        onClick: () => {
          if (c.cost) t.money -= c.cost;
          const res = c.effect(t, Math.random, g);
          persist();
          story({ title: ev.title, paras: [ev.text(g)], result: res, buttons: [{ label: 'К карте', onClick: openMap }] });
        },
      })),
    });
  }

  function openMarket(fresh) {
    const t = SAVE.tour;
    if (fresh || !t.market) t.market = marketOffer(t, Math.random);
    persist();
    $('market-money').textContent = `${t.money} ₽`;
    const box = $('market-list');
    box.innerHTML = '';
    for (const o of t.market) {
      const r = RELICS[o.id], owned = t.relics.includes(o.id);
      const el = document.createElement('div');
      el.className = 'item';
      el.innerHTML = `<div class="info"><div class="name">${esc(r.name)}</div><div class="desc">${esc(r.desc)}</div></div>`;
      const b = document.createElement('button');
      b.className = 'buy';
      b.textContent = owned ? 'Твоё' : `${o.price} ₽`;
      b.disabled = owned || t.money < o.price;
      b.addEventListener('click', () => { t.money -= o.price; t.relics.push(o.id); persist(); openMarket(false); });
      el.appendChild(b);
      box.appendChild(el);
    }
    show('overlay-market');
  }
  $('market-leave').addEventListener('click', () => { SAVE.tour.market = null; persist(); openMap(); });

  // После победы над боссом — закрепить одну из взятых карт в стартовый набор
  function openPin(cards, then) {
    const t = SAVE.tour, slots = pinSlots(SAVE);
    const cand = cards.map(c => c.id).filter(id => !t.pinned.includes(id));
    if (!cand.length) { then(); return; }
    const full = t.pinned.length >= slots;
    $('pin-sub').textContent = full
      ? `Все ${slots} места заняты: новая карта заменит «${CARD_DEFS[t.pinned[0]].name}».`
      : `Карта будет у тебя в начале каждого концерта тура на 1-м уровне. Мест: ${t.pinned.length} из ${slots}.`;
    const box = $('pin-list');
    box.innerHTML = '';
    for (const id of cand) {
      const def = CARD_DEFS[id];
      const b = document.createElement('button');
      b.className = 'card ' + def.type;
      b.style.setProperty('--c', def.color);
      const ic = document.createElement('div'); ic.className = 'card-icon'; ic.appendChild(iconCanvas(id, 44));
      const body = document.createElement('div'); body.className = 'card-body';
      body.innerHTML = `<div class="card-top"><span class="card-name">${def.name}</span><span class="card-tag">${def.type === 'active' ? 'Активная' : 'Пассивная'}</span></div><div class="card-desc">${def.desc(0)}</div>`;
      b.append(ic, body);
      b.addEventListener('click', () => { if (full) t.pinned.shift(); t.pinned.push(id); persist(); then(); });
      box.appendChild(b);
    }
    $('pin-skip').onclick = then;
    show('overlay-pin');
  }

  function afterBoss(r) {
    const t = SAVE.tour;
    if (!r.bossBeaten) { tourEnd(false, r.boss === 'critic' && !r.criticStayed ? 'Критик ушёл, не дослушав.' : 'Зал не удержан.'); return; }
    openPin(r.cards, () => {
      if (!nextAct(t)) { tourEnd(true); return; }
      persist();
      const act = TOUR.acts[t.act];
      story({
        title: `Акт ${t.act + 1}. ${act.name}`,
        paras: t.act === 1
          ? ['Критик ушёл последним и что-то долго записывал. Утром в журнале — три строчки: «Кажется, в баре снова живая музыка».', 'Тебя зовут в клубы. Залы больше, публика капризнее.']
          : ['Соперник замолчал на полуслове, а потом зааплодировал вместе со всеми.', `Впереди — городской фестиваль. Та самая сцена. Тело на сцене впервые за десять лет смотрит в зал, а не в пол.`],
        buttons: [{ label: 'К карте', onClick: openMap }],
      });
    });
  }

  function tourEnd(victory, reason) {
    const t = SAVE.tour;
    if (!t) { openMenu(); return; }
    const fame = tourFame(t, victory);
    SAVE.fame += fame;
    SAVE.records.tours++;
    if (victory) SAVE.records.wins++;
    SAVE.records.fameTotal += fame;
    const talk = BAR_TALKS[Math.min(SAVE.story.talks, BAR_TALKS.length - 1)];
    SAVE.story.talks++;
    SAVE.tour = null;
    persist();
    story({
      title: victory ? 'Фестиваль покорён' : 'Душа вернулась в бар',
      speaker: 'Михалыч',
      paras: [
        (reason ? reason + ' ' : '') + `Акт ${t.act + (victory ? 0 : 1)}, вечеров: ${t.nights}, удержано зрителей: ${t.kept}, боссов: ${t.bosses}.`,
        talk[victory ? 'win' : 'lose'](g),
      ],
      result: `+${fame} «Славы». Её можно потратить на душу.`,
      buttons: [{ label: 'Прокачать душу', onClick: openSoul }, { label: 'В меню', cls: 'ghost', onClick: openMenu }],
    });
  }

  $('btn-giveup').addEventListener('click', () => {
    if (window.confirm('Сдаться? Тур закончится, «Слава» за пройденное начислится.')) tourEnd(false, g('Ты ушёл со сцены сам.', 'Ты ушла со сцены сама.'));
  });

  // ---------- душа: дерево способностей и облик ----------
  function openSoul() {
    $('soul-fame').textContent = SAVE.fame;
    const tree = $('soul-tree');
    tree.innerHTML = '';
    for (const n of SOUL_TREE) {
      const l = treeLevel(SAVE, n.id), max = n.cost.length, price = treePrice(SAVE, n.id);
      const el = document.createElement('div');
      el.className = 'item';
      el.innerHTML = `<div class="info"><div class="name">${esc(n.name)}</div><div class="desc">${esc(n.desc(Math.min(max, l + 1)))}${l && l < max ? ` Сейчас: ${esc(n.desc(l))}` : ''}</div>` +
        `<div class="card-pips">${n.cost.map((_, i) => `<i class="${i < l ? 'on' : ''}"></i>`).join('')}</div></div>`;
      const b = document.createElement('button');
      b.className = 'buy';
      b.textContent = price == null ? 'Есть' : `${price} ★`;
      b.disabled = price == null || SAVE.fame < price;
      b.addEventListener('click', () => { if (buyTree(SAVE, n.id)) { persist(); openSoul(); } });
      el.appendChild(b);
      tree.appendChild(el);
    }
    const skins = $('soul-skins');
    skins.innerHTML = '';
    for (const sk of SOUL_SKINS) {
      const owned = SAVE.skins.owned.includes(sk.id), sel = SAVE.skins.selected === sk.id;
      const el = document.createElement('div');
      el.className = 'item';
      el.innerHTML = `<div class="info"><div class="name">${esc(sk.name)}</div><div class="swatch">${sk.colors.map(c => `<i style="background:${c}"></i>`).join('')}</div></div>`;
      const b = document.createElement('button');
      b.className = 'buy';
      b.textContent = sel ? 'Выбран' : owned ? 'Выбрать' : `${sk.cost} ★`;
      b.disabled = sel || (!owned && SAVE.fame < sk.cost);
      b.addEventListener('click', () => {
        if (owned) SAVE.skins.selected = sk.id; else if (!buySkin(SAVE, sk.id)) return;
        persist(); openSoul();
      });
      el.appendChild(b);
      skins.appendChild(el);
    }
    show('overlay-soul');
  }

  // ---------- вызов дня ----------
  function openDaily() {
    const d = dailyNow = dailyChallenge(new Date(), CONFIG.levels.length);
    const lv = CONFIG.levels[d.levelNo], best = SAVE.daily[d.key];
    $('daily-date').textContent = new Date().toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' });
    $('daily-info').innerHTML = `<p><b>${esc(lv.name)}</b>: ${esc(lv.desc)} Зрителей: ${lv.viewers}.</p><p><b>${esc(d.mod.name)}.</b> ${esc(d.mod.desc)}</p><p class="note">Один зал и одна раздача для всех. Без прокачки души — только мастерство.</p>`;
    $('daily-best').innerHTML = best ? `Твой рекорд сегодня: <b>${best.left} из ${best.total}</b> ${starsHtml(starsFor(best.left, best.total))}` : g('Сегодня ещё не играл.', 'Сегодня ещё не играла.');
    $('daily-share').classList.toggle('hidden', !best);
    $('daily-share-text').textContent = '';
    show('overlay-daily');
  }
  $('daily-play').addEventListener('click', () => {
    const d = dailyNow, m = cleanMods();
    d.mod.apply(m);
    startGame(d.levelNo, { mode: 'daily', seed: d.seed, mods: m });
  });
  $('daily-share').addEventListener('click', () => {
    const d = dailyNow, best = SAVE.daily[d.key];
    if (!best) return;
    const st = starsFor(best.left, best.total);
    const text = `Удержи зал · вызов ${d.key}\n${CONFIG.levels[d.levelNo].name} (${d.mod.name}): ${best.left}/${best.total} ${'★'.repeat(st)}${'☆'.repeat(3 - st)}\n${location.href}`;
    const done = () => { $('daily-share-text').textContent = 'Скопировано — отправь другу.'; };
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, () => { $('daily-share-text').textContent = text; });
    else $('daily-share-text').textContent = text;
  });

  for (const b of document.querySelectorAll('[data-go]')) {
    b.addEventListener('click', () => { if (b.dataset.go === 'overlay-start') openMenu(); else show(b.dataset.go); });
  }
  $('btn-tour').addEventListener('click', openTour);
  $('btn-daily').addEventListener('click', openDaily);
  $('btn-soul').addEventListener('click', openSoul);
  $('btn-play').addEventListener('click', () => { buildLevelMenu(); show('overlay-free'); });
  $('btn-records').addEventListener('click', openRecords);
  openMenu();

  // ---------- ввод: душа следует за пальцем ----------
  function toWorld(e) { return { x: (e.clientX - offX) / scale, y: (e.clientY - offY) / scale }; }
  let pointerId = null;
  function setTarget(e) {
    const w = toWorld(e);
    const off = e.pointerType === 'mouse' ? 0 : CONFIG.player.touchOffset;
    G.player.tx = w.x; G.player.ty = w.y - off;
  }
  canvas.addEventListener('pointerdown', e => {
    e.preventDefault();
    if (state !== 'play' || !G) return;
    pointerId = e.pointerId;
    try { canvas.setPointerCapture(e.pointerId); } catch (_) { /* старые браузеры */ }
    setTarget(e);
  });
  canvas.addEventListener('pointermove', e => {
    if (state !== 'play' || !G) return;
    if (e.pointerType === 'mouse' ? e.buttons : e.pointerId === pointerId) setTarget(e);
  });
  const endPointer = e => { if (e.pointerId === pointerId) pointerId = null; };
  canvas.addEventListener('pointerup', endPointer);
  canvas.addEventListener('pointercancel', endPointer);
  // окна меню можно прокручивать, всё остальное — нет
  document.addEventListener('touchmove', e => { if (!e.target.closest('.panel')) e.preventDefault(); }, { passive: false });
  document.addEventListener('gesturestart', e => e.preventDefault());
  document.addEventListener('contextmenu', e => e.preventDefault());
  window.addEventListener('resize', resize);
  window.addEventListener('orientationchange', resize);
  window.addEventListener('pageshow', resize);
  if (window.visualViewport) window.visualViewport.addEventListener('resize', resize);

  // ---------- оверлеи ----------
  function show(id) {
    soundBtn.classList.toggle('hidden', id !== null);
    for (const o of document.querySelectorAll('.overlay')) o.classList.toggle('hidden', o.id !== id);
  }

  function iconCanvas(id, size) {
    const c = document.createElement('canvas');
    const r = Math.min(window.devicePixelRatio || 1, 3);
    c.width = c.height = size * r; c.style.width = c.style.height = size + 'px';
    const x = c.getContext('2d');
    x.scale(r, r);
    drawCardIcon(x, id, size / 2, size / 2, size);
    return c;
  }

  function openLevelUp() {
    state = 'levelup';
    pauseMusic();
    pointerId = null;
    const box = $('cards');
    box.innerHTML = '';
    box.classList.remove('armed');
    for (const id of G.choice) {
      const def = CARD_DEFS[id], l = lvl(id);
      const b = document.createElement('button');
      b.className = 'card ' + def.type;
      b.style.setProperty('--c', def.color);
      const ic = document.createElement('div'); ic.className = 'card-icon'; ic.appendChild(iconCanvas(id, 52));
      const body = document.createElement('div'); body.className = 'card-body';
      body.innerHTML =
        `<div class="card-top"><span class="card-name">${def.name}</span>` +
        `<span class="card-tag">${def.type === 'active' ? 'Активная' : 'Пассивная'} · ${l === 0 ? 'Новая' : 'Ур. ' + (l + 1)}</span></div>` +
        `<div class="card-desc">${def.desc(l)}</div>` +
        `<div class="card-pips">${[0, 1, 2].map(i => `<i class="${i <= l ? 'on' : ''}"></i>`).join('')}</div>`;
      b.append(ic, body);
      b.addEventListener('click', () => {
        if (!box.classList.contains('armed')) return;
        chooseCard(id);
        resumeMusic();
        state = 'play';
        show(null);
        banners.push({ text: `${def.name}${l ? ' — ур. ' + (l + 1) : ''}!`, t: 0, life: 1.6, color: def.color });
      });
      box.appendChild(b);
    }
    show('overlay-levelup');
    // защита от случайного тапа пальцем, который только что вёл героя
    setTimeout(() => box.classList.add('armed'), 450);
  }

  function openResults() {
    state = 'results';
    const r = results();
    const share = r.left / r.total;
    const last = r.levelNo >= CONFIG.levels.length - 1;
    const isRecord = recordGig(SAVE.records, r.levelNo, r);
    const tourBox = $('res-tour');
    tourBox.innerHTML = '';
    const row = (k, v) => `<div class="res-row"><span>${k}</span><b>${v}</b></div>`;

    let title = r.encored ? 'Бис! Зал твой!' : r.passed ? (last ? 'Все залы пройдены!' : 'Зал удержан!') : 'Песня окончена';
    if (r.boss) title = r.bossBeaten ? 'Босс повержен!' : 'Босс не сдался';
    if (mode === 'tour' && SAVE.tour) {
      const t = SAVE.tour;
      const st = settleConcert(t, tourNode, r);
      enterNode(t, tourNode);
      tourBox.innerHTML = row('В кассу тура', `+${st.money} ₽`) + row('Деньги тура', `${t.money} ₽`) + row('Связь тела и души', `${t.bond} (+${st.bondGain})`) +
        (r.passed ? '' : '<p class="note">Зал не удержан — заплатили только половину.</p>') +
        (r.boss === 'critic' && !r.criticStayed ? '<p class="note">Критик ушёл, не дослушав.</p>' : '');
    } else if (mode === 'daily' && dailyNow) {
      const prev = SAVE.daily[dailyNow.key];
      if (!prev || r.left > prev.left) SAVE.daily[dailyNow.key] = { left: r.left, total: r.total };
      tourBox.innerHTML = row('Рекорд дня', `${SAVE.daily[dailyNow.key].left} из ${r.total}`);
    }
    persist();

    $('res-title').textContent = title;
    $('res-level').textContent = `${CONFIG.levels[r.levelNo].name}. Цель: удержать больше половины зала` + (r.boss === 'critic' ? ' и критика.' : '.');
    $('res-verdict').textContent = (isRecord ? 'Новый рекорд! ' : '') + (
      share >= 0.75 ? 'Зал твой! Тебя зовут снова.' :
      share > 0.5 ? 'Хороший сет, бармен доволен.' :
      share >= 0.25 ? 'Половина ушла, но кто-то остался.' : 'Тихий вечер. Попробуй другую сборку.');
    $('res-stars').innerHTML = starsHtml(starsFor(r.left, r.total));
    $('res-left').textContent = `${r.left} из ${r.total}`;
    $('res-money').textContent = `${r.money} ₽`;
    $('res-money-note').textContent = `${r.left} × ${r.perViewer}` +
      (r.bonus ? ` + ${r.bonus} бонус за полный зал` : ' (бонус +100, если осталось больше половины)') +
      (r.encored ? `, +${Math.round(r.encoreBonus * 100)}% за бис` : '') + (r.incidents.length ? `. Происшествий: ${r.incidents.length}.` : '');
    const free = mode === 'free';
    $('btn-continue').classList.toggle('hidden', free);
    $('btn-next').classList.toggle('hidden', !free || !r.passed || last);
    $('btn-again').classList.toggle('hidden', !free);
    $('btn-menu').classList.toggle('hidden', !free);

    const list = $('res-cards');
    list.innerHTML = '';
    if (!r.cards.length) list.innerHTML = '<span class="muted">Без карт</span>';
    for (const c of r.cards) {
      const el = document.createElement('div');
      el.className = 'res-card';
      el.appendChild(iconCanvas(c.id, 34));
      const sp = document.createElement('span'); sp.textContent = `${CARD_DEFS[c.id].name} ${c.level}`;
      el.appendChild(sp);
      list.appendChild(el);
    }
    lastResult = r;
    show('overlay-results');
  }

  let lastResult = null;
  $('btn-continue').addEventListener('click', () => {
    if (mode === 'daily') { openDaily(); return; }
    if (tourNode && tourNode.type === 'boss') afterBoss(lastResult); else openMap();
  });
  $('btn-next').addEventListener('click', () => startGame(G.levelNo + 1, { mode: 'free', mods: cleanMods() }));
  $('btn-again').addEventListener('click', () => startGame(G.levelNo, { mode: 'free', mods: cleanMods() }));
  $('btn-menu').addEventListener('click', () => { buildLevelMenu(); show('overlay-free'); });

  // ---------- визуальные события ----------
  function spawnParticles(x, y, n, color, speed, life, size, gravity) {
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2, s = speed * (0.4 + Math.random() * 0.6);
      particles.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life, max: life, color, size: size * (0.6 + Math.random() * 0.6), g: gravity || 0 });
    }
  }

  function handleEvents() {
    for (const ev of G.events) {
      if (ev.type === 'solo') fx.push({ type: 'ring', x: ev.x, y: ev.y, r: ev.r, t: 0, life: 0.6, color: CARD_DEFS.solo.color });
      else if (ev.type === 'chorus') {
        fx.push({ type: 'chorus', x: ev.x, y: ev.y, targets: ev.targets, t: 0, life: 0.8 });
      } else if (ev.type === 'pyro') {
        fx.push({ type: 'flash', t: 0, life: 0.5, edge: ev.edge });
        shake = 0.35;
        for (let i = 0; i < 6; i++) {
          const x = 30 + i * (G.L.W - 60) / 5;
          for (let k = 0; k < 14; k++) {
            particles.push({ x, y: G.L.stageBottom, vx: (Math.random() - 0.5) * 70, vy: -120 - Math.random() * 160, life: 1.1, max: 1.1, color: Math.random() < 0.5 ? '#ffd23d' : '#ff7a3d', size: 2.5, g: 260 });
          }
        }
      } else if (ev.type === 'pickup') {
        spawnParticles(ev.x, ev.y, 7, EMO_COLORS[ev.kind], 70, 0.45, 2.2);
      } else if (ev.type === 'repel') {
        fx.push({ type: 'ring', x: ev.x, y: ev.y - 8, r: 50, t: 0, life: 0.45, color: ev.kind === 'fear' ? '#ff3d50' : '#b49cff' });
        spawnParticles(ev.x, ev.y - 10, 14, ev.kind === 'fear' ? '#ff3d50' : '#b49cff', 130, 0.5, 2.6);
      } else if (ev.type === 'encore') {
        banners.push({ text: 'БИС! Зал просит ещё!', t: 0, life: 3, color: PAL.amber });
        shake = 0.4;
        for (let i = 0; i < 40; i++) spawnParticles(Math.random() * G.L.W, G.L.stageBottom, 1, Math.random() < 0.5 ? PAL.amber : PAL.pink, 160, 1.2, 3, 140);
      } else if (ev.type === 'leave') {
        fx.push({ type: 'leaveMark', x: ev.x, y: ev.y, t: 0, life: 1.0 });
      } else if (ev.type === 'incident') {
        banners.push({ text: ev.text, t: 0, life: 2.6, color: PAL.pink });
        shake = 0.3;
      } else if (ev.type === 'incidentEnd') {
        banners.push({ text: ev.text, t: 0, life: 1.8, color: PAL.green });
        spawnParticles(G.player.x, G.player.y - 20, 12, PAL.green, 90, 0.6, 2.5);
      } else if (ev.type === 'banner') {
        banners.push({ text: ev.text, t: 0, life: 2.6, color: PAL.amber });
      } else if (ev.type === 'levelup') {
        openLevelUp();
      } else if (ev.type === 'end') {
        setTimeout(openResults, 600);
        fadeOutMusic(2.5);
        state = 'ending';
        banners.push({ text: 'Песня окончена!', t: 0, life: 3, color: PAL.pink });
      }
    }
  }

  function updateVisuals(dt) {
    for (const f of fx) f.t += dt;
    fx = fx.filter(f => f.t < f.life);
    for (const p of particles) { p.life -= dt; p.x += p.vx * dt; p.y += p.vy * dt; p.vy += p.g * dt; p.vx *= 0.98; }
    particles = particles.filter(p => p.life > 0);
    for (const b of banners) b.t += dt;
    banners = banners.filter(b => b.t < b.life).slice(-2);
    // след души
    if (G && (state === 'play' || state === 'ending')) {
      const p = G.player;
      if (Math.random() < dt * (p.moving ? 40 : 18)) {
        particles.push({ x: p.x + (Math.random() - 0.5) * 8, y: p.y + (Math.random() - 0.5) * 6, vx: (Math.random() - 0.5) * 12, vy: 10 + Math.random() * 14,
          life: 0.6, max: 0.6, color: soulColor(), size: 2.2 + Math.random() * 2, g: 0 });
      }
    }
    shake = Math.max(0, shake - dt);
    // дым вокруг героя
    const sr = smokeRadius();
    if (sr && state === 'play') {
      if (smoke.length < 26 && Math.random() < dt * 14) {
        const a = Math.random() * Math.PI * 2, r = Math.sqrt(Math.random()) * sr * 0.85;
        smoke.push({ ox: Math.cos(a) * r, oy: Math.sin(a) * r * 0.75, life: 2.4, max: 2.4, size: 12 + Math.random() * 14 });
      }
    }
    for (const s of smoke) { s.life -= dt; s.oy -= 4 * dt; }
    smoke = smoke.filter(s => s.life > 0);
  }

  // ---------- рендер ----------
  const EMO_COLORS = ['#ff3d8b', '#3de0ff', '#ffd23d'];

  function lerpColor(a, b, k) {
    const pa = parseInt(a.slice(1), 16), pb = parseInt(b.slice(1), 16);
    const r = ((pa >> 16) & 255) + (((pb >> 16) & 255) - ((pa >> 16) & 255)) * k;
    const g = ((pa >> 8) & 255) + (((pb >> 8) & 255) - ((pa >> 8) & 255)) * k;
    const bl = (pa & 255) + ((pb & 255) - (pa & 255)) * k;
    return `rgb(${r | 0},${g | 0},${bl | 0})`;
  }

  function drawBackground() {
    const L = G.L;
    ctx.fillStyle = PAL.wall; ctx.fillRect(0, 0, L.W, L.wallBottom);
    ctx.fillStyle = PAL.wallBrick;
    for (let y = 0, row = 0; y < L.wallBottom; y += 14, row++) {
      for (let x = (row % 2) * 18 - 18; x < L.W; x += 36) ctx.fillRect(x + 1, y + 1, 34, 12);
    }
    // неоновая вывеска
    ctx.save();
    ctx.font = 'bold 20px system-ui, sans-serif';
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.shadowColor = PAL.pink; ctx.shadowBlur = 12;
    ctx.fillStyle = lerpColor('#a3275d', PAL.pink, 0.55 + 0.45 * pulse);
    ctx.fillText('ЖИВАЯ МУЗЫКА', L.W / 2, 74);
    ctx.restore();
    ctx.strokeStyle = PAL.pink; ctx.lineWidth = 2; ctx.globalAlpha = 0.6;
    ctx.strokeRect(L.W / 2 - 92, 59, 184, 30);
    ctx.globalAlpha = 1;

    // сцена
    ctx.fillStyle = PAL.stage; ctx.fillRect(0, L.wallBottom, L.W, L.stageBottom - L.wallBottom);
    ctx.fillStyle = PAL.stagePlank;
    for (let y = L.wallBottom + 12; y < L.stageBottom; y += 12) ctx.fillRect(0, y, L.W, 1.5);
    for (let y = L.wallBottom, i = 0; y < L.stageBottom; y += 12, i++) {
      for (let x = (i * 47) % 90; x < L.W; x += 90) ctx.fillRect(x, y, 1.5, 12);
    }
    // прожекторы — плоские полупрозрачные конусы
    ctx.globalAlpha = 0.07; ctx.fillStyle = '#ffe9b0';
    for (const sx of [70, 290]) {
      const sw = Math.sin(clock * 0.6 + sx) * 30;
      ctx.beginPath(); ctx.moveTo(sx, 0); ctx.lineTo(sx - 50 + sw, L.stageBottom); ctx.lineTo(sx + 50 + sw, L.stageBottom); ctx.fill();
    }
    ctx.globalAlpha = 1;
    // край сцены с лампочками
    ctx.fillStyle = PAL.stageEdge; ctx.fillRect(0, L.stageBottom, L.W, L.hallTop - L.stageBottom);
    for (let x = 10, i = 0; x < L.W; x += 20, i++) {
      ctx.fillStyle = lerpColor('#8a5a20', '#ffe28a', i % 2 === beatIndex % 2 ? pulse : 0.15);
      ctx.fillRect(x - 2, L.stageBottom + 3, 4, 4);
    }
    // пол зала
    ctx.fillStyle = PAL.floor; ctx.fillRect(0, L.hallTop, L.W, L.hallBottom - L.hallTop + 6);
    ctx.fillStyle = PAL.floorTile;
    const ts = 30;
    for (let y = L.hallTop, r = 0; y < L.hallBottom + 6; y += ts, r++) {
      for (let x = (r % 2) * ts; x < L.W; x += ts * 2) ctx.fillRect(x, y, ts, Math.min(ts, L.hallBottom + 6 - y));
    }
    drawAmp();
    // выход
    const ex = L.exit;
    ctx.fillStyle = '#0d1f14'; ctx.fillRect(L.W - 10, ex.y - 26, 10, 52);
    ctx.fillStyle = PAL.green; ctx.fillRect(L.W - 10, ex.y - 26, 2, 52);
    ctx.save();
    ctx.translate(L.W - 20, ex.y - 40);
    ctx.fillStyle = '#0f3a22'; ctx.fillRect(-26, -8, 44, 16);
    ctx.fillStyle = PAL.green; ctx.font = 'bold 10px system-ui, sans-serif';
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText('ВЫХОД', -4, 1);
    ctx.restore();
  }

  function drawViewer(v) {
    const V = CONFIG.viewers;
    const I = v.interest;
    const happy = I > V.happyThreshold && !v.leaving;
    const bored = I < V.boredThreshold || v.leaving;
    const k = v.leaving ? 0 : clamp((I - 12) / 55, 0, 1);
    const shirt = lerpColor(PAL.gray, v.shirt, k);
    const skin = v.leaving || bored ? lerpColor('#7d7670', v.skin, 0.35) : v.skin;
    const hk = happy ? clamp((I - V.happyThreshold) / 40, 0, 1) : 0;
    const bob = happy ? Math.abs(Math.sin(clock * (4 + hk * 3) + v.phase)) * (1.5 + hk * 2.5) : 0;
    const sway = happy ? Math.sin(clock * 3 + v.phase) * 0.12 * (0.5 + hk) : 0;
    const x = v.x, y = v.y;

    ctx.globalAlpha = v.leaving ? 0.65 : 1;
    ctx.fillStyle = 'rgba(0,0,0,0.35)';
    ctx.beginPath(); ctx.ellipse(x, y + 1, 8, 3, 0, 0, Math.PI * 2); ctx.fill();

    ctx.save();
    ctx.translate(x, y - bob);
    ctx.rotate(sway);
    const slump = bored ? 2 : 0;
    // руки вверх у очень довольных
    if (I > 80 && !v.leaving) {
      ctx.strokeStyle = skin; ctx.lineWidth = 2.5; ctx.lineCap = 'round';
      const w = Math.sin(clock * 6 + v.phase) * 2;
      ctx.beginPath(); ctx.moveTo(-5, -12); ctx.lineTo(-8 + w, -24); ctx.moveTo(5, -12); ctx.lineTo(8 - w, -24); ctx.stroke();
    }
    ctx.fillStyle = shirt;
    roundRect(-6, -15 + slump, 12, 14 - slump, 4); ctx.fill();
    ctx.fillStyle = skin;
    ctx.beginPath(); ctx.arc(0, -19 + slump * 1.5, 5, 0, Math.PI * 2); ctx.fill();
    if (v.flash > 0) {
      ctx.strokeStyle = '#fff'; ctx.globalAlpha = Math.min(1, v.flash * 2) * 0.9; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.arc(0, -12, 11, 0, Math.PI * 2); ctx.stroke();
      ctx.globalAlpha = 1;
    }
    ctx.restore();

    // критик: берет, блокнот и шкала его интереса
    if (v.critic && !v.leaving) {
      ctx.fillStyle = '#2a1640';
      ctx.beginPath(); ctx.ellipse(x + 1, y - 23 - bob, 7, 3, -0.2, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#f6e7d0'; ctx.fillRect(x + 6, y - 14 - bob, 6, 8);
      ctx.fillStyle = '#1a0f09'; ctx.fillRect(x - 12, y - 40, 24, 4);
      ctx.fillStyle = I > 40 ? PAL.green : I > 20 ? PAL.amber : PAL.pink;
      ctx.fillRect(x - 12, y - 40, 24 * clamp(I / 100, 0, 1), 4);
      ctx.strokeStyle = 'rgba(180,140,255,0.7)'; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.arc(x, y - 10, 15, 0, Math.PI * 2); ctx.stroke();
    }
    // значки настроения
    if (!v.leaving && I < V.boredThreshold) {
      ctx.fillStyle = '#9a9aa2';
      for (let i = 0; i < 3; i++) ctx.fillRect(x - 5 + i * 4, y - 32, 2, 2);
    } else if (v.leaving) {
      ctx.fillStyle = '#9a9aa2'; ctx.font = 'bold 9px system-ui, sans-serif'; ctx.textAlign = 'center';
      ctx.fillText('пока', x, y - 30);
    }
    ctx.globalAlpha = 1;
  }

  function roundRect(x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath();
  }

  function heroIsF() { return !!(SAVE.profile && SAVE.profile.hero === 'f'); }

  // ---------- пульс зала в такт музыки ----------
  let beatT = 0, pulse = 0, beatIndex = 0, bodyLife = 0;
  function beatPhase() {
    const b = G.beat, x = (beatT - b.offset) / b.period;
    beatIndex = Math.floor(x);
    return x - Math.floor(x); // 0 — сама доля
  }
  // душа разгорается, когда зал доволен: голубая → зелёная → розовая → золотая
  const SOUL_COLORS = ['#3de0ff', '#5dff9e', '#ff3d8b', '#ffd23d'];
  function soulColor() {
    const sk = SOUL_SKINS.find(x => x.id === SAVE.skins.selected);
    return (sk ? sk.colors : SOUL_COLORS)[Math.min(3, Math.floor(bodyLife * 4))];
  }

  // Силуэт музыканта с гитарой. Общий для тела на сцене и души-двойника.
  // o: цвета частей, headDrop — насколько опущена голова, ghost — без ног, с туманным хвостом
  function drawMusician(o) {
    if (o.ghost) {
      ctx.fillStyle = o.jacket;
      ctx.beginPath();
      ctx.moveTo(-8, -10);
      ctx.quadraticCurveTo(-6, 2, Math.sin(clock * 4) * 3, 10);
      ctx.quadraticCurveTo(6, 2, 8, -10);
      ctx.fill();
    } else {
      ctx.fillStyle = o.legs;
      ctx.fillRect(-5, -8, 4, 8); ctx.fillRect(1, -8, 4, 8);
    }
    ctx.fillStyle = o.jacket;
    roundRect(-8, -26, 16, 19, 5); ctx.fill();
    ctx.fillStyle = o.skin;
    ctx.beginPath(); ctx.arc(0, -32 + o.headDrop, 6.5, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = o.hair;
    ctx.beginPath(); ctx.arc(0, -34 + o.headDrop, 7, Math.PI, Math.PI * 2); ctx.fill();
    if (o.longHair) { ctx.fillRect(-7, -34 + o.headDrop, 3.5, 12); ctx.fillRect(3.5, -34 + o.headDrop, 3.5, 12); }
    ctx.save();
    ctx.translate(1, -15); ctx.rotate(-0.55);
    ctx.fillStyle = o.neck; ctx.fillRect(4, -2, 20, 3.5);
    ctx.fillStyle = o.guitar;
    ctx.beginPath(); ctx.ellipse(0, 0, 8, 6, 0, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.ellipse(-6, 0, 6, 5, 0, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
    ctx.fillStyle = o.skin;
    ctx.beginPath(); ctx.arc(-2, -15 + o.strum, 2.6, 0, Math.PI * 2); ctx.fill();
  }

  // Тело музыканта: стоит в центре сцены и играет на автопилоте. Оживает, когда зал доволен.
  function drawBody() {
    const S = CONFIG.incidents.string, x = S.spot.x, y = S.spot.y + 8;
    const life = bodyLife; // 0 — серое и неподвижное, 1 — живое
    const bob = pulse * (0.6 + life * 2.4);
    ctx.fillStyle = 'rgba(0,0,0,0.4)';
    ctx.beginPath(); ctx.ellipse(x, y + 1, 12, 4, 0, 0, Math.PI * 2); ctx.fill();
    ctx.save();
    ctx.translate(x, y - bob);
    drawMusician({
      legs: lerpColor('#3a3840', '#2b2b3a', life),
      jacket: lerpColor('#6b6670', '#c94f2f', life),
      skin: lerpColor('#8f8680', '#f1c9a5', life),
      hair: lerpColor('#4a4448', '#3a1d10', life),
      neck: lerpColor('#4a4245', '#5a2c10', life),
      guitar: lerpColor('#7d7570', PAL.amber, life),
      headDrop: (1 - life) * 3, strum: pulse * 2, longHair: heroIsF(),
    });
    ctx.restore();

    if (stringBroken()) {
      const blink = Math.sin(clock * 8) > 0;
      ctx.strokeStyle = blink ? PAL.pink : 'rgba(255,61,139,0.4)'; ctx.lineWidth = 2; ctx.setLineDash([4, 4]);
      ctx.beginPath(); ctx.arc(x, y - 16, S.radius + 6, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
      ring(x, y - 54, 9, G.incident.progress, PAL.green);
      ctx.fillStyle = PAL.text; ctx.font = 'bold 12px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText('!', x, y - 53);
    }
  }

  // Душа: прозрачный светящийся двойник музыканта, парит над залом.
  function drawSoul() {
    const p = G.player, x = p.x, y = p.y;
    const col = soulColor();
    const broken = stringBroken();
    // аура и радиус сбора эмоций
    ctx.fillStyle = broken ? 'rgba(120,120,130,0.08)' : 'rgba(255,176,58,0.07)';
    ctx.beginPath(); ctx.arc(x, y - 6, auraRadius(), 0, Math.PI * 2); ctx.fill();
    ctx.setLineDash([4, 5]); ctx.strokeStyle = 'rgba(255,210,61,0.45)'; ctx.lineWidth = 1.2;
    ctx.beginPath(); ctx.arc(x, y - 10, pickupRadius(), 0, Math.PI * 2); ctx.stroke();
    ctx.setLineDash([]);
    const hover = Math.sin(clock * 3) * 2 + pulse * 1.5;
    ctx.save();
    ctx.translate(x, y - 6 - hover);
    ctx.scale(p.dir * 1.25, 1.25); // душа чуть крупнее тела, чтобы её было хорошо видно
    // мягкое свечение
    ctx.globalAlpha = 0.18; ctx.fillStyle = col;
    ctx.beginPath(); ctx.ellipse(0, -14, 18, 24, 0, 0, Math.PI * 2); ctx.fill();
    // полупрозрачный двойник
    ctx.globalAlpha = 0.6;
    const light = lerpColor(col, '#ffffff', 0.55);
    drawMusician({
      jacket: col, skin: light, hair: lerpColor(col, '#1a0f09', 0.35),
      neck: lerpColor(col, '#ffffff', 0.25), guitar: light,
      headDrop: 0, strum: Math.sin(clock * 9) * 2, ghost: true, longHair: heroIsF(),
    });
    // светлый контур
    ctx.globalAlpha = 0.85; ctx.strokeStyle = light; ctx.lineWidth = 1.2;
    roundRect(-8, -26, 16, 19, 5); ctx.stroke();
    ctx.beginPath(); ctx.arc(0, -32, 6.5, 0, Math.PI * 2); ctx.stroke();
    ctx.restore();
    ctx.globalAlpha = 1;
  }

  function drawHeart(x, y, s) {
    ctx.beginPath();
    ctx.moveTo(x, y + s * 0.35);
    ctx.bezierCurveTo(x - s * 0.9, y - s * 0.2, x - s * 0.35, y - s * 0.8, x, y - s * 0.3);
    ctx.bezierCurveTo(x + s * 0.35, y - s * 0.8, x + s * 0.9, y - s * 0.2, x, y + s * 0.35);
    ctx.fill();
  }
  function drawNote(x, y, s) {
    ctx.beginPath(); ctx.ellipse(x - s * 0.15, y + s * 0.3, s * 0.28, s * 0.2, -0.4, 0, Math.PI * 2); ctx.fill();
    ctx.fillRect(x + s * 0.06, y - s * 0.45, s * 0.12, s * 0.78);
    ctx.beginPath(); ctx.moveTo(x + s * 0.18, y - s * 0.45); ctx.quadraticCurveTo(x + s * 0.55, y - s * 0.25, x + s * 0.4, y); ctx.lineTo(x + s * 0.18, y - s * 0.2); ctx.fill();
  }
  function drawBurst(x, y, s, n, inner) {
    ctx.beginPath();
    for (let i = 0; i < n * 2; i++) {
      const a = i * Math.PI / n - Math.PI / 2, r = i % 2 ? s * inner : s * 0.55;
      ctx.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r);
    }
    ctx.closePath(); ctx.fill();
  }

  function drawEmotions() {
    for (const e of G.emotions) {
      const rest = e.life - e.age;
      if (rest < 1.2 && Math.floor(rest * 8) % 2 === 0) continue; // мигает перед исчезновением
      const pulse = 1 + Math.sin(clock * 8 + e.x) * 0.06;
      const s = e.size * pulse * Math.min(1, e.age * 6);
      ctx.fillStyle = 'rgba(20,12,8,0.55)';
      ctx.beginPath(); ctx.arc(e.x, e.y, s * 0.62, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = EMO_COLORS[e.kind];
      if (e.kind === 0) drawHeart(e.x, e.y + s * 0.05, s * 0.85);
      else if (e.kind === 1) drawNote(e.x, e.y, s);
      else drawBurst(e.x, e.y, s, 6, 0.3);
    }
  }

  function drawFxUnder() {
    // дым — под зрителями и героем
    const p = G.player;
    for (const s of smoke) {
      const k = s.life / s.max;
      ctx.fillStyle = `rgba(190,170,255,${0.16 * Math.sin(k * Math.PI)})`;
      ctx.beginPath(); ctx.arc(p.x + s.ox, p.y - 6 + s.oy, s.size * (1.4 - k * 0.4), 0, Math.PI * 2); ctx.fill();
    }
    const sr = smokeRadius();
    if (sr) {
      ctx.strokeStyle = 'rgba(180,156,255,0.35)'; ctx.lineWidth = 1.5; ctx.setLineDash([2, 6]);
      ctx.beginPath(); ctx.arc(p.x, p.y - 6, sr, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
    }
    for (const f of fx) {
      if (f.type === 'ring') {
        const k = f.t / f.life;
        ctx.strokeStyle = f.color; ctx.globalAlpha = 1 - k; ctx.lineWidth = 5 * (1 - k) + 1;
        ctx.beginPath(); ctx.arc(f.x, f.y - 6, f.r * (0.25 + 0.75 * Math.sqrt(k)), 0, Math.PI * 2); ctx.stroke();
        ctx.globalAlpha = (1 - k) * 0.12; ctx.fillStyle = f.color; ctx.fill();
        ctx.globalAlpha = 1;
      } else if (f.type === 'tapMark') {
        const k = f.t / f.life;
        ctx.strokeStyle = f.color; ctx.globalAlpha = 1 - k; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.arc(f.x, f.y, 6 + 10 * k, 0, Math.PI * 2); ctx.stroke();
        ctx.globalAlpha = 1;
      } else if (f.type === 'leaveMark') {
        const k = f.t / f.life;
        ctx.fillStyle = PAL.gray; ctx.globalAlpha = 1 - k;
        ctx.font = 'bold 12px system-ui, sans-serif'; ctx.textAlign = 'center';
        ctx.fillText('−1', f.x, f.y - 36 - k * 14);
        ctx.globalAlpha = 1;
      }
    }
  }

  function drawFxOver() {
    for (const f of fx) {
      if (f.type === 'chorus') {
        const k = f.t / f.life;
        ctx.strokeStyle = CARD_DEFS.chorus.color; ctx.lineWidth = 2; ctx.globalAlpha = 1 - k;
        ctx.setLineDash([3, 4]);
        for (const tg of f.targets) {
          ctx.beginPath(); ctx.moveTo(f.x, f.y - 20); ctx.lineTo(tg.x, tg.y - 20); ctx.stroke();
        }
        ctx.setLineDash([]);
        ctx.fillStyle = CARD_DEFS.chorus.color;
        for (const tg of f.targets) {
          const m = Math.min(1, k * 2.2);
          drawNote(f.x + (tg.x - f.x) * m, f.y - 20 + (tg.y - f.y) * m - Math.sin(m * Math.PI) * 18, 12);
        }
        ctx.globalAlpha = 1;
      } else if (f.type === 'flash') {
        const k = f.t / f.life;
        ctx.fillStyle = '#ffcf6a'; ctx.globalAlpha = (1 - k) * 0.35;
        ctx.fillRect(0, 0, G.L.W, f.edge);
        ctx.globalAlpha = (1 - k) * 0.9; ctx.fillStyle = '#ff7a3d';
        ctx.fillRect(0, f.edge - 2, G.L.W, 4);
        ctx.globalAlpha = 1;
      }
    }
    for (const p of particles) {
      ctx.globalAlpha = clamp(p.life / p.max, 0, 1);
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);
    }
    ctx.globalAlpha = 1;
  }

  function drawCardIcon(c, id, x, y, size) {
    const s = size;
    const col = CARD_DEFS[id].color;
    c.save();
    c.fillStyle = '#2a170d'; c.strokeStyle = col; c.lineWidth = Math.max(1.5, s * 0.06);
    c.beginPath();
    const r = s * 0.2, h = s * 0.46;
    c.moveTo(x - h + r, y - h); c.arcTo(x + h, y - h, x + h, y + h, r); c.arcTo(x + h, y + h, x - h, y + h, r);
    c.arcTo(x - h, y + h, x - h, y - h, r); c.arcTo(x - h, y - h, x + h, y - h, r); c.closePath();
    c.fill(); c.stroke();
    c.fillStyle = col; c.strokeStyle = col; c.lineWidth = s * 0.07; c.lineCap = 'round';
    const u = s * 0.3;
    if (id === 'solo') {
      c.beginPath(); c.arc(x, y, u * 0.28, 0, Math.PI * 2); c.fill();
      for (const k of [0.6, 1.0]) { c.beginPath(); c.arc(x, y, u * k, 0, Math.PI * 2); c.stroke(); }
    } else if (id === 'smoke') {
      for (const [dx, dy, rr] of [[-0.45, 0.15, 0.42], [0.05, -0.2, 0.55], [0.5, 0.15, 0.4], [0, 0.3, 0.45]]) {
        c.beginPath(); c.arc(x + dx * u, y + dy * u, rr * u, 0, Math.PI * 2); c.fill();
      }
    } else if (id === 'chorus') {
      c.beginPath(); c.ellipse(x - u * 0.55, y + u * 0.55, u * 0.3, u * 0.22, -0.4, 0, Math.PI * 2); c.fill();
      c.beginPath(); c.ellipse(x + u * 0.55, y + u * 0.35, u * 0.3, u * 0.22, -0.4, 0, Math.PI * 2); c.fill();
      c.fillRect(x - u * 0.33, y - u * 0.65, u * 0.14, u * 1.2);
      c.fillRect(x + u * 0.77, y - u * 0.85, u * 0.14, u * 1.2);
      c.beginPath(); c.moveTo(x - u * 0.33, y - u * 0.65); c.lineTo(x + u * 0.9, y - u * 0.85); c.lineTo(x + u * 0.9, y - u * 0.55); c.lineTo(x - u * 0.33, y - u * 0.35); c.fill();
    } else if (id === 'pyro') {
      c.beginPath();
      for (let i = 0; i < 16; i++) {
        const a = i * Math.PI / 8, rr = i % 2 ? u * 0.4 : u * 1.05;
        c.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
      }
      c.closePath(); c.fill();
    } else if (id === 'costume') {
      c.beginPath();
      for (let i = 0; i < 10; i++) {
        const a = i * Math.PI / 5 - Math.PI / 2, rr = i % 2 ? u * 0.42 : u * 1.0;
        c.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
      }
      c.closePath(); c.fill();
    } else if (id === 'charisma') {
      const hs = u * 1.6;
      c.beginPath();
      c.moveTo(x, y + hs * 0.4);
      c.bezierCurveTo(x - hs * 0.9, y - hs * 0.15, x - hs * 0.35, y - hs * 0.75, x, y - hs * 0.25);
      c.bezierCurveTo(x + hs * 0.35, y - hs * 0.75, x + hs * 0.9, y - hs * 0.15, x, y + hs * 0.4);
      c.fill();
    } else if (id === 'amp') {
      c.fillRect(x - u * 0.8, y - u * 0.95, u * 1.6, u * 1.9);
      c.fillStyle = '#2a170d';
      c.beginPath(); c.arc(x, y + u * 0.2, u * 0.55, 0, Math.PI * 2); c.fill();
      c.beginPath(); c.arc(x, y - u * 0.62, u * 0.15, 0, Math.PI * 2); c.fill();
      c.fillStyle = col;
      c.beginPath(); c.arc(x, y + u * 0.2, u * 0.2, 0, Math.PI * 2); c.fill();
    } else if (id === 'mic') {
      c.beginPath(); c.arc(x, y - u * 0.4, u * 0.48, 0, Math.PI * 2); c.fill();
      c.fillRect(x - u * 0.16, y, u * 0.32, u * 0.95);
      c.beginPath(); c.arc(x, y - u * 0.1, u * 0.7, 0.15 * Math.PI, 0.85 * Math.PI); c.stroke();
    }
    c.restore();
  }

  function drawHUD() {
    const L = G.L;
    // верхняя плашка
    ctx.fillStyle = 'rgba(16,9,6,0.82)'; ctx.fillRect(0, 0, L.W, L.hudH);
    ctx.fillStyle = PAL.amber; ctx.fillRect(0, L.hudH - 2, L.W, 2);
    const rest = G.encore ? Math.max(0, CONFIG.encore.duration - G.encore.t) : Math.max(0, G.duration - G.t);
    const m = Math.floor(Math.ceil(rest) / 60), s = Math.ceil(rest) % 60;
    ctx.textBaseline = 'middle';
    ctx.font = 'bold 22px system-ui, sans-serif'; ctx.textAlign = 'left';
    ctx.fillStyle = G.encore ? PAL.amber : rest <= 20 ? PAL.pink : PAL.text;
    if (G.encore) ctx.font = 'bold 15px system-ui, sans-serif';
    ctx.fillText(G.encore ? `БИС ${Math.ceil(rest)}` : `${m}:${String(s).padStart(2, '0')}`, 12, 23);
    ctx.font = 'bold 22px system-ui, sans-serif';
    // прогресс песни
    ctx.fillStyle = '#3a2416'; ctx.fillRect(74, 19, 110, 6);
    ctx.fillStyle = PAL.amber; ctx.fillRect(74, 19, 110 * (G.t / G.duration), 6);
    for (const ph of CONFIG.decayPhases.slice(0, -1)) { ctx.fillStyle = PAL.panel; ctx.fillRect(74 + 110 * ph.until / CONFIG.songDuration - 0.5, 18, 1.5, 8); }
    // зрители
    const n = viewersInHall();
    ctx.textAlign = 'right';
    ctx.fillStyle = n > G.total / 2 ? PAL.text : PAL.pink;
    ctx.fillText(`${n}`, L.W - 34, 23);
    ctx.font = 'bold 12px system-ui, sans-serif'; ctx.fillStyle = PAL.dim;
    ctx.fillText(`/${G.total}`, L.W - 10, 26);
    // иконка человечка
    const ix = L.W - 76 - (n >= 10 ? 8 : 0);
    ctx.fillStyle = PAL.text;
    ctx.beginPath(); ctx.arc(ix, 15, 4.5, 0, Math.PI * 2); ctx.fill();
    roundRect(ix - 6, 21, 12, 11, 4); ctx.fill();

    // нижняя панель: драйв и карты
    const y0 = L.panelTop;
    ctx.fillStyle = PAL.panel; ctx.fillRect(0, y0, L.W, L.H - y0);
    ctx.fillStyle = PAL.amber; ctx.fillRect(0, y0, L.W, 2);
    const need = driveThreshold(G.level);
    const k = clamp(G.drive / need, 0, 1);
    ctx.font = 'bold 11px system-ui, sans-serif'; ctx.textAlign = 'left'; ctx.fillStyle = PAL.dim;
    ctx.fillText('ДРАЙВ', 10, y0 + 13);
    const bx = 56, bw = L.W - 56 - 50, by = y0 + 7, bh = 12;
    ctx.fillStyle = '#3a2416'; ctx.fillRect(bx, by, bw, bh);
    ctx.fillStyle = PAL.pink; ctx.fillRect(bx, by, bw * k, bh);
    ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(bx, by, bw * k, 3);
    ctx.textAlign = 'right'; ctx.fillStyle = PAL.text; ctx.font = 'bold 12px system-ui, sans-serif';
    ctx.fillStyle = PAL.text;
    ctx.fillText(`ур. ${G.level}`, L.W - 8, y0 + 13);
    // слоты карт: 4 активных + 4 пассивных
    const act = G.cardOrder.filter(id => CARD_DEFS[id].type === 'active');
    const pas = G.cardOrder.filter(id => CARD_DEFS[id].type === 'passive');
    const sz = 26, gap = 6, cy = y0 + 39;
    const slots = [...pad(act), null, ...pad(pas)];
    let x = (L.W - (slots.length - 1) * (sz + gap) + gap) / 2;
    for (let i = 0; i < slots.length; i++) {
      const id = slots[i];
      if (i === 4) { x += (sz + gap) / 2; continue; }
      if (id === undefined) {
        ctx.strokeStyle = '#3a2416'; ctx.lineWidth = 1.5; ctx.setLineDash([3, 3]);
        ctx.strokeRect(x - sz / 2 + 1, cy - sz / 2 + 1, sz - 2, sz - 2); ctx.setLineDash([]);
      } else {
        drawCardIcon(ctx, id, x, cy, sz);
        const l = G.cards[id];
        for (let p = 0; p < 3; p++) { ctx.fillStyle = p < l ? CARD_DEFS[id].color : '#3a2416'; ctx.fillRect(x - 7 + p * 5.5, cy + sz / 2 + 1, 4, 2.5); }
        // индикатор перезарядки
        if (G.timers[id] != null && C[id].cooldown) {
          const cd = C[id].cooldown[l - 1] * cooldownMul();
          const kk = clamp(1 - G.timers[id] / cd, 0, 1);
          ctx.fillStyle = 'rgba(0,0,0,0.45)'; ctx.fillRect(x - sz / 2 + 2, cy - sz / 2 + 2, sz - 4, (sz - 4) * (1 - kk));
        }
      }
      x += sz + gap;
    }
    function pad(a) { const r = a.slice(0, 4); while (r.length < 4) r.push(undefined); return r; }
  }

  // ---------- происшествия ----------
  function ring(x, y, r, k, color) {
    ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.lineWidth = 4;
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
    ctx.strokeStyle = color; ctx.lineWidth = 4;
    ctx.beginPath(); ctx.arc(x, y, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * clamp(k, 0, 1)); ctx.stroke();
  }

  function drawAmp() {
    // усилитель — просто декор слева на сцене, подпрыгивает в такт
    const x = 34, y = 150, k = pulse * 1.5;
    ctx.fillStyle = '#121212'; ctx.fillRect(x - 13, y - 30, 26, 30);
    ctx.fillStyle = '#2b2b2b'; ctx.beginPath(); ctx.arc(x, y - 13, 8 + k, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = PAL.amber; ctx.fillRect(x - 11, y - 28, 22, 3);
  }

  function drawDrunk() {
    const inc = G.incident;
    if (!inc || inc.type !== 'drunk') return;
    const D = CONFIG.incidents.drunk, x = inc.x, y = inc.y;
    if (!inc.leaving) {
      ctx.fillStyle = 'rgba(255,61,139,0.08)';
      ctx.beginPath(); ctx.arc(x, y - 8, D.radius, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = 'rgba(255,61,139,0.55)'; ctx.lineWidth = 1.5; ctx.setLineDash([3, 5]);
      ctx.beginPath(); ctx.arc(x, y - 8, D.radius, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
    }
    const wob = Math.sin(clock * 5) * 0.25;
    ctx.fillStyle = 'rgba(0,0,0,0.35)';
    ctx.beginPath(); ctx.ellipse(x, y + 1, 9, 3, 0, 0, Math.PI * 2); ctx.fill();
    ctx.save(); ctx.translate(x, y); ctx.rotate(wob);
    ctx.fillStyle = '#6b8f3a'; roundRect(-7, -16, 14, 15, 4); ctx.fill();
    ctx.fillStyle = '#e08a7a'; ctx.beginPath(); ctx.arc(0, -21, 5.5, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#c0392b'; ctx.beginPath(); ctx.arc(1.5, -20, 1.8, 0, Math.PI * 2); ctx.fill();
    // бутылка
    ctx.fillStyle = '#3f7a4a'; ctx.fillRect(7, -18, 3, 9); ctx.fillRect(7.8, -21, 1.4, 3);
    ctx.restore();
    if (!inc.leaving) {
      ring(x, y - 38, 8, inc.progress, PAL.green);
      ctx.fillStyle = PAL.pink; ctx.font = 'bold 12px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText('!', x, y - 37);
    }
  }

  function drawBlackout() {
    const inc = G.incident;
    if (!inc || inc.type !== 'blackout') return;
    const B = CONFIG.incidents.blackout;
    const fade = Math.min(1, inc.age * 3, (B.duration - inc.age) * 2);
    const p = G.player;
    ctx.save();
    ctx.fillStyle = `rgba(4,2,1,${0.86 * fade})`;
    ctx.beginPath();
    ctx.rect(0, G.L.hudH, G.L.W, G.L.panelTop - G.L.hudH);
    ctx.arc(p.x, p.y - 10, B.light * G.mods.blackoutLightMul, 0, Math.PI * 2, true);
    ctx.fill('evenodd');
    ctx.restore();
  }

  // Соперник — тёмный двойник музыканта, Страх — чёрная тень с красными глазами
  function drawAntagonist() {
    const A = G.antagonist;
    if (!A || !A.active) return;
    const B = CONFIG.bosses[A.kind];
    const fade = A.stun ? 0.35 : 1;
    if (!A.stun) {
      ctx.fillStyle = A.kind === 'fear' ? 'rgba(10,0,20,0.22)' : 'rgba(120,60,160,0.12)';
      ctx.beginPath(); ctx.arc(A.x, A.y - 8, B.radius, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = A.kind === 'fear' ? 'rgba(255,61,80,0.5)' : 'rgba(180,120,255,0.5)';
      ctx.lineWidth = 1.5; ctx.setLineDash([3, 5]);
      ctx.beginPath(); ctx.arc(A.x, A.y - 8, B.radius, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
    }
    ctx.save();
    ctx.globalAlpha = fade;
    ctx.translate(A.x, A.y - 6 + Math.sin(clock * 3.3) * 2);
    if (A.kind === 'rival') {
      ctx.globalAlpha = 0.75 * fade;
      drawMusician({ jacket: '#4b3a66', skin: '#9a8aa8', hair: '#1c1426', neck: '#2c2238', guitar: '#7a5ca0', headDrop: 0, strum: Math.sin(clock * 9) * 2, ghost: true });
    } else {
      const s = 1.35;
      ctx.scale(s, s);
      ctx.fillStyle = '#0c0610';
      ctx.beginPath();
      ctx.moveTo(0, -34);
      ctx.bezierCurveTo(16, -30, 14, -4, 10, 8);
      ctx.quadraticCurveTo(0, 2 + Math.sin(clock * 5) * 3, -10, 8);
      ctx.bezierCurveTo(-14, -4, -16, -30, 0, -34);
      ctx.fill();
      ctx.fillStyle = '#ff3d50';
      ctx.fillRect(-6, -22, 4, 2); ctx.fillRect(2, -22, 4, 2);
    }
    ctx.restore();
  }

  function drawIncidentChip() {
    const inc = G.incident, A = G.antagonist;
    let text = null;
    if (inc && !(inc.type === 'drunk' && inc.leaving)) {
      text = inc.type === 'string' ? 'Струна! Верни душу к телу на сцене' :
        inc.type === 'drunk' ? 'Дебошир! Подойди и постой рядом' :
        `Нет света: ещё ${Math.ceil(CONFIG.incidents.blackout.duration - inc.age)} с`;
    } else if (A && A.active && !A.stun && !G.encore) {
      text = A.kind === 'rival' ? 'Соперник уводит зал — коснись его душой' : 'Страх уводит зал — коснись его душой';
    } else if (G.critic && !G.critic.leaving && G.critic.interest < 35) {
      text = 'Критик скучает — лети к нему!';
    }
    if (!text) return;
    ctx.font = 'bold 13px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    const w = ctx.measureText(text).width + 20, y = G.L.hudH + 14;
    ctx.fillStyle = Math.sin(clock * 6) > 0 ? '#5a1430' : '#3a0d20';
    roundRect(G.L.W / 2 - w / 2, y - 11, w, 22, 6); ctx.fill();
    ctx.fillStyle = PAL.text; ctx.fillText(text, G.L.W / 2, y + 1);
  }

  function drawBanners() {
    let y = G.L.hallTop + 30;
    for (const b of banners) {
      const a = Math.min(1, b.t * 4, (b.life - b.t) * 2);
      ctx.globalAlpha = a;
      ctx.font = 'bold 17px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      const w = ctx.measureText(b.text).width + 24;
      ctx.fillStyle = 'rgba(16,9,6,0.85)'; roundRect(G.L.W / 2 - w / 2, y - 15, w, 30, 8); ctx.fill();
      ctx.strokeStyle = b.color || PAL.amber; ctx.lineWidth = 2; ctx.stroke();
      ctx.fillStyle = b.color || PAL.text; ctx.fillText(b.text, G.L.W / 2, y + 1);
      y += 38;
    }
    ctx.globalAlpha = 1;
  }

  function render() {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillStyle = PAL.bg; ctx.fillRect(0, 0, canvas.width, canvas.height);
    if (!G) return;
    const sh = shake > 0 ? (Math.random() - 0.5) * 6 * shake : 0;
    ctx.setTransform(dpr * scale, 0, 0, dpr * scale, (offX + sh) * dpr, offY * dpr);
    ctx.save();
    ctx.beginPath(); ctx.rect(0, 0, G.L.W, G.L.H); ctx.clip();
    drawBackground();
    drawFxUnder();
    drawBody();
    const list = G.viewers.filter(v => !v.gone).sort((a, b) => a.y - b.y);
    for (const v of list) drawViewer(v);
    drawDrunk();
    drawAntagonist();
    drawEmotions();
    drawSoul();
    drawFxOver();
    drawBlackout();
    drawHUD();
    drawIncidentChip();
    drawBanners();
    ctx.restore();
  }

  function frame(ts) {
    const dt = Math.min(0.05, (ts - lastTs) / 1000 || 0);
    lastTs = ts;
    clock += dt;
    if (G) {
      // позиция трека по часам элемента <audio>, если музыка играет (для пульса зала)
      const pos = state === 'play' || state === 'ending' ? musicPos() : null;
      if (pos != null && pos >= 0) { G.externalClock = true; G.musicTime = pos; } else G.externalClock = false;
      beatT = G.musicTime;
      const ph = beatPhase();
      pulse = Math.max(0, 1 - ph * 4);
      // тело и душа оживают, когда в зале много довольных
      let happy = 0, inHallN = 0;
      for (const v of G.viewers) if (!v.leaving) { inHallN++; if (v.interest > CONFIG.viewers.happyThreshold) happy++; }
      const target = Math.max(lifeFloor, inHallN ? happy / inHallN : 0);
      bodyLife += (target - bodyLife) * Math.min(1, dt * 1.5);
    }
    if (G && (state === 'play' || state === 'ending') && !document.hidden) {
      if (state === 'play') { update(dt); handleEvents(); }
      updateVisuals(dt);
    }
    // В установленном PWA iOS меняет размер окна и плотность пикселей без события resize —
    // тогда холст рисуется в старом разрешении и растягивается, картинка «мылится».
    if (canvas.width !== Math.round(window.innerWidth * Math.min(window.devicePixelRatio || 1, 3)) ||
        canvas.height !== Math.round(window.innerHeight * Math.min(window.devicePixelRatio || 1, 3))) resize();
    render();
    requestAnimationFrame(frame);
  }

  resize();
  requestAnimationFrame(frame);

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('./sw.js').catch(() => {}));
  }
})();

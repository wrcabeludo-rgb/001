'use strict';

// =====================================================================
//  «Удержи зал» — прототип. Все числа для баланса собраны в CONFIG.
//  Единицы расстояния — условные пиксели мира шириной 360.
// =====================================================================
const CONFIG = {
  songDuration: 180, // секунд
  worldWidth: 360,
  worldHeightMin: 600,
  worldHeightMax: 780,

  // Уровни по нарастанию сложности. decayMul умножает спад интереса из decayPhases.
  // Музыка: Kevin MacLeod (incompetech.com), CC BY 4.0 — см. music/CREDITS.txt
  levels: [
    { name: 'Пустой вторник', desc: 'Свои люди, никто не торопится домой.', viewers: 36, startInterest: 65, decayMul: 0.80,
      music: './music/level1-bossa-antigua.mp3', track: 'Bossa Antigua' },
    { name: 'Пятничный бар', desc: 'Обычный вечер: публика добрая, но не бесконечно.', viewers: 40, startInterest: 60, decayMul: 1.00,
      music: './music/level2-backbay-lounge.mp3', track: 'Backbay Lounge' },
    { name: 'Студенческая вечеринка', desc: 'Народу больше, внимание короче.', viewers: 44, startInterest: 60, decayMul: 1.18,
      music: './music/level3-funkorama.mp3', track: 'Funkorama' },
    { name: 'Клуб для своих', desc: 'Тут слышали всё. Удивить сложно.', viewers: 44, startInterest: 55, decayMul: 1.30,
      music: './music/level4-hep-cats.mp3', track: 'Hep Cats' },
    { name: 'Городской фестиваль', desc: 'Огромный зал, и все смотрят в телефоны.', viewers: 48, startInterest: 55, decayMul: 1.45,
      music: './music/level5-volatile-reaction.mp3', track: 'Volatile Reaction' },
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
    { until: 30, rate: 0.30, banner: '' },
    { until: 90, rate: 0.95, banner: 'Куплет: зал привыкает' },
    { until: 150, rate: 1.35, banner: 'Внимание тает быстрее!' },
    { until: 180, rate: 1.80, banner: 'Финал! Держи их!' },
  ],

  // Первые секунды зал благожелателен: эмоции идут и от «нейтральных»
  warmup: { duration: 30, emitThreshold: 45 },

  player: {
    speed: 230,
    touchOffset: 55,   // герой держится выше пальца
    auraRadius: 48,    // само присутствие музыканта рядом
    auraGain: 5,       // +интерес/с зрителям в ауре
  },

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
  // (по симуляции: ~4-6 уровней за песню, 1-2 из них в разогреве)
  drive: { thresholds: [40, 85, 130, 180, 240, 310, 390, 480], extraPerLevel: 100 },

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

  // Происшествия во время песни. count — сколько их запланировано на уровне,
  // каждое случается с вероятностью chance (её снижает «Знакомый техник»).
  incidents: {
    count: [1, 1, 2, 2, 3],
    chance: 0.8,
    window: [35, 160],   // в какие секунды песни могут начаться
    minGap: 25,
    string: { spot: { x: 34, y: 150 }, radius: 24, repairTime: 1.5 },
    blackout: { duration: 10, decayMul: 1.7, light: 85 },
    drunk: { speed: 26, radius: 60, drain: 4, calmRadius: 32, calmTime: 1.8, maxTime: 40 },
  },
};

// Модификаторы от покупок в магазине карьеры (career.js). В свободной игре — нули.
const DEFAULT_MODS = {
  auraGain: 0, speedMul: 1, startInterest: 0, pickup: 0,
  perViewer: 0, incidentMul: 1, repairMul: 1, freeCard: false,
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
    player: { x: L.W / 2, y: (L.wallBottom + L.stageBottom) / 2 + 4, tx: L.W / 2, ty: (L.wallBottom + L.stageBottom) / 2 + 4, dir: 1, moving: false },
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
    incidentPlan: planIncidents(rnd, levelNo, M),
    incident: null,     // текущее происшествие
    incidentsHappened: [],
  };
  // «Сет-лист» из магазина: одна карта на выбор сразу на старте
  if (M.freeCard) G.pendingLevelUps = 1;
  return G;
}

// ---------------------------------------------------------------------
//  Модификаторы от карт
// ---------------------------------------------------------------------
function lvl(id) { return G.cards[id] || 0; }
function radiusMul() { const l = lvl('costume'); return l ? C.costume.radiusMul[l - 1] : 1; }
function gainMul() { const l = lvl('charisma'); return l ? C.charisma.gainMul[l - 1] : 1; }
function cooldownMul() { const l = lvl('amp'); return l ? C.amp.cooldownMul[l - 1] : 1; }
function pickupRadius() { const l = lvl('mic'); return CONFIG.emotion.pickupRadius + G.mods.pickup + (l ? C.mic.pickupBonus[l - 1] : 0); }
function emotionDriveMul() { const l = lvl('mic'); return l ? C.mic.driveMul[l - 1] : 1; }
function auraRadius() { return CONFIG.player.auraRadius * radiusMul(); }
function smokeRadius() { const l = lvl('smoke'); return l ? C.smoke.radius[l - 1] * radiusMul() : 0; }

function currentPhase() {
  const ph = CONFIG.decayPhases;
  for (let i = 0; i < ph.length; i++) if (G.t < ph[i].until) return i;
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

function chooseCard(id) {
  if (!G.choice || !G.choice.includes(id)) return;
  const l = lvl(id);
  G.cards[id] = l + 1;
  if (l === 0) {
    G.cardOrder.push(id);
    // первое срабатывание вскоре, чтобы было видно, что карта работает
    if (id === 'solo' || id === 'chorus') G.timers[id] = 0.6;
    if (id === 'pyro') G.timers[id] = 2.0;
  }
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
  if (G.t >= CONFIG.songDuration) { G.t = CONFIG.songDuration; G.over = true; G.events.push({ type: 'end' }); return; }

  const ph = currentPhase();
  if (ph !== G.phaseIndex) {
    G.phaseIndex = ph;
    if (CONFIG.decayPhases[ph].banner) G.events.push({ type: 'banner', text: CONFIG.decayPhases[ph].banner });
  }

  updatePlayer(dt);
  updateIncidents(dt);
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
  const baseRate = CONFIG.decayPhases[ph].rate * G.lv.decayMul * (blackout ? CONFIG.incidents.blackout.decayMul : 1);
  const dr = G.incident && G.incident.type === 'drunk' && !G.incident.leaving ? G.incident : null;
  const auraGain = stringBroken() ? 0 : CONFIG.player.auraGain + G.mods.auraGain;
  const smokeR = smokeRadius();
  const smokeMul = smokeR ? C.smoke.decayMul[lvl('smoke') - 1] : 1;
  const auraR = auraRadius();
  const warm = G.t < CONFIG.warmup.duration;
  const emitThr = warm ? CONFIG.warmup.emitThreshold : V.happyThreshold;

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
    let rate = baseRate * v.decayMul;
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
      v.emitTimer = E.intervalMin + G.rnd() * (E.intervalMax - E.intervalMin);
      if (v.interest > emitThr) {
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
      addDrive(e.drive * dm, 'emotion');
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
  const types = ['string', 'blackout', 'drunk'];
  const plan = [];
  for (let i = 0; i < n; i++) {
    if (rnd() >= I.chance * M.incidentMul) continue;
    // по возможности без повторов
    const pool = types.filter(t => !plan.some(p => p.type === t));
    const type = (pool.length ? pool : types)[(rnd() * (pool.length || types.length)) | 0];
    plan.push({ type, t: 0 });
  }
  // равномерно раскладываем по окну песни с небольшим разбросом
  const [a, b] = I.window;
  const step = (b - a) / Math.max(1, plan.length);
  plan.forEach((p, i) => { p.t = a + step * i + rnd() * Math.max(0, step - I.minGap); });
  return plan;
}

function stringBroken() { return !!(G.incident && G.incident.type === 'string'); }

function startIncident(type) {
  const I = CONFIG.incidents, L = G.L;
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
  if (!G.incident && G.incidentPlan.length && G.t >= G.incidentPlan[0].t) startIncident(G.incidentPlan.shift().type);
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
      if (dist(p.x, p.y, inc.x, inc.y) <= D.calmRadius) inc.progress += dt / D.calmTime;
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

function results() {
  const left = viewersInHall();
  const total = G.total;
  const bonus = left > total / 2 ? CONFIG.money.halfBonus : 0;
  return {
    left, total, bonus,
    perViewer: CONFIG.money.perViewer + G.mods.perViewer,
    money: left * (CONFIG.money.perViewer + G.mods.perViewer) + bonus,
    incidents: G.incidentsHappened.slice(),
    cards: G.cardOrder.map(id => ({ id, level: G.cards[id] })),
    levels: G.level,
    levelNo: G.levelNo,
    passed: bonus > 0,
  };
}

if (typeof module !== 'undefined') {
  module.exports = {
    CONFIG, CARD_DEFS, CARD_IDS, DEFAULT_MODS, newGame, update, addDrive, chooseCard, skipChoice, results,
    get G() { return G; }, viewersInHall, pickupRadius, auraRadius, smokeRadius, radiusMul,
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
  let state = 'start'; // start | play | levelup | results
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

  // ---------- режимы, карьера, сохранения ----------
  function storage() { try { return window.localStorage; } catch (_) { return null; } }
  let SAVE = loadSave(storage());
  let mode = 'free'; // free | career
  const persist = () => writeSave(storage(), SAVE);

  // ---------- музыка ----------
  // Web Audio вместо <audio>: файл берётся обычным fetch, поэтому его отдаёт кэш
  // service worker'а и музыка работает офлайн.
  const MUSIC_VOLUME = 0.55;
  let actx = null, gainNode = null, source = null, musicToken = 0;
  let loadedTrack = { url: null, buffer: null };

  function audio() {
    if (!actx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return null;
      actx = new AC();
      gainNode = actx.createGain();
      gainNode.connect(actx.destination);
    }
    return actx;
  }

  function loadTrack(url) {
    if (loadedTrack.url === url) return Promise.resolve(loadedTrack.buffer);
    return fetch(url)
      .then(r => { if (!r.ok) throw new Error(r.status); return r.arrayBuffer(); })
      .then(data => new Promise((res, rej) => actx.decodeAudioData(data, res, rej)))
      .then(buffer => { loadedTrack = { url, buffer }; return buffer; });
  }

  function stopMusic() {
    musicToken++;
    if (source) { try { source.stop(); } catch (_) { /* уже остановлен */ } source = null; }
  }

  function playMusic(levelNo) {
    stopMusic();
    if (!SAVE.settings.music) return;
    const ctx = audio();
    if (!ctx) return;
    ctx.resume();
    const token = musicToken;
    loadTrack(CONFIG.levels[levelNo].music).then(buffer => {
      if (token !== musicToken || state !== 'play' && state !== 'levelup') return;
      source = ctx.createBufferSource();
      source.buffer = buffer;
      source.loop = true;
      source.connect(gainNode);
      const t = ctx.currentTime;
      gainNode.gain.cancelScheduledValues(t);
      gainNode.gain.setValueAtTime(0, t);
      gainNode.gain.linearRampToValueAtTime(MUSIC_VOLUME, t + 1.5);
      source.start();
      if (state === 'levelup') ctx.suspend();
    }).catch(() => { /* без музыки игра работает так же */ });
  }

  function fadeOutMusic(sec) {
    if (!actx || !source) return;
    const t = actx.currentTime;
    gainNode.gain.cancelScheduledValues(t);
    gainNode.gain.setValueAtTime(gainNode.gain.value, t);
    gainNode.gain.linearRampToValueAtTime(0, t + sec);
    const s = source;
    source = null;
    try { s.stop(t + sec + 0.05); } catch (_) { /* уже остановлен */ }
  }

  function pauseMusic() { if (actx) actx.suspend(); }
  function resumeMusic() { if (actx && SAVE.settings.music) actx.resume(); }

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
    if (!SAVE.settings.music) stopMusic();
    else if (G && (state === 'play' || state === 'levelup')) playMusic(G.levelNo);
  });
  syncSoundButton();

  function startGame(levelNo, gameMode) {
    mode = gameMode || 'free';
    const mods = mode === 'career' ? careerMods(SAVE.career) : null;
    newGame(null, worldHeightFor(window.innerWidth, window.innerHeight), levelNo, mods);
    fx = []; particles = []; smoke = []; banners = [];
    resize();
    state = 'play';
    show(null);
    playMusic(levelNo);
    const head = mode === 'career' ? `День ${SAVE.career.day}: ${G.lv.name}` : `Уровень ${G.levelNo + 1}: ${G.lv.name}`;
    banners.push({ text: head, t: 0, life: 2.6, color: PAL.pink });
    banners.push({ text: 'Разогрев: собирай эмоции!', t: 0, life: 3.2 });
  }

  const LEVEL_COLORS = ['#5dff9e', '#3de0ff', '#ffd23d', '#ff7a3d', '#ff3d8b'];
  const esc = t => String(t).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const starsHtml = n => [0, 1, 2].map(i => `<span class="star${i < n ? '' : ' off'}">&#9733;&#xFE0E;</span>`).join('');
  const money = n => `${n < 0 ? '−' : ''}${Math.abs(Math.round(n))} ₽`;
  const signed = n => Math.round(n) === 0 ? '0 ₽' : `${n < 0 ? '−' : '+'}${Math.abs(Math.round(n))} ₽`;

  function levelButton(i, meta, onClick, disabled) {
    const lv = CONFIG.levels[i];
    const b = document.createElement('button');
    b.className = 'lvl';
    b.disabled = !!disabled;
    b.style.setProperty('--c', LEVEL_COLORS[i % LEVEL_COLORS.length]);
    b.innerHTML = `<span class="lvl-num">${i + 1}</span><span><div class="lvl-name">${esc(lv.name)}</div>` +
      `<div class="lvl-desc">${esc(lv.desc)} Зрителей: ${lv.viewers}.</div>${meta ? `<div class="lvl-meta">${meta}</div>` : ''}</span>`;
    b.addEventListener('click', onClick);
    return b;
  }

  function buildLevelMenu() {
    const box = $('levels');
    box.innerHTML = '';
    CONFIG.levels.forEach((lv, i) => {
      const r = SAVE.records.levels[i];
      const meta = r ? `Рекорд: ${r.bestLeft} из ${r.total} ${starsHtml(r.bestStars)}` : '';
      box.appendChild(levelButton(i, meta, () => startGame(i, 'free')));
    });
  }

  function openMenu() {
    const c = SAVE.career;
    $('career-sub').textContent = c.gigs ? `день ${c.day} · ${money(c.money)} · известность ${c.rep}` : 'начать с пустого вторника';
    show('overlay-start');
  }

  function openCareer() {
    const c = SAVE.career;
    $('day-title').textContent = `День ${c.day}`;
    $('day-money').textContent = money(c.money);
    $('day-money').classList.toggle('neg', c.money < 0);
    $('day-rep').textContent = c.rep;
    $('day-rent').textContent = money(rentFor(c.day));
    const next = CAREER.venues.findIndex((v, i) => !venueUnlocked(c, i));
    $('day-note').textContent = c.won
      ? `Фестиваль покорён на ${c.wonDay}-й день! Можно играть дальше и копить на улучшения.`
      : c.money < 0 ? 'Ты в долгах: магазин закрыт, пока не выйдешь в плюс.'
      : next >= 0 ? `Следующий зал откроется при известности ${CAREER.venues[next].rep}.` : 'Открыты все залы. Покори фестиваль!';
    const box = $('venues');
    box.innerHTML = '';
    CAREER.venues.forEach((v, i) => {
      const open = venueUnlocked(c, i);
      const best = c.best[i] || 0;
      const meta = open
        ? `Гонорар ×${f1(v.pay)} · дорога ${v.travel} ₽ · ${starsHtml(best)}`
        : `Закрыто: нужна известность ${v.rep}`;
      box.appendChild(levelButton(i, meta, () => startGame(i, 'career'), !open));
    });
    show('overlay-career');
  }

  function openShop() {
    const c = SAVE.career;
    $('shop-money').textContent = money(c.money);
    const box = $('shop');
    box.innerHTML = '';
    for (const u of CAREER.upgrades) {
      const l = upgradeLevel(c, u.id), max = u.cost.length;
      const price = upgradePrice(c, u.id);
      const el = document.createElement('div');
      el.className = 'shop-item';
      const shown = u.values[Math.min(l, max - 1)];
      el.innerHTML = `<div class="info"><div class="name">${esc(u.name)}</div>` +
        `<div class="desc">${l >= max ? esc(u.desc(u.values[max - 1])) : (l ? 'Сейчас: ' + esc(u.desc(u.values[l - 1])) + ' Дальше: ' : '') + (l < max ? esc(u.desc(shown)) : '')}</div>` +
        `<div class="card-pips">${u.cost.map((_, i) => `<i class="${i < l ? 'on' : ''}"></i>`).join('')}</div></div>`;
      const b = document.createElement('button');
      b.className = 'buy';
      b.textContent = price == null ? 'Куплено' : `${price} ₽`;
      b.disabled = price == null || c.money < price;
      b.addEventListener('click', () => { if (buyUpgrade(c, u.id)) { persist(); openShop(); } });
      el.appendChild(b);
      box.appendChild(el);
    }
    show('overlay-shop');
  }

  function openRecords() {
    const R = SAVE.records;
    let html = '<div class="rec-head">Лучший результат по уровням</div>';
    CONFIG.levels.forEach((lv, i) => {
      const r = R.levels[i];
      html += `<div class="rec-row"><span>${i + 1}. ${esc(lv.name)}<small>${r ? 'сыграно ' + r.plays : 'ещё не играл'}</small></span>` +
        `<b>${r ? `${r.bestLeft}/${r.total} ${starsHtml(r.bestStars)}` : '—'}</b></div>`;
    });
    html += '<div class="rec-head">Карьера</div>';
    const rows = [
      ['Фестиваль покорён быстрее всего', R.bestWinDay ? `за ${R.bestWinDay} дн.` : '—'],
      ['Сколько раз начинал карьеру', R.careers],
      ['Всего концертов', R.gigs],
      ['Заработано за всё время', money(R.totalEarned)],
    ];
    for (const [k, v] of rows) html += `<div class="rec-row"><span>${k}</span><b>${v}</b></div>`;
    $('records').innerHTML = html;
    show('overlay-records');
  }

  for (const b of document.querySelectorAll('[data-go]')) {
    b.addEventListener('click', () => {
      const id = b.dataset.go;
      if (id === 'overlay-start') openMenu(); else if (id === 'overlay-career') openCareer(); else show(id);
    });
  }
  $('btn-career').addEventListener('click', openCareer);
  $('btn-free').addEventListener('click', () => { buildLevelMenu(); show('overlay-free'); });
  $('btn-records').addEventListener('click', openRecords);
  $('btn-shop').addEventListener('click', openShop);
  $('btn-reset').addEventListener('click', () => {
    if (!window.confirm('Начать карьеру заново? Деньги, известность и покупки обнулятся. Рекорды останутся.')) return;
    SAVE.career = newCareer();
    SAVE.records.careers++;
    persist();
    openCareer();
  });
  openMenu();

  // ---------- ввод ----------
  function toWorld(e) { return { x: (e.clientX - offX) / scale, y: (e.clientY - offY) / scale }; }
  let pointerId = null;
  function setTarget(e) {
    const w = toWorld(e);
    const off = e.pointerType === 'mouse' ? 0 : CONFIG.player.touchOffset;
    G.player.tx = w.x; G.player.ty = w.y - off;
  }
  canvas.addEventListener('pointerdown', e => {
    if (state !== 'play') return;
    pointerId = e.pointerId;
    try { canvas.setPointerCapture(e.pointerId); } catch (_) { /* старые браузеры */ }
    setTarget(e); e.preventDefault();
  });
  canvas.addEventListener('pointermove', e => {
    if (state !== 'play') return;
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
    const career = mode === 'career';
    const isRecord = recordGig(SAVE.records, r.levelNo, r, 0);
    let st = null;
    if (career) {
      st = settleGig(SAVE.career, r.levelNo, r);
      if (st.fee > 0) SAVE.records.totalEarned += st.fee;
      if (st.won) SAVE.records.bestWinDay = Math.min(SAVE.records.bestWinDay || Infinity, st.day);
    }
    persist();

    $('res-title').textContent = st && st.won ? 'Фестиваль покорён!' :
      r.passed ? (career ? 'Отличный вечер!' : last ? 'Все уровни пройдены!' : 'Уровень пройден!') : 'Песня окончена';
    $('res-level').textContent = (career ? `День ${st.day}. ` : `Уровень ${r.levelNo + 1}. `) +
      `${CONFIG.levels[r.levelNo].name}. Цель: удержать больше половины зала.`;
    $('res-verdict').textContent = (isRecord ? 'Новый рекорд! ' : '') + (
      share >= 0.75 ? 'Зал твой! Тебя зовут снова.' :
      share > 0.5 ? 'Хороший сет, бармен доволен.' :
      share >= 0.25 ? 'Половина ушла, но кто-то остался.' : 'Тихий вечер. Попробуй другую сборку.');
    $('res-stars').innerHTML = starsHtml(starsFor(r.left, r.total));
    $('res-left').textContent = `${r.left} из ${r.total}`;
    $('res-money-label').textContent = career ? 'Касса зала' : 'Заработано';
    $('res-money').textContent = `${r.money} ₽`;
    $('res-money-note').textContent = `${r.left} × ${r.perViewer}` + (r.bonus ? ` + ${r.bonus} бонус: осталось больше половины` : ' (бонус +100, если осталось больше половины)') +
      (r.incidents.length ? `. Происшествий: ${r.incidents.length}.` : '');

    const box = $('res-career');
    box.innerHTML = '';
    if (st) {
      const V = CAREER.venues[r.levelNo];
      const rows = [
        ['Гонорар', `×${f1(V.pay)}${r.passed ? '' : ', половина: зал не удержан'}`, signed(st.fee)],
        ['Дорога', '', signed(-st.travel)],
        ['Аренда', '', signed(-st.rent)],
        ['Итого за вечер', '', signed(st.net)],
        ['Известность', '', `+${st.repGain}`],
        ['Деньги', '', money(SAVE.career.money)],
      ];
      box.innerHTML = rows.map(([k, n, v]) => `<div class="res-row"><span>${k}${n ? `<small class="muted"> ${n}</small>` : ''}</span><b>${v}</b></div>`).join('') +
        st.unlocked.map(i => `<p class="note center">Открыт новый зал: <b>${esc(CONFIG.levels[i].name)}</b></p>`).join('') +
        (st.won ? '<p class="note center">Ты звезда городского фестиваля! Карьера продолжается.</p>' : '');
    }
    $('btn-day').classList.toggle('hidden', !career);
    $('btn-next').classList.toggle('hidden', career || !r.passed || last);
    $('btn-again').classList.toggle('hidden', career);
    $('btn-menu').classList.toggle('hidden', career);

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
    show('overlay-results');
  }

  $('btn-next').addEventListener('click', () => startGame(G.levelNo + 1, 'free'));
  $('btn-again').addEventListener('click', () => startGame(G.levelNo, 'free'));
  $('btn-menu').addEventListener('click', () => { buildLevelMenu(); show('overlay-free'); });
  $('btn-day').addEventListener('click', openCareer);

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
    ctx.fillStyle = (Math.sin(clock * 1.7) > -0.95) ? PAL.pink : '#7a2246';
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
      ctx.fillStyle = ((i + Math.floor(clock * 3)) % 3 === 0) ? '#ffe28a' : '#8a5a20';
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

  function drawPlayer() {
    const p = G.player;
    const x = p.x, y = p.y;
    // аура присутствия и радиус подбора
    ctx.fillStyle = stringBroken() ? 'rgba(120,120,130,0.08)' : 'rgba(255,176,58,0.07)';
    ctx.beginPath(); ctx.arc(x, y - 6, auraRadius(), 0, Math.PI * 2); ctx.fill();
    ctx.setLineDash([4, 5]); ctx.strokeStyle = 'rgba(255,210,61,0.45)'; ctx.lineWidth = 1.2;
    ctx.beginPath(); ctx.arc(x, y - 10, pickupRadius(), 0, Math.PI * 2); ctx.stroke();
    ctx.setLineDash([]);

    const step = p.moving ? Math.sin(clock * 14) * 2.5 : 0;
    const strum = Math.sin(clock * 8) * 1.5;
    ctx.fillStyle = 'rgba(0,0,0,0.4)';
    ctx.beginPath(); ctx.ellipse(x, y + 1, 11, 4, 0, 0, Math.PI * 2); ctx.fill();
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(p.dir, 1);
    // ноги
    ctx.fillStyle = '#2b2b3a';
    ctx.fillRect(-5, -8 + step * 0.3, 4, 8 - step * 0.3);
    ctx.fillRect(1, -8 - step * 0.3, 4, 8 + step * 0.3);
    // куртка
    const costume = lvl('costume');
    ctx.fillStyle = costume ? '#ffd23d' : PAL.cyan;
    roundRect(-8, -26, 16, 19, 5); ctx.fill();
    if (costume) {
      ctx.fillStyle = '#fff';
      for (let i = 0; i < costume * 2; i++) {
        const tw = (Math.sin(clock * 5 + i * 2) + 1) / 2;
        ctx.globalAlpha = tw; ctx.fillRect(-6 + (i * 5) % 12, -24 + (i * 7) % 15, 2, 2);
      }
      ctx.globalAlpha = 1;
    }
    // голова и волосы
    ctx.fillStyle = '#f1c9a5';
    ctx.beginPath(); ctx.arc(0, -32, 6.5, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#3a1d10';
    ctx.beginPath(); ctx.arc(0, -34, 7, Math.PI, Math.PI * 2); ctx.fill();
    ctx.fillRect(-7, -34, 3, 7);
    // гитара
    ctx.save();
    ctx.translate(1, -15);
    ctx.rotate(-0.55);
    ctx.fillStyle = '#5a2c10'; ctx.fillRect(4, -2, 20, 3.5);
    ctx.fillStyle = PAL.amber;
    ctx.beginPath(); ctx.ellipse(0, 0, 8, 6, 0, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.ellipse(-6, 0, 6, 5, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#2a160c';
    ctx.beginPath(); ctx.arc(-1, 0, 2, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
    // рука, бьющая по струнам
    ctx.fillStyle = '#f1c9a5';
    ctx.beginPath(); ctx.arc(-2, -15 + strum, 2.6, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
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
    const rest = Math.max(0, CONFIG.songDuration - G.t);
    const m = Math.floor(Math.ceil(rest) / 60), s = Math.ceil(rest) % 60;
    ctx.textBaseline = 'middle';
    ctx.font = 'bold 22px system-ui, sans-serif'; ctx.textAlign = 'left';
    ctx.fillStyle = rest <= 30 ? PAL.pink : PAL.text;
    ctx.fillText(`${m}:${String(s).padStart(2, '0')}`, 12, 23);
    // прогресс песни
    ctx.fillStyle = '#3a2416'; ctx.fillRect(74, 19, 110, 6);
    ctx.fillStyle = PAL.amber; ctx.fillRect(74, 19, 110 * (G.t / CONFIG.songDuration), 6);
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
    const bx = 56, bw = L.W - 56 - 46, by = y0 + 7, bh = 12;
    ctx.fillStyle = '#3a2416'; ctx.fillRect(bx, by, bw, bh);
    ctx.fillStyle = PAL.pink; ctx.fillRect(bx, by, bw * k, bh);
    ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(bx, by, bw * k, 3);
    ctx.textAlign = 'right'; ctx.fillStyle = PAL.text; ctx.font = 'bold 12px system-ui, sans-serif';
    ctx.fillText(`ур. ${G.levelNo + 1}`, L.W - 8, y0 + 13);
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
    const S = CONFIG.incidents.string, x = S.spot.x, y = S.spot.y;
    const broken = stringBroken();
    ctx.fillStyle = '#121212'; ctx.fillRect(x - 13, y - 30, 26, 30);
    ctx.fillStyle = '#2b2b2b'; ctx.beginPath(); ctx.arc(x, y - 13, 8, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = PAL.amber; ctx.fillRect(x - 11, y - 28, 22, 3);
    if (!broken) return;
    const blink = Math.sin(clock * 8) > 0;
    ctx.strokeStyle = blink ? PAL.pink : 'rgba(255,61,139,0.4)'; ctx.lineWidth = 2; ctx.setLineDash([4, 4]);
    ctx.beginPath(); ctx.arc(x, y - 6, S.radius + 4, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
    ring(x, y - 46, 9, G.incident.progress, PAL.green);
    ctx.fillStyle = PAL.text; ctx.font = 'bold 12px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText('!', x, y - 45);
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
    ctx.arc(p.x, p.y - 10, B.light, 0, Math.PI * 2, true);
    ctx.fill('evenodd');
    ctx.restore();
  }

  function drawIncidentChip() {
    const inc = G.incident;
    if (!inc || (inc.type === 'drunk' && inc.leaving)) return;
    const text = inc.type === 'string' ? 'Струна! Беги к усилителю слева' :
      inc.type === 'drunk' ? 'Дебошир! Подойди и постой рядом' :
      `Нет света: ещё ${Math.ceil(CONFIG.incidents.blackout.duration - inc.age)} с`;
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
    const list = G.viewers.filter(v => !v.gone).sort((a, b) => a.y - b.y);
    const p = G.player;
    let drawn = false;
    for (const v of list) {
      if (!drawn && v.y > p.y) { drawPlayer(); drawn = true; }
      drawViewer(v);
    }
    if (!drawn) drawPlayer();
    drawDrunk();
    drawEmotions();
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
    if (G && (state === 'play' || state === 'ending') && !document.hidden) {
      if (state === 'play') { update(dt); handleEvents(); }
      updateVisuals(dt);
    }
    render();
    requestAnimationFrame(frame);
  }

  resize();
  requestAnimationFrame(frame);

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('./sw.js').catch(() => {}));
  }
})();

'use strict';

// =====================================================================
//  Карьера: дни, деньги, известность, магазин, сохранения.
//  Только данные и чистые функции, без DOM: интерфейс живёт в game.js.
// =====================================================================
const CAREER = {
  startMoney: 100,
  // аренда комнаты списывается каждый вечер после концерта
  rent: { base: 70, perDay: 10, max: 260 },
  // если удержал половину зала или меньше, организатор платит только часть
  failPay: 0.5,
  // залы совпадают по номеру с CONFIG.levels
  venues: [
    { pay: 0.7, travel: 0, rep: 0, repPerStar: 1 },
    { pay: 0.9, travel: 10, rep: 4, repPerStar: 1.5 },
    { pay: 1.15, travel: 40, rep: 10, repPerStar: 2 },
    { pay: 1.45, travel: 80, rep: 19, repPerStar: 2.5 },
    { pay: 1.9, travel: 140, rep: 30, repPerStar: 3 },
  ],
  // доля удержанного зала для 1, 2 и 3 звёзд (первая = больше половины, как и цель уровня)
  stars: [0.5, 0.65, 0.8],

  upgrades: [
    {
      id: 'guitar', name: 'Гитара получше', cost: [250, 500, 900], values: [1, 2, 3],
      desc: v => `Аура рядом с тобой даёт +${v} интереса в секунду.`,
      apply: (m, v) => { m.auraGain += v; },
    },
    {
      id: 'shoes', name: 'Удобные кеды', cost: [200, 400, 700], values: [0.1, 0.2, 0.3],
      desc: v => `Музыкант бегает на ${Math.round(v * 100)}% быстрее.`,
      apply: (m, v) => { m.speedMul += v; },
    },
    {
      id: 'rehearsal', name: 'Репетиции', cost: [300, 600, 1000], values: [4, 8, 12],
      desc: v => `Зал начинает песню с интересом на ${v} выше.`,
      apply: (m, v) => { m.startInterest += v; },
    },
    {
      id: 'merch', name: 'Мерч', cost: [200, 450, 800], values: [2, 4, 6],
      desc: v => `+${v} ₽ за каждого оставшегося зрителя.`,
      apply: (m, v) => { m.perViewer += v; },
    },
    {
      id: 'cable', name: 'Длинный шнур', cost: [200, 400, 700], values: [6, 12, 18],
      desc: v => `Радиус сбора эмоций +${v}.`,
      apply: (m, v) => { m.pickup += v; },
    },
    {
      id: 'tech', name: 'Знакомый техник', cost: [250, 600], values: [0.35, 0.65],
      desc: v => `Происшествий на ${Math.round(v * 100)}% меньше, струну чинишь вдвое быстрее.`,
      apply: (m, v) => { m.incidentMul *= 1 - v; m.repairMul = 2; },
    },
    {
      id: 'setlist', name: 'Сет-лист', cost: [800], values: [1],
      desc: () => 'В начале каждого концерта — одна карта на выбор.',
      apply: m => { m.freeCard = true; },
    },
  ],
};

const SAVE_KEY = 'hold-the-room-save-v1';

function newCareer() {
  return { day: 1, money: CAREER.startMoney, rep: 0, upgrades: {}, best: [], won: false, wonDay: null, gigs: 0 };
}

function defaultSave() {
  return {
    v: 1,
    career: newCareer(),
    records: { levels: [], careers: 1, bestWinDay: null, totalEarned: 0, gigs: 0 },
    settings: { music: true },
  };
}

// Сохранение в localStorage. При любой ошибке (приватный режим, битые данные)
// игра работает дальше, просто без сохранений.
function loadSave(storage) {
  const base = defaultSave();
  try {
    const raw = storage && storage.getItem(SAVE_KEY);
    if (!raw) return base;
    const data = JSON.parse(raw);
    if (!data || data.v !== 1) return base;
    return {
      v: 1,
      career: Object.assign(newCareer(), data.career),
      records: Object.assign(base.records, data.records),
      settings: Object.assign(base.settings, data.settings),
    };
  } catch (_) {
    return base;
  }
}

function writeSave(storage, save) {
  try { storage && storage.setItem(SAVE_KEY, JSON.stringify(save)); return true; } catch (_) { return false; }
}

function upgradeLevel(career, id) { return career.upgrades[id] || 0; }

function careerMods(career) {
  const m = { auraGain: 0, speedMul: 1, startInterest: 0, pickup: 0, perViewer: 0, incidentMul: 1, repairMul: 1, freeCard: false };
  for (const u of CAREER.upgrades) {
    const l = upgradeLevel(career, u.id);
    if (l) u.apply(m, u.values[l - 1]);
  }
  return m;
}

function upgradePrice(career, id) {
  const u = CAREER.upgrades.find(x => x.id === id);
  const l = upgradeLevel(career, id);
  return u && l < u.cost.length ? u.cost[l] : null;
}

function buyUpgrade(career, id) {
  const price = upgradePrice(career, id);
  if (price == null || career.money < price) return false;
  career.money -= price;
  career.upgrades[id] = upgradeLevel(career, id) + 1;
  return true;
}

function rentFor(day) {
  const R = CAREER.rent;
  return Math.min(R.max, R.base + R.perDay * (day - 1));
}

function venueUnlocked(career, i) { return career.rep >= CAREER.venues[i].rep; }

function starsFor(left, total) {
  const share = total ? left / total : 0;
  return CAREER.stars.filter(s => share > s).length;
}

// Подводит итог вечера: гонорар, дорога, аренда, известность.
function settleGig(career, levelNo, res) {
  const V = CAREER.venues[levelNo];
  const stars = starsFor(res.left, res.total);
  const fee = Math.round(res.money * V.pay * (res.passed ? 1 : CAREER.failPay));
  const rent = rentFor(career.day);
  const net = fee - V.travel - rent;
  const repGain = Math.round(stars * V.repPerStar * 10) / 10;
  const unlockedBefore = CAREER.venues.map((_, i) => venueUnlocked(career, i));

  career.money += net;
  career.rep = Math.round((career.rep + repGain) * 10) / 10;
  career.gigs++;
  career.best[levelNo] = Math.max(career.best[levelNo] || 0, stars);
  const won = !career.won && levelNo === CAREER.venues.length - 1 && res.passed;
  if (won) { career.won = true; career.wonDay = career.day; }
  const day = career.day;
  career.day++;

  const unlocked = CAREER.venues.map((_, i) => i).filter(i => !unlockedBefore[i] && venueUnlocked(career, i));
  return { day, stars, fee, travel: V.travel, rent, net, repGain, unlocked, won };
}

// Рекорды общие для карьеры и свободной игры.
function recordGig(records, levelNo, res, earned) {
  const r = records.levels[levelNo] || { bestLeft: 0, total: res.total, bestStars: 0, plays: 0 };
  const isBest = res.left > r.bestLeft;
  r.bestLeft = Math.max(r.bestLeft, res.left);
  r.total = res.total;
  r.bestStars = Math.max(r.bestStars, starsFor(res.left, res.total));
  r.plays++;
  records.levels[levelNo] = r;
  records.gigs++;
  if (earned > 0) records.totalEarned += earned;
  return isBest;
}

if (typeof module !== 'undefined') {
  module.exports = {
    CAREER, SAVE_KEY, newCareer, defaultSave, loadSave, writeSave, careerMods, upgradeLevel,
    upgradePrice, buyUpgrade, rentFor, venueUnlocked, starsFor, settleGig, recordGig,
  };
}

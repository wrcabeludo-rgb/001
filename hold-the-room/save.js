'use strict';

// =====================================================================
//  Сохранения: рекорды и настройки. Только данные, без DOM.
//  Тур, «Слава», дерево души, облики, ежедневный вызов — см. tour.js и DESIGN.md.
// =====================================================================
const SAVE_KEY = 'hold-the-room-save-v1';

// Доля удержанного зала для 1, 2 и 3 звёзд (первая = больше половины, как и цель уровня)
const STAR_SHARES = [0.5, 0.65, 0.8];

function defaultSave() {
  return {
    v: 1,
    records: { levels: [], gigs: 0, tours: 0, wins: 0, fameTotal: 0 },
    settings: { music: true },
    profile: { hero: null },            // 'm' | 'f' — выбирается перед первым туром
    fame: 0,                            // «Слава», тратится между турами
    tree: {},                           // дерево способностей души: id -> уровень
    skins: { owned: ['neon'], selected: 'neon' },
    tour: null,                         // текущий тур (сохраняется между вечерами)
    story: { intro: false, talks: 0 },  // сколько разговоров с Михалычем уже было
    daily: {},                          // день -> { left, total }
  };
}

// При любой ошибке (приватный режим, битые данные) игра работает дальше без сохранений.
// Старые сохранения с карьерой читаются: из них берутся только рекорды и настройки.
function loadSave(storage) {
  const base = defaultSave();
  try {
    const raw = storage && storage.getItem(SAVE_KEY);
    if (!raw) return base;
    const data = JSON.parse(raw);
    if (!data || data.v !== 1) return base;
    return {
      v: 1,
      records: Object.assign(base.records, data.records),
      settings: Object.assign(base.settings, data.settings),
      profile: Object.assign(base.profile, data.profile),
      fame: typeof data.fame === 'number' ? data.fame : 0,
      tree: Object.assign({}, data.tree),
      skins: Object.assign(base.skins, data.skins),
      tour: data.tour || null,
      story: Object.assign(base.story, data.story),
      daily: Object.assign({}, data.daily),
    };
  } catch (_) {
    return base;
  }
}

function writeSave(storage, save) {
  try { storage && storage.setItem(SAVE_KEY, JSON.stringify(save)); return true; } catch (_) { return false; }
}

function starsFor(left, total) {
  const share = total ? left / total : 0;
  return STAR_SHARES.filter(s => share > s).length;
}

// Возвращает true, если это новый рекорд зала.
function recordGig(records, levelNo, res) {
  const r = records.levels[levelNo] || { bestLeft: 0, total: res.total, bestStars: 0, plays: 0 };
  const isBest = res.left > r.bestLeft;
  r.bestLeft = Math.max(r.bestLeft, res.left);
  r.total = res.total;
  r.bestStars = Math.max(r.bestStars, starsFor(res.left, res.total));
  r.plays++;
  records.levels[levelNo] = r;
  records.gigs++;
  return isBest;
}

if (typeof module !== 'undefined') {
  module.exports = { SAVE_KEY, defaultSave, loadSave, writeSave, starsFor, recordGig };
}

'use strict';

// =====================================================================
//  Сохранения: рекорды и настройки. Только данные, без DOM.
//  Карьера по дням убрана; туры появятся на этапе 2 (см. DESIGN.md).
// =====================================================================
const SAVE_KEY = 'hold-the-room-save-v1';

// Доля удержанного зала для 1, 2 и 3 звёзд (первая = больше половины, как и цель уровня)
const STAR_SHARES = [0.5, 0.65, 0.8];

function defaultSave() {
  return {
    v: 1,
    records: { levels: [], gigs: 0 },
    settings: { music: true },
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

(function () {
  'use strict';
  const KEY = 'ft_progress_v1';
  const app = document.getElementById('app');

  // ---------- данные ----------
  const Q = window.RAW.map((r, id) => ({
    id, topic: r[0], q: r[1], img: r[8] || '',
    opts: [
      { t: r[2], why: r[3], ok: true },
      { t: r[4], why: r[5], ok: false },
      { t: r[6], why: r[7], ok: false }
    ]
  }));
  const TOPICS = [...new Set(Q.map(q => q.topic))];

  // ---------- прогресс ----------
  function load() { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { return {}; } }
  function save(p) { try { localStorage.setItem(KEY, JSON.stringify(p)); } catch (e) {} }
  let progress = load(); // {id: {ok:bool, n:int}}
  const mistakes = () => Q.filter(q => progress[q.id] && !progress[q.id].ok);
  const learned = () => Q.filter(q => progress[q.id] && progress[q.id].ok);
  const answered = () => Q.filter(q => progress[q.id]);

  const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  // ---------- сессия ----------
  let S = null; // {ids, i, correct, wrong:[ids], title}

  function start(ids, title) {
    if (!ids.length) return;
    S = { ids, i: 0, correct: 0, wrong: [], title };
    quiz();
  }

  // ---------- экраны ----------
  function home() {
    S = null;
    const total = Q.length, l = learned().length, a = answered().length, m = mistakes().length;
    const acc = a ? Math.round(100 * l / a) : 0;
    app.innerHTML = `
      <h1>Экзамен фитнес-тренера</h1>
      <p class="muted">${total} вопросов по билетам. Выберите ответ, и приложение объяснит, почему он верный или неверный.</p>
      <div class="stats">
        <div class="stat"><b>${l}</b><span class="muted">выучено</span></div>
        <div class="stat"><b>${m}</b><span class="muted">ошибок</span></div>
        <div class="stat"><b>${acc}%</b><span class="muted">точность</span></div>
      </div>
      <div class="bar" aria-label="Прогресс"><i style="width:${Math.round(100 * l / total)}%"></i></div>
      <button class="btn" data-a="rand">Случайные 20 вопросов<small>быстрая тренировка</small></button>
      <button class="btn" data-a="new" ${a >= total ? 'disabled' : ''}>Новые вопросы<small>ещё не отвеченные: ${total - a}</small></button>
      <button class="btn alt" data-a="mist" ${m ? '' : 'disabled'}>Работа над ошибками<small>вопросы, где вы ошиблись: ${m}</small></button>
      <button class="btn alt" data-a="topics">По темам<small>${TOPICS.length} тем</small></button>
      <button class="btn alt" data-a="all">Все вопросы подряд<small>в случайном порядке</small></button>
      <footer>Прогресс хранится на этом устройстве и работает без интернета.<br><a href="#" data-a="reset" class="muted">Сбросить прогресс</a></footer>`;
  }

  function topics() {
    app.innerHTML = `<div class="top"><button class="x" data-a="home" aria-label="Назад">←</button><h1>Темы</h1></div>` +
      TOPICS.map((t, i) => {
        const qs = Q.filter(q => q.topic === t);
        const ok = qs.filter(q => progress[q.id] && progress[q.id].ok).length;
        return `<button class="btn alt" data-a="topic" data-i="${i}">${esc(t)}<small>${ok} из ${qs.length} выучено</small></button>`;
      }).join('');
  }

  function quiz() {
    const q = Q[S.ids[S.i]];
    const opts = shuffle(q.opts);
    app.innerHTML = `
      <div class="top"><button class="x" data-a="home" aria-label="Выйти">✕</button>
        <div class="bar"><i style="width:${Math.round(100 * S.i / S.ids.length)}%"></i></div>
        <span class="muted">${S.i + 1}/${S.ids.length}</span></div>
      <span class="tag">${esc(q.topic)}</span>
      ${q.img && window.IMG[q.img] ? `<div class="pic">${window.IMG[q.img]}</div>` : ''}
      <div class="q">${esc(q.q)}</div>
      <div id="opts">${opts.map((o, i) => `<button class="opt" data-a="pick" data-i="${i}">${esc(o.t)}</button>`).join('')}</div>
      <div id="fb"></div>`;
    app._opts = opts;
    window.scrollTo(0, 0);
  }

  function pick(i) {
    const q = Q[S.ids[S.i]], opts = app._opts, chosen = opts[i], right = opts.find(o => o.ok);
    const btns = app.querySelectorAll('.opt');
    btns.forEach((b, k) => { b.disabled = true; if (opts[k].ok) b.classList.add('ok'); else if (k === i) b.classList.add('bad'); });
    const prev = progress[q.id] || { n: 0 };
    progress[q.id] = { ok: chosen.ok, n: prev.n + 1 };
    save(progress);
    if (chosen.ok) S.correct++; else S.wrong.push(q.id);
    const last = S.i + 1 >= S.ids.length;
    const fb = chosen.ok
      ? `<div class="fb ok"><b class="t">✓ Верно</b><p>${esc(chosen.why)}</p></div>`
      : `<div class="fb bad"><b class="t">✗ Неверно</b><p><b>Почему не так:</b> ${esc(chosen.why)}</p></div>
         <div class="fb ok"><b class="t">Правильный ответ: ${esc(right.t)}</b><p>${esc(right.why)}</p></div>`;
    document.getElementById('fb').innerHTML = fb +
      `<button class="btn" data-a="next">${last ? 'Показать итог' : 'Дальше'}</button>`;
    document.querySelector('[data-a="next"]').scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }

  function result() {
    const n = S.ids.length, pct = Math.round(100 * S.correct / n);
    const msg = pct >= 90 ? 'Отлично!' : pct >= 70 ? 'Хороший результат' : 'Есть что повторить';
    const wrong = S.wrong.map(id => Q[id]);
    app.innerHTML = `
      <h1>${msg}</h1>
      <div class="score">${S.correct} / ${n}</div>
      <p class="muted" style="text-align:center">${esc(S.title)} · ${pct}%</p>
      ${wrong.length ? `<div class="card"><b>Повторите:</b>${wrong.map(q => `<div class="row"><span>${esc(q.q)}</span></div>`).join('')}</div>` : ''}
      ${wrong.length ? `<button class="btn" data-a="retry">Пройти ошибки ещё раз<small>${wrong.length} вопр.</small></button>` : ''}
      <button class="btn alt" data-a="home">На главную</button>`;
    S.retry = S.wrong.slice();
  }

  // ---------- события ----------
  app.addEventListener('click', e => {
    const el = e.target.closest('[data-a]'); if (!el) return;
    const a = el.dataset.a; if (a === 'reset' || a === 'pick') { /* ниже */ }
    if (a === 'reset') { e.preventDefault(); if (confirm('Сбросить весь прогресс?')) { progress = {}; save(progress); home(); } return; }
    if (a === 'home') return home();
    if (a === 'topics') return topics();
    if (a === 'topic') { const t = TOPICS[+el.dataset.i]; return start(shuffle(Q.filter(q => q.topic === t).map(q => q.id)), t); }
    if (a === 'rand') return start(shuffle(Q.map(q => q.id)).slice(0, 20), 'Случайные вопросы');
    if (a === 'new') return start(shuffle(Q.filter(q => !progress[q.id]).map(q => q.id)).slice(0, 20), 'Новые вопросы');
    if (a === 'mist') return start(shuffle(mistakes().map(q => q.id)), 'Работа над ошибками');
    if (a === 'all') return start(shuffle(Q.map(q => q.id)), 'Все вопросы');
    if (a === 'pick') return pick(+el.dataset.i);
    if (a === 'next') { S.i++; return S.i >= S.ids.length ? result() : quiz(); }
    if (a === 'retry') return start(shuffle(S.retry), 'Повтор ошибок');
  });

  home();

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
  }
})();

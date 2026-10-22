#!/usr/bin/env python3
"""Видео эффекта (Veo, чёрный фон) → лист кадров WebP для игры.

  python3 tools/fx_convert.py art/fx-pickup.mp4 [--start 0.4 --end 5.2]

Пишет art/fx/<имя>.webp и печатает строку для таблицы FX_ART в game.js.
Тишина в начале и в конце (почти чёрные кадры) отрезается, кадр обрезается по свету,
чёрный «шум» видео опускается в ноль — иначе в режиме «осветление» он даёт серую дымку.
"""
import argparse, math, os, shutil, subprocess, sys, tempfile
from PIL import Image
import numpy as np

# длительность в игре (с), высота кадра в мире, стоит ли кадр низом на точке, сколько кадров
DEFAULTS = {
    'pickup': (0.45, 70, False, 12), 'wave': (0.6, 160, False, 14), 'triple': (0.6, 120, False, 14),
    'chain': (0.8, 150, False, 18), 'climax': (2.0, 340, False, 32), 'evolve': (1.4, 200, False, 26),
    'leave': (0.8, 60, True, 14), 'pyro': (1.1, 160, True, 20), 'smoke': (2.4, 140, False, 24),
    'confetti': (1.8, 300, True, 28), 'string': (0.8, 200, False, 16), 'blackout': (1.2, 180, False, 20),
    'alarm': (1.0, 120, False, 16), 'party': (1.2, 200, False, 18), 'blogger': (1.2, 110, False, 18),
    'lastcall': (1.5, 120, False, 22), 'feedback': (0.9, 260, False, 16), 'fight': (0.9, 110, False, 16),
    'fear': (0.9, 300, False, 18),
}
# эти эффекты растут из центра кадра: обрезка симметрична, чтобы центр вспышки совпал с точкой в игре
CENTERED = {'pickup', 'wave', 'triple', 'climax', 'evolve', 'string', 'alarm', 'blogger', 'feedback', 'fight', 'fear'}
# эти эффекты игра перекрашивает в цвет эмоции или карты: лист сохраняется в оттенках серого
TINTED = {'pickup', 'wave', 'triple', 'chain', 'leave'}
MAX_SIDE = {'climax': 384, 'confetti': 320, 'feedback': 320, 'fear': 320}
FLOOR = 14   # всё темнее — чистый чёрный
LIT = 28     # порог «здесь есть свет» для обрезки


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('video')
    ap.add_argument('--name')
    ap.add_argument('--start', type=float)
    ap.add_argument('--end', type=float)
    ap.add_argument('--out', default=os.path.join(os.path.dirname(__file__), '..', 'art', 'fx'))
    a = ap.parse_args()
    name = a.name or os.path.basename(a.video).split('.')[0].replace('fx-', '')
    dur, size, bottom, n = DEFAULTS[name]
    tmp = tempfile.mkdtemp()
    try:
        cmd = ['ffmpeg', '-v', 'error', '-y']
        if a.start is not None: cmd += ['-ss', str(a.start)]
        if a.end is not None: cmd += ['-to', str(a.end)]
        cmd += ['-i', a.video, '-vf', 'scale=640:-2', os.path.join(tmp, 'f%04d.png')]
        subprocess.run(cmd, check=True)
        files = sorted(f for f in os.listdir(tmp) if f.endswith('.png'))
        frames = [np.asarray(Image.open(os.path.join(tmp, f)).convert('RGB')).astype(np.float32) for f in files]
        lum = [fr.max(2) for fr in frames]
        lit = [i for i, l in enumerate(lum) if (l > LIT).sum() > 30]
        if not lit: sys.exit('в видео нет света')
        i0, i1 = lit[0], lit[-1]
        # длинный тусклый хвост отрезается: конец — последний кадр, где света хотя бы 10% от пика
        energy = [float(np.clip(l - FLOOR, 0, None).sum()) for l in lum]
        peak = max(energy)
        while i1 > i0 and energy[i1] < 0.1 * peak: i1 -= 1
        # свет, который держится хотя бы в 5% кадров: вспышки-блики и водяной знак не раздувают рамку
        cnt = np.zeros(lum[0].shape, np.int32)
        for i in range(i0, i1 + 1): cnt += lum[i] > LIT
        ys, xs = np.nonzero(cnt >= max(2, 0.05 * (i1 - i0 + 1)))
        pad = 6
        H, W = cnt.shape
        x0, x1 = max(0, xs.min() - pad), min(W, xs.max() + pad)
        y0, y1 = max(0, ys.min() - pad), min(H, ys.max() + pad)
        if name in CENTERED:
            rx = max(W / 2 - x0, x1 - W / 2); ry = max(H / 2 - y0, y1 - H / 2)
            x0, x1 = int(max(0, W / 2 - rx)), int(min(W, W / 2 + rx))
            y0, y1 = int(max(0, H / 2 - ry)), int(min(H, H / 2 + ry))
        cw, ch = x1 - x0, y1 - y0
        k = min(1, MAX_SIDE.get(name, 256) / max(cw, ch))
        w, h = max(1, round(cw * k)), max(1, round(ch * k))
        pick = [round(i0 + (i1 - i0) * j / max(1, n - 1)) for j in range(n)]
        cols = math.ceil(math.sqrt(n)); rows = math.ceil(n / cols)
        sheet = Image.new('RGB', (cols * w, rows * h))
        # мягкое затухание к краям кадра: если эффект в видео упирался в край, среза не видно
        fy = np.minimum(np.arange(ch), np.arange(ch)[::-1]) / (0.12 * ch)
        fx = np.minimum(np.arange(cw), np.arange(cw)[::-1]) / (0.12 * cw)
        feather = (np.clip(fy, 0, 1)[:, None] * np.clip(fx, 0, 1)[None, :])[..., None]
        for j, i in enumerate(pick):
            fr = frames[i][y0:y1, x0:x1]
            fr = np.clip((fr - FLOOR) * 255 / (255 - FLOOR) * feather, 0, 255).astype(np.uint8)
            sheet.paste(Image.fromarray(fr).resize((w, h), Image.LANCZOS), ((j % cols) * w, (j // cols) * h))
        os.makedirs(a.out, exist_ok=True)
        dst = os.path.join(a.out, name + '.webp')
        if name in TINTED: sheet = sheet.convert('L').convert('RGB')
        sheet.save(dst, 'WEBP', quality=88, method=6)
        meta = {'frames': n, 'cols': cols, 'w': w, 'h': h, 'dur': dur, 'size': size, 'bottom': bottom}
        print('    ' + name + ': { ' + ', '.join(f'{k}: {str(v).lower()}' for k, v in meta.items()) + ' },')
        print(f'  {dst}: {os.path.getsize(dst) // 1024} КБ, свет в кадрах {i0}–{i1} из {len(frames)}', file=sys.stderr)
    finally:
        shutil.rmtree(tmp)


if __name__ == '__main__':
    main()

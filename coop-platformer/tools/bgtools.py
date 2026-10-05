"""Helpers for preparing parallax layers: white-to-alpha and seamless tiling via a min-cost seam."""
import numpy as np
from PIL import Image


def white_to_alpha(img):
    """GIMP-style colour-to-alpha against pure white: keeps soft smoke semi-transparent."""
    a = np.asarray(img.convert('RGB')).astype(np.float32) / 255.0
    alpha = np.max(1.0 - a, axis=2)
    safe = np.maximum(alpha, 1e-6)[..., None]
    rgb = (a - (1.0 - alpha[..., None])) / safe
    rgb = np.clip(rgb, 0, 1)
    out = np.dstack([rgb, alpha])
    return Image.fromarray((out * 255).round().astype(np.uint8), 'RGBA')


def make_seamless(img, overlap=360, feather=6):
    """The last `overlap` columns are merged into the first ones along the least visible vertical seam,
    so the result (width W - overlap) tiles without a visible joint."""
    a = np.asarray(img.convert('RGBA')).astype(np.float32) / 255.0
    h, w, _ = a.shape
    k = overlap
    right = a[:, w - k:]          # continues from the end of the image
    left = a[:, :k]               # original beginning
    pm = lambda x: np.dstack([x[..., :3] * x[..., 3:], x[..., 3:]])
    cost = np.sum((pm(right) - pm(left)) ** 2, axis=2)
    # keep the seam away from the strip borders
    cost[:, :feather + 2] += 1e3
    cost[:, -(feather + 2):] += 1e3
    acc = cost.copy()
    back = np.zeros((h, k), dtype=np.int32)
    for y in range(1, h):
        prev = acc[y - 1]
        cand = np.vstack([np.r_[np.inf, prev[:-1]], prev, np.r_[prev[1:], np.inf]])
        idx = np.argmin(cand, axis=0)
        back[y] = idx - 1
        acc[y] += cand[idx, np.arange(k)]
    seam = np.zeros(h, dtype=np.int32)
    seam[-1] = int(np.argmin(acc[-1]))
    for y in range(h - 1, 0, -1):
        seam[y - 1] = seam[y] + back[y, seam[y]]
    xs = np.arange(k)[None, :]
    t = np.clip((xs - seam[:, None]) / (2 * feather) + 0.5, 0, 1)[..., None]   # 0 -> right strip, 1 -> left strip
    merged = right * (1 - t) + left * t
    out = a[:, :w - k].copy()
    out[:, :k] = merged
    return Image.fromarray((np.clip(out, 0, 1) * 255).round().astype(np.uint8), 'RGBA'), seam

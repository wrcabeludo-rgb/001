"""Synthesizes the game's sound effects (no samples, no licences to worry
about). Re-run after changing anything here:

    python3 tools/audio_synth.py

Writes game/assets/audio/sfx/*.wav, except the sounds that now come from
recordings (tools/sfx_import.py). The game's music now comes from
tools/music_import.py; the old synthesized loops are still here and are
written to game/assets/audio/music/*.ogg only with --music (needs ffmpeg
with libvorbis) — that replaces the imported music.
"""
import os
import subprocess
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sfx_import import SOUNDS as RECORDED  # noqa: E402

RATE = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "audio")
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- basics

def t_axis(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def midi_hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def phase_of(freq, seconds):
    """Phase (in cycles) for a frequency that may change over time."""
    n = int(seconds * RATE)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if np.ndim(freq) == 0 else np.asarray(freq)
    return np.cumsum(f) / RATE


def osc(kind, freq, seconds):
    ph = phase_of(freq, seconds)
    if kind == "sine":
        return np.sin(2 * np.pi * ph)
    if kind == "square":
        return np.sign(np.sin(2 * np.pi * ph))
    if kind == "saw":
        return 2.0 * (ph % 1.0) - 1.0
    if kind == "tri":
        return 2.0 * np.abs(2.0 * (ph % 1.0) - 1.0) - 1.0
    raise ValueError(kind)


def noise(seconds):
    return rng.uniform(-1, 1, int(seconds * RATE))


def env(seconds, attack=0.005, decay=0.1, sustain=0.0, release=0.05, hold=None):
    """ADSR envelope; `hold` is how long the note is held before release."""
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    hold = seconds - release if hold is None else hold
    e = np.where(t < attack, t / max(attack, 1e-6), 1.0)
    after = np.clip(t - attack, 0, None)
    e = np.where(t >= attack, sustain + (1 - sustain) * np.exp(-after / max(decay, 1e-6)), e)
    rel = np.clip((t - hold) / max(release, 1e-6), 0, 1)
    return e * (1 - rel)


def lowpass(x, cutoff, resonance=0.0):
    """Lowpass in the frequency domain (fast, no scipy); `cutoff` in Hz."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / RATE)
    response = 1 / np.sqrt(1 + (f / cutoff) ** 4)
    if resonance:
        response *= 1 + resonance * np.exp(-((f - cutoff) / (cutoff * 0.15)) ** 2)
    return np.fft.irfft(spec * response, len(x))


def highpass(x, cutoff):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / RATE)
    return np.fft.irfft(spec * (1 - 1 / np.sqrt(1 + (f / cutoff) ** 4)), len(x))


def echo(x, delay, feedback, taps=6):
    out = x.copy()
    d = int(delay * RATE)
    for k in range(1, taps + 1):
        if d * k >= len(x):
            break
        out[d * k:] += x[:-d * k] * feedback ** k
    return out


def reverb(x, size=1.0, mix=0.3):
    wet = np.zeros_like(x)
    for delay, gain in [(0.0297, 0.7), (0.0371, 0.65), (0.0411, 0.6), (0.0437, 0.55)]:
        wet += echo(x, delay * size * 1.7, gain, taps=12)
    wet = lowpass(wet, 5000)
    return x * (1 - mix) + wet * mix * 0.35


def normalize(x, peak=0.9):
    m = np.max(np.abs(x))
    return x if m == 0 else x / m * peak


def write_wav(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = np.clip(x, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1 if data.ndim == 1 else 2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes() if data.ndim == 1 else pcm.T.reshape(-1).tobytes())


# ---------------------------------------------------------------- sound effects

def sweep(f0, f1, seconds, curve=2.0):
    t = np.linspace(0, 1, int(seconds * RATE))
    return f0 + (f1 - f0) * (1 - (1 - t) ** curve)


def sfx():
    s = {}
    d = 0.12
    s["shoot"] = lowpass(osc("square", sweep(1400, 300, d), d) * env(d, 0.001, 0.05) * 0.5
                         + noise(d) * env(d, 0.001, 0.02) * 0.4, 6000)
    d = 0.45
    s["shoot_charged"] = lowpass(osc("saw", sweep(900, 80, d), d) * env(d, 0.001, 0.2)
                                 + noise(d) * env(d, 0.001, 0.12) * 0.7, 3500)
    d = 0.25
    s["charge_ready"] = osc("sine", sweep(600, 1600, d, 1), d) * env(d, 0.01, 0.1, 0.4, 0.08) * 0.6
    d = 0.18
    s["kick"] = lowpass(noise(d) * env(d, 0.001, 0.04) + osc("sine", sweep(180, 60, d), d) * env(d, 0.001, 0.08), 1800)
    d = 0.16
    s["slash"] = highpass(noise(d) * env(d, 0.01, 0.06), 1500) * np.linspace(0.6, 1, int(d * RATE))
    d = 0.3
    s["slash_heavy"] = (highpass(noise(d) * env(d, 0.01, 0.1), 900)
                        + osc("saw", sweep(300, 90, d), d) * env(d, 0.001, 0.12) * 0.5)
    d = 0.15
    s["block"] = osc("square", 1800, d) * env(d, 0.001, 0.03) * 0.4 + osc("square", 2300, d) * env(d, 0.001, 0.05) * 0.3
    d = 0.14
    s["jump"] = osc("square", sweep(300, 700, d, 1), d) * env(d, 0.002, 0.08) * 0.35
    s["double_jump"] = osc("square", sweep(500, 1100, d, 1), d) * env(d, 0.002, 0.08) * 0.35
    d = 0.22
    s["dash"] = lowpass(noise(d), 2500) * env(d, 0.02, 0.1) * np.linspace(0.3, 1, int(d * RATE)) ** 0.5
    d = 0.08
    s["land"] = lowpass(noise(d) * env(d, 0.001, 0.025), 600)
    d = 0.3
    s["hurt"] = osc("saw", sweep(500, 150, d), d) * env(d, 0.001, 0.12) * 0.6 + noise(d) * env(d, 0.001, 0.04) * 0.3
    d = 0.9
    s["death"] = lowpass(osc("saw", sweep(400, 40, d, 1.2), d) * env(d, 0.001, 0.5) + noise(d) * env(d, 0.001, 0.3) * 0.4, 1500)
    d = 0.1
    s["hit"] = lowpass(noise(d) * env(d, 0.001, 0.03) + osc("square", sweep(260, 120, d), d) * env(d, 0.001, 0.04) * 0.6, 3000)
    d = 0.45
    s["enemy_die"] = lowpass(noise(d) * env(d, 0.001, 0.15) + osc("saw", sweep(220, 50, d), d) * env(d, 0.001, 0.2) * 0.6, 2200)
    d = 0.18
    s["telegraph"] = (osc("square", 980, d) * env(d, 0.001, 0.05, hold=0.06) + osc("square", 1310, d) * env(d, 0.08, 0.05)) * 0.3
    d = 0.3
    s["pickup_health"] = sum(osc("sine", midi_hz(n), d) * env(d, 0.005, 0.15) * (0.4 if i else 0.5)
                             for i, n in enumerate([72, 76, 79]))
    d = 0.18
    s["pickup_ammo"] = osc("square", sweep(800, 1500, d, 1), d) * env(d, 0.002, 0.08) * 0.3
    d = 0.12
    s["pickup_scrap"] = osc("tri", 1760, d) * env(d, 0.001, 0.05) * 0.5 + osc("tri", 2637, d) * env(d, 0.03, 0.05) * 0.4
    d = 1.0
    s["checkpoint"] = reverb(sum(np.concatenate([np.zeros(int(i * 0.09 * RATE)), osc("sine", midi_hz(n), d - i * 0.09)
                                                 * env(d - i * 0.09, 0.005, 0.3)]) for i, n in enumerate([67, 71, 74, 79])), 1.2, 0.4)
    d = 1.2
    boom = lowpass(noise(d), 900) * env(d, 0.001, 0.35) + osc("sine", sweep(120, 30, d), d) * env(d, 0.001, 0.4)
    s["explosion"] = reverb(boom, 1.0, 0.25)
    d = 0.7
    s["door"] = lowpass(osc("saw", sweep(70, 90, d), d) * env(d, 0.05, 0.4, 0.6, 0.15) + noise(d) * 0.2 * env(d, 0.05, 0.3), 800)
    d = 0.2
    s["lever"] = lowpass(noise(d) * env(d, 0.001, 0.02), 3000) + osc("square", 300, d) * env(d, 0.06, 0.04) * 0.3
    d = 0.5
    s["laser"] = osc("saw", 220 + 40 * np.sin(2 * np.pi * 30 * t_axis(d)), d) * env(d, 0.01, 0.3, 0.5, 0.1) * 0.25
    d = 0.8
    s["flame"] = lowpass(noise(d), 1200) * env(d, 0.05, 0.4, 0.7, 0.2)
    d = 0.35
    s["crumble"] = lowpass(noise(d) * env(d, 0.001, 0.15), 1100) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 18 * t_axis(d))))
    d = 0.5
    s["splash"] = lowpass(noise(d) * env(d, 0.005, 0.15), 1600) + osc("sine", sweep(500, 200, d), d) * env(d, 0.005, 0.1) * 0.3
    d = 1.4
    s["arena"] = reverb(osc("saw", 110, d) * env(d, 0.02, 0.8) * 0.5 + osc("saw", 116.5, d) * env(d, 0.02, 0.8) * 0.5, 1.4, 0.4)
    d = 1.6
    roar = lowpass(osc("saw", 70 + 25 * np.sin(2 * np.pi * 6 * t_axis(d)), d) + noise(d) * 0.6, 900) * env(d, 0.15, 0.7, 0.5, 0.4)
    s["boss_roar"] = reverb(roar, 1.6, 0.35)
    d = 0.9
    s["boss_slam"] = reverb(lowpass(noise(d), 500) * env(d, 0.001, 0.25) + osc("sine", sweep(90, 25, d), d) * env(d, 0.001, 0.35), 1.2, 0.3)
    d = 0.35
    s["boss_spit"] = lowpass(noise(d) * env(d, 0.01, 0.12), 1400) + osc("sine", sweep(300, 120, d), d) * env(d, 0.01, 0.1) * 0.4
    d = 0.08
    s["menu_move"] = osc("square", 880, d) * env(d, 0.001, 0.03) * 0.25
    d = 0.2
    s["menu_select"] = osc("square", sweep(660, 1320, d, 1), d) * env(d, 0.001, 0.1) * 0.3
    d = 2.2
    s["level_complete"] = reverb(sum(np.concatenate([np.zeros(int(i * 0.16 * RATE)), (osc("saw", midi_hz(n), d - i * 0.16)
                                                     + osc("saw", midi_hz(n) * 1.005, d - i * 0.16)) * env(d - i * 0.16, 0.01, 0.6) * 0.3])
                                     for i, n in enumerate([60, 64, 67, 72, 76])), 1.4, 0.45)
    d = 1.4
    s["coin_shop"] = sum(np.concatenate([np.zeros(int(i * 0.07 * RATE)), osc("tri", midi_hz(n), d - i * 0.07) * env(d - i * 0.07, 0.002, 0.2)])
                         for i, n in enumerate([84, 88, 91]))[: int(0.6 * RATE)]
    # Sounds taken from recordings (tools/sfx_import.py) are not overwritten.
    made = [name for name in s if name not in RECORDED]
    for name in made:
        write_wav(os.path.join(ROOT, "sfx", name + ".wav"), normalize(s[name], 0.85))
    return made


# ---------------------------------------------------------------- music

def place(buf, start, x, gain=1.0):
    i = int(start * RATE)
    end = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:end] += x[: end - i] * gain


def synth_note(kind, note, seconds, cutoff, attack=0.005, decay=0.2, sustain=0.5, release=0.08, detune=0.0, resonance=0.0):
    f = midi_hz(note)
    x = osc(kind, f, seconds)
    if detune:
        x = 0.5 * x + 0.5 * osc(kind, f * (1 + detune), seconds)
    x *= env(seconds, attack, decay, sustain, release)
    return lowpass(x, cutoff, resonance)


def kick(seconds=0.35):
    return osc("sine", sweep(150, 45, seconds, 3), seconds) * env(seconds, 0.001, 0.18)


def snare(seconds=0.25):
    return highpass(noise(seconds), 1200) * env(seconds, 0.001, 0.08) + osc("tri", 190, seconds) * env(seconds, 0.001, 0.05) * 0.5


def hat(seconds=0.06):
    return highpass(noise(seconds), 7000) * env(seconds, 0.001, 0.02)


CHORDS = {"m": [0, 3, 7], "M": [0, 4, 7], "m7": [0, 3, 7, 10], "M7": [0, 4, 7, 11], "s4": [0, 5, 7]}


def song(name, bpm, progression, bars, layers, seed, key_shift=0, lead=False, dark=1.0):
    """A looping track. `progression` is a list of (root midi, chord) per bar."""
    local = np.random.default_rng(seed)
    beat = 60.0 / bpm
    step = beat / 4
    length = bars * 4 * beat
    tail = 2.5
    mix = {k: np.zeros(int((length + tail) * RATE)) for k in ["bass", "arp", "pad", "drums", "lead"]}
    melody = []
    for bar in range(bars):
        root, kind = progression[bar % len(progression)]
        root += key_shift
        chord = CHORDS[kind]
        start = bar * 4 * beat
        section = layers(bar)
        if "pad" in section:
            for n in chord:
                place(mix["pad"], start, synth_note("saw", root + 12 + n, 4 * beat, 900 * dark, 0.4, 1.5, 0.7, 0.4, 0.006), 0.18)
        if "bass" in section:
            pattern = [1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1] if "drive" in section else [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0]
            for i, on in enumerate(pattern):
                if on:
                    octave = 12 if (i % 8 == 6 and "drive" in section) else 0
                    place(mix["bass"], start + i * step, synth_note("saw", root - 12 + octave, step * 1.1, 380 * dark, 0.003, 0.12, 0.3, 0.03, 0.004, 1.5), 0.5)
        if "arp" in section:
            notes = [root + 24 + chord[i % len(chord)] + (12 if i % 8 >= 4 else 0) for i in range(16)]
            for i, n in enumerate(notes):
                place(mix["arp"], start + i * step, synth_note("square", n, step * 0.9, 2600 * dark, 0.002, 0.08, 0.1, 0.02), 0.11)
        if "drums" in section:
            for i in range(16):
                if i % 4 == 0 or ("drive" in section and i == 10):
                    place(mix["drums"], start + i * step, kick(), 0.85)
                if i % 8 == 4:
                    place(mix["drums"], start + i * step, snare(), 0.45)
                if i % 2 == 0 or "drive" in section:
                    place(mix["drums"], start + i * step, hat(), 0.18 if i % 4 == 2 else 0.1)
        if lead and "lead" in section:
            if bar % 2 == 0 or not melody:
                melody = [root + 24 + local.choice(chord + [12]) for _ in range(8)]
            rhythm = [2, 1, 1, 2, 2, 3, 1, 4]
            pos = 0
            for i, n in enumerate(melody):
                length_steps = rhythm[i % len(rhythm)]
                if pos + length_steps > 16:
                    break
                if local.random() > 0.15:
                    place(mix["lead"], start + pos * step, synth_note("saw", n, step * length_steps, 2200 * dark, 0.01, 0.3, 0.6, 0.1, 0.008), 0.16)
                pos += length_steps
    out = (reverb(mix["pad"], 1.6, 0.5) + mix["bass"] + echo(mix["arp"], beat * 0.75, 0.35)
           + mix["drums"] + reverb(echo(mix["lead"], beat * 0.5, 0.3), 1.2, 0.35))
    # Fold the tail back to the start so the loop is seamless.
    n = int(length * RATE)
    looped = out[:n].copy()
    looped[: len(out) - n] += out[n:]
    stereo = np.stack([looped, np.roll(looped, int(0.012 * RATE)) * 0.97])
    path = os.path.join(ROOT, "music", name + ".ogg")
    tmp = path + ".wav"
    write_wav(tmp, normalize(stereo, 0.8))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", path], check=True)
    os.remove(tmp)
    return name


def music():
    names = []
    # Menu: slow and wide, minor with a lifting major chord.
    names.append(song("menu", 84, [(45, "m7"), (41, "M7"), (36, "M"), (43, "s4")], 16,
                      lambda b: {"pad", "arp"} | ({"bass"} if b >= 4 else set()) | ({"lead"} if b >= 8 else set()),
                      seed=1, lead=True))
    # 1-1 Slums: driving synthwave.
    names.append(song("zone_1_1", 112, [(45, "m"), (41, "M"), (43, "M"), (40, "m")], 32,
                      lambda b: {"pad", "bass", "arp"} | ({"drums"} if b >= 4 else set())
                      | ({"drive", "lead"} if 8 <= b < 24 else set()), seed=2, lead=True))
    # 1-2 Flooded metro: darker, echoing, slower.
    names.append(song("zone_1_2", 100, [(38, "m"), (38, "m7"), (46, "M"), (45, "s4")], 32,
                      lambda b: {"pad", "bass"} | ({"arp"} if b >= 2 else set()) | ({"drums"} if b >= 6 else set())
                      | ({"lead"} if 12 <= b < 28 else set()), seed=3, lead=True, dark=0.75))
    # 1-3 Main drain: tense and fast.
    names.append(song("zone_1_3", 122, [(40, "m"), (41, "M"), (40, "m"), (47, "M")], 32,
                      lambda b: {"bass", "arp", "pad"} | ({"drums", "drive"} if b >= 4 else set())
                      | ({"lead"} if b >= 16 else set()), seed=4, lead=True, dark=0.85))
    # Boss: aggressive.
    names.append(song("boss", 140, [(40, "m"), (40, "m"), (43, "M"), (42, "s4")], 32,
                      lambda b: {"bass", "drums", "drive", "arp", "pad"} | ({"lead"} if b >= 8 else set()),
                      seed=5, lead=True, dark=1.1))
    # Shop: calm.
    names.append(song("shop", 92, [(48, "M7"), (45, "m7"), (41, "M7"), (43, "M")], 16,
                      lambda b: {"pad", "arp", "bass"} | ({"lead"} if b >= 8 else set()), seed=6, lead=True, dark=0.9))
    return names


if __name__ == "__main__":
    print("sfx:", ", ".join(sfx()))
    if "--music" in sys.argv:
        print("music:", ", ".join(music()))

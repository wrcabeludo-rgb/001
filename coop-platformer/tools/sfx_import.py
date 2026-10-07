"""Recorded sound effects from free CC0 packs (Kenney, OpenGameArt).

Run: python3 tools/sfx_import.py
Downloads the packs (about 12 MB), takes the file chosen for each game sound, trims silence,
cuts it to a sane length, makes it mono and evens out the peak level, and saves
game/assets/audio/sfx/<name>.wav. Sounds not listed here stay synthesized
(tools/audio_synth.py). Sources and licences: CREDITS.md."""
import os
import subprocess
import tempfile
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "game", "assets", "audio", "sfx")

KENNEY = "https://kenney.nl/media/pages/assets/"
OGA = "https://opengameart.org/sites/default/files/"
# pack: (download, author) — every pack is CC0.
PACKS = {
    "impact": (KENNEY + "impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip", "Kenney"),
    "scifi": (KENNEY + "sci-fi-sounds/6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip", "Kenney"),
    "rpg": (KENNEY + "rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip", "Kenney"),
    "interface": (KENNEY + "interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip", "Kenney"),
    "digital": (KENNEY + "digital-audio/216eac4753-1677590265/kenney_digital-audio.zip", "Kenney"),
    "creatures": (OGA + "80-CC0-creature-SFX_0.zip", "Chasersgaming"),
    "creatures2": (OGA + "80-CC0-creature-sfx-2.zip", "Dread Knight"),
    "swishes": (OGA + "swishes.zip", "qubodup"),
    "swords": (OGA + "sword_-_starninjas_1.zip", "MedicineStorm"),
    "clashes": (OGA + "sword_clash_-_starninjas_0.zip", "MedicineStorm"),
    "splash": (OGA + "water-splash-slime-sfx.zip", "rockseller"),
    "bang": (OGA + "25-CC0-bang-sfx.zip", "Snabisch"),
    "mud": (OGA + "25-CC0-mud-sfx.zip", "Bonsaiheldin"),
    "gunshots": (OGA + "Black%20Powder.wav", "LarkPay"),
    "roar": (OGA + "monster_roar.wav", "OpenGameArt (CC0 Deep Monster Roar)"),
}

# game sound: (pack, file name in the pack, longest length in seconds, peak in dBFS)
SOUNDS = {
    "shoot": ("scifi", "laserSmall_000.ogg", 0.4, -3),
    "shoot_charged": ("scifi", "laserLarge_000.ogg", 0.9, -1),
    "shotgun": ("gunshots", "Black Powder.wav", 0.9, -1),
    "charge_ready": ("digital", "powerUp2.ogg", 0.6, -4),
    "kick": ("impact", "impactPunch_heavy_000.ogg", 0.5, -1),
    "slash": ("swishes", "swish-7.wav", 0.4, -2),
    "slash_heavy": ("swords", "sword.3.ogg", 0.8, -1),
    "block": ("clashes", "sword_clash.1.ogg", 0.7, -2),
    "jump": ("rpg", "cloth2.ogg", 0.3, -4),
    "double_jump": ("swishes", "swish-8.wav", 0.4, -4),
    "dash": ("scifi", "thrusterFire_000.ogg", 0.5, -3),
    "land": ("impact", "footstep_concrete_000.ogg", 0.3, -3),
    "hurt": ("impact", "impactPunch_medium_000.ogg", 0.5, -1),
    "hit": ("mud", "mud_01.ogg", 0.4, -2),
    "enemy_die": ("creatures2", "die_01.ogg", 1.2, -2),
    "telegraph": ("creatures2", "attack_03.ogg", 0.8, -4),
    "pickup_health": ("digital", "powerUp5.ogg", 0.7, -4),
    "pickup_ammo": ("rpg", "metalLatch.ogg", 0.5, -3),
    "pickup_scrap": ("rpg", "handleCoins.ogg", 0.6, -3),
    "checkpoint": ("interface", "confirmation_002.ogg", 1.0, -3),
    "explosion": ("bang", "bang_01.ogg", 2.0, -1),
    "door": ("scifi", "doorOpen_000.ogg", 1.2, -3),
    "lever": ("rpg", "metalClick.ogg", 0.5, -2),
    "laser": ("scifi", "laserLarge_002.ogg", 0.8, -4),
    "flame": ("scifi", "thrusterFire_002.ogg", 1.0, -3),
    "crumble": ("impact", "impactMining_000.ogg", 0.8, -2),
    "splash": ("splash", "splash_01.ogg", 1.0, -3),
    "arena": ("impact", "impactBell_heavy_000.ogg", 1.8, -2),
    "boss_roar": ("roar", "monster_roar.wav", 2.5, -1),
    "boss_slam": ("scifi", "lowFrequency_explosion_000.ogg", 1.8, -1),
    "boss_spit": ("splash", "slime_05.ogg", 0.8, -2),
    "menu_move": ("interface", "tick_001.ogg", 0.2, -6),
    "menu_select": ("interface", "select_002.ogg", 0.4, -4),
    "coin_shop": ("rpg", "handleCoins2.ogg", 0.8, -3),
}


def fetch(tmp, pack):
    url = PACKS[pack][0]
    folder = os.path.join(tmp, pack)
    if not os.path.isdir(folder):
        os.makedirs(folder)
        target = os.path.join(folder, urllib.request.url2pathname(url.rsplit("/", 1)[1]))
        request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with open(target, "wb") as f:
            f.write(urllib.request.urlopen(request, timeout=120).read())
        if target.endswith(".zip"):
            zipfile.ZipFile(target).extractall(folder)
    return folder


def find(folder, name):
    for root, _, files in os.walk(folder):
        if name in files and "__MACOSX" not in root:
            return os.path.join(root, name)
    raise FileNotFoundError(name)


def convert(source, target, longest, peak):
    # Trim the silence in front, cut to length with a short fade, then set the peak.
    trimmed = target + ".tmp.wav"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", source, "-af",
                    "silenceremove=start_periods=1:start_threshold=-45dB,atrim=0:%s,afade=t=out:st=%s:d=0.05"
                    % (longest, max(0.0, longest - 0.05)), "-ac", "1", "-ar", "44100", trimmed], check=True)
    level = subprocess.run(["ffmpeg", "-i", trimmed, "-af", "volumedetect", "-f", "null", "-"],
                           capture_output=True, text=True).stderr
    max_volume = float(level.split("max_volume:")[1].split("dB")[0])
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", trimmed, "-af", "volume=%sdB" % (peak - max_volume),
                    "-c:a", "pcm_s16le", target], check=True)
    os.remove(trimmed)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        for name, (pack, file, longest, peak) in SOUNDS.items():
            convert(find(fetch(tmp, pack), file), os.path.join(OUT, name + ".wav"), longest, peak)
            print("sfx:", name, "<-", pack, file)


if __name__ == "__main__":
    main()

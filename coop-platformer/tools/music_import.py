"""Music for the game from incompetech.com (Kevin MacLeod, CC BY 4.0).

Run: python3 tools/music_import.py
Downloads each track, trims silence at the ends, evens out loudness and saves
an Ogg loop to game/assets/audio/music/<name>.ogg; writes the credits to
CREDITS.md (the game's credits screen reads the same list from
game/scripts/core/credits.gd, keep both in step)."""
import os
import subprocess
import tempfile
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "game", "assets", "audio", "music")
BASE = "https://incompetech.com/music/royalty-free/mp3-royaltyfree/"

# game name: (track title, loudness in LUFS)
TRACKS = {
    "menu": ("Gearhead", -17.0),
    "zone_1_1": ("Neolith", -16.0),
    "zone_1_2": ("Zap Beat", -16.0),
    "zone_1_3": ("Noise Attack", -16.0),
    "boss": ("Summon the Rawk", -15.0),
    "shop": ("RetroFuture Dirty", -17.0),
}


def convert(source, target, loudness):
    filters = ",".join([
        # Silence at both ends would stall the loop.
        "silenceremove=start_periods=1:start_threshold=-50dB",
        "areverse",
        "silenceremove=start_periods=1:start_threshold=-50dB",
        "areverse",
        "loudnorm=I=%s:TP=-1.5:LRA=11" % loudness,
    ])
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", source, "-af", filters,
                    "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", target], check=True)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        for name, (title, loudness) in TRACKS.items():
            source = os.path.join(tmp, title + ".mp3")
            urllib.request.urlretrieve(BASE + urllib.parse.quote(title + ".mp3"), source)
            convert(source, os.path.join(OUT, name + ".ogg"), loudness)
            print("music:", name, "<-", title)


if __name__ == "__main__":
    main()

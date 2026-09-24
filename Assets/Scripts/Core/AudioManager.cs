using UnityEngine;

namespace PuzzleGame.Core
{
    /// <summary>
    /// Простой менеджер звука: фоновая музыка + звуковые эффекты.
    /// AudioClip-поля можно заполнить в инспекторе (перетащив компонент на объект
    /// сцены) — по умолчанию клипы не назначены, и вызовы просто ничего не делают.
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance { get; private set; }

        public static bool MusicEnabled { get; private set; } = true;
        public static bool SfxEnabled { get; private set; } = true;

        private AudioSource musicSource;
        private AudioSource sfxSource;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            if (Instance != null) return;
            var go = new GameObject("AudioManager");
            go.AddComponent<AudioManager>();
        }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);

            musicSource = gameObject.AddComponent<AudioSource>();
            musicSource.loop = true;
            sfxSource = gameObject.AddComponent<AudioSource>();

            MusicEnabled = PlayerPrefs.GetInt("music_enabled", 1) == 1;
            SfxEnabled = PlayerPrefs.GetInt("sfx_enabled", 1) == 1;
            musicSource.mute = !MusicEnabled;
        }

        public static void ToggleMusic()
        {
            MusicEnabled = !MusicEnabled;
            PlayerPrefs.SetInt("music_enabled", MusicEnabled ? 1 : 0);
            if (Instance != null) Instance.musicSource.mute = !MusicEnabled;
        }

        public static void ToggleSfx()
        {
            SfxEnabled = !SfxEnabled;
            PlayerPrefs.SetInt("sfx_enabled", SfxEnabled ? 1 : 0);
        }

        public static void PlaySfx(AudioClip clip)
        {
            if (Instance == null || clip == null || !SfxEnabled) return;
            Instance.sfxSource.PlayOneShot(clip);
        }

        public static void PlayMusic(AudioClip clip)
        {
            if (Instance == null || clip == null) return;
            if (Instance.musicSource.clip == clip && Instance.musicSource.isPlaying) return;
            Instance.musicSource.clip = clip;
            Instance.musicSource.Play();
        }
    }
}

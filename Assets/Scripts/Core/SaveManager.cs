using UnityEngine;
using PuzzleGame.Data;
using PuzzleGame.PowerUps;

namespace PuzzleGame.Core
{
    /// <summary>
    /// Отвечает за сохранение и загрузку прогресса игрока через PlayerPrefs
    /// (данные сериализуются в JSON через JsonUtility).
    /// </summary>
    public static class SaveManager
    {
        private const string SaveKey = "PuzzleGame_SaveData_v1";

        public static PlayerProgressData Data { get; private set; }

        static SaveManager()
        {
            Load();
        }

        public static void Load()
        {
            if (PlayerPrefs.HasKey(SaveKey))
            {
                try
                {
                    Data = JsonUtility.FromJson<PlayerProgressData>(PlayerPrefs.GetString(SaveKey));
                }
                catch
                {
                    Data = null;
                }
            }

            if (Data == null)
            {
                Data = CreateDefault();
            }
        }

        private static PlayerProgressData CreateDefault()
        {
            var data = new PlayerProgressData
            {
                highestUnlockedLevel = 1,
                coins = 200,
                crystals = 20,
                currentLives = 5,
                lastLifeLostTimeUtc = ""
            };

            // Стартовый набор усилений, чтобы игрок мог опробовать механику сразу
            data.powerUps.Add(new PowerUpCountEntry { type = PowerUpType.Bomb, count = 2 });
            data.powerUps.Add(new PowerUpCountEntry { type = PowerUpType.Lightning, count = 2 });
            data.powerUps.Add(new PowerUpCountEntry { type = PowerUpType.Freeze, count = 1 });

            return data;
        }

        public static void Save()
        {
            PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(Data));
            PlayerPrefs.Save();
        }

        public static LevelProgressEntry GetOrCreateLevelEntry(int levelId)
        {
            LevelProgressEntry entry = Data.levelProgress.Find(e => e.levelId == levelId);
            if (entry == null)
            {
                entry = new LevelProgressEntry { levelId = levelId };
                Data.levelProgress.Add(entry);
            }
            return entry;
        }

        public static int GetPowerUpCount(PowerUpType type)
        {
            PowerUpCountEntry entry = Data.powerUps.Find(p => p.type == type);
            return entry?.count ?? 0;
        }

        public static void SetPowerUpCount(PowerUpType type, int count)
        {
            PowerUpCountEntry entry = Data.powerUps.Find(p => p.type == type);
            if (entry == null)
            {
                entry = new PowerUpCountEntry { type = type };
                Data.powerUps.Add(entry);
            }
            entry.count = Mathf.Max(0, count);
        }

        /// <summary>Полный сброс прогресса (например, для отладки или кнопки "Новая игра").</summary>
        public static void ResetProgress()
        {
            Data = CreateDefault();
            Save();
        }
    }
}

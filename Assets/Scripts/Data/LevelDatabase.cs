using System.Collections.Generic;
using UnityEngine;

namespace PuzzleGame.Data
{
    /// <summary>
    /// Загружает и кэширует данные всех уровней из Resources/Levels/level_XX.json.
    /// </summary>
    public static class LevelDatabase
    {
        public const int LevelCount = 20;

        private static Dictionary<int, LevelData> cache;

        private static void EnsureLoaded()
        {
            if (cache != null) return;
            cache = new Dictionary<int, LevelData>();

            for (int i = 1; i <= LevelCount; i++)
            {
                TextAsset json = Resources.Load<TextAsset>($"Levels/level_{i:D2}");
                if (json == null)
                {
                    Debug.LogWarning($"[LevelDatabase] Не найден файл уровня level_{i:D2}.json");
                    continue;
                }

                LevelData data = JsonUtility.FromJson<LevelData>(json.text);
                cache[data.id] = data;
            }
        }

        public static LevelData GetLevel(int id)
        {
            EnsureLoaded();
            return cache.TryGetValue(id, out LevelData data) ? data : null;
        }

        public static int GetLoadedCount()
        {
            EnsureLoaded();
            return cache.Count;
        }
    }
}

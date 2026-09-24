using System;
using System.Collections.Generic;
using PuzzleGame.PowerUps;

namespace PuzzleGame.Data
{
    [Serializable]
    public class LevelProgressEntry
    {
        public int levelId;
        public int stars;
        public int bestScore;
        public bool completed;
    }

    [Serializable]
    public class PowerUpCountEntry
    {
        public PowerUpType type;
        public int count;
    }

    /// <summary>
    /// Полное состояние прогресса игрока. Сериализуется в JSON и хранится
    /// в PlayerPrefs через SaveManager.
    /// </summary>
    [Serializable]
    public class PlayerProgressData
    {
        public int highestUnlockedLevel = 1;
        public int coins = 200;
        public int crystals = 20;
        public int currentLives = 5;
        public string lastLifeLostTimeUtc = ""; // ISO-8601 UTC, пусто = жизни полные

        public List<LevelProgressEntry> levelProgress = new List<LevelProgressEntry>();
        public List<PowerUpCountEntry> powerUps = new List<PowerUpCountEntry>();
    }
}

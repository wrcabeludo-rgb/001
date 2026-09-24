using System;
using System.Collections.Generic;

namespace PuzzleGame.Data
{
    /// <summary>
    /// Описание одного уровня. Загружается из JSON (Resources/Levels/level_XX.json)
    /// через JsonUtility — редактировать баланс можно без пересборки скриптов.
    /// </summary>
    [Serializable]
    public class LevelData
    {
        public int id;
        public int gridWidth = 6;
        public int gridHeight = 6;
        public int colorCount = 5;
        public int moveLimit = 20;

        public int star1Score;
        public int star2Score;
        public int star3Score;

        public int coinReward = 20;
        public int crystalReward = 0;

        public List<LevelObjective> objectives = new List<LevelObjective>();
    }
}

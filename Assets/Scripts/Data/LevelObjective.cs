using System;

namespace PuzzleGame.Data
{
    /// <summary>Одна цель уровня (можно комбинировать несколько на уровень).</summary>
    [Serializable]
    public class LevelObjective
    {
        public ObjectiveType type;
        public TileType targetColor = TileType.Red; // используется при type == CollectColor
        public int targetAmount;
    }
}

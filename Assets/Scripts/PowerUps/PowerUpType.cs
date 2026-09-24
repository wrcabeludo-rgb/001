namespace PuzzleGame.PowerUps
{
    /// <summary>Типы усилений (power-up), доступные игроку.</summary>
    public enum PowerUpType
    {
        Bomb,       // взрывает область 3x3
        Lightning,  // уничтожает строку
        Freeze      // добавляет дополнительные ходы на уровне
    }
}

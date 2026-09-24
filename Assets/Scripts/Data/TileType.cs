namespace PuzzleGame.Data
{
    /// <summary>
    /// Типы плиток на игровом поле. Первые шесть — обычные цветные плитки,
    /// Bomb и Lightning — специальные плитки, создаваемые комбинациями из 4+ плиток.
    /// </summary>
    public enum TileType
    {
        Red,
        Blue,
        Green,
        Yellow,
        Purple,
        Orange,
        Bomb,       // взрывает область 3x3 вокруг себя
        Lightning   // уничтожает всю строку
    }
}

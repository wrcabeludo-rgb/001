using System;

namespace PuzzleGame.Core
{
    /// <summary>Управление игровой валютой: монеты (за уровни) и кристаллы (премиум).</summary>
    public static class CurrencyManager
    {
        public static event Action<int> OnCoinsChanged;
        public static event Action<int> OnCrystalsChanged;

        public static int Coins => SaveManager.Data.coins;
        public static int Crystals => SaveManager.Data.crystals;

        public static void AddCoins(int amount)
        {
            if (amount <= 0) return;
            SaveManager.Data.coins += amount;
            SaveManager.Save();
            OnCoinsChanged?.Invoke(SaveManager.Data.coins);
        }

        public static bool SpendCoins(int amount)
        {
            if (amount <= 0 || SaveManager.Data.coins < amount) return false;
            SaveManager.Data.coins -= amount;
            SaveManager.Save();
            OnCoinsChanged?.Invoke(SaveManager.Data.coins);
            return true;
        }

        public static void AddCrystals(int amount)
        {
            if (amount <= 0) return;
            SaveManager.Data.crystals += amount;
            SaveManager.Save();
            OnCrystalsChanged?.Invoke(SaveManager.Data.crystals);
        }

        public static bool SpendCrystals(int amount)
        {
            if (amount <= 0 || SaveManager.Data.crystals < amount) return false;
            SaveManager.Data.crystals -= amount;
            SaveManager.Save();
            OnCrystalsChanged?.Invoke(SaveManager.Data.crystals);
            return true;
        }
    }
}

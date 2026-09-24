using System;
using System.Collections.Generic;
using PuzzleGame.Core;

namespace PuzzleGame.PowerUps
{
    /// <summary>Инвентарь усилений игрока: покупка за монеты/кристаллы, расход в игре.</summary>
    public static class PowerUpManager
    {
        private static readonly Dictionary<PowerUpType, int> CoinCost = new Dictionary<PowerUpType, int>
        {
            { PowerUpType.Bomb, 150 },
            { PowerUpType.Lightning, 150 },
            { PowerUpType.Freeze, 100 },
        };

        private static readonly Dictionary<PowerUpType, int> CrystalCost = new Dictionary<PowerUpType, int>
        {
            { PowerUpType.Bomb, 10 },
            { PowerUpType.Lightning, 10 },
            { PowerUpType.Freeze, 6 },
        };

        public static event Action OnInventoryChanged;

        public static int GetCount(PowerUpType type) => SaveManager.GetPowerUpCount(type);
        public static int GetCoinCost(PowerUpType type) => CoinCost[type];
        public static int GetCrystalCost(PowerUpType type) => CrystalCost[type];

        public static bool BuyWithCoins(PowerUpType type)
        {
            if (!CurrencyManager.SpendCoins(CoinCost[type])) return false;
            SaveManager.SetPowerUpCount(type, GetCount(type) + 1);
            SaveManager.Save();
            OnInventoryChanged?.Invoke();
            return true;
        }

        public static bool BuyWithCrystals(PowerUpType type)
        {
            if (!CurrencyManager.SpendCrystals(CrystalCost[type])) return false;
            SaveManager.SetPowerUpCount(type, GetCount(type) + 1);
            SaveManager.Save();
            OnInventoryChanged?.Invoke();
            return true;
        }

        /// <summary>Списывает одну единицу усиления. Возвращает false, если их не было.</summary>
        public static bool Consume(PowerUpType type)
        {
            int count = GetCount(type);
            if (count <= 0) return false;
            SaveManager.SetPowerUpCount(type, count - 1);
            SaveManager.Save();
            OnInventoryChanged?.Invoke();
            return true;
        }
    }
}

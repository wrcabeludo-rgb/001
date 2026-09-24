using System;
using System.Globalization;
using UnityEngine;

namespace PuzzleGame.Core
{
    /// <summary>
    /// Система жизней (попыток). Максимум 5 жизней, восстановление по таймеру
    /// (одна жизнь каждые 20 минут) либо мгновенное восполнение за кристаллы.
    /// </summary>
    public static class LivesManager
    {
        public const int MaxLives = 5;
        public static readonly TimeSpan RegenTime = TimeSpan.FromMinutes(20);
        public const int RefillCrystalCost = 20;

        public static int CurrentLives
        {
            get { RegenerateIfNeeded(); return SaveManager.Data.currentLives; }
        }

        public static bool HasLives => CurrentLives > 0;

        public static bool ConsumeLife()
        {
            RegenerateIfNeeded();
            if (SaveManager.Data.currentLives <= 0) return false;

            SaveManager.Data.currentLives--;
            if (SaveManager.Data.currentLives < MaxLives && string.IsNullOrEmpty(SaveManager.Data.lastLifeLostTimeUtc))
            {
                SaveManager.Data.lastLifeLostTimeUtc = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture);
            }
            SaveManager.Save();
            return true;
        }

        private static void RegenerateIfNeeded()
        {
            if (SaveManager.Data.currentLives >= MaxLives)
            {
                SaveManager.Data.lastLifeLostTimeUtc = "";
                return;
            }
            if (string.IsNullOrEmpty(SaveManager.Data.lastLifeLostTimeUtc)) return;
            if (!DateTime.TryParse(SaveManager.Data.lastLifeLostTimeUtc, CultureInfo.InvariantCulture,
                    DateTimeStyles.RoundtripKind, out DateTime lost)) return;

            TimeSpan elapsed = DateTime.UtcNow - lost;
            int livesToAdd = (int)(elapsed.TotalMinutes / RegenTime.TotalMinutes);
            if (livesToAdd <= 0) return;

            SaveManager.Data.currentLives = Mathf.Min(MaxLives, SaveManager.Data.currentLives + livesToAdd);
            if (SaveManager.Data.currentLives >= MaxLives)
            {
                SaveManager.Data.lastLifeLostTimeUtc = "";
            }
            else
            {
                double remainderMinutes = elapsed.TotalMinutes % RegenTime.TotalMinutes;
                SaveManager.Data.lastLifeLostTimeUtc = DateTime.UtcNow.AddMinutes(-remainderMinutes)
                    .ToString("o", CultureInfo.InvariantCulture);
            }
            SaveManager.Save();
        }

        /// <summary>Время до следующей восстановленной жизни (Zero, если жизни полные).</summary>
        public static TimeSpan TimeUntilNextLife()
        {
            RegenerateIfNeeded();
            if (SaveManager.Data.currentLives >= MaxLives || string.IsNullOrEmpty(SaveManager.Data.lastLifeLostTimeUtc))
                return TimeSpan.Zero;
            if (!DateTime.TryParse(SaveManager.Data.lastLifeLostTimeUtc, CultureInfo.InvariantCulture,
                    DateTimeStyles.RoundtripKind, out DateTime lost)) return TimeSpan.Zero;

            TimeSpan elapsed = DateTime.UtcNow - lost;
            double remainderMinutes = elapsed.TotalMinutes % RegenTime.TotalMinutes;
            return RegenTime - TimeSpan.FromMinutes(remainderMinutes);
        }

        public static bool RefillFullWithCrystals()
        {
            if (!CurrencyManager.SpendCrystals(RefillCrystalCost)) return false;
            SaveManager.Data.currentLives = MaxLives;
            SaveManager.Data.lastLifeLostTimeUtc = "";
            SaveManager.Save();
            return true;
        }

        /// <summary>Награда за просмотр рекламы (см. AdManager.ShowRewardedAd).</summary>
        public static void AddLife(int amount = 1)
        {
            SaveManager.Data.currentLives = Mathf.Min(MaxLives, SaveManager.Data.currentLives + amount);
            if (SaveManager.Data.currentLives >= MaxLives) SaveManager.Data.lastLifeLostTimeUtc = "";
            SaveManager.Save();
        }
    }
}

using System;
using System.Collections.Generic;
using UnityEngine;
using PuzzleGame.Data;
using PuzzleGame.Grid;
using PuzzleGame.Core;
using PuzzleGame.PowerUps;
using PuzzleGame.UI;

namespace PuzzleGame.Level
{
    /// <summary>
    /// Контроллер одного уровня: считает ходы/очки, проверяет цели,
    /// определяет победу/поражение, начисляет награды и обновляет прогресс.
    /// </summary>
    public class LevelManager : MonoBehaviour
    {
        public PuzzleGrid grid;

        private LevelData data;
        private int movesLeft;
        private int score;
        private bool levelEnded;
        private readonly Dictionary<TileType, int> collected = new Dictionary<TileType, int>();

        /// <summary>score, movesLeft, stars</summary>
        public event Action<int, int, int> OnHudUpdate;

        public LevelData Data => data;
        public int Score => score;
        public int MovesLeft => movesLeft;
        public int GetCollected(TileType type) => collected.TryGetValue(type, out int v) ? v : 0;

        private void Start()
        {
            data = LevelDatabase.GetLevel(GameManager.SelectedLevelId);
            if (data == null)
            {
                Debug.LogError($"[LevelManager] Не найдены данные уровня id={GameManager.SelectedLevelId}");
                return;
            }

            movesLeft = data.moveLimit;

            grid.OnTilesCleared += HandleTilesCleared;
            grid.OnMoveUsed += HandleMoveUsed;
            grid.OnBoardSettled += HandleBoardSettled;

            grid.Init(data.gridWidth, data.gridHeight, data.colorCount);
            OnHudUpdate?.Invoke(score, movesLeft, CalcStars());
        }

        private void HandleTilesCleared(TileType type, int count)
        {
            score += count * 10;
            collected.TryGetValue(type, out int cur);
            collected[type] = cur + count;
            OnHudUpdate?.Invoke(score, movesLeft, CalcStars());
        }

        private void HandleMoveUsed()
        {
            movesLeft = Mathf.Max(0, movesLeft - 1);
            OnHudUpdate?.Invoke(score, movesLeft, CalcStars());
        }

        private void HandleBoardSettled()
        {
            if (levelEnded) return;
            if (ObjectivesMet()) EndLevel(true);
            else if (movesLeft <= 0) EndLevel(false);
        }

        public bool ObjectivesMet()
        {
            foreach (LevelObjective obj in data.objectives)
            {
                if (obj.type == ObjectiveType.CollectColor && GetCollected(obj.targetColor) < obj.targetAmount) return false;
                if (obj.type == ObjectiveType.ReachScore && score < obj.targetAmount) return false;
            }
            return true;
        }

        private int CalcStars()
        {
            if (score >= data.star3Score) return 3;
            if (score >= data.star2Score) return 2;
            if (score >= data.star1Score) return 1;
            return 0;
        }

        /// <summary>Усиление "Заморозка": добавляет дополнительные ходы вместо остановки времени —
        /// так игрок получает ощутимую пользу вне зависимости от того, ограничены ли уровни по времени.</summary>
        public void UseFreeze()
        {
            if (!PowerUpManager.Consume(PowerUpType.Freeze)) return;
            movesLeft += 5;
            OnHudUpdate?.Invoke(score, movesLeft, CalcStars());
        }

        private void EndLevel(bool won)
        {
            levelEnded = true;
            int stars = won ? CalcStars() : 0;
            int coinsEarned = won ? data.coinReward : 0;
            int crystalsEarned = won && stars >= 3 ? data.crystalReward : 0;

            if (won)
            {
                CurrencyManager.AddCoins(coinsEarned);
                if (crystalsEarned > 0) CurrencyManager.AddCrystals(crystalsEarned);

                LevelProgressEntry entry = SaveManager.GetOrCreateLevelEntry(data.id);
                entry.completed = true;
                if (stars > entry.stars) entry.stars = stars;
                if (score > entry.bestScore) entry.bestScore = score;
                if (SaveManager.Data.highestUnlockedLevel <= data.id)
                    SaveManager.Data.highestUnlockedLevel = data.id + 1;
                SaveManager.Save();
            }

            UIManager.Instance.ShowEndLevel(won, stars, coinsEarned, crystalsEarned,
                onNext: () =>
                {
                    if (data.id < LevelDatabase.LevelCount) GameManager.Instance.StartLevel(data.id + 1);
                    else GameManager.Instance.GoToLevelMap();
                },
                onRetry: () => GameManager.Instance.StartLevel(data.id),
                onMenu: () => GameManager.Instance.GoToLevelMap());
        }
    }
}

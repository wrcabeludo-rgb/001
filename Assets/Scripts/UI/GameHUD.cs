using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.UI;
using PuzzleGame.Core;
using PuzzleGame.Grid;
using PuzzleGame.Level;
using PuzzleGame.PowerUps;
using PuzzleGame.Data;

namespace PuzzleGame.UI
{
    /// <summary>
    /// Bootstrap-компонент игровой сцены: создаёт камеру, PuzzleGrid, LevelManager
    /// и HUD (очки/ходы/цель, кнопки усилений, пауза). Списывает одну жизнь при входе.
    /// </summary>
    public class GameHUD : MonoBehaviour
    {
        private LevelManager levelManager;
        private PuzzleGrid grid;

        private Text scoreText;
        private Text movesText;
        private Text objectiveText;
        private readonly Dictionary<PowerUpType, Text> powerUpLabels = new Dictionary<PowerUpType, Text>();

        private void Start()
        {
            if (!LivesManager.HasLives)
            {
                UIManager.Instance.ShowToast("Нет попыток!");
                GameManager.Instance.GoToLevelMap();
                return;
            }
            LivesManager.ConsumeLife();

            Camera cam = new GameObject("Main Camera").AddComponent<Camera>();
            cam.tag = "MainCamera";
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.08f, 0.09f, 0.12f);

            GameObject gridGO = new GameObject("PuzzleGrid");
            grid = gridGO.AddComponent<PuzzleGrid>();

            GameObject lmGO = new GameObject("LevelManager");
            levelManager = lmGO.AddComponent<LevelManager>();
            levelManager.grid = grid;

            BuildHud();

            levelManager.OnHudUpdate += RefreshHud;
            grid.OnPowerUpTargetChosen += HandlePowerUpTarget;

            Invoke(nameof(RefreshObjectiveDelayed), 0.1f);
        }

        private void RefreshObjectiveDelayed()
        {
            if (levelManager.Data == null) return;
            objectiveText.text = BuildObjectiveString();
        }

        private string BuildObjectiveString()
        {
            LevelData data = levelManager.Data;
            StringBuilder sb = new StringBuilder();
            foreach (LevelObjective obj in data.objectives)
            {
                if (obj.type == ObjectiveType.CollectColor)
                    sb.Append($"Собрать {obj.targetColor}: {levelManager.GetCollected(obj.targetColor)}/{obj.targetAmount}   ");
                else if (obj.type == ObjectiveType.ReachScore)
                    sb.Append($"Очки: {levelManager.Score}/{obj.targetAmount}   ");
            }
            return sb.ToString();
        }

        private void BuildHud()
        {
            GameObject canvasGO = UIWidgets.CreateCanvas("HUDCanvas");
            Transform root = canvasGO.transform;

            GameObject top = UIWidgets.CreatePanel(root, "TopBar", new Color(0, 0, 0, 0.35f),
                new Vector2(0, 1), new Vector2(1, 1), new Vector2(0, -160), new Vector2(0, -90));

            scoreText = UIWidgets.CreateText(top.transform, "Очки: 0", 34, Color.white,
                new Vector2(0, 0.5f), new Vector2(0.5f, 1f), new Vector2(20, 0), Vector2.zero);
            movesText = UIWidgets.CreateText(top.transform, "Ходы: 0", 34, Color.white,
                new Vector2(0.5f, 0.5f), new Vector2(1f, 1f), Vector2.zero, new Vector2(-20, 0));
            objectiveText = UIWidgets.CreateText(top.transform, "", 26, new Color(0.9f, 0.9f, 0.9f),
                new Vector2(0, 0), new Vector2(1, 0.5f), new Vector2(20, 0), new Vector2(-20, 0));

            UIWidgets.CreateButton(root, "II", () => UIManager.Instance.ShowPause(
                onResume: () => { },
                onRestart: () => GameManager.Instance.StartLevel(levelManager.Data.id),
                onExit: () => GameManager.Instance.GoToLevelMap()
            ), new Vector2(90, 90), new Vector2(1, 1), new Vector2(-100, -195));

            GameObject bottom = UIWidgets.CreatePanel(root, "BottomBar", new Color(0, 0, 0, 0.35f),
                new Vector2(0, 0), new Vector2(1, 0), new Vector2(0, 0), new Vector2(0, 180));

            CreatePowerUpButton(bottom.transform, PowerUpType.Bomb, "Бомба", new Vector2(0.2f, 0.5f));
            CreatePowerUpButton(bottom.transform, PowerUpType.Lightning, "Молния", new Vector2(0.5f, 0.5f));
            CreateFreezeButton(bottom.transform, new Vector2(0.8f, 0.5f));
        }

        private void CreatePowerUpButton(Transform parent, PowerUpType type, string label, Vector2 anchor)
        {
            GameObject btn = UIWidgets.CreateButton(parent, PowerUpLabel(type, label), () =>
            {
                if (PowerUpManager.GetCount(type) <= 0)
                {
                    UIManager.Instance.ShowToast("Нет усилений! Загляните в магазин.");
                    return;
                }
                grid.SetPendingPowerUp(type);
                UIManager.Instance.ShowToast("Выберите плитку для применения усиления");
            }, new Vector2(150, 150), anchor, Vector2.zero);

            powerUpLabels[type] = btn.GetComponentInChildren<Text>();
        }

        private void CreateFreezeButton(Transform parent, Vector2 anchor)
        {
            GameObject btn = UIWidgets.CreateButton(parent, PowerUpLabel(PowerUpType.Freeze, "Заморозка"), () =>
            {
                if (PowerUpManager.GetCount(PowerUpType.Freeze) <= 0)
                {
                    UIManager.Instance.ShowToast("Нет усилений! Загляните в магазин.");
                    return;
                }
                levelManager.UseFreeze();
                RefreshPowerUpLabels();
            }, new Vector2(150, 150), anchor, Vector2.zero);

            powerUpLabels[PowerUpType.Freeze] = btn.GetComponentInChildren<Text>();
        }

        private static string PowerUpLabel(PowerUpType type, string name) => $"{name}\n({PowerUpManager.GetCount(type)})";

        private void HandlePowerUpTarget(PowerUpType type, Vector2Int coord)
        {
            if (!PowerUpManager.Consume(type)) return;
            if (type == PowerUpType.Bomb) grid.ActivateBombAt(coord.x, coord.y);
            else if (type == PowerUpType.Lightning) grid.ActivateLightningAt(coord.x, coord.y);
            RefreshPowerUpLabels();
        }

        private void RefreshPowerUpLabels()
        {
            foreach (var kvp in powerUpLabels)
            {
                string name = kvp.Key == PowerUpType.Bomb ? "Бомба" : kvp.Key == PowerUpType.Lightning ? "Молния" : "Заморозка";
                kvp.Value.text = PowerUpLabel(kvp.Key, name);
            }
        }

        private void RefreshHud(int score, int moves, int stars)
        {
            scoreText.text = $"Очки: {score}";
            movesText.text = $"Ходы: {moves}";
            objectiveText.text = BuildObjectiveString();
        }
    }
}

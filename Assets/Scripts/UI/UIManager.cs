using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using PuzzleGame.Core;
using PuzzleGame.PowerUps;

namespace PuzzleGame.UI
{
    /// <summary>
    /// Постоянный (across scenes) слой интерфейса: верхняя панель с валютой/жизнями,
    /// всплывающие уведомления (toast) и модальные окна (пауза, конец уровня, магазин,
    /// настройки), доступные из любой сцены через UIManager.Instance.
    /// </summary>
    public class UIManager : MonoBehaviour
    {
        public static UIManager Instance { get; private set; }

        private GameObject overlayCanvas;
        private Text coinsText, crystalsText, livesText;
        private GameObject toastGO;
        private Text toastText;
        private Coroutine toastRoutine;
        private GameObject activePopup;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            if (Instance != null) return;
            var go = new GameObject("UIManager");
            go.AddComponent<UIManager>();
        }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);

            BuildOverlay();
            CurrencyManager.OnCoinsChanged += _ => RefreshCurrency();
            CurrencyManager.OnCrystalsChanged += _ => RefreshCurrency();
        }

        private float livesRefreshTimer;
        private void Update()
        {
            livesRefreshTimer += Time.unscaledDeltaTime;
            if (livesRefreshTimer >= 1f)
            {
                livesRefreshTimer = 0f;
                RefreshLives();
            }
        }

        private void BuildOverlay()
        {
            GameObject canvasGO = UIWidgets.CreateCanvas("OverlayCanvas");
            DontDestroyOnLoad(canvasGO);
            overlayCanvas = canvasGO;

            GameObject bar = UIWidgets.CreatePanel(canvasGO.transform, "CurrencyBar", new Color(0, 0, 0, 0.4f),
                new Vector2(0, 1), new Vector2(1, 1), new Vector2(0, -90), new Vector2(0, 0));

            coinsText = UIWidgets.CreateText(bar.transform, "0", 30, Color.yellow,
                new Vector2(0, 0), new Vector2(0.34f, 1), new Vector2(20, 0), new Vector2(0, 0));
            crystalsText = UIWidgets.CreateText(bar.transform, "0", 30, new Color(0.6f, 0.85f, 1f),
                new Vector2(0.34f, 0), new Vector2(0.67f, 1), new Vector2(0, 0), new Vector2(0, 0));
            livesText = UIWidgets.CreateText(bar.transform, "5/5", 30, Color.white,
                new Vector2(0.67f, 0), new Vector2(1f, 1), new Vector2(0, 0), new Vector2(-20, 0));

            RefreshCurrency();
            RefreshLives();

            toastGO = UIWidgets.CreatePanel(canvasGO.transform, "Toast", new Color(0, 0, 0, 0.8f),
                new Vector2(0.1f, 0.08f), new Vector2(0.9f, 0.16f), Vector2.zero, Vector2.zero);
            toastText = UIWidgets.CreateText(toastGO.transform, "", 28, Color.white,
                Vector2.zero, Vector2.one, new Vector2(20, 0), new Vector2(-20, 0));
            toastText.alignment = TextAnchor.MiddleCenter;
            toastGO.SetActive(false);
        }

        public void RefreshCurrency()
        {
            coinsText.text = $"Монеты: {CurrencyManager.Coins}";
            crystalsText.text = $"Кристаллы: {CurrencyManager.Crystals}";
        }

        public void RefreshLives()
        {
            int lives = LivesManager.CurrentLives;
            if (lives >= LivesManager.MaxLives)
            {
                livesText.text = $"Жизни: {lives}/{LivesManager.MaxLives}";
            }
            else
            {
                TimeSpan t = LivesManager.TimeUntilNextLife();
                livesText.text = $"Жизни: {lives}/{LivesManager.MaxLives} ({t.Minutes:D2}:{t.Seconds:D2})";
            }
        }

        public void ShowToast(string message, float duration = 2f)
        {
            if (toastRoutine != null) StopCoroutine(toastRoutine);
            toastRoutine = StartCoroutine(ToastRoutine(message, duration));
        }

        private IEnumerator ToastRoutine(string msg, float dur)
        {
            toastGO.SetActive(true);
            toastText.text = msg;
            yield return new WaitForSecondsRealtime(dur);
            toastGO.SetActive(false);
        }

        private GameObject BeginPopup(string name)
        {
            if (activePopup != null) Destroy(activePopup);
            GameObject popup = UIWidgets.CreatePanel(overlayCanvas.transform, name, new Color(0, 0, 0, 0.6f),
                Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            activePopup = popup;
            return popup;
        }

        public void ClosePopup()
        {
            if (activePopup == null) return;
            Destroy(activePopup);
            activePopup = null;
        }

        public void ShowPause(Action onResume, Action onRestart, Action onExit)
        {
            Time.timeScale = 0f;
            GameObject popup = BeginPopup("PausePopup");
            GameObject box = UIWidgets.CreatePanel(popup.transform, "Box", new Color(0.12f, 0.12f, 0.16f, 0.95f),
                new Vector2(0.2f, 0.35f), new Vector2(0.8f, 0.65f), Vector2.zero, Vector2.zero);

            UIWidgets.CreateText(box.transform, "Пауза", 40, Color.white,
                new Vector2(0, 0.7f), new Vector2(1, 1), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            UIWidgets.CreateButton(box.transform, "Продолжить", () => { Time.timeScale = 1f; ClosePopup(); onResume?.Invoke(); },
                new Vector2(300, 90), new Vector2(0.5f, 0.55f), Vector2.zero);
            UIWidgets.CreateButton(box.transform, "Рестарт", () => { Time.timeScale = 1f; ClosePopup(); onRestart?.Invoke(); },
                new Vector2(300, 90), new Vector2(0.5f, 0.32f), Vector2.zero);
            UIWidgets.CreateButton(box.transform, "В меню", () => { Time.timeScale = 1f; ClosePopup(); onExit?.Invoke(); },
                new Vector2(300, 90), new Vector2(0.5f, 0.09f), Vector2.zero);
        }

        public void ShowEndLevel(bool won, int stars, int coins, int crystals, Action onNext, Action onRetry, Action onMenu)
        {
            GameObject popup = BeginPopup("EndLevelPopup");
            GameObject box = UIWidgets.CreatePanel(popup.transform, "Box", new Color(0.12f, 0.12f, 0.16f, 0.97f),
                new Vector2(0.12f, 0.22f), new Vector2(0.88f, 0.78f), Vector2.zero, Vector2.zero);

            UIWidgets.CreateText(box.transform, won ? "Победа!" : "Поражение", 44, won ? Color.green : Color.red,
                new Vector2(0, 0.8f), new Vector2(1, 1), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            string rewardLine = won
                ? $"Звёзды: {new string('*', stars)}{new string('-', 3 - stars)}\nМонеты: +{coins}" + (crystals > 0 ? $"\nКристаллы: +{crystals}" : "")
                : "Ходы закончились";
            UIWidgets.CreateText(box.transform, rewardLine, 28, Color.white,
                new Vector2(0, 0.4f), new Vector2(1, 0.8f), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            if (won)
                UIWidgets.CreateButton(box.transform, "Дальше", () => { ClosePopup(); onNext?.Invoke(); },
                    new Vector2(280, 90), new Vector2(0.5f, 0.28f), Vector2.zero);

            UIWidgets.CreateButton(box.transform, "Заново", () => { ClosePopup(); onRetry?.Invoke(); },
                new Vector2(280, 90), new Vector2(0.5f, won ? 0.14f : 0.28f), Vector2.zero);
            UIWidgets.CreateButton(box.transform, "В меню", () => { ClosePopup(); onMenu?.Invoke(); },
                new Vector2(280, 90), new Vector2(0.5f, 0.05f), Vector2.zero);
        }

        public void ShowShop()
        {
            GameObject popup = BeginPopup("ShopPopup");
            GameObject box = UIWidgets.CreatePanel(popup.transform, "Box", new Color(0.12f, 0.12f, 0.16f, 0.97f),
                new Vector2(0.08f, 0.1f), new Vector2(0.92f, 0.9f), Vector2.zero, Vector2.zero);

            UIWidgets.CreateText(box.transform, "Магазин", 40, Color.white,
                new Vector2(0, 0.9f), new Vector2(1, 1), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            float y = 0.78f;
            foreach (PowerUpType type in Enum.GetValues(typeof(PowerUpType)))
            {
                string name = type == PowerUpType.Bomb ? "Бомба (3x3)" : type == PowerUpType.Lightning ? "Молния (строка)" : "Заморозка (+5 ходов)";
                int coinCost = PowerUpManager.GetCoinCost(type);
                Vector2 rowMin = new Vector2(0.05f, y - 0.1f), rowMax = new Vector2(0.6f, y);

                UIWidgets.CreateText(box.transform, $"{name}\nУ вас: {PowerUpManager.GetCount(type)}", 24, Color.white,
                    rowMin, rowMax, Vector2.zero, Vector2.zero);

                PowerUpType captured = type;
                UIWidgets.CreateButton(box.transform, $"{coinCost} монет", () =>
                {
                    UIManager.Instance.ShowToast(PowerUpManager.BuyWithCoins(captured) ? "Куплено!" : "Недостаточно монет");
                    ShowShop();
                }, new Vector2(220, 70), new Vector2(0.78f, y - 0.05f), Vector2.zero);

                y -= 0.16f;
            }

            UIWidgets.CreateText(box.transform, "Наборы кристаллов (демо-покупка, без реального биллинга)", 22, Color.white,
                new Vector2(0.05f, 0.26f), new Vector2(0.95f, 0.32f), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;
            UIWidgets.CreateButton(box.transform, "+50 кристаллов", () =>
            {
                CurrencyManager.AddCrystals(50);
                UIManager.Instance.ShowToast("Спасибо за покупку! (демо)");
            }, new Vector2(320, 80), new Vector2(0.5f, 0.16f), Vector2.zero);

            UIWidgets.CreateButton(box.transform, "Закрыть", () => ClosePopup(),
                new Vector2(220, 70), new Vector2(0.5f, 0.05f), Vector2.zero);
        }

        public void ShowSettings()
        {
            GameObject popup = BeginPopup("SettingsPopup");
            GameObject box = UIWidgets.CreatePanel(popup.transform, "Box", new Color(0.12f, 0.12f, 0.16f, 0.97f),
                new Vector2(0.12f, 0.3f), new Vector2(0.88f, 0.7f), Vector2.zero, Vector2.zero);

            UIWidgets.CreateText(box.transform, "Настройки", 36, Color.white,
                new Vector2(0, 0.8f), new Vector2(1, 1), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            UIWidgets.CreateButton(box.transform, AudioManager.MusicEnabled ? "Музыка: Вкл" : "Музыка: Выкл",
                () => { AudioManager.ToggleMusic(); ShowSettings(); }, new Vector2(320, 80), new Vector2(0.5f, 0.55f), Vector2.zero);
            UIWidgets.CreateButton(box.transform, AudioManager.SfxEnabled ? "Звук: Вкл" : "Звук: Выкл",
                () => { AudioManager.ToggleSfx(); ShowSettings(); }, new Vector2(320, 80), new Vector2(0.5f, 0.35f), Vector2.zero);
            UIWidgets.CreateButton(box.transform, "Закрыть", () => ClosePopup(),
                new Vector2(220, 70), new Vector2(0.5f, 0.12f), Vector2.zero);
        }
    }
}

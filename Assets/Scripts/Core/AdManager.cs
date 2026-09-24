using System;
using System.Collections;
using UnityEngine;

namespace PuzzleGame.Core
{
    /// <summary>
    /// Заготовка для интеграции Google AdMob. Настоящий SDK не подключён —
    /// методы ниже симулируют показ рекламы задержкой в корутине, чтобы вся
    /// остальная игра (магазин, экран поражения "посмотреть рекламу за жизнь")
    /// уже сейчас работала через единый интерфейс.
    ///
    /// Чтобы подключить реальный AdMob:
    /// 1. Установить пакет Google Mobile Ads Unity plugin.
    /// 2. В ShowRewardedAd/ShowInterstitial заменить вызов SimulateAd на
    ///    RewardedAd.Load(...) / InterstitialAd.Load(...) из GoogleMobileAds.Api.
    /// 3. Прописать реальные Ad Unit ID вместо TestAdUnitId.
    /// </summary>
    public class AdManager : MonoBehaviour
    {
        public static AdManager Instance { get; private set; }

        private const string TestAdUnitId = "ca-app-pub-3940256099942544/5224354917"; // тестовый rewarded ID от Google

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            if (Instance != null) return;
            var go = new GameObject("AdManager");
            go.AddComponent<AdManager>();
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
        }

        public void ShowRewardedAd(Action onReward, Action onFailed = null)
        {
            StartCoroutine(SimulateAd(true, onReward, onFailed));
        }

        public void ShowInterstitial(Action onComplete = null)
        {
            StartCoroutine(SimulateAd(false, onComplete, null));
        }

        private IEnumerator SimulateAd(bool rewarded, Action onSuccess, Action onFailed)
        {
            Debug.Log(rewarded
                ? $"[AdManager] Показ rewarded-рекламы (заглушка, unit={TestAdUnitId})"
                : "[AdManager] Показ interstitial-рекламы (заглушка)");
            yield return new WaitForSeconds(1.0f);
            onSuccess?.Invoke();
        }
    }
}

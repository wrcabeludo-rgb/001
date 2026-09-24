using UnityEngine;
using UnityEngine.UI;
using PuzzleGame.Core;
using PuzzleGame.Data;

namespace PuzzleGame.UI
{
    /// <summary>Bootstrap-компонент экрана карты уровней: прокручиваемый список из 20 уровней с прогрессом.</summary>
    public class LevelMapUI : MonoBehaviour
    {
        private void Start()
        {
            Camera cam = new GameObject("Main Camera").AddComponent<Camera>();
            cam.tag = "MainCamera";
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.05f, 0.06f, 0.10f);

            GameObject canvasGO = UIWidgets.CreateCanvas("LevelMapCanvas");

            UIWidgets.CreateText(canvasGO.transform, "Выбор уровня", 46, Color.white,
                new Vector2(0, 0.9f), new Vector2(1, 1f), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            GameObject scrollGO = new GameObject("ScrollView", typeof(RectTransform));
            scrollGO.transform.SetParent(canvasGO.transform, false);
            RectTransform scrollRt = scrollGO.GetComponent<RectTransform>();
            scrollRt.anchorMin = new Vector2(0.05f, 0.1f);
            scrollRt.anchorMax = new Vector2(0.95f, 0.87f);
            scrollRt.offsetMin = Vector2.zero;
            scrollRt.offsetMax = Vector2.zero;

            Image scrollBg = scrollGO.AddComponent<Image>();
            scrollBg.color = new Color(1, 1, 1, 0.03f);
            ScrollRect scroll = scrollGO.AddComponent<ScrollRect>();
            scrollGO.AddComponent<Mask>().showMaskGraphic = true;

            GameObject content = new GameObject("Content", typeof(RectTransform));
            content.transform.SetParent(scrollGO.transform, false);
            RectTransform contentRt = content.GetComponent<RectTransform>();
            contentRt.anchorMin = new Vector2(0, 1);
            contentRt.anchorMax = new Vector2(1, 1);
            contentRt.pivot = new Vector2(0.5f, 1);

            VerticalLayoutGroup vlg = content.AddComponent<VerticalLayoutGroup>();
            vlg.spacing = 20;
            vlg.padding = new RectOffset(20, 20, 20, 20);
            vlg.childForceExpandHeight = false;
            vlg.childForceExpandWidth = true;

            ContentSizeFitter fitter = content.AddComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

            scroll.content = contentRt;
            scroll.horizontal = false;
            scroll.vertical = true;

            int highestUnlocked = SaveManager.Data.highestUnlockedLevel;

            for (int i = 1; i <= LevelDatabase.LevelCount; i++)
            {
                int levelId = i;
                bool unlocked = levelId <= highestUnlocked;
                LevelProgressEntry entry = SaveManager.GetOrCreateLevelEntry(levelId);

                GameObject row = UIWidgets.CreatePanel(content.transform, $"Level_{i}",
                    new Color(1, 1, 1, unlocked ? 0.08f : 0.03f), Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
                LayoutElement le = row.AddComponent<LayoutElement>();
                le.preferredHeight = 140;

                string stars = new string('*', entry.stars) + new string('-', 3 - entry.stars);
                UIWidgets.CreateText(row.transform, $"Уровень {levelId}\n{stars}", 28,
                    unlocked ? Color.white : new Color(1, 1, 1, 0.4f),
                    new Vector2(0.05f, 0f), new Vector2(0.55f, 1f), Vector2.zero, Vector2.zero);

                GameObject btn = UIWidgets.CreateButton(row.transform, unlocked ? "Играть" : "Закрыто", () =>
                {
                    if (!unlocked) { UIManager.Instance.ShowToast("Сначала пройдите предыдущий уровень"); return; }
                    if (!LivesManager.HasLives) { UIManager.Instance.ShowToast("Нет попыток! Подождите восстановления или откройте магазин"); return; }
                    GameManager.Instance.StartLevel(levelId);
                }, new Vector2(220, 90), new Vector2(0.8f, 0.5f), Vector2.zero);

                if (!unlocked) btn.GetComponent<Button>().interactable = false;
            }

            UIWidgets.CreateButton(canvasGO.transform, "Назад", () => GameManager.Instance.GoToMainMenu(),
                new Vector2(220, 90), new Vector2(0.15f, 0.05f), Vector2.zero);
        }
    }
}

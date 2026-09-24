using System;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace PuzzleGame.UI
{
    /// <summary>
    /// Вспомогательные методы для построения UI полностью кодом (без сцен/префабов).
    /// Такой подход позволяет всей игре собираться "с нуля" при запуске Bootstrap-компонента
    /// на пустой сцене — надёжно работает без ручной настройки Canvas в редакторе.
    /// </summary>
    public static class UIWidgets
    {
        public static Font GetDefaultFont()
        {
            Font f = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            if (f == null) f = Resources.GetBuiltinResource<Font>("Arial.ttf");
            return f;
        }

        public static GameObject CreateCanvas(string name)
        {
            GameObject canvasGO = new GameObject(name, typeof(RectTransform));
            Canvas canvas = canvasGO.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;

            CanvasScaler scaler = canvasGO.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight = 0.5f;

            canvasGO.AddComponent<GraphicRaycaster>();
            EnsureEventSystem();
            return canvasGO;
        }

        private static void EnsureEventSystem()
        {
            if (UnityEngine.Object.FindObjectOfType<EventSystem>() != null) return;
            GameObject es = new GameObject("EventSystem");
            es.AddComponent<EventSystem>();
            es.AddComponent<StandaloneInputModule>();
        }

        public static GameObject CreatePanel(Transform parent, string name, Color color,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax)
        {
            GameObject go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(parent, false);
            RectTransform rt = go.GetComponent<RectTransform>();
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.offsetMin = offsetMin;
            rt.offsetMax = offsetMax;
            Image img = go.AddComponent<Image>();
            img.color = color;
            return go;
        }

        public static Text CreateText(Transform parent, string content, int fontSize, Color color,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax)
        {
            GameObject go = new GameObject("Text", typeof(RectTransform));
            go.transform.SetParent(parent, false);
            RectTransform rt = go.GetComponent<RectTransform>();
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.offsetMin = offsetMin;
            rt.offsetMax = offsetMax;

            Text t = go.AddComponent<Text>();
            t.font = GetDefaultFont();
            t.fontSize = fontSize;
            t.color = color;
            t.text = content;
            t.alignment = TextAnchor.MiddleLeft;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            return t;
        }

        /// <summary>Кнопка с фиксированным размером, привязанная к точке anchor (0..1) со смещением anchoredPosition.</summary>
        public static GameObject CreateButton(Transform parent, string label, Action onClick,
            Vector2 size, Vector2 anchor, Vector2 anchoredPosition)
        {
            GameObject go = new GameObject("Button", typeof(RectTransform));
            go.transform.SetParent(parent, false);
            RectTransform rt = go.GetComponent<RectTransform>();
            rt.anchorMin = anchor;
            rt.anchorMax = anchor;
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = size;
            rt.anchoredPosition = anchoredPosition;

            Image img = go.AddComponent<Image>();
            img.color = new Color(0.2f, 0.5f, 0.9f);

            Button btn = go.AddComponent<Button>();
            btn.onClick.AddListener(() => onClick?.Invoke());

            Text t = CreateText(go.transform, label, 28, Color.white, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            t.alignment = TextAnchor.MiddleCenter;

            return go;
        }
    }
}

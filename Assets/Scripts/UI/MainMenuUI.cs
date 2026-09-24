using UnityEngine;
using PuzzleGame.Core;

namespace PuzzleGame.UI
{
    /// <summary>
    /// Bootstrap-компонент главного меню. Строит весь интерфейс кодом при старте
    /// сцены MainMenu (см. Assets/Scripts/Editor/SceneBuilder.cs — сцена создаётся
    /// с единственным объектом "Bootstrap", на который повешен этот скрипт).
    /// </summary>
    public class MainMenuUI : MonoBehaviour
    {
        private void Start()
        {
            Camera cam = new GameObject("Main Camera").AddComponent<Camera>();
            cam.tag = "MainCamera";
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.05f, 0.06f, 0.10f);

            GameObject canvasGO = UIWidgets.CreateCanvas("MenuCanvas");

            UIWidgets.CreateText(canvasGO.transform, "PUZZLE QUEST", 64, Color.white,
                new Vector2(0, 0.72f), new Vector2(1, 0.9f), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;
            UIWidgets.CreateText(canvasGO.transform, "Match-3 приключение", 28, new Color(0.8f, 0.8f, 0.85f),
                new Vector2(0, 0.65f), new Vector2(1, 0.72f), Vector2.zero, Vector2.zero).alignment = TextAnchor.MiddleCenter;

            UIWidgets.CreateButton(canvasGO.transform, "Играть", () => GameManager.Instance.GoToLevelMap(),
                new Vector2(420, 110), new Vector2(0.5f, 0.48f), Vector2.zero);
            UIWidgets.CreateButton(canvasGO.transform, "Магазин", () => UIManager.Instance.ShowShop(),
                new Vector2(420, 95), new Vector2(0.5f, 0.34f), Vector2.zero);
            UIWidgets.CreateButton(canvasGO.transform, "Настройки", () => UIManager.Instance.ShowSettings(),
                new Vector2(420, 95), new Vector2(0.5f, 0.21f), Vector2.zero);
            UIWidgets.CreateButton(canvasGO.transform, "Выход", () => GameManager.Instance.QuitGame(),
                new Vector2(420, 95), new Vector2(0.5f, 0.08f), Vector2.zero);
        }
    }
}

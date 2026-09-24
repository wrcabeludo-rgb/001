#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using PuzzleGame.UI;

namespace PuzzleGame.EditorTools
{
    /// <summary>
    /// Создаёт три игровые сцены (MainMenu, LevelMap, GameScene) и добавляет их
    /// в Build Settings. Каждая сцена состоит из единственного пустого объекта
    /// "Bootstrap" с соответствующим *UI-компонентом — весь интерфейс и логика
    /// строятся кодом при запуске (см. MainMenuUI/LevelMapUI/GameHUD), поэтому
    /// сцены не нужно вручную наполнять Canvas'ами и кнопками.
    ///
    /// Запустите этот пункт меню один раз после открытия проекта в Unity:
    /// Puzzle Game -> Создать сцены (Create Scenes)
    /// </summary>
    public static class SceneBuilder
    {
        private const string ScenesFolder = "Assets/Scenes";

        [MenuItem("Puzzle Game/Создать сцены (Create Scenes)")]
        public static void CreateScenes()
        {
            if (!Directory.Exists(ScenesFolder)) Directory.CreateDirectory(ScenesFolder);

            string mainMenuPath = BuildScene("MainMenu", typeof(MainMenuUI));
            string levelMapPath = BuildScene("LevelMap", typeof(LevelMapUI));
            string gameScenePath = BuildScene("GameScene", typeof(GameHUD));

            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(mainMenuPath, true),
                new EditorBuildSettingsScene(levelMapPath, true),
                new EditorBuildSettingsScene(gameScenePath, true),
            };

            AssetDatabase.SaveAssets();
            Debug.Log("[SceneBuilder] Сцены MainMenu, LevelMap и GameScene созданы и добавлены в Build Settings.");
        }

        private static string BuildScene(string name, System.Type bootstrapType)
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            GameObject bootstrap = new GameObject("Bootstrap");
            bootstrap.AddComponent(bootstrapType);

            string path = $"{ScenesFolder}/{name}.unity";
            EditorSceneManager.SaveScene(scene, path);
            return path;
        }
    }
}
#endif

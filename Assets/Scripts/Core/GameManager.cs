using UnityEngine;
using UnityEngine.SceneManagement;
using PuzzleGame.Data;

namespace PuzzleGame.Core
{
    /// <summary>
    /// Главный синглтон игры: переключение сцен, хранение выбранного уровня.
    /// Создаётся автоматически при старте приложения (см. Bootstrap), поэтому
    /// его не нужно вручную размещать на сценах.
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }
        public static int SelectedLevelId { get; set; } = 1;

        public const string SceneMainMenu = "MainMenu";
        public const string SceneLevelMap = "LevelMap";
        public const string SceneGame = "GameScene";

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            if (Instance != null) return;
            var go = new GameObject("GameManager");
            go.AddComponent<GameManager>();
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

        public void GoToMainMenu() => SceneManager.LoadScene(SceneMainMenu);
        public void GoToLevelMap() => SceneManager.LoadScene(SceneLevelMap);

        public void StartLevel(int levelId)
        {
            SelectedLevelId = Mathf.Clamp(levelId, 1, LevelDatabase.LevelCount);
            SceneManager.LoadScene(SceneGame);
        }

        public void QuitGame()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }
    }
}

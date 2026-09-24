#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace PuzzleGame.EditorTools
{
    /// <summary>
    /// Настраивает Player Settings под требования ТЗ: Android, минимальный API 26,
    /// IL2CPP + ARM64 (уменьшает размер APK и требуется Google Play), Gradle-сборка.
    /// Запустите один раз: Puzzle Game -> Настроить Android Player Settings.
    /// </summary>
    public static class ProjectSetup
    {
        [MenuItem("Puzzle Game/Настроить Android Player Settings")]
        public static void ConfigureAndroid()
        {
            PlayerSettings.productName = "Puzzle Quest";
            PlayerSettings.applicationIdentifier = "com.puzzlegame.quest";

            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;

            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;

            EditorUserBuildSettings.androidBuildSystem = AndroidBuildSystem.Gradle;

            Debug.Log("[ProjectSetup] Android Player Settings настроены: minSdk=26 (Android 8.0), IL2CPP, ARM64.");
        }
    }
}
#endif

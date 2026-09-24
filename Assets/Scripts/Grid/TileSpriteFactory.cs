using UnityEngine;

namespace PuzzleGame.Grid
{
    /// <summary>
    /// Генерирует единый квадратный спрайт для всех плиток во время выполнения,
    /// чтобы не требовать импорта картинок-ассетов. Цвет плитки задаётся через
    /// SpriteRenderer.color (см. Tile.SetType).
    /// </summary>
    public static class TileSpriteFactory
    {
        private static Sprite cached;

        public static Sprite GetSquareSprite()
        {
            if (cached != null) return cached;

            const int size = 64;
            const int border = 4;
            Texture2D tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            Color32 fill = new Color32(255, 255, 255, 255);
            Color32 edge = new Color32(0, 0, 0, 90);

            Color32[] pixels = new Color32[size * size];
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    bool onEdge = x < border || y < border || x >= size - border || y >= size - border;
                    pixels[y * size + x] = onEdge ? edge : fill;
                }
            }

            tex.SetPixels32(pixels);
            tex.Apply();
            tex.filterMode = FilterMode.Bilinear;

            cached = Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), size);
            return cached;
        }
    }
}

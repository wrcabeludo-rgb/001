using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using PuzzleGame.Data;
using PuzzleGame.PowerUps;

namespace PuzzleGame.Grid
{
    /// <summary>
    /// Ядро механики Match-3: создание поля, обработка свайпов, поиск совпадений,
    /// создание спец-плиток (бомба/молния), каскадное обрушение и заполнение,
    /// а также ручная активация усилений (бомба/молния по выбранной плитке).
    ///
    /// Плитки создаются полностью кодом (без префабов) через TileSpriteFactory —
    /// это упрощает проект и не требует импорта графики для MVP.
    /// </summary>
    public class PuzzleGrid : MonoBehaviour
    {
        public int Width { get; private set; }
        public int Height { get; private set; }

        private int colorCount;
        private const float CellSize = 1.0f;

        private Tile[,] cells;
        private Transform tilesRoot;
        private Sprite tileSprite;
        private readonly System.Random rng = new System.Random();
        private bool isBusy;
        private Tile selectedTile;

        /// <summary>Плитка, выбранная для применения усиления (Bomb/Lightning), либо null.</summary>
        public PowerUpType? PendingPowerUp { get; private set; }

        public event Action<TileType, int> OnTilesCleared;   // цвет, количество очищенных плиток
        public event Action OnMoveUsed;
        public event Action OnBoardSettled;                  // доска стабилизировалась после каскадов
        public event Action<PowerUpType, Vector2Int> OnPowerUpTargetChosen;

        public bool IsBusy => isBusy;

        private static readonly TileType[] ColorPalette =
            { TileType.Red, TileType.Blue, TileType.Green, TileType.Yellow, TileType.Purple, TileType.Orange };

        public void Init(int width, int height, int colorCount)
        {
            Width = width;
            Height = height;
            this.colorCount = Mathf.Clamp(colorCount, 3, ColorPalette.Length);
            tileSprite = TileSpriteFactory.GetSquareSprite();

            tilesRoot = new GameObject("Tiles").transform;
            tilesRoot.SetParent(transform, false);

            cells = new Tile[Width, Height];
            for (int y = 0; y < Height; y++)
            for (int x = 0; x < Width; x++)
                cells[x, y] = CreateTile(x, y, RandomTypeNoMatch(x, y));

            CenterCamera();
        }

        // ---------------------------------------------------------------
        // Создание поля
        // ---------------------------------------------------------------

        private TileType RandomTypeNoMatch(int x, int y)
        {
            TileType t;
            int guard = 0;
            do
            {
                t = ColorPalette[rng.Next(colorCount)];
                guard++;
            } while (guard < 30 && CreatesMatchAt(x, y, t));
            return t;
        }

        private bool CreatesMatchAt(int x, int y, TileType t)
        {
            if (x >= 2 && Get(x - 1, y) != null && Get(x - 2, y) != null &&
                Get(x - 1, y).Type == t && Get(x - 2, y).Type == t) return true;
            if (y >= 2 && Get(x, y - 1) != null && Get(x, y - 2) != null &&
                Get(x, y - 1).Type == t && Get(x, y - 2).Type == t) return true;
            return false;
        }

        private Tile Get(int x, int y) =>
            (x < 0 || y < 0 || x >= Width || y >= Height) ? null : cells[x, y];

        private Tile CreateTile(int x, int y, TileType type)
        {
            GameObject go = new GameObject($"Tile_{x}_{y}");
            go.transform.SetParent(tilesRoot, false);
            go.transform.localPosition = GridToLocal(x, y);

            go.AddComponent<SpriteRenderer>();
            go.AddComponent<BoxCollider2D>();
            Tile tile = go.AddComponent<Tile>();
            tile.Init(this, type, x, y, tileSprite);
            return tile;
        }

        private Vector3 GridToLocal(int x, int y) => new Vector3(x * CellSize, y * CellSize, 0f);

        private void CenterCamera()
        {
            Camera cam = Camera.main;
            if (cam == null) return;

            cam.orthographic = true;
            float boardW = Width * CellSize;
            float boardH = Height * CellSize;

            transform.position = new Vector3(-boardW / 2f + CellSize / 2f, -boardH / 2f + CellSize / 2f, 0f);

            float sizeByHeight = boardH / 2f + 1.5f;
            float sizeByWidth = (boardW / 2f + 1.5f) / Mathf.Max(0.1f, cam.aspect);
            cam.orthographicSize = Mathf.Max(sizeByHeight, sizeByWidth);
            cam.transform.position = new Vector3(0, 1.0f, -10f);
        }

        // ---------------------------------------------------------------
        // Ввод игрока
        // ---------------------------------------------------------------

        public void OnTileClicked(Tile tile)
        {
            if (PendingPowerUp.HasValue)
            {
                PowerUpType type = PendingPowerUp.Value;
                PendingPowerUp = null;
                OnPowerUpTargetChosen?.Invoke(type, new Vector2Int(tile.X, tile.Y));
                return;
            }

            if (isBusy) return;

            if (selectedTile == null)
            {
                selectedTile = tile;
                tile.SetSelected(true);
            }
            else if (selectedTile == tile)
            {
                tile.SetSelected(false);
                selectedTile = null;
            }
            else
            {
                selectedTile.SetSelected(false);
                selectedTile = tile;
                tile.SetSelected(true);
            }
        }

        public void OnTileSwipe(Tile tile, Vector2Int dir)
        {
            if (PendingPowerUp.HasValue) return;
            if (isBusy) return;

            Tile other = Get(tile.X + dir.x, tile.Y + dir.y);
            if (other == null) return;

            if (selectedTile != null)
            {
                selectedTile.SetSelected(false);
                selectedTile = null;
            }

            StartCoroutine(TrySwapRoutine(tile, other));
        }

        public void SetPendingPowerUp(PowerUpType type) => PendingPowerUp = type;
        public void CancelPendingPowerUp() => PendingPowerUp = null;

        private IEnumerator TrySwapRoutine(Tile a, Tile b)
        {
            isBusy = true;
            SwapCells(a, b, true);
            yield return new WaitForSeconds(0.15f);

            bool hasMatch = HasAnyMatchInvolving(a) || HasAnyMatchInvolving(b);
            if (!hasMatch)
            {
                SwapCells(a, b, true);
                yield return new WaitForSeconds(0.15f);
                isBusy = false;
                yield break;
            }

            OnMoveUsed?.Invoke();
            yield return StartCoroutine(ResolveBoardRoutine());
            isBusy = false;
        }

        private void SwapCells(Tile a, Tile b, bool animate)
        {
            int ax = a.X, ay = a.Y, bx = b.X, by = b.Y;
            cells[ax, ay] = b;
            cells[bx, by] = a;
            a.SetCoords(bx, by);
            b.SetCoords(ax, ay);

            if (animate)
            {
                a.MoveTo(GridToLocal(bx, by), 0.15f);
                b.MoveTo(GridToLocal(ax, ay), 0.15f);
            }
            else
            {
                a.transform.localPosition = GridToLocal(bx, by);
                b.transform.localPosition = GridToLocal(ax, ay);
            }
        }

        private bool HasAnyMatchInvolving(Tile t)
        {
            return CountLine(t.X, t.Y, -1, 0) + CountLine(t.X, t.Y, 1, 0) >= 2
                || CountLine(t.X, t.Y, 0, -1) + CountLine(t.X, t.Y, 0, 1) >= 2;
        }

        private int CountLine(int x, int y, int dx, int dy)
        {
            Tile origin = Get(x, y);
            if (origin == null) return 0;
            int count = 0;
            int cx = x + dx, cy = y + dy;
            while (Get(cx, cy) != null && Get(cx, cy).Type == origin.Type)
            {
                count++;
                cx += dx;
                cy += dy;
            }
            return count;
        }

        // ---------------------------------------------------------------
        // Поиск и разрешение совпадений
        // ---------------------------------------------------------------

        private class Run
        {
            public readonly List<Vector2Int> Cells = new List<Vector2Int>();
            public bool Horizontal;
        }

        private List<Run> FindRuns()
        {
            List<Run> runs = new List<Run>();

            for (int y = 0; y < Height; y++)
            {
                int runStart = 0;
                for (int x = 1; x <= Width; x++)
                {
                    bool breakRun = x == Width || Get(x, y) == null || Get(x - 1, y) == null ||
                                     Get(x, y).Type != Get(x - 1, y).Type;
                    if (breakRun)
                    {
                        int len = x - runStart;
                        if (len >= 3)
                        {
                            Run r = new Run { Horizontal = true };
                            for (int k = runStart; k < x; k++) r.Cells.Add(new Vector2Int(k, y));
                            runs.Add(r);
                        }
                        runStart = x;
                    }
                }
            }

            for (int x = 0; x < Width; x++)
            {
                int runStart = 0;
                for (int y = 1; y <= Height; y++)
                {
                    bool breakRun = y == Height || Get(x, y) == null || Get(x, y - 1) == null ||
                                     Get(x, y).Type != Get(x, y - 1).Type;
                    if (breakRun)
                    {
                        int len = y - runStart;
                        if (len >= 3)
                        {
                            Run r = new Run { Horizontal = false };
                            for (int k = runStart; k < y; k++) r.Cells.Add(new Vector2Int(x, k));
                            runs.Add(r);
                        }
                        runStart = y;
                    }
                }
            }

            return runs;
        }

        private IEnumerator ResolveBoardRoutine()
        {
            while (true)
            {
                List<Run> runs = FindRuns();
                if (runs.Count == 0) break;

                HashSet<Vector2Int> matched = new HashSet<Vector2Int>();
                foreach (Run r in runs)
                foreach (Vector2Int c in r.Cells)
                    matched.Add(c);

                // Совпадение из 4 плиток -> Молния, из 5+ -> Бомба, в середине ряда.
                Dictionary<Vector2Int, TileType> specials = new Dictionary<Vector2Int, TileType>();
                foreach (Run r in runs)
                {
                    if (r.Cells.Count >= 5) specials[r.Cells[r.Cells.Count / 2]] = TileType.Bomb;
                    else if (r.Cells.Count == 4) specials[r.Cells[r.Cells.Count / 2]] = TileType.Lightning;
                }

                // Т/Г-образное пересечение горизонтального и вертикального ряда -> Бомба.
                for (int i = 0; i < runs.Count; i++)
                for (int j = i + 1; j < runs.Count; j++)
                {
                    if (runs[i].Horizontal == runs[j].Horizontal) continue;
                    foreach (Vector2Int c in runs[i].Cells)
                        if (runs[j].Cells.Contains(c)) specials[c] = TileType.Bomb;
                }

                // Если в совпадение попала уже существующая спец-плитка — расширяем зону очистки её эффектом.
                Queue<Vector2Int> toProcess = new Queue<Vector2Int>(matched);
                HashSet<Vector2Int> processed = new HashSet<Vector2Int>();
                while (toProcess.Count > 0)
                {
                    Vector2Int c = toProcess.Dequeue();
                    if (processed.Contains(c)) continue;
                    processed.Add(c);

                    Tile t = Get(c.x, c.y);
                    if (t == null || specials.ContainsKey(c)) continue;

                    if (t.Type == TileType.Bomb)
                    {
                        for (int dx = -1; dx <= 1; dx++)
                        for (int dy = -1; dy <= 1; dy++)
                        {
                            Vector2Int n = new Vector2Int(c.x + dx, c.y + dy);
                            if (Get(n.x, n.y) != null && matched.Add(n)) toProcess.Enqueue(n);
                        }
                    }
                    else if (t.Type == TileType.Lightning)
                    {
                        for (int xx = 0; xx < Width; xx++)
                        {
                            Vector2Int n = new Vector2Int(xx, c.y);
                            if (Get(n.x, n.y) != null && matched.Add(n)) toProcess.Enqueue(n);
                        }
                    }
                }

                Dictionary<TileType, int> clearedByColor = new Dictionary<TileType, int>();
                foreach (Vector2Int c in matched)
                {
                    Tile t = Get(c.x, c.y);
                    if (t == null) continue;

                    if (specials.TryGetValue(c, out TileType specialType))
                    {
                        t.SetType(specialType); // плитка не удаляется, а превращается в спец-плитку
                        continue;
                    }

                    TileType type = t.Type;
                    clearedByColor.TryGetValue(type, out int cur);
                    clearedByColor[type] = cur + 1;

                    cells[c.x, c.y] = null;
                    t.PlayClearAnimation(null);
                }

                foreach (var kvp in clearedByColor) OnTilesCleared?.Invoke(kvp.Key, kvp.Value);

                yield return new WaitForSeconds(0.22f);
                yield return StartCoroutine(CollapseAndRefillRoutine());
                yield return new WaitForSeconds(0.22f);
            }

            if (!HasAnyPossibleMove()) ShuffleBoard();
            OnBoardSettled?.Invoke();
        }

        private IEnumerator CollapseAndRefillRoutine()
        {
            for (int x = 0; x < Width; x++)
            {
                int writeY = 0;
                for (int y = 0; y < Height; y++)
                {
                    if (cells[x, y] != null)
                    {
                        if (writeY != y)
                        {
                            Tile t = cells[x, y];
                            cells[x, writeY] = t;
                            cells[x, y] = null;
                            t.SetCoords(x, writeY);
                            t.MoveTo(GridToLocal(x, writeY), 0.2f);
                        }
                        writeY++;
                    }
                }

                for (int y = writeY; y < Height; y++)
                {
                    TileType type = ColorPalette[rng.Next(colorCount)];
                    Tile t = CreateTile(x, y, type);
                    t.transform.localPosition = GridToLocal(x, Height + (y - writeY));
                    cells[x, y] = t;
                    t.MoveTo(GridToLocal(x, y), 0.25f);
                }
            }
            yield return null;
        }

        // ---------------------------------------------------------------
        // Проверка наличия ходов и перемешивание
        // ---------------------------------------------------------------

        private bool HasAnyPossibleMove()
        {
            for (int x = 0; x < Width; x++)
            for (int y = 0; y < Height; y++)
            {
                if (x < Width - 1 && WouldMatch(x, y, x + 1, y)) return true;
                if (y < Height - 1 && WouldMatch(x, y, x, y + 1)) return true;
            }
            return false;
        }

        private bool WouldMatch(int ax, int ay, int bx, int by)
        {
            Tile a = Get(ax, ay), b = Get(bx, by);
            if (a == null || b == null) return false;
            return SimulateSwapCreatesMatch(ax, ay, b.Type) || SimulateSwapCreatesMatch(bx, by, a.Type);
        }

        private bool SimulateSwapCreatesMatch(int x, int y, TileType newType)
        {
            if (CountLineType(x - 1, y, -1, 0, newType) + CountLineType(x + 1, y, 1, 0, newType) >= 2) return true;
            if (CountLineType(x, y - 1, 0, -1, newType) + CountLineType(x, y + 1, 0, 1, newType) >= 2) return true;
            return false;
        }

        private int CountLineType(int x, int y, int dx, int dy, TileType type)
        {
            int count = 0;
            while (Get(x, y) != null && Get(x, y).Type == type)
            {
                count++;
                x += dx;
                y += dy;
            }
            return count;
        }

        private void ShuffleBoard()
        {
            List<TileType> types = new List<TileType>();
            for (int x = 0; x < Width; x++)
            for (int y = 0; y < Height; y++)
                types.Add(cells[x, y].Type);

            for (int i = types.Count - 1; i > 0; i--)
            {
                int j = rng.Next(i + 1);
                (types[i], types[j]) = (types[j], types[i]);
            }

            int idx = 0;
            for (int x = 0; x < Width; x++)
            for (int y = 0; y < Height; y++)
                cells[x, y].SetType(types[idx++]);

            if (!HasAnyPossibleMove()) ShuffleBoard();
        }

        // ---------------------------------------------------------------
        // Активация усилений из UI (не расходует ход)
        // ---------------------------------------------------------------

        public void ActivateBombAt(int x, int y)
        {
            if (isBusy || Get(x, y) == null) return;
            StartCoroutine(ActivateAreaRoutine(x, y));
        }

        private IEnumerator ActivateAreaRoutine(int cx, int cy)
        {
            isBusy = true;
            Dictionary<TileType, int> clearedByColor = new Dictionary<TileType, int>();

            for (int dx = -1; dx <= 1; dx++)
            for (int dy = -1; dy <= 1; dy++)
            {
                Tile t = Get(cx + dx, cy + dy);
                if (t == null) continue;
                clearedByColor.TryGetValue(t.Type, out int cur);
                clearedByColor[t.Type] = cur + 1;
                cells[t.X, t.Y] = null;
                t.PlayClearAnimation(null);
            }

            foreach (var kvp in clearedByColor) OnTilesCleared?.Invoke(kvp.Key, kvp.Value);

            yield return new WaitForSeconds(0.2f);
            yield return StartCoroutine(CollapseAndRefillRoutine());
            yield return new WaitForSeconds(0.2f);

            if (!HasAnyPossibleMove()) ShuffleBoard();
            OnBoardSettled?.Invoke();
            isBusy = false;
        }

        public void ActivateLightningAt(int x, int y)
        {
            if (isBusy || Get(x, y) == null) return;
            StartCoroutine(ActivateRowRoutine(y));
        }

        private IEnumerator ActivateRowRoutine(int row)
        {
            isBusy = true;
            Dictionary<TileType, int> clearedByColor = new Dictionary<TileType, int>();

            for (int x = 0; x < Width; x++)
            {
                Tile t = Get(x, row);
                if (t == null) continue;
                clearedByColor.TryGetValue(t.Type, out int cur);
                clearedByColor[t.Type] = cur + 1;
                cells[x, row] = null;
                t.PlayClearAnimation(null);
            }

            foreach (var kvp in clearedByColor) OnTilesCleared?.Invoke(kvp.Key, kvp.Value);

            yield return new WaitForSeconds(0.2f);
            yield return StartCoroutine(CollapseAndRefillRoutine());
            yield return new WaitForSeconds(0.2f);

            if (!HasAnyPossibleMove()) ShuffleBoard();
            OnBoardSettled?.Invoke();
            isBusy = false;
        }
    }
}

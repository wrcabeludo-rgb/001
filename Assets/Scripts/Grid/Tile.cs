using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using PuzzleGame.Data;

namespace PuzzleGame.Grid
{
    /// <summary>
    /// Одна плитка на игровом поле. Отвечает за визуал, анимацию перемещения/
    /// исчезновения и распознавание свайпа для запроса обмена соседними плитками.
    /// </summary>
    [RequireComponent(typeof(SpriteRenderer))]
    [RequireComponent(typeof(BoxCollider2D))]
    public class Tile : MonoBehaviour
    {
        public TileType Type { get; private set; }
        public int X { get; private set; }
        public int Y { get; private set; }

        private SpriteRenderer sr;
        private PuzzleGrid grid;
        private Vector2 dragStartScreenPos;
        private bool isDragging;

        private const float SwipeThreshold = 20f; // пикселей экрана

        private static readonly Dictionary<TileType, Color> ColorMap = new Dictionary<TileType, Color>
        {
            { TileType.Red,       new Color(0.90f, 0.25f, 0.25f) },
            { TileType.Blue,      new Color(0.25f, 0.45f, 0.90f) },
            { TileType.Green,     new Color(0.30f, 0.80f, 0.35f) },
            { TileType.Yellow,    new Color(0.95f, 0.85f, 0.20f) },
            { TileType.Purple,    new Color(0.65f, 0.35f, 0.85f) },
            { TileType.Orange,    new Color(0.95f, 0.55f, 0.20f) },
            { TileType.Bomb,      new Color(0.12f, 0.12f, 0.12f) },
            { TileType.Lightning, new Color(0.95f, 0.95f, 0.95f) },
        };

        public void Init(PuzzleGrid owner, TileType type, int x, int y, Sprite sprite)
        {
            grid = owner;
            sr = GetComponent<SpriteRenderer>();
            sr.sprite = sprite;
            sr.sortingOrder = 1;
            X = x;
            Y = y;
            SetType(type);
        }

        public void SetType(TileType type)
        {
            Type = type;
            sr.color = ColorMap.TryGetValue(type, out Color c) ? c : Color.white;
        }

        public void SetCoords(int x, int y)
        {
            X = x;
            Y = y;
        }

        public void MoveTo(Vector3 localPos, float duration)
        {
            StopAllCoroutines();
            StartCoroutine(MoveRoutine(localPos, duration));
        }

        private IEnumerator MoveRoutine(Vector3 target, float duration)
        {
            Vector3 start = transform.localPosition;
            float t = 0f;
            while (t < duration)
            {
                t += Time.deltaTime;
                transform.localPosition = Vector3.Lerp(start, target, duration <= 0f ? 1f : t / duration);
                yield return null;
            }
            transform.localPosition = target;
        }

        public void PlayClearAnimation(Action onComplete)
        {
            StartCoroutine(ClearRoutine(onComplete));
        }

        private IEnumerator ClearRoutine(Action onComplete)
        {
            const float dur = 0.18f;
            float t = 0f;
            Vector3 startScale = transform.localScale;
            while (t < dur)
            {
                t += Time.deltaTime;
                transform.localScale = Vector3.Lerp(startScale, Vector3.zero, t / dur);
                yield return null;
            }
            onComplete?.Invoke();
            Destroy(gameObject);
        }

        public void SetSelected(bool selected)
        {
            transform.localScale = selected ? Vector3.one * 1.12f : Vector3.one;
        }

        private void OnMouseDown()
        {
            dragStartScreenPos = Input.mousePosition;
            isDragging = true;
            grid.OnTileClicked(this);
        }

        private void OnMouseUp()
        {
            if (!isDragging) return;
            isDragging = false;

            Vector2 delta = (Vector2)Input.mousePosition - dragStartScreenPos;
            if (delta.magnitude < SwipeThreshold) return;

            Vector2Int dir = Mathf.Abs(delta.x) > Mathf.Abs(delta.y)
                ? new Vector2Int((int)Mathf.Sign(delta.x), 0)
                : new Vector2Int(0, (int)Mathf.Sign(delta.y));

            grid.OnTileSwipe(this, dir);
        }
    }
}

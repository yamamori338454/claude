# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication

- 日本語で対話すること

## Project Status

バニラJS製のTODOリスト管理Webアプリ。ビルドシステム・パッケージマネージャー不要で、ブラウザで直接動作する。

## アーキテクチャ

- `index.html` — UIマークアップ
- `style.css` — グラデーション背景・レスポンシブデザイン・アニメーション
- `app.js` — `TodoApp` クラス（単一クラスでロジックを管理）

### データ構造

```js
{ id: Date.now(), text: string, completed: boolean, createdAt: ISO8601 }
```

ローカルストレージキー: `todos`

### 主要メソッド（app.js）

| メソッド | 役割 |
|---|---|
| `addTodo()` | 入力値を検証してtodosに追加 |
| `deleteTodo(id)` | IDで絞り込み削除 |
| `toggleTodo(id)` | completed フラグ反転 |
| `clearCompleted()` | 完了済みを一括削除 |
| `setFilter(filter)` | all / active / completed 切り替え |
| `render()` | DOM全再描画 |
| `escapeHtml(text)` | XSS対策（textContent経由） |

## 開発コマンド

ビルド不要。`index.html` をブラウザで直接開くだけで動作する。

```bash
# ローカルサーバーを立てる場合
python3 -m http.server 8080
```

## 既知の設計上の注意点

- `render()` は毎回 `innerHTML` を全置換するため、タスク数が増えるとパフォーマンスに注意
- イベントハンドラーはHTMLのインライン属性（`onclick="app.toggleTodo(...)"`）で登録しているため、グローバル変数 `app` に依存している

# Web アプリ

**2026-11-15 から保留中。開発者から Web の作業を明示的に依頼されない限り、ここは何も変更しない。**

`20_Source/Web/` 配下で作業すると読み込まれる。リポジトリ全体の規約はルートの `CLAUDE.md` にある。

## 概要
ばすみるの Web 版。iOS アプリの置き換えではなく並行するチャネルで、iOS と同等の機能を目指す。Web 独自の追加要素は、共有できる URL(駅の組み合わせをクエリ文字列に持つ)と PWA 対応。公開先は Cloudflare Pages の予定。現状は雛形のみ(`App.tsx` + 正規化ユーティリティ)。方針とタスク一覧: `10_Document/06_Web版/`

## 技術スタック
- Vite、React 19、TypeScript、react-router-dom、`@supabase/supabase-js`、Vitest、ESLint
- **環境変数**: `.env.example` を `.env.local` にコピーし、`VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` を設定する。anon キーは設計上公開されるもの(RLS で保護)。service role キーは絶対に使わない。
- **静的データ**: `public/data/stops.json`(`scripts/generate_stops_json.py` で生成)

## 検証コマンド(`20_Source/Web/` で実行)

```bash
npm run typecheck
npm run lint
npm test
npm run build
```

- 変更のたびに `typecheck`、`lint`、`test` を実行する。
- `npm run dev` は常駐プロセスなので起動しない。

## プロジェクト固有の規約
- `src/utils/stringNormalization.ts` は Swift の `StringNormalization` と同じ挙動でなければならない。Web の作業を再開するときは、まず Swift 側と揃え(保留中は Swift の変更を反映していない)、両方のテストを更新する。
- UI文言・エラーメッセージは日本語。

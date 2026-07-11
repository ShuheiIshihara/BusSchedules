# 「ばすみる」Web化 方針・作戦

作成日: 2026-07-05
ステータス: 提案(承認待ち)

---

## 1. 目的と位置づけ

iOSアプリ「ばすみる」と同等の機能をWebアプリとして提供し、以下を実現する。

- **リーチ拡大**: Androidユーザー・アプリ未インストール層でもブラウザさえあれば利用可能にする
- **無料での立ち上げ**: 初期案では有料サービスを一切使わず、無料枠のみで公開・運用する
- **Webならではの価値**: 発着ペアをURLクエリパラメータに載せることで「時刻表を人に共有できる」体験を追加する(iOSアプリにはない利点)
- **将来のPWA化**: ホーム画面追加・オフライン対応により、アプリに近い体験へ段階的に進化させる

本Web版は既存のiOSアプリを置き換えるものではなく、同一バックエンドを共用する並行チャネルとする。

---

## 2. 推奨アーキテクチャ

```
┌─────────────────────────────┐
│  Cloudflare Pages (無料)     │
│  Vite + React + TypeScript  │  ← SPA (将来PWA化)
│  https://busmiru.pages.dev  │
└─────────────┬───────────────┘
              │ Supabase JS SDK (anon key + RLS)
┌─────────────▼───────────────┐
│  既存 Supabase (無料枠)      │
│  RPC: get_phase1_bus_schedule_3
│  GTFS-JPデータ (iOSと共用)   │
└─────────────────────────────┘
```

### フロントエンド: Vite + React + TypeScript (SPA)

選定理由:
- 「時刻表検索」というアプリ的UXにはSPAが素直に合う(SSR不要。SEOが必要なのはランディングページのみで、静的HTMLで足りる)
- `vite-plugin-pwa` により Phase 2 の PWA 化が設定追加だけで済む
- Reactはエコシステム・情報量が最大で、Supabase JS SDKとの組み合わせ事例も豊富
- ビルド成果物は静的ファイルのみ → どの無料ホスティングにも載る(ベンダーロックインなし)

### バックエンド: 既存 Supabase をそのまま共用

- iOSアプリは単一RPC `get_phase1_bus_schedule_3(departure_station, arrival_station, target_date)` に集約されており、**Supabase JS SDK から同じRPCを呼ぶだけでバックエンド改修はほぼ不要**
- 認証は匿名アクセス+RLS。**anon key はRLS前提で公開してよい設計**であり、Webクライアントに埋め込んで問題ない(Service Role Key は絶対に使わない)
- 確認事項: Supabase ダッシュボードで Web ドメイン(`*.pages.dev` およびカスタムドメイン)からの CORS が通ることを疎通確認する

### ホスティング: Cloudflare Pages (第一候補)

| 項目 | Cloudflare Pages (推奨) | Vercel Hobby (代替案) |
|---|---|---|
| 料金 | 無料 | 無料 |
| 帯域 | **無制限** | 100GB/月 |
| ビルド回数 | 500回/月 | 6,000分/月 |
| 無料ドメイン | `*.pages.dev` | `*.vercel.app` |
| カスタムドメイン | 無料で設定可 | 無料で設定可 |
| 商用利用 | 可 | Hobbyは非商用のみ |
| Git連携自動デプロイ | あり | あり |

帯域無制限・商用利用可の点で Cloudflare Pages を第一候補とする。静的SPAなのでVercel固有機能(SSR等)は不要であり、乗り換えも容易。

### CI/CD

Cloudflare Pages の GitHub 連携を使い、`main` ブランチへの push で自動デプロイ。ビルドチェック(型チェック・テスト)は GitHub Actions(パブリックリポジトリなら無料、プライベートでも月2,000分無料)で行う。

### リポジトリ構成案

既存の番号ディレクトリ規約に合わせ、同一リポジトリ内に配置する(モノレポ)。

```
20_Source/
├── BusNow/        # 既存iOSアプリ
└── Web/           # Web版 (Vite + React + TS)
    ├── src/
    ├── public/
    └── package.json
```

stops.json 生成スクリプト(`scripts/generate_stops_json.py`)の出力先に Web 側を追加し、iOS/Web で停留所マスタを同期する。

---

## 3. 無料サービス選定表

| 用途 | サービス | 無料枠 | 超過時のリスク・備考 |
|---|---|---|---|
| ホスティング | Cloudflare Pages | 帯域無制限、500ビルド/月、2万ファイル | ビルド回数超過時は待機。個人アプリでは実質到達しない |
| DB/API | Supabase (既存プロジェクト共用) | DB 500MB、Egress 5GB/月、7日間非アクティブで一時停止 | **Egress 5GB/月が最重要制約**(下記リスク参照)。iOSアプリが稼働中のため非アクティブ停止の懸念は低い |
| ドメイン | `busmiru.pages.dev` (Cloudflare付属) | 無料 | カスタムドメインは唯一の有料候補(年約1,500円、Phase 4で任意検討) |
| アナリティクス | Cloudflare Web Analytics | 無料 | Cookieレス・GDPR配慮不要。GA4より導入が軽い |
| 死活監視 | UptimeRobot 無料枠 | 50モニター、5分間隔 | 任意。静的ホスティングなので優先度低 |
| CI | GitHub Actions | パブリック無料 / プライベート2,000分/月 | 型チェック+単体テストのみなら十分 |

**初期費用・月額ともに0円で立ち上げ可能。**

---

## 4. 機能マッピング(iOS → Web)

| iOS機能 | Web実装方針 |
|---|---|
| 停留所選択+サジェスト(漢字/読み前方一致→部分一致) | `stops.json`(約900件)をバンドル同梱し、クライアント側でフィルタ。iOSと同一の優先順位ロジックをTSで移植 |
| 日本語正規化(`StringNormalization.swift`) | **JSで再実装が必要**: `String.prototype.normalize('NFC')`+全角スペース→半角+連続空白圧縮+しんにょう異体字(U+E0100)+半角カナ→ひらがな変換。iOSと同一の入出力になるよう単体テストで担保 |
| 時刻表表示(同一RPC呼び出し) | Supabase JS SDK で `get_phase1_bus_schedule_3` を呼ぶ。レスポンス型はiOSの `BusScheduleRPCResponse` と同一 |
| リアルタイム時計(秒精度)・次バスハイライト・過去便グレーアウト | `setInterval`(1秒)で現在時刻を更新し、iOSの `BusScheduleViewModel` と同じ判定ロジックを移植 |
| 平日/土日祝 切替・日付選択 | 同ロジックをTSで移植(サービス種別切替時に次の月曜/土曜を自動選択する挙動も踏襲) |
| 行き/帰り 切替 | 発着ペアの反転。iOSと同じ |
| 接近情報(WKWebViewで市交通局サイト表示) | **別タブで開く外部リンク方式**に変更(`https://www.kotsu.city.nagoya.jp/jp/pc/bus/stand_access.html?name=..&toname=..`)。市交通局サイトは X-Frame-Options により iframe 埋め込み不可の可能性が高いため |
| UserDefaults(前回ペア・履歴10件) | `localStorage` に JSON で保存。キー設計・上限10件はiOSと揃える |
| 起動時バージョンチェック(iTunes Lookup API) | **不要**(Webは常に最新が配信される) |
| 設定画面(プライバシーポリシー・CC-BYライセンス表記) | フッター/aboutページとして実装。**GTFS-JPデータのCC-BY表記はWeb版でも必須** |

### Web版で追加する機能(iOSにない価値)

- **URL共有**: `?from=栄&to=名古屋駅` 形式で発着ペアをURLに反映。開いた瞬間に時刻表が表示される共有リンク

---

## 5. 段階的ロードマップ

### Phase 1: MVP公開(まずここまで)

- `20_Source/Web/` に Vite + React + TS プロジェクトを作成
- 停留所選択(サジェスト付き)+時刻表表示+履歴(localStorage)
- 日本語正規化のTS移植+単体テスト(iOS版 `StopNameRepositoryTests` 相当のケースを流用)
- `busmiru.pages.dev` で公開

### Phase 2: PWA化

- `vite-plugin-pwa` で manifest + Service Worker を追加
- ホーム画面追加(A2HS)対応、アプリシェルのオフラインキャッシュ
- ※時刻表データ自体はオンライン必須のままで良い(接近情報もオンライン前提のため)

### Phase 3: Web独自の進化

- 多言語対応: 既存の `10_Document/05_多言語/translations.txt` に英語訳があるため、UI文言のi18n+停留所名英語表示を低コストで実現可能
- SEO用ランディングページの拡充(アプリ紹介+App Storeへの導線を兼ねる)
- ※URL共有機能はSEO手戻り防止のため Phase 1 に前倒し(下記リスク参照)

### Phase 4: 運用・改善

- Cloudflare Web Analytics 導入、利用状況の把握
- Supabase ダッシュボードで Egress 使用量を月次確認
- カスタムドメイン検討(任意・唯一の有料項目)

---

## 6. リスクと対策

| リスク | 影響 | 対策 |
|---|---|---|
| **Supabase Egress 5GB/月超過** | 超過時は402応答となりiOSアプリまで巻き添えで停止しうる | RPCレスポンスは軽量(数KB/回)なので通常は余裕があるが、(1) 同一検索条件の結果をクライアント側で日付単位キャッシュ、(2) ダッシュボードで月次監視、(3) 逼迫したらWeb側にCDNキャッシュ層(Cloudflare Workers KV等、無料枠あり)を検討 |
| 7日間非アクティブでプロジェクト一時停止 | サービス全停止 | iOSアプリが日常的にクエリを発行しているため実質リスクなし。念のためUptimeRobotでの定期ヘルスチェックも可 |
| anon key の公開 | RLSが不備だと全データ露出 | 現行のRLS設計(公開読み取り専用)を再確認したうえで公開。書き込み系ポリシーが存在しないことをチェックリスト化 |
| 市交通局サイトの仕様変更(接近情報URL) | 接近情報リンク切れ | iOS版と共通のリスク。リンク方式なので影響は限定的。定期的な動作確認 |
| ライセンス表記漏れ | GTFS-JPデータ(CC-BY)の利用条件違反 | フッターに出典・CC-BY表記を常時表示。iOS版の設定画面と同等の記載を踏襲 |
| 無料枠の条件変更 | 運用コスト発生 | 静的SPAのためホスティング移行は容易(Netlify/GitHub Pages等の代替あり)。Supabaseが本丸だが現状の利用規模では無料枠内 |
| **SPA構成によるSEO制約**(後から検索流入を狙う際の手戻り) | 時刻表がURLを持たない・初期HTMLが空シェルだと、SSR化しても index対象が存在せず作り直しになる | GooglebotはJSを実行するためSPA自体は致命傷ではない。本質はURL設計。手戻り防止として Phase 1 から以下を織り込む: (1) `react-router-dom`+クエリパラメータで全時刻表を直接開けるURLにする(`/timetable?from=..&to=..`)、(2) `index.html` にタイトル・meta description・OGP・h1+紹介文を静的に記述、(3) services/utils層をUIから分離維持。本格SEOが必要になったら Astro/Next.js へ載せ替え停留所別ページ(約900件)をSSGする — コンポーネントとロジック層は再利用可能で、書き直しはルーティング層のみ。Cloudflare Pagesは両者とも無料枠で稼働可 |

---

## 7. 次のアクション(Phase 1 着手時のタスク)

1. `20_Source/Web/` に Vite + React + TS の雛形を作成(`npm create vite@latest`)
2. Supabase JS SDK 導入、環境変数(`VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY`)の設定、`get_phase1_bus_schedule_3` の疎通確認
3. `StringNormalization.swift` のTS移植+単体テスト(Vitest)
4. `scripts/generate_stops_json.py` の出力先にWeb側 `public/` を追加
5. 停留所選択画面(サジェスト+履歴)の実装
6. 時刻表画面(リアルタイム時計・次バスハイライト・各種切替)の実装
7. Cloudflare Pages プロジェクト作成、GitHub連携で自動デプロイ設定
8. RLSポリシーの読み取り専用チェック、CORS疎通確認
9. CC-BY表記・プライバシーポリシーページの作成
10. 公開・動作確認

---

## 参考(無料枠情報の出典)

- [Cloudflare Pages Limits (公式)](https://developers.cloudflare.com/pages/platform/limits/)
- [Supabase Pricing (公式)](https://supabase.com/pricing)
- [Supabase Billing Docs (公式)](https://supabase.com/docs/guides/platform/billing-on-supabase)

※無料枠の条件は変更されうるため、Phase 1 着手時に公式ページで再確認すること。

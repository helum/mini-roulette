# AGENT.md

このファイルは、本リポジトリで作業するエージェント向けの入口である。実装・修正・テスト追加の前に `.cursor/rules/` を読み、そこに書かれたソフトウェアアーキテクチャとディレクトリ責務に従う。

## プロダクト

複数のルーレットを登録し、重み付きで回す Flutter ミニアプリ（パッケージ名 `mini_roulette`）。UI 文言とユーザー向けメッセージは日本語。

## 必読

1. [architecture.mdc](.cursor/rules/architecture.mdc) — レイヤ境界、依存方向、実行時の流れ
2. [directories.mdc](.cursor/rules/directories.mdc) — ディレクトリと責務
3. 変更対象に隣接する既存実装と、同階層の `test/` テスト

アーキテクチャの正本は `.cursor/rules/` である。ここに無いレイヤやディレクトリを新設しない。

## 作業原則

- 既存の層分割（`domain` / `application` / `data` / `presentation`）と依存方向を崩さない。
- 具象の組み立ては `lib/main.dart` に閉じる。画面やユースケースから `LocalRoulettesApi` を直接作らない。
- 画面は `ContentController`（Riverpod）経由でユースケースを呼ぶ。Page から Repository / DataSource を直接触らない。
- ビジネスルール（抽選、回転計画、スピン可否、既定項目の生成）は domain / application に置く。Widget に埋め込まない。
- 永続化の詳細（SharedPreferences、JSON キー）は `data` に閉じる。
- 変更した層のテストを `test/` のミラー配置で更新または追加する。
- ユーザーから依頼されていないリファクタ、依存追加、フォーマット全体かけはしない。

## 実装の進め方

1. 変更がどの層の責務かを `.cursor/rules/` で決める。
2. 契約（Repository / UseCase / Api）を先に合わせ、そのあと実装とテストを直す。
3. 関連テストを実行する（例: `flutter test`、または変更ファイルに対応するテスト）。
4. UI を変えた場合は、影響する画面フローを確認する。

## 言語・スタイル

- エージェントの返答は日本語。
- Dart の識別子は既存どおり英語。ユーザー向け文字列は日本語。
- 既存ファイルの書き方（Equatable、`call()` を持つ UseCase、Riverpod の Provider 配置）に合わせる。

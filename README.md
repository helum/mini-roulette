# mini_roulette

複数のルーレットを登録して回す Flutter ミニアプリです。対象プラットフォームは Android です。

## 必要環境

| 項目 | 要件 |
| --- | --- |
| Flutter | **3.38 以降**（同梱 Dart が **3.10.4 以上**であること。`pubspec.yaml` の `sdk: ^3.10.4`） |
| JDK | **17**（Android Gradle が Java 17 を要求。Android Studio 同梱 JDK で可） |
| Android SDK | Android Studio 経由で導入。Command-line Tools / Build-Tools / Platform を含める |
| Git | リポジトリの取得に使用 |
| 端末 | Android 実機（USB デバッグ）または Android エミュレータ |

Dart SDK を別途入れる必要はありません。Flutter SDK に同梱されます。

## 環境構築

公式手順の詳細は [Install Flutter](https://docs.flutter.dev/install) と [Set up Android](https://docs.flutter.dev/platform-integration/android/setup) を参照してください。

### 1. Flutter SDK を入れる

1. [Flutter SDK のアーカイブ](https://docs.flutter.dev/install/manual) を取得し、スペースを含まないパスへ展開する（例: `C:\src\flutter`）。
2. `flutter\bin` を PATH に追加する。
   - Windows: 「システムのプロパティ」→「環境変数」→ Path に `C:\src\flutter\bin` を追加。
3. ターミナルを開き直して確認する。

```bash
flutter --version
```

`Flutter 3.38` 以降、かつ `Dart 3.10.4` 以降であることを確認してください。古い場合は `flutter upgrade` するか、対応する SDK を入れ直します。

### 2. Android ツールチェーンを入れる

1. [Android Studio](https://developer.android.com/studio) をインストールする。
2. Android Studio の SDK Manager で次を入れる。
   - Android SDK Platform（最新の安定版）
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools（`adb` を含む）
3. 初回は SDK ライセンスに同意する。

```bash
flutter doctor --android-licenses
```

### 3. 導入状況を確認する

```bash
flutter doctor
```

`Flutter` と `Android toolchain` が問題なしになるまで直します。`flutter doctor -v` で Java のパスとバージョンも確認できます。

### 4. 依存関係を取得する

プロジェクトルートで実行します。

```bash
flutter pub get
```

## デバッグ起動

実機を使う場合は、端末の「開発者向けオプション」で **USB デバッグ** を有効にし、PC に接続して端末側でデバッグを許可してください。エミュレータを使う場合は、Android Studio の Device Manager から AVD を起動します。

接続確認:

```bash
flutter devices
```

### コマンドライン

プロジェクトルートで次を実行します。端末が 1 台ならそのまま起動します。

```bash
flutter run
```

複数台あるときはデバイス ID を指定します。

```bash
flutter devices
flutter run -d <device_id>
```

起動後のターミナル操作:

| キー | 動作 |
| --- | --- |
| `r` | ホットリロード |
| `R` | ホットリスタート |
| `q` | 終了 |

### IDE（Cursor / VS Code / Android Studio）

1. Flutter / Dart 拡張（または Android Studio の Flutter プラグイン）を入れる。
2. プロジェクトルートを開く。
3. デバッグ対象の端末を選ぶ。
4. `lib/main.dart` を開いた状態で **F5**（または Run / Debug）を実行する。

ブレークポイントは Dart ソースに置けます。ホットリロードは保存時、またはデバッグツールバーから実行できます。

## APK のビルドとインストール

現在の release ビルドは **デバッグ用キーで署名** しています（`android/app/build.gradle.kts`）。手元の実機へのインストールや動作確認用です。Google Play への公開には、別途リリース用キーストアの設定が必要です。

### ビルド

プロジェクトルートで実行します。

```bash
# リリース APK（全 ABI 入り。実機インストール向け）
flutter build apk --release

# ABI ごとに分割（ファイルサイズを抑えたい場合）
flutter build apk --release --split-per-abi

# デバッグ APK
flutter build apk --debug
```

生成物:

| コマンド | 出力パス |
| --- | --- |
| `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build apk --release --split-per-abi` | `build/app/outputs/flutter-apk/app-<abi>-release.apk`（例: `app-arm64-v8a-release.apk`） |
| `flutter build apk --debug` | `build/app/outputs/flutter-apk/app-debug.apk` |

最近の実機は `arm64-v8a` が一般的です。分割ビルドを使う場合はその APK を選んでください。

### USB でインストール

端末が `adb` で見えることを確認します。

```bash
adb devices
```

ビルド済み APK を上書きインストールします。

```bash
# リリース APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 直前のビルドを入れて起動する（接続端末が 1 台のとき）
flutter install --release
```

分割 APK の場合は対象 ABI のファイルを指定します。

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### APK ファイルを端末へコピーしてインストール

1. `app-release.apk` を端末へ送る（USB ファイル転送、クラウド、メールなど）。
2. 端末のファイルアプリから APK を開く。
3. 「提供元不明のアプリ」のインストール許可を求められたら、そのアプリにだけ許可する。
4. インストール完了後、ランチャーの「ミニルーレット」から起動する。

パッケージ ID は `com.miniroulette.app` です。同じ ID の別署名 APK が既にあると上書きに失敗するため、その場合は既存アプリを削除してから入れ直してください。

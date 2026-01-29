# Firebase設定ファイルのセットアップ

このプロジェクトでは、Firebase APIキーを含む設定ファイルをgit追跡から除外しています。

## 設定が必要なファイル

以下のファイルをセットアップする必要があります：

1. **firebase_options.dart** - Dart/Flutter用のFirebase設定
2. **google-services.json** - Android用のFirebase設定
3. **GoogleService-Info.plist** - iOS/macOS用のFirebase設定

## 方法1: FlutterFire CLI を使用（推奨）

最も簡単な方法は、FlutterFire CLIを使用してすべての設定ファイルを自動生成することです：

```bash
# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli

# Firebaseプロジェクトと連携して設定ファイルを生成
flutterfire configure
```

このコマンドを実行すると、以下のファイルが自動的に生成されます：
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

## 方法2: 手動でセットアップ

### 1. firebase_options.dart の設定

1. `firebase_options.dart.example` ファイルを `firebase_options.dart` にコピー:
   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```

2. Firebase Consoleから取得したAPIキーで `firebase_options.dart` を更新:
   - `YOUR_WEB_API_KEY` → 実際のWeb APIキー
   - `YOUR_WEB_APP_ID` → 実際のWeb App ID
   - `YOUR_MESSAGING_SENDER_ID` → 実際のMessaging Sender ID
   - `YOUR_PROJECT_ID` → 実際のProject ID
   - `YOUR_MEASUREMENT_ID` → 実際のMeasurement ID
   - iOS/Android設定も同様に更新

### 2. google-services.json の設定（Android）

1. サンプルファイルをコピー:
   ```bash
   cp android/app/google-services.json.example android/app/google-services.json
   ```

2. Firebase ConsoleのProject Settings → General → Your appsからAndroidアプリを選択し、`google-services.json`をダウンロード

3. ダウンロードしたファイルを `android/app/google-services.json` に配置

### 3. GoogleService-Info.plist の設定（iOS/macOS）

1. サンプルファイルをコピー:
   ```bash
   cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
   cp macos/Runner/GoogleService-Info.plist.example macos/Runner/GoogleService-Info.plist
   ```

2. Firebase ConsoleのProject Settings → General → Your appsからiOS/macOSアプリを選択し、`GoogleService-Info.plist`をダウンロード

3. ダウンロードしたファイルを以下に配置:
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - macOS: `macos/Runner/GoogleService-Info.plist`

## 注意事項

- これらの設定ファイルはgit追跡されません（`.gitignore`に追加済み）
- 実際のAPIキーを含むファイルは**絶対にコミットしないでください**
- チーム開発の場合、各開発者が個別に設定ファイルを作成する必要があります
- セキュリティのため、本番環境とテスト環境で異なるFirebaseプロジェクトを使用することを推奨します

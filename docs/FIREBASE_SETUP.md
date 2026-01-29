# Firebase設定ファイルのセットアップ

## firebase_options.dart の設定方法

このプロジェクトでは、Firebase APIキーを含む `firebase_options.dart` ファイルをgit追跡から除外しています。

### セットアップ手順

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

3. または、FlutterFire CLIを使用して自動生成:
   ```bash
   flutterfire configure
   ```

### 注意事項

- `firebase_options.dart` ファイルはgit追跡されません（`.gitignore`に追加済み）
- 実際のAPIキーを含むファイルは絶対にコミットしないでください
- チーム開発の場合、各開発者が個別に設定ファイルを作成する必要があります

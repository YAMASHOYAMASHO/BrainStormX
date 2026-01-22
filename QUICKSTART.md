# クイックスタートガイド / Quick Start Guide

## 日本語

### 5分でFlutter開発を始める

1. **Flutter SDKのインストール**
   - macOS/Linux: `git clone https://github.com/flutter/flutter.git -b stable`
   - Windows: [flutter.dev](https://flutter.dev)からダウンロード
   - パスを通す: `export PATH="$PATH:[Flutterのパス]/bin"`

2. **セットアップの確認**
   ```bash
   flutter doctor
   ```

3. **プロジェクトの準備**
   ```bash
   cd BrainStormX
   flutter pub get
   ```

4. **アプリの実行**
   ```bash
   flutter run
   ```
   または
   ```bash
   make run
   ```

### よく使うコマンド

```bash
make install      # 依存関係をインストール
make run          # アプリを実行
make test         # テストを実行
make build-apk    # Androidビルド
make build-web    # Webビルド
make doctor       # 環境チェック
make help         # ヘルプを表示
```

## English

### Get Started with Flutter in 5 Minutes

1. **Install Flutter SDK**
   - macOS/Linux: `git clone https://github.com/flutter/flutter.git -b stable`
   - Windows: Download from [flutter.dev](https://flutter.dev)
   - Add to PATH: `export PATH="$PATH:[path-to-flutter]/bin"`

2. **Verify Setup**
   ```bash
   flutter doctor
   ```

3. **Prepare Project**
   ```bash
   cd BrainStormX
   flutter pub get
   ```

4. **Run the App**
   ```bash
   flutter run
   ```
   or
   ```bash
   make run
   ```

### Common Commands

```bash
make install      # Install dependencies
make run          # Run the app
make test         # Run tests
make build-apk    # Build for Android
make build-web    # Build for Web
make doctor       # Check environment
make help         # Show help
```

## Supported Platforms / 対応プラットフォーム

- ✅ Android
- ✅ iOS (macOS only)
- ✅ Web
- ⚠️ Linux (experimental)
- ⚠️ Windows (experimental)
- ⚠️ macOS (experimental)

## Next Steps / 次のステップ

1. Read the full setup guide: [FLUTTER_SETUP.md](FLUTTER_SETUP.md)
2. Explore the code in `lib/main.dart`
3. Try modifying the app and see hot reload in action!
4. Read Flutter documentation: https://flutter.dev/docs

## Troubleshooting / トラブルシューティング

### エラーが出た場合 / If you encounter errors

```bash
flutter clean
flutter pub get
flutter doctor -v
```

### ヘルプが必要な場合 / Need help?

- GitHub Issues: https://github.com/YAMASHOYAMASHO/BrainStormX/issues
- Flutter Documentation: https://flutter.dev/docs
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

# Flutter環境構築ガイド / Flutter Environment Setup Guide

このドキュメントでは、BrainstormXプロジェクトのFlutter開発環境の構築手順を説明します。

This document explains how to set up the Flutter development environment for the BrainstormX project.

## 前提条件 / Prerequisites

- macOS, Windows, Linux, または ChromeOS
- 十分なディスク容量 (最低2.5 GB)
- Git

## Flutter SDKのインストール / Installing Flutter SDK

### macOS

1. Flutter SDKをダウンロード:
```bash
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
```

2. パスを通す (.zshrcまたは.bashrcに追加):
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

3. 設定を反映:
```bash
source ~/.zshrc  # または source ~/.bashrc
```

### Windows

1. [Flutter公式サイト](https://flutter.dev/docs/get-started/install/windows)からSDKをダウンロード
2. ダウンロードしたzipファイルを展開 (例: `C:\src\flutter`)
3. システム環境変数のPathに `C:\src\flutter\bin` を追加

### Linux

1. Flutter SDKをダウンロード:
```bash
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
```

2. パスを通す (~/.bashrcに追加):
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

3. 設定を反映:
```bash
source ~/.bashrc
```

## 環境の確認 / Verify Installation

```bash
flutter doctor
```

このコマンドで、不足している依存関係やツールが表示されます。

## プラットフォーム別のセットアップ / Platform-specific Setup

### Android開発

1. Android Studioをインストール
2. Android SDKをインストール
3. Android エミュレータまたは実機を準備

### iOS開発 (macOSのみ)

1. Xcodeをインストール
2. CocoaPodsをインストール:
```bash
sudo gem install cocoapods
```

### Web開発

追加のセットアップは不要です。Chrome, Edge, Safari, Firefoxなどのブラウザで動作します。

## プロジェクトのセットアップ / Project Setup

1. このリポジトリをクローン:
```bash
git clone https://github.com/YAMASHOYAMASHO/BrainStormX.git
cd BrainStormX
```

2. 依存関係をインストール:
```bash
flutter pub get
```

3. 動作確認:
```bash
flutter run
```

## エディタのセットアップ / Editor Setup

### Visual Studio Code

1. VS Codeをインストール
2. Flutter拡張機能をインストール
3. Dart拡張機能をインストール

### Android Studio / IntelliJ IDEA

1. Flutter pluginをインストール
2. Dart pluginをインストール

## トラブルシューティング / Troubleshooting

### flutter doctorでエラーが出る場合

```bash
flutter doctor -v
```

詳細な情報を確認し、指示に従って不足しているツールをインストールしてください。

### 依存関係のエラー

```bash
flutter clean
flutter pub get
```

### キャッシュのクリア

```bash
flutter pub cache repair
```

## 参考資料 / Resources

- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [Dart公式ドキュメント](https://dart.dev/guides)
- [Flutter入門ガイド](https://flutter.dev/docs/get-started/codelab)

## サポート / Support

問題が発生した場合は、GitHubのIssuesで報告してください。

# Aquarium Monitoring System

## 概要
このプロジェクトは、水槽の水温と環境データをモニタリングし、データをダッシュボードで表示するシステムです。Raspberry Piを使用してセンサーデータを収集し、Flutterアプリケーションでデータを可視化します。

## 主な機能
- リアルタイムの水温、気温、湿度モニタリング
- 24時間の温度と湿度の推移グラフ
- データのデータベース保存とAPI経由でのアクセス
- クロスプラットフォーム対応のFlutterダッシュボードアプリケーション

## システム構成
1. **センサー部分（Raspberry Pi）**
   - 水温センサー
   - DHT22温湿度センサー
   - Python scripts for data collection

2. **バックエンド**
   - Flask RESTful API
   - SQLiteデータベース

3. **フロントエンド**
   - Flutterアプリケーション（デスクトップ対応）

## セットアップ手順

### Raspberry Pi セットアップ
1. 必要なライブラリをインストール:
   ```
   pip install flask flask-restful flask-cors seeed-dht
   ```

2. センサーを接続し、`aquarium_monitoring.py`スクリプトを実行:
   ```
   python3 /path/to/aquarium_monitoring.py
   ```

3. APIサーバーを起動:
   ```
   python3 /path/to/aquarium_api.py
   ```

### Flutter アプリケーションのセットアップ
1. Flutter SDKをインストール

2. 依存関係をインストール:
   ```
   flutter pub get
   ```

3. アプリケーションを実行:
   ```
   flutter run -d windows  # Windowsの場合
   flutter run -d macos    # macOSの場合
   flutter run -d linux    # Linuxの場合
   ```

## 使用技術
- **Backend**: Python, Flask, SQLite
- **Frontend**: Flutter, Dart
- **Sensors**: DS18B20 (水温), DHT22 (気温・湿度)
- **Hardware**: Raspberry Pi

## 注意事項
- APIのベースURLは`constants.dart`ファイルで設定されています。必要に応じて変更してください。
- このシステムは家庭用の水槽監視を想定しています。大規模な用途には適していない可能性があります。

## 今後の展望
- モバイルアプリケーションの開発
- アラート機能の追加
- データ分析機能の強化

## ライセンス
このプロジェクトはMITライセンスの下で公開されています。詳細は`LICENSE`ファイルを参照してください。

## コントリビューション
バグ報告や機能リクエストは、GitHubのIssueで受け付けています。プルリクエストも歓迎します。

## 作者
hasumirihito

---

ご質問やフィードバックがありましたら、お気軽にお問い合わせください。

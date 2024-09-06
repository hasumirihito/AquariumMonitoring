from google.cloud import bigquery
from datetime import datetime
import os

# プロジェクトIDを環境変数から取得
project_id = os.environ.get('GOOGLE_CLOUD_PROJECT')

# クライアントの初期化時にプロジェクトIDを明示的に指定
client = bigquery.Client(project=project_id)

# プロジェクト ID、データセット ID、テーブル ID を設定
dataset_id = "aquarium_data"
table_id = "monitaring_data"

# テーブルの完全な参照を作成
table_ref = f"{client.project}.{dataset_id}.{table_id}"

# 現在の日時を取得
current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# 挿入するデータを準備
rows_to_insert = [
    {
        "aquarium_id": "sensor_001",
        "water_temperature": 25.5,
        "date_acquisition": current_time,
        "temperature": 28.0,  # 室温（NULLABLEなので省略可能）
        "humidity": 60.5,     # 湿度（NULLABLEなので省略可能）
        "water_level": 50.0   # 水位（NULLABLEなので省略可能）
    }
]

# データを挿入
try:
    errors = client.insert_rows_json(table_ref, rows_to_insert)
    if errors == []:
        print("新しい行が正常に追加されました。")
    else:
        print("データの挿入中にエラーが発生しました: {}".format(errors))
except Exception as e:
    print(f"エラーが発生しました: {e}")

from flask import Flask, request, jsonify, has_request_context
from flask_restful import Api, Resource
from flask_cors import CORS
import sqlite3
from datetime import datetime
import logging
from logging.handlers import TimedRotatingFileHandler
import os

app = Flask(__name__)
CORS(app)
api = Api(app)

DB_PATH = '/var/lib/aquarium_monitoring/aquarium.db'
LOG_PATH = '/var/log/aquarium_monitoring'

# ユーザー名を取得する関数
def get_username():
    # 実際の環境に応じて適切な方法でユーザー名を取得してください
    return "unknown_user"

# IPアドレスを取得する関数
def get_ip_address():
    if has_request_context():
        return request.remote_addr
    return "N/A"  # リクエストコンテキスト外の場合

# カスタムログフォーマッタの作成
class CustomFormatter(logging.Formatter):
    def format(self, record):
        timestamp = datetime.fromtimestamp(record.created).strftime("%Y-%m-%d %H:%M:%S")
        username = get_username()
        ip_address = get_ip_address()
        log_message = f"{timestamp} [{record.levelname}] [{username}] [{ip_address}] {record.getMessage()}"
        if record.exc_info:
            log_message += '\n' + self.formatException(record.exc_info)
        return log_message

# ログディレクトリが存在しない場合は作成
os.makedirs(LOG_PATH, exist_ok=True)

# ログファイル名に日付を追加
log_file_name = os.path.join(LOG_PATH, 'aquarium_api_{}.log'.format(datetime.now().strftime('%Y%m%d')))

# ログの設定
handler = TimedRotatingFileHandler(log_file_name, when="midnight", interval=1, backupCount=30)
handler.setFormatter(CustomFormatter())
handler.setLevel(logging.INFO)
app.logger.addHandler(handler)
app.logger.setLevel(logging.INFO)

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

class WaterTemperature(Resource):
    def get(self):
        app.logger.info('Received GET request for water temperature')
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = dict_factory
        cursor = conn.cursor()

        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        limit = request.args.get('limit', type=int)

        try:
            if start_date and end_date:
                app.logger.info(f'Querying data between {start_date} and {end_date}')
                query = '''
                SELECT 
                    wt.id AS water_temp_id,
                    wt.temperature AS water_temperature,
                    wt.timestamp AS water_temp_timestamp,
                    ed.id AS env_data_id,
                    ed.temperature AS air_temperature,
                    ed.humidity,
                    ed.timestamp AS env_data_timestamp
                FROM 
                    water_temperature wt
                JOIN 
                    environmental_data ed
                ON 
                    wt.timestamp = ed.timestamp
                WHERE ed.timestamp BETWEEN ? AND ?
                ORDER BY ed.timestamp DESC
                '''
                params = (start_date, end_date)
            else:
                app.logger.info('Querying latest data')
                query = '''
                WITH latest_water_temp AS (
                SELECT * FROM water_temperature
                ORDER BY timestamp DESC
                LIMIT 1
                )
                SELECT 
                    wt.id AS water_temp_id,
                    wt.temperature AS water_temperature,
                    wt.timestamp AS water_temp_timestamp,
                    ed.id AS env_data_id,
                    ed.temperature AS air_temperature,
                    ed.humidity,
                    ed.timestamp AS env_data_timestamp
                FROM 
                    latest_water_temp wt
                JOIN 
                    environmental_data ed
                ON 
                    wt.timestamp = ed.timestamp
                '''
                params = ()

            if limit:
                query += ' LIMIT ?'
                params += (limit,)

            cursor.execute(query, params)
            results = cursor.fetchall()
            app.logger.info(f'Retrieved {len(results)} records')
        except sqlite3.Error as e:
            app.logger.error(f'Database error: {e}', exc_info=True)
            return jsonify({'error': 'Database error occurred'}), 500
        finally:
            conn.close()

        return jsonify(results)

api.add_resource(WaterTemperature, '/water_temperature')

@app.before_request
def log_request_info():
    app.logger.info(f'Received request: {request.method} {request.url}')

@app.after_request
def log_response_info(response):
    app.logger.info(f'Sending response: status {response.status_code}')
    return response

if __name__ == '__main__':
    app.logger.info('Starting the Aquarium Monitoring API')
    app.run(debug=True, host='0.0.0.0', port=5000)
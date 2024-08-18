import sys
import subprocess
import logging
import os
import sqlite3
from datetime import datetime
 
# SENSOR_ID = "28-0267b00a6461"
ERR_VAL = 85000
DATABASE = "/var/lib/aquarium_monitoring/aquarium.db"
LOG_PATH_DIR = "/var/log/aquarium_monitoring"

def get_sensor_id():
    """
    SENSOR_IDを環境変数から取得する関数
    環境変数が設定されていない場合はデフォルト値を返す
    """
    return os.getenv('SENSOR_ID', 'unknown_sensor')

def get_username():
    """
    SSHユーザー名を取得する関数
    複数の方法を試みて、最も信頼できる情報を返す
    """
    try:
        return os.getlogin()
    except:
        try:
            return pwd.getpwuid(os.getuid()).pw_name
        except:
            return os.environ.get('LOGNAME') or os.environ.get('USER') or getpass.getuser() or 'unknown_user'

def get_ip_address():
    """
    接続元のIPアドレスを取得する関数
    SSH接続の場合はSSH_CLIENTまたはSSH_CONNECTION環境変数から取得
    ローカル接続の場合はループバックアドレスを返す
    """
    ssh_client = os.environ.get('SSH_CLIENT')
    ssh_connection = os.environ.get('SSH_CONNECTION')
    
    if ssh_client:
        return ssh_client.split()[0]
    elif ssh_connection:
        return ssh_connection.split()[0]
    else:
        return '127.0.0.1'  # ローカル接続の場合

# カスタムログフォーマッタの作成
class CustomFormatter(logging.Formatter):
    def format(self, record):
        timestamp = datetime.fromtimestamp(record.created).strftime("%Y-%m-%d %H:%M:%S")
        username = get_username()
        ip_address = get_ip_address()
        return f"{timestamp} [{record.levelname}] [{username}] [{ip_address}] {record.getMessage()}"

def setup_logger(log_directory=None):
    # ログディレクトリの設定
    if log_directory is None:
        # 環境変数からログディレクトリを取得、設定されていない場合はデフォルト値を使用
        log_directory = os.environ.get('LOG_DIRECTORY', os.path.join(os.getcwd(), 'logs'))
    
    # ログディレクトリが存在しない場合は作成
    os.makedirs(log_directory, exist_ok=True)
    
    # 現在の日付を取得してログファイル名を生成
    current_date = datetime.now().strftime("%Y%m%d")
    log_filename = f"aquariumlog_{current_date}.log"
    
    # ログファイルのパスを設定
    log_file_path = os.path.join(log_directory, log_filename)

    # ロガーの設定
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)

    # ファイルハンドラの作成と設定
    file_handler = logging.FileHandler(log_file_path, encoding='utf-8')
    file_handler.setFormatter(CustomFormatter())
    logger.addHandler(file_handler)

    # コンソール出力用のハンドラ（オプション）
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(CustomFormatter())
    logger.addHandler(console_handler)

    return logger, log_file_path

def create_connection(db_file):
    """データベースへの接続を作成し、接続を返す"""
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except sqlite3.Error as e:
        logger.error(f"データベース接続エラー: {e}")
    return conn

def create_table(conn):
    """水温管理用のテーブルを作成する"""
    try:
        c = conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS water_temperature
                     (id INTEGER PRIMARY KEY AUTOINCREMENT,
                      temperature REAL NOT NULL,
                      timestamp TEXT NOT NULL)''')
    except sqlite3.Error as e:
        logger.error(f"テーブル作成エラー: {e}")

def insert_temperature(conn, temperature):
    """水温データを挿入する"""
    sql = ''' INSERT INTO water_temperature(temperature,timestamp)
              VALUES(?,?) '''
    cur = conn.cursor()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cur.execute(sql, (temperature, timestamp))
    conn.commit()
    return cur.lastrowid

def get_water_temp_val(sensorId):
    try:
        res = subprocess.check_output(["cat", "/sys/bus/w1/devices/" + sensorId + "/w1_slave"], universal_newlines=True)
        return res
    except:
        return None

def main():
    # ロガーのセットアップ
    logger, log_file_path = setup_logger(LOG_PATH_DIR)

    SENSOR_ID = get_sensor_id()
    if SENSOR_ID == 'unknown_sensor':
        logger.error(f"環境変数：SENSOR_ID({SENSOR_ID})が設定されていません。")
        sys.exit(1)

    conn = create_connection(DATABASE)
    if conn is None:
        logger.error("データベースに接続できませんでした。")
        sys.exit(1)

    create_table(conn)

    res = get_water_temp_val(SENSOR_ID)
    if res is not None:
        temp_val = res.split("=")
        if temp_val[-1] == str(ERR_VAL):
            print("Circuit is ok, but something wrong happens...")
            conn.close()
            sys.exit(1)
        
        temp_val = round(float(temp_val[-1]) / 1000, 1)
        logger.info(f"水温: {temp_val}°C({SENSOR_ID})")

        # データベースに水温を挿入
        inserted_id = insert_temperature(conn, temp_val)
        logger.debug(f"INSERT DATA : {inserted_id}")

    else:
        logger.error("水温を読み取れませんでした。")
        conn.close()
        sys.exit(1)

    conn.close()

if __name__ == "__main__":
    main()

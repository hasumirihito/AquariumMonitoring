- ポート利用チェック
`sudo lsof -i |grep :5000`

- pythonの仮想環境構築手順
```
rm -rf ~/python3_env
python3 -m venv ~/python3_env
source ~/python3_env/bin/activate
```

- ライブラリインストール
```
pip install -U flask-cors
pip install flask-restful
```
FROM ubuntu:latest

# システムのパッケージリストを更新し、必要なパッケージをインストール
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    git \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app

# 環境変数を設定（例）
ENV APP_ENV=production

# ポートを公開（必要に応じて）
# EXPOSE 8080

# コンテナ起動時に実行されるコマンド
CMD ["/bin/bash"]

# 以下はオプションの追加設定例：

# ファイルをコンテナにコピー
# COPY ./app /app

# ボリュームをマウント
# VOLUME /app/data

# 特定のユーザーを作成して切り替え
# RUN useradd -ms /bin/bash appuser
# USER appuser
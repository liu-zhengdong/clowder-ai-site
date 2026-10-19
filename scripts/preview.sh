#!/usr/bin/env bash
# 构建静态站并起本地服务。改动文档后重新跑一次即可。
set -euo pipefail
cd "$(dirname "$0")/.."

ATLAS_SITE=${ATLAS_SITE:-../atlas-site/build.py}
[ -f "$ATLAS_SITE" ] || { echo "找不到建站工具：$ATLAS_SITE（设 ATLAS_SITE 指过去）" >&2; exit 1; }
PORT=${PORT:-8791}

bash scripts/compose.sh
python3 "$ATLAS_SITE" \
  --repo .build \
  --out .site \
  --source-url https://github.com/zts212653/clowder-ai/blob/main/

echo
echo "http://127.0.0.1:$PORT/  （Ctrl-C 停止）"
cd .site && exec python3 -m http.server "$PORT" --bind 127.0.0.1

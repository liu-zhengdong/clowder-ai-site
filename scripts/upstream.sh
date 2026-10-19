#!/usr/bin/env bash
# 确保 .cache/upstream/ 里有一份被描述的那个代码仓库的浅克隆。
# 审计脚本靠它核 code: 锚点、「文档地图」可达性与 verified: 漂移。
set -euo pipefail
cd "$(dirname "$0")/.."

REPO=${CLOWDER_REPO:-https://github.com/zts212653/clowder-ai.git}
DIR=.cache/upstream

if [ -d "$DIR/.git" ]; then
  echo "upstream: 已有，更新到 origin 最新"
  git -C "$DIR" fetch --depth 1 -q origin
  git -C "$DIR" reset --hard -q FETCH_HEAD
else
  echo "upstream: 浅克隆 $REPO（约 470 MB，第一次会慢）"
  mkdir -p .cache
  git clone --depth 1 -q "$REPO" "$DIR"
fi

echo "upstream: $(git -C "$DIR" rev-parse --short HEAD)"

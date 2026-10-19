#!/usr/bin/env bash
# 构建站点并发布到 gh-pages 分支。
#
# Pages 从这个分支直接发布，所以不需要 CI 去拉私有工具仓或上游代码——
# 构建全在本机做完，只把产物推上去。main 分支里始终只有 Markdown 和脚本。
#
# 用法：scripts/publish.sh [站点网址]
set -euo pipefail
cd "$(dirname "$0")/.."

ATLAS_SITE=${ATLAS_SITE:-../atlas-site/build.py}
[ -f "$ATLAS_SITE" ] || { echo "找不到建站工具：$ATLAS_SITE（设 ATLAS_SITE 指过去）" >&2; exit 1; }

REMOTE=${REMOTE:-$(git remote get-url origin)}
SITE_URL=${1:-${SITE_URL:-https://liu-zhengdong.github.io/clowder-ai-site/}}

scripts/upstream.sh >/dev/null
python3 scripts/atlas_audit.py
bash scripts/compose.sh >/dev/null

echo "== 建站 =="
python3 "$ATLAS_SITE" \
  --repo .build \
  --out .site \
  --source-url https://github.com/zts212653/clowder-ai/blob/main/ \
  --site-url "$SITE_URL"

# 用临时 git 目录把产物推成一个孤立分支，不碰当前工作区
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git -C "$TMP" init -q -b gh-pages .
cp -R .site/. "$TMP"/
touch "$TMP/.nojekyll"          # 站点有以 _ 开头的资源，绕开 Jekyll
git -C "$TMP" add -A
git -C "$TMP" -c user.name="$(git config user.name || echo publish)" \
  -c user.email="$(git config user.email || echo publish@local)" \
  commit -q -m "site: 发布 $(date -u +%Y-%m-%dT%H:%MZ) 构建的站点"
git -C "$TMP" push -q --force "$REMOTE" gh-pages

echo
echo "已发布到 gh-pages → $SITE_URL"

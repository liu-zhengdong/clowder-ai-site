#!/usr/bin/env bash
# 拼出一个「仓库形状」的临时根目录给建站工具用。
#
# 本站的文档住在这里，代码住在 zts212653/clowder-ai。建站工具只认一个
# --repo 根目录，并且会在这个根里检查 code: 锚点和指向代码的相对链接。
# 只给它这几份 Markdown，每个 code: 锚点都会被渲染成「路径不存在」。
#
# 所以这里用软链接拼一个只读的合成根：上游的每个顶层条目链过去，只有
# docs/ 要单独处理——把上游 docs/ 下的每一项链进去，唯独 docs/atlas 换成
# 本仓库的这一份。全部是软链接，不复制内容。
#
# 用法：scripts/compose.sh [合成根]（默认 .build）
set -euo pipefail
cd "$(dirname "$0")/.."

UP=${UPSTREAM_DIR:-.cache/upstream}
OUT=${1:-.build}

[ -d "$UP/.git" ] || { echo "缺少上游克隆 $UP，先跑 scripts/upstream.sh" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/docs"

# 上游顶层条目，docs 单独处理
for e in "$UP"/*; do
  n=$(basename "$e")
  [ "$n" = "docs" ] && continue
  ln -s "$(cd "$UP" && pwd)/$n" "$OUT/$n"
done

# 上游 docs/ 下每一项，atlas 换成自己的
for e in "$UP/docs"/*; do
  n=$(basename "$e")
  [ "$n" = "atlas" ] && continue
  ln -s "$(cd "$UP/docs" && pwd)/$n" "$OUT/docs/$n"
done
ln -s "$(pwd)/docs/atlas" "$OUT/docs/atlas"

echo "composed $OUT ← 上游 $(git -C "$UP" rev-parse --short HEAD) + 本仓库 docs/atlas"

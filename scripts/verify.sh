#!/usr/bin/env bash
# 一遍跑完三件事：拉上游 → 审计 atlas → 建站并查链接。
# 任何一步失败就停，退出码非零。
set -euo pipefail
cd "$(dirname "$0")/.."

# atlas-site 是独立的建站工具，不在本仓库里。
# 默认假设它克隆在本仓库的兄弟目录；别处就设 ATLAS_SITE。
ATLAS_SITE=${ATLAS_SITE:-../atlas-site/build.py}
[ -f "$ATLAS_SITE" ] || { echo "找不到建站工具：$ATLAS_SITE（设 ATLAS_SITE 指过去）" >&2; exit 1; }

scripts/upstream.sh
echo
echo "== atlas 审计 =="
python3 scripts/atlas_audit.py
echo
echo "== 建站 =="
bash scripts/compose.sh
python3 "$ATLAS_SITE" \
  --repo .build \
  --out .site \
  --source-url https://github.com/zts212653/clowder-ai/blob/main/

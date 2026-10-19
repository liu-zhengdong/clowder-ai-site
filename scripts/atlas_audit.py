#!/usr/bin/env python3
"""Atlas audit for a docs-only atlas that documents a separate code repository.

The atlas lives here; the code it describes lives in zts212653/clowder-ai.
Plain doc-atlas audits resolve `code:` anchors, `verified:` drift and the
document map against the *same* checkout, which this repo does not have. So
those three checks run against an upstream checkout at .cache/upstream
(a `git clone --depth 1` of the code repo; see scripts/upstream.sh).

Run from the repository root. Exit code 1 when any issue is found.
"""
import argparse
import pathlib
import re
import subprocess

GH = 'https://github.com/zts212653/clowder-ai'
BUDGET = 250  # doc-atlas: 组成节点 250 行；本仓库没有需要 60 行预算的 AGENTS.md 入口

ap = argparse.ArgumentParser()
ap.add_argument('--atlas', default='docs/atlas')
ap.add_argument('--upstream', default='.cache/upstream',
                help='checkout of the documented code repo; its checks are skipped when absent')
args = ap.parse_args()

ROOT = pathlib.Path('.').resolve()
ATLAS = ROOT / args.atlas
TREE_ROOT = ATLAS / 'README.md'
UPSTREAM = ROOT / args.upstream
have_upstream = UPSTREAM.is_dir()

nodes = sorted(ATLAS.rglob('*.md'))
linked, issues = set(), []
CODE_URL = re.compile(re.escape(GH) + r'/(?:blob|tree)/main/([^)\s#]+)')


def front(p):
    m = re.match(r'---\n(.*?)\n---', p.read_text(encoding='utf-8'), re.S)
    return m.group(1) if m else ''


def field_list(head, key):
    m = re.search(rf'^{key}:\s*\[(.*?)\]', head, re.M)
    return [a.strip() for a in m.group(1).split(',') if a.strip()] if m else []


def field(head, key):
    m = re.search(rf'^{key}:\s*([^\s#]+)', head, re.M)
    return m.group(1) if m else None


for p in nodes:
    text = p.read_text(encoding='utf-8')
    head = front(p)
    rel = p.relative_to(ROOT)
    is_root = p == TREE_ROOT

    if not field(head, 'kind'):
        issues.append(f'[meta]   {rel}: missing kind in frontmatter')
    if re.search(r'^(<{7} |={7}$|>{7} )', text, re.M):
        issues.append(f'[merge]  {rel}: leftover merge conflict markers')

    lines = text.count('\n')
    if lines > BUDGET:
        issues.append(f'[size]   {rel}: {lines} lines > {BUDGET}')

    # code: 锚点指向代码仓库，相对代码仓库根
    code = field_list(head, 'code')
    if code and have_upstream:
        for a in code:
            if not (UPSTREAM / a).exists():
                issues.append(f'[anchor] {rel}: missing {a} in upstream')

    ver = re.search(r'^verified:.*@\s*([0-9a-f]{7,40})', head, re.M)
    if code and not ver:
        issues.append(f'[stale?] {rel}: no verified commit')
    elif code and ver and have_upstream:
        r = subprocess.run(['git', 'rev-list', '--count', f'{ver.group(1)}..HEAD', '--', *code],
                           capture_output=True, text=True, cwd=UPSTREAM)
        if r.returncode:
            issues.append(f'[stale?] {rel}: verified commit {ver.group(1)} not found in upstream')
        elif int(r.stdout.strip() or 0) > 0:
            issues.append(f'[stale?] {rel}: {r.stdout.strip()} commits touched its code since verified')

    # atlas 内部链接按文件解析
    for link in re.findall(r'\]\(((?!https?:|mailto:|<)[^)\s#]+)', text):
        target = (p.parent / link).resolve()
        if not target.exists():
            issues.append(f'[link]   {rel}: broken link {link}')
        elif target.suffix == '.md' or target.is_dir():
            linked.add(target)

    # 跨仓库链接必须是绝对地址：相对路径在新仓库解析不到，站点会退化成纯文字。
    # 落在 atlas 目录内的相对链接是正确的（ideas/ 用 ../ 指组成节点），不报。
    for link in re.findall(r'\]\((\.\./[^)\s]+)', text):
        target = (p.parent / link).resolve()
        if ATLAS not in target.parents and target != ATLAS:
            issues.append(f'[link]   {rel}: cross-repo link still relative {link}')

    # 指向代码仓库的绝对地址：路径要在上游存在；.md 的算作已挂进文档地图
    for m in CODE_URL.finditer(text):
        up = m.group(1).rstrip('/')
        linked.add(('upstream', up))
        if have_upstream and not (UPSTREAM / up).exists():
            issues.append(f'[link]   {rel}: {up} does not exist upstream')

for p in nodes:
    if p != TREE_ROOT and p.resolve() not in linked:
        issues.append(f'[orphan] {p.relative_to(ROOT)}: no node links here')

# 文档地图：代码仓库里的每份 .md 都要能从某个绝对链接（或它所在目录）走到
if have_upstream:
    dirs = {x[1] for x in linked if isinstance(x, tuple)}
    for p in sorted(UPSTREAM.rglob('*.md')):
        if {'.git', '.github', 'node_modules', 'vendor', 'dist', 'build'} & set(p.relative_to(UPSTREAM).parts):
            continue
        up = p.relative_to(UPSTREAM).as_posix()
        if ('upstream', up) in linked:
            continue
        if any(up.startswith(d + '/') for d in dirs):
            continue
        issues.append(f'[unmapped] {up}: not reachable from atlas document map')

print('\n'.join(issues) or 'atlas OK')
raise SystemExit(1 if issues else 0)

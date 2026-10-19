# Clowder AI · 文档站

Clowder AI 的架构中枢文档。它回答一个问题：**Clowder AI 究竟是什么、由什么组成、各部分怎么配合。**

文档本身描述的是 [zts212653/clowder-ai](https://github.com/zts212653/clowder-ai) 这份代码仓库。文档放在这里，代码在那里——本仓库只有 Markdown 和两个脚本，没有代码。

## 从哪开始

读 [`docs/atlas/README.md`](docs/atlas/README.md)。它用 30 秒说清这是什么，再给九个组成节点的导航和一张「一条消息的一生」的走查图。

要改 Clowder AI 的代码，先在这份 atlas 里找到你改的那块属于哪个组成节点，再进代码仓库找对应的架构归属线。

## 看网页版

```sh
scripts/preview.sh          # 构建并起本地服务，浏览器打开 127.0.0.1:8791
```

构建产物在 `.site/`，是纯静态 HTML。发布时给 `build.py` 传 `--site-url`，让 `llms.txt` 和每页 `.md` 里的链接写成绝对地址。

## 改文档

```sh
scripts/verify.sh           # 一遍跑完：上游校验 + atlas 审计 + 建站链接检查
```

`scripts/verify.sh` 会先确保 `.cache/upstream/` 里有一份代码仓库的浅克隆，然后用它来核三件事：`code:` 锚点在代码里真的存在、「文档地图」真的能把代码仓库里每份 `.md` 走到、以及标了 `verified:` 的节点所引用的代码有没有在之后被改过。没有这份克隆，这三类检查只能跳过——所以别在没跑过 `verify.sh` 的情况下说文档是对的。

`.cache/` 和 `.site/` 不进版本库。

## 文档的规矩

格式按 `doc-atlas`：根节点 `docs/atlas/README.md`，组成节点 `kind: part`，思想节点 `docs/atlas/ideas/` 下 `kind: idea` + `guard: owner`。

两层内容的改动权限不同：根节点的「30 秒版」「愿景与思想」和整个 `ideas/` 属于**守护层**，只有仓库主人能改，AI 只能提议；其余组成节点属于**自由层**，可以随代码同步。所以给本仓库提 PR 时，动自由层可以直接提，动守护层请先开 issue 讨论。

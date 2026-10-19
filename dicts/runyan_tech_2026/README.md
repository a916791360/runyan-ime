# runyan_tech_2026 · 2026 AI / 互联网词库

润言自带的补充词库，收录 2026 年常见的 AI 公司与产品、AI 与开发术语、互联网流行语、平台与品牌。

以 `table_translator@runyan_tech` 挂载到雾凇拼音（见 `SharedSupport/runyan/defaults/rime_ice.yaml`），
可在设置里随方案一同关闭。

| 文件 | 内容 |
| --- | --- |
| `ai-companies-products.tsv` | AI 公司、模型与产品名 |
| `ai-terms-dev-tools.tsv` | AI 与开发术语 |
| `internet-brands-platforms.tsv` | 互联网品牌与平台 |

格式为 `词<TAB>编码<TAB>权重`。`scripts/fetch-dicts.sh` 会生成 `runyan_tech.txt` 放入 SharedSupport。

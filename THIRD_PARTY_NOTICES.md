# 第三方声明

润言（Runyan）源码采用 [MIT](LICENSE) 许可；完整版权声明见 LICENSE。MIT 许可不改变依赖、词库与社区文档各自的许可。润言不是鼠须管（Squirrel）的分支，不包含其 GPLv3 源码。

本清单覆盖润言随包分发与可下载的组件，不能替代各组件完整的许可正文。分发时须随附对应许可与版权声明（例如 rime-ice 的 `SharedSupport/LICENSE`）。

## Components and data

| Component | Upstream / license | Status and handling |
| --- | --- | --- |
| AIME (艾么输入法) | [zoolapp/aime](https://github.com/zoolapp/aime), MIT, © 2026 ZOOL LLC | **Upstream base.** 润言是它的二次开发：InputMethodKit 外壳、设置面板结构、候选窗绘制、包管理与 lua/词库加载方式源自 AIME；润言重做了品牌、外观与配色系统、中英混排整形、AI 动作流程与安装/构建脚本。上游版权与许可正文保留在 [LICENSE](LICENSE)，修改说明见 CHANGELOG。 |
| librime 1.17.0 (33e7814) | [rime/librime](https://github.com/rime/librime), BSD-3-Clause | **Bundled** as `Contents/Frameworks/librime.1.dylib` from the official prebuilt release; sha256 pinned in `Vendor/librime.lock`. Statically includes yaml-cpp (MIT), leveldb (BSD-3), marisa-trie (BSD-2/LGPL-2.1 dual), glog (BSD-3), OpenCC (Apache-2.0). |
| librime-lua (ec52e48) | [Pinned license](https://github.com/hchunhui/librime-lua/blob/ec52e48ea18f11af37717a01c337f853215cf70b/LICENSE), BSD-3-Clause | **Bundled** in `Contents/Frameworks/rime-plugins/` from the same librime release. Embeds Lua (MIT); the embedded Lua version and full notices remain to be audited. |
| librime-octagram (dfcc151) | [Pinned license](https://github.com/lotem/librime-octagram/blob/dfcc15115788c828d9dd7b4bff68067d3ce2ffb8/LICENSE), **GPL-3.0** | **Bundled native plugin**, linked to `librime.1.dylib`. Because the plugin is loaded into the same process, 润言将安装包视为结合作品，**整体按 GPL-3.0 条款分发**；源码本身保持 MIT，二者兼容。分发二进制时须一并提供对应的完整源码。 |
| librime-predict (920bd41) | [Pinned license](https://github.com/rime/librime-predict/blob/920bd41ebf6f9bf6855d14fbe80212e54e749791/LICENSE), BSD-3-Clause | **Bundled** in `Contents/Frameworks/rime-plugins/` from the same librime release. Transitive components remain to be audited. |
| OpenCC data | [BYVoid/OpenCC](https://github.com/BYVoid/OpenCC), Apache-2.0 | **Bundled** in `Contents/SharedSupport/opencc/` from the librime dependency archive. |
| GitHub Octicon mark | [primer/octicons](https://github.com/primer/octicons), MIT | **Bundled** as the About page's repository icon. The unmodified `mark-github-16.svg`, pinned source commit and SHA-256 are recorded in `SharedSupport/runyan/licenses/github-octicon.source.json`; its full license accompanies the resource. Displayed as a monochrome template image. |
| Unicode Emoji 16.0 data | [Unicode, Inc.](https://www.unicode.org/Public/emoji/16.0/emoji-test.txt), Unicode License V3 | **Bundled derived data** in `SharedSupport/runyan/emoji.json`: 1,906 fully-qualified sequences in the nine official groups, excluding skin-tone variants and retaining hair styles, variation selectors and ZWJ sequences. Group titles are translated into Chinese; original CLDR ordering is retained. Source: © 2024 Unicode®, Inc.; the [source/filter record](SharedSupport/runyan/licenses/unicode-emoji-16.0.source.json) pins version, SHA-256 and counts. The [full Unicode license](SharedSupport/runyan/licenses/unicode-emoji-16.0.LICENSE.txt) accompanies the data. Original generation code is MIT; these data remain under the Unicode license. |
| Yams | [jpsim/Yams](https://github.com/jpsim/Yams), MIT | Swift package dependency (version pinned in `Package.resolved`). |
| swift-argument-parser | [apple/swift-argument-parser](https://github.com/apple/swift-argument-parser), Apache-2.0 | Swift package dependency of the `runyan` CLI. |
| rime-ice / 雾凇拼音 2026.06.30 | [iDvel/rime-ice](https://github.com/iDvel/rime-ice), GPL-3.0 | **Bundled** in `Contents/SharedSupport/`: schemas, word lists and executable Lua scripts. Downloaded at build time by `scripts/fetch-dicts.sh`, never committed. Its `LICENSE` ships next to it; source is the pinned upstream release. Runyan intends to distribute it as a separate work; that boundary must be reviewed against the actual adaptations and coupling before release. It does not become MIT. Also installable as a package. |
| wanxiang / 万象拼音 v18.0.15 | [amzxyz/rime_wanxiang](https://github.com/amzxyz/rime_wanxiang), CC-BY-4.0 | Optional download through the package manager (sha256 pinned in `dicts/registry.json`); not bundled. |
| wanxiang-lts-zh-hans / 万象简体整句模型 | [amzxyz/RIME-LMDG](https://github.com/amzxyz/RIME-LMDG), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | **Optional download**, not bundled or enabled by default. Registry source pins an unmodified copy of the LTS asset published 2026-10-06 (GitHub asset `616996347`), 398,309,420 bytes, SHA-256 `c330bca73a4102b097fd6b239e6d10097a41995864f13004dec06e8cec98f2cc`. The unmodified `.gram` file runs locally through octagram. Attribution: “amzxyz and RIME-LMDG contributors”; source URL, license and attribution are retained in the installed manifest. The [fixed source/license record](SharedSupport/runyan/licenses/wanxiang-lts-zh-hans.source.json) and [full license](SharedSupport/runyan/licenses/wanxiang-lts-zh-hans.LICENSE.txt) accompany Runyan's shared data. |
| rime-frost / 白霜拼音 1.0.4 | [gaboolic/rime-frost](https://github.com/gaboolic/rime-frost), GPL-3.0 | Optional download; not bundled. |
| rime-essay / 八股文 | [rime/rime-essay](https://github.com/rime/rime-essay), LGPL-3.0 | Optional download of `essay.txt` at a pinned commit; not bundled. |
| Runyan online word lists | Runyan, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | **Optional subscription**, with a catalog shipped as `SharedSupport/runyan/vocabulary-catalog.json`. No word list is bundled; subscriptions are downloaded on demand and can be removed at any time. Online word lists are maintained in the separate `runyan-dicts` project. Attribution: “润言词表 — 杨冉 — CC BY 4.0”，再分发时保留来源地址与修改说明。品牌名归各自所有者，收录不代表背书。 |

## Distribution checklist

三个插件的许可正文与 Vendor 二进制哈希记录在 [native-plugin manifest](licenses/native-plugins/manifest.json)。构建时会把这些声明、插件许可与项目许可嵌入 `Contents/Resources/LicenseMaterials/` 后再签名；与已审计哈希不一致的输入会被拒绝。

Before publishing any binary or dictionary package:

1. Inventory the exact versions, source URLs, archive hashes, bundled libraries, plugins, scripts, and data files, including transitive components in prebuilt archives.
2. Include the full required license texts and copyright notices with the distributed artifacts, plus any applicable `NOTICE` file. This summary is not a substitute for those texts.
3. 安装包包含 GPL 组件（octagram 原生插件、rime-ice），因此整体按 GPL-3.0 条款分发，许可页须写明，并随发布提供对应完整源码。项目自身源码仍为 MIT，但合并后的二进制不能只按 MIT 提供。
4. Ensure original MIT source contains no copied, translated, or adapted GPL implementation code, including Squirrel code. Data import compatibility is not permission to copy source.
5. For CC BY 4.0 data, include attribution, a license link, and modification notices. Do not imply endorsement by named brands or upstream authors.

Licensing must be checked against the pinned artifact, not only a moving upstream branch. Resolve missing or conflicting provenance before adding or distributing a component.

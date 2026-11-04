# 第一章须庭 · Framecraft 增量压缩

2026-11-04。本批实际调用已安装 Framecraft `e5dc68902bdd1e86402bfbeafe27e5ed301b539c` 的本机 `/api/compression/frame`，仅处理 `story-c01/` 的 10 张 PNG：2 张角色动作图集、3 张新环境图、5 张复用构件。处理前逐张确认同步副本与源文件相同，且其原件哈希未出现在既有 Framecraft 批次。未把另外 10 张尚未处理的非本章 PNG 混入本批。

实际输入 **13,568,857 字节（12.94 MiB）**，选用输出 **12,344,842 字节（11.77 MiB）**，减少 **1,224,015 字节（1.17 MiB，9.02%）**。10 张平台输出全部小于原件；没有缩小分辨率、减帧或调色板量化。只清理 alpha=0 像素的不可见 RGB，尺寸、完整 Alpha 和可见 RGBA 逐像素相同。

| 对象 | 输入字节 | Framecraft 实际输出字节 |
| --- | ---: | ---: |
| 食腐甲图集 | 1,324,170 | 1,090,998 |
| 补巢者图集 | 2,013,484 | 1,548,017 |
| 须板支墩 | 1,633,152 | 1,513,352 |
| 骨平台 | 977,206 | 935,199 |
| 菌床 | 884,451 | 851,157 |
| 垂根 | 991,312 | 915,858 |
| 回流淤絮 | 853,331 | 703,233 |
| 壳营地 | 1,758,909 | 1,725,357 |
| 住巢 | 1,249,795 | 1,201,922 |
| 须庭全景 | 1,883,047 | 1,859,749 |

## 原件、真实结果与运行选择

[provenance.json](provenance.json) 保存输入源码提交、每图原始路径/哈希、平台响应哈希/字节、运行选用结果哈希/字节及工程路径。原件仍在原目录；可重开的 [Framecraft 工程](projects/8f42227e71a74cd991c867165acce602.framecraft/project.json) 再保留全部原件与真实平台输出。工程是 `.framecraft` 目录，`frames/` 为原件，`compression/results/` 为真实接口结果；即使以后平台输出更大，也必须保存真实结果，运行层另选较小原件。

运行映射只改 [同步清单](../../../../../game/art/manifest.json) 内这 10 张 PNG 的 `src`，目标路径与动作 JSON 不变；输出在 `assets/runtime/sprites/framecraft-runtime-batches/story-c01-2026-11-04/story-c01/`。图集格子、脚底原点、时长、循环和碰撞均未变更。

参数：`scale=1`、`algorithm=lanczos`（保真 PNG）、`resizeMode=soft`、`alphaThreshold=0`、`sharpen=0`。界面出现 `colors=256` 但仅调色板量化使用，本批没有启用该算法。工程的 12 FPS 仅用于十个独立文件的批次浏览，不是角色动作 FPS。

## 执行与验证

使用既有 Framecraft 的 Python 环境运行 [compress.py](../../compress.py)：

```sh
python assets/source/framecraft-runtime/compress.py --batch story-c01-2026-11-04 --dest-prefix story-c01/ --fresh
python assets/source/framecraft-runtime/compress.py --verify --batch story-c01-2026-11-04
```

首条已经执行成功，不得重跑覆盖本批；后续使用新批次名。`--dest-prefix` 限定目标子树，`--fresh` 确保逐图实际调用平台而非复用本地缓存。旧批次不要求新增字段，`--verify --batch 2026-11-04` 仍通过 111 对原件/结果与 2 个工程校验。

本轮已完成：

1. 10 次实际压缩接口调用；每图检查尺寸、完整 Alpha、alpha>0 的完整 RGBA，全部一致。
2. 使用 `/api/projects` 保存，再 GET 重开；确认 10 个原件与 10 个平台结果的顺序、参数及字节哈希恢复。另从磁盘复核工程与最终运行结果。
3. 在独立浏览器打开真实工作台，输入本批 `projects/` 目录并点击打开工程；界面恢复 10 帧、100% 原尺寸、阈值 0、锐化 0、12.94→11.77 MiB。逐项查看两张角色图集与全景的原件/压缩同尺寸对比，未出现可见变化，页面无异常。
4. 清单差异只涉及本章 10 个源映射；其它条目和目标路径保持一致。诊断截图/自动报告仅留 `game/build/qa/story-c01-art/`。

浏览器工具建页成功，但两次截图均返回 `Preview automation snapshot timed out after 15000ms.`，因此按回退规则使用独立 Playwright/Chromium 上下文打开真实 Framecraft 页面；没有用自制页面冒充工作台。

**收益边界：9.02%是 PNG 源文件节省量。** 随后主任务已同步并完成章节选择性导出，从入口递归选择130项资源，排除无关旧房与由现有动作图集替代的重复独立帧库；没有缩小图片或删减正在使用的动画帧。优化后 `downloads.json` 实测压缩引擎10,153,810字节、压缩PCK 41,651,618字节，启动下载合计 **115.51→49.41 MiB**；原始PCK为42,112,360字节。Godot会重新编码纹理，且导出资源范围已变化，因此不能把Web降幅归因于本次PNG压缩。

优化导出尚未发布；线上仍为源码 `f75a6b13` 对应版本。优化版真实Web路线复验、后续玩法调整与发布状态统一见 [游戏进度](../../../../../game/progress.md)，不以旧版通过记录替代新包验收。

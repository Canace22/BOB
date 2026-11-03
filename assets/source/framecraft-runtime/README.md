# Framecraft 运行图片压缩

正式工程当前使用的 856 张运行图片通过 Framecraft 的本机压缩接口处理，约 135.26 → 121.07 MiB（减少 10.48%）。输出放在 `assets/runtime/sprites/framecraft-runtime/`；`game/art/manifest.json` 同步到游戏。原始文件保存在本目录 `projects/` 的 9 个可重开 `.framecraft` 工程中。

本批保留原尺寸、完整颜色与 Alpha：保真 PNG、100% 尺寸、透明阈值 0、锐化 0。只清零完全透明像素里不可见的 RGB。若平台输出比输入更大，保留较小的输入文件；两者都经过可见像素与透明度一致性核对。没有使用调色板量化或重新抠图。

`provenance.json` 记录每张图片的来源哈希、平台输出哈希、最终输出、体积及工程位置。来源对应整理前的 [归档分支](https://github.com/Canace22/BOB/tree/codex/archive-legacy-20261103) 中 `game/art/<dest>`。图片压缩不改变游戏中的帧数、裁片、锚点、帧时长或循环设置；工程中的 12 FPS 只是压缩批次对比速度，不作为游戏动画数据。

先处理的全量 1,908 张图片中，1,052 张仅用于旧版或旧预览，随后从当前分支移出。当前保留的依据是默认入口、七房动态路径、现用角色技能参数场、Run 与环境预览的引用闭包，包含脚本动态拼接的身体/特效帧、音效变体及鱼群路径。`usage.json` 记录历史移出清单；游戏内的 `runtime-resources.json` 记录当前引用及拥有者。

首次处理时启动现有 Framecraft，使用其带 Pillow 和 NumPy 的 Python 环境运行：

```sh
python assets/source/framecraft-runtime/compress.py --url http://127.0.0.1:8765
node tools/godot.mjs sync-art
```

该脚本调用真实的 `/api/compression/frame`，按帧数和像素量拆分工程，再通过 `/api/projects` 保存并重开验证。脚本拒绝覆盖已完成批次；新增素材建立新批次。已有批次执行 `python assets/source/framecraft-runtime/compress.py --verify` 检查输出和来源工程；引用复核执行 `node game/tools/audit_resources.mjs`。临时缓存与自动验收报告放在 `game/build/qa/`。

在工作台顶部选择本目录的 `projects/`，打开对应工程即可比较原帧和压缩帧。项目文件和正式导出入库，ZIP 传输包不入库。最终体积与游戏验证见 [game/progress.md](../../../game/progress.md)。

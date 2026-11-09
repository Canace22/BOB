# 新增素材与游戏包压缩

本批处理后来接入的六房环境和拾潮者动作图集。打开 Framecraft，在顶部输入本目录的 `projects/` 路径，即可重开两个工程，比较原件与结果。工程内的图片是完整图集或场景分层；12 FPS 仅用于批次比较，游戏中的帧序、帧时长、裁片和锚点继续由原来的数据控制。

111 张图片实际调用 Framecraft `e5dc689` 的 `/api/compression/frame`，原尺寸、保真 PNG、透明阈值 0、锐化 0，约 **53.48 → 52.36 MiB**。尺寸、可见 RGBA 与 Alpha 逐张一致；输出更大时选用较小原件。两个工程通过 `/api/projects` 保存并重开，并在实际工作台打开确认。新增动作没有沿用旧批次的美术验收结论。

`provenance.json` 记录输入源码提交、原件和平台输出哈希，以及各运行副本的体积。原件也保存在工程中；运行副本通过 `game/art/manifest.json` 从 `assets/runtime/sprites/framecraft-runtime-batches/2026-11-04/` 同步。原始六房母版与动作制作源保留原位。

## 游戏实际下载量

Godot 会重新编码 PNG，因此另对 `import-settings.json` 中的 **50 张场景图片**启用原尺寸、质量 0.9 的轻度有损导入。实际导入纹理约 **54.59 → 10.51 MiB**，尺寸和 Alpha 完全一致，可见 RGB 的最低 PSNR 为 35.62 dB。平台边缘 `ledge.png` 的 RGB 偏差较大，保留原有保真编码；所有角色、动作及特效图集也保持保真。没有缩图、丢帧或改动碰撞。

Web 启动文件合计 **147.46 → 103.15 MiB（减少 30.05%）**；其中 PCK 为 99,122,364 字节，gzip 后 98,004,735 字节。此数值是启动文件大小，不是加载耗时或显存占用承诺。运行包中有轻度颜色压缩，不能称作整包无损。

## 复核

使用带 Pillow 与 NumPy 的 Python：

```sh
python assets/source/framecraft-runtime/compress.py --verify --batch 2026-11-04
node tools/godot.mjs sync-art
node game/tools/audit_resources.mjs
node tools/godot.mjs check
node tools/godot.mjs test
node tools/godot.mjs export-web
```

新增素材另选新批次名。首次运行需要现有 Framecraft 服务；`--verify` 只读本地工程与输出，不需要服务。可从 `import-settings.json` 找到每张场景的路径及源码 PNG 哈希，修改对应 `.import` 的 `compress/mode` 为 0 可恢复保真导入。恢复后重新导出并验收，不能手改游戏同步副本。

本批工程检查、48 项测试、七房预览真实移动/跳跃/暂停、菜单与营地存档回归通过；七房预览不作为连续通关证明。报告、实际纹理解码、截图与录像只保留在 `game/build/qa/`。发布提交、线上状态和证据边界见 [游戏进度](../../../../../game/progress.md)。

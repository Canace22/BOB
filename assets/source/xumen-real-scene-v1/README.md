# 须门遗港总布局实景样式

2026-11-06状态修正：用户指出本图丢失原房间内部设计，本图已撤出主展示，折叠为历史概括稿；不能再用本图或其7个标签证明七房设计完整覆盖。当前入口采用[原图保真总览](../xumen-reference-panorama-v2/README.md)。

[在图册查看实景总览](../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html#real-scene)。默认无注记，可打开7房/6边标签和放大横向查看。原有工程布局图保留在其后。

本批新绘1张3:1联合全景，沿用已交付房间与接续画法，把骨根、须幕、舌背、软腭和上下支路画成同一空间。它是用于评审游戏场景观感的概念原画，不是已实现关卡的截图，不替代工程坐标。

- `images/总布局-实景全景.png`：最终无字原尺寸图。
- `inputs/`：真实用于后续局部编辑的图片快照与本次布局参考。
- `prompts/`与`generation.json`：4次真实生成/局部修订的提示词与ID。
- `reference-manifest.json`、`art-manifest.json`：来源、尺寸和哈希。
- `render_scene.py`：在原画册添加实景展示、缩放及可切换注记。
- `acceptance.md`：视觉观察、修订与验收范围；本地review保留浏览器证据。

由原图册`build_atlas.py`同步生成。`node assets/source/xumen-real-scene-v1/verify_scene.cjs`检查交互；`register.py`登记并验证来源链。无需重新生成已交付图，也未修改game/或部署试玩。

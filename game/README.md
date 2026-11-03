# 鲸腹遗城 · 当前工程

用Godot 4.7.2打开 `project.godot`，按F5启动WhalebellyRuins七房主关卡：`content/whalebelly/main.tscn`。首次操作说明按Enter关闭。

`A/D`移动，`K/空格`跳跃，`J/Q`短击，`L/Shift`冲刺，`U`迎珠，`I`重鸣，`P`调息，`O`潜隙，`E`交互，`W`浮游，`G`牵引，`Esc`暂停，`H`帮助，`M`静音。能力沿用解锁限制。

在仓库根目录运行：

```sh
node tools/godot.mjs run
node tools/godot.mjs editor
node tools/godot.mjs check
node tools/godot.mjs test
```

找不到引擎时，将 `GODOT` 设置为现有Godot 4.7.2 console可执行文件。运行素材由 `art/manifest.json` 从 `assets/` 同步，不依赖旧工程目录。图片来源、工作台工程与压缩方式见 [Framecraft批次](../assets/source/framecraft-runtime/README.md)。

主线代码在 `src/campaign/`，房间在 `content/whalebelly/r1/`，环境在 `content/whalebelly/environment/`。角色技能参数场 `content/whalebelly/test/PlayerTest.tscn`、Run预览与当前环境预览继续保留。旧模块版、旧动画、完整 `legacy/` 与历史制作源见[归档说明](../docs/legacy-archive.md)。

主线存档为 `user://whalebelly/artmatch_save.json`。桌面仅在目标尚无存档时复制旧目录的有效V6进度，不覆盖新档或删除原件；浏览器不会读取本机AppData。隔离试玩使用 `node tools/godot.mjs run -- res://tests/whalebelly/manual_play.tscn`。

Web验证先运行 `node tools/godot.mjs export-web`，再在独立终端运行 `node game/tests/serve_web.mjs`，使用 `node game/tests/web_whalebelly.mjs` 真实按键验收。可用 `GAME_URL` 指定线上入口、`TEST_LABEL` 区分证据。测试创建独立浏览器上下文；报告、截图和录像只留本地。

模块边界、发布和资源审计见[架构](../docs/architecture.md)，本轮执行结果见[进度](progress.md)。

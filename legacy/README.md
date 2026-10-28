# legacy/ · 冻结的旧版本（只读）

**不要在这里开发新功能。** 正式开发只在 [`game/`](../game/)，架构见 [docs/architecture.md](../docs/architecture.md)。

这里的内容保留作历史成果、玩法参考和素材来源：查手感数值、关卡设计意图或旧素材时可以读，但修改应当落到 `game/` 或 `assets/`。

| 目录 | 内容 | 状态 |
| --- | --- | --- |
| `godot/first-level/` | Godot 首关 v0.4：5 房主路、负壳蟹 Boss、贴流冲、七房路线 | 玩法、房间布景和素材已迁入 `game/` |
| `godot/first-level-artmatch/` | 参考图分层还原 v0.5（Shader + 遮罩） | 分层与遮罩方法供参考 |
| `godot/first-level-v02-graybox/` | v0.2 灰盒 | 仅历史 |
| `work/` | 旧制作脚本、地图与解剖资料、分享页 | 脚本写死了原机器的绝对路径（`G:/`、`C:/Users/Kingsoft`），不能直接运行 |
| `web/mvp-v2/` | Canvas 2D V2 原画版，线上 [V2 试玩](https://canace22.github.io/BOB/mvp-v2/) | 冻结；仍可本地运行和重新发布 |
| `web/mvp-nightmare/` | Three.js 2.5D 原型 | 仅历史 |
| `web/mvp/` | 初版 Canvas 原型；`deploy.mjs` 用于发布 V2 | 仅历史 |

## 仍可运行的入口

- V2：`cd legacy/web/mvp-v2 && npm run publish:preview && npm start`，打开 http://127.0.0.1:4175/ 。
- 初版：`cd legacy/web/mvp && npm start`，打开 http://127.0.0.1:4173/ 。
- 重新发布 V2（一般不需要）：`cd legacy/web/mvp && npm run deploy`。
- 旧 Godot 工程：用 Godot 4.7.2 打开 `godot/<工程>/project.godot`。编辑器缓存、`evidence/` 验收截图和 Effekseer 工具只保留在本地，需要时可从 `8a3a20d` 及更早的提交中找回，见[迁移与提交范围](../docs/workspace-migration.md)。

各目录原有的 README、progress 和设计文档记录的是当时的路径与结论，不代表当前工程状态。

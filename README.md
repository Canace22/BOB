# BOB · 鲸腹遗城

以「鲸落」为题材的游戏。仓库包含概念原画和两版可玩原型：

| 版本 | 目录 | 玩法 | 在线试玩 |
| --- | --- | --- | --- |
| 新版：深处的来客 | `mvp-nightmare/` | 2.5D（Three.js），探索 + 解谜 + 潜行逃离，三个短篇关卡 | https://canace22.github.io/BOB-/nightmare/ |
| 初版 | `mvp/` | 2D 横版，跳跃探索 + 共鸣开路 + 找回记忆，三关 | https://canace22.github.io/BOB-/mvp/ |

打开 https://canace22.github.io/BOB-/ 会直接进入新版。

## 快速开始

需要 Node.js。

新版（需要先安装 Three.js，需联网一次）：

```sh
cd mvp-nightmare
npm install
npm start
```

浏览器打开 http://127.0.0.1:4174/ 。需要支持 WebGL 的桌面浏览器，键盘操作。

初版（无需安装依赖）：

```sh
cd mvp
npm start
```

浏览器打开 http://127.0.0.1:4173/ 。按 `Ctrl+C` 停止服务。

## 美术资源管理页面

```sh
npm --prefix assets/manager start
```

打开 http://127.0.0.1:4176/ 查看、筛选和管理已入库素材。标签、备注及验收状态保存到项目台账。现有 192 张静态文件、105 个需求家族的完整清单与状态组合预览，另有 7 页静态图集；两版游戏尚未接入，动作动画尚未制作。详见[资源管理说明](assets/README.md)。

## 发布到 GitHub Pages

```sh
cd mvp
npm run deploy
```

会先检查两版代码语法，再把新版、初版和用到的原画打包，强推到远程 `gh-pages` 分支，不改动 `main`。发布前请先在 `mvp-nightmare/` 执行过 `npm install`。1–2 分钟后线上生效。只想看打包结果、不推送：`npm run build:pages`（输出在 `.pages-dist/`）。

## 目录

```
BOB/
├── assets/                # 美术资源入口、台账、制作源与游戏导出资源
├── docs/
│   └── 鲸腹遗城原画集/     # 原画、原画册、提示词与版本设计说明
├── mvp/                    # 初版（原生 Canvas + WebAudio）
│   ├── progress.md         # 初版 MVP 的实现范围与验收记录
│   └── deploy.mjs          # 一键发布脚本（两版一起发）
└── mvp-nightmare/          # 新版（Three.js 2.5D）
    ├── progress.md         # 新版的实现范围与验收记录
    └── tests/              # 自动游玩测试脚本
```

## 当前进度

- 初版：三关（鲸口门庭、肋骨穹顶、心室潮泵），含存档、地图与手记。
- 新版：三关（失声门庭、听骨廊、最后一次心跳），含检查点存档、藏身潜行、顺序解谜与潮水追逐；美术仍是程序几何体，属于玩法与节奏验证。
- 其余器官区域、鲸落四阶段演化和 Boss 尚未实现。

## 更多说明

- 美术资源统一管理：[全局风格规范](assets/art-style.md) · [目录约定](assets/README.md) · [资源台账](assets/catalog.md)

- 新版操作、完整路线、验收清单：[mvp-nightmare/README.md](mvp-nightmare/README.md)
- 初版操作、完整路线：[mvp/README.md](mvp/README.md)
- 实现记录：[新版](mvp-nightmare/progress.md) · [初版](mvp/progress.md)
- 开发协作与项目 Skill：[AGENTS.md](AGENTS.md)

注意：初版 `mvp` 本地运行时会读取上级目录的原画，不要单独移动 `mvp` 或改动原画文件名。新版不依赖原画，可独立运行。

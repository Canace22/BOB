# BOB · 鲸腹遗城

以「鲸落」为题材的游戏。仓库包含概念原画和三版可玩原型：

| 版本 | 目录 | 玩法 | 在线试玩 |
| --- | --- | --- | --- |
| V2 原画版：鲸落万物生 | `mvp-v2/` | 2D 生态探索 + 绳网攀爬 / 升降台 / 骨环摆荡 | [公网试玩](https://canace22.github.io/BOB/mvp-v2/) |
| 新版：深处的来客 | `mvp-nightmare/` | 2.5D（Three.js），探索 + 解谜 + 潜行逃离，三个短篇关卡 | 保留源码，不再发布 |
| 初版 | `mvp/` | 2D 横版，跳跃探索 + 共鸣开路 + 找回记忆，三关 | 保留源码，不再发布 |

打开 https://canace22.github.io/BOB/ 会直接进入 V2 2D 版本。

## 快速开始

需要 Node.js。

V2 原画版（Node.js 18+，无需安装依赖）：

```sh
cd mvp-v2
npm run publish:preview
npm start
```

浏览器打开 http://127.0.0.1:4175/ 。后台常驻启动可用 `.\mvp-v2\launch-preview.ps1`（仓库根目录）。4175 为稳定试玩快照；4176 为 `npm run dev` 开发预览，通过测试后 `npm run publish:preview` 更新试玩，已打开游戏由玩家选择更新。`A / D` 移动、`W / S` 攀爬、`Space` 跳跃 / 脱离、`E` 共鸣、`F` 交互 / 抓环、`Shift` 浮膜。标题页可直接练习攀爬且不覆盖主线存档。`npm run check` 和 `npm test` 用于验证。GitHub Pages 为公开试玩入口，本地服务用于开发验证。

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

只检查并打包当前 V2 2D 版本、独立场景素材和封面原画，再提交并推送到 `gh-pages` 分支。无需安装 Three.js；旧版源码保留，但不进入本次站点。Pages 部署完成后线上生效。只想看打包结果、不推送：`npm run build:pages`（输出在 `.pages-dist/`）。

## 目录

```
BOB/
├── assets/                # 美术资源入口、台账、制作源与游戏导出资源
├── docs/
│   ├── 鲸腹遗城原画集/     # 第一版与 V2 原画、原画册、玩法设计及提示词
│   └── progress.md         # 初版 MVP 的实现范围与验收记录
├── mvp/                    # 初版（原生 Canvas + WebAudio）
│   └── deploy.mjs          # 一键发布脚本（仅 V2）
├── mvp-v2/                 # V2 原画版（Canvas 2D + WebAudio），本地端口 4175
└── mvp-nightmare/          # 新版（Three.js 2.5D）
    ├── progress.md         # 新版的实现范围与验收记录
    └── tests/              # 自动游玩测试脚本
```

## 当前进度

- V2 原画版：四区生态探索、攀网 / 升降 / 摆荡设施与回访；三处栖息地渐进恢复，出现不同居民，地图与手记追踪回访进度。原画仅作设计参考，地图和场景分层组装，可用工作台检查。GitHub Pages 公网分享，本地稳定试玩与开发预览分离。
- 初版：三关（鲸口门庭、肋骨穹顶、心室潮泵），含存档、地图与手记。
- 新版：三关（失声门庭、听骨廊、最后一次心跳），含检查点存档、藏身潜行、顺序解谜与潮水追逐；美术仍是程序几何体，属于玩法与节奏验证。
- 其余器官区域、鲸落四阶段演化和 Boss 尚未实现。

## 更多说明

- 美术资源统一管理：[全局风格规范](assets/art-style.md) · [目录约定](assets/README.md) · [资源台账](assets/catalog.md)
- V2 原画版操作与试玩范围：[mvp-v2/README.md](mvp-v2/README.md)
- 新版操作、完整路线、验收清单：[mvp-nightmare/README.md](mvp-nightmare/README.md)
- 初版操作、完整路线：[mvp/README.md](mvp/README.md)
- 实现记录：[新版](mvp-nightmare/progress.md) · [初版](docs/progress.md)
- 开发协作与项目 Skill：[AGENTS.md](AGENTS.md)

注意：初版 `mvp` 与 V2 原画版 `mvp-v2` 本地运行时会读取上级目录的原画，不要单独移动目录或改动原画文件名。深处的来客 `mvp-nightmare` 不依赖原画，可独立运行。

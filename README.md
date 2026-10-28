# BOB · 鲸腹遗城

以「鲸落」为题材的游戏。仓库包含概念原画和三版可玩原型：

当前开发与公开试玩主线是 `mvp-v2/`；`mvp-nightmare/` 和 `mvp/` 保留为可本地运行的历史原型，不进入当前 Pages 发布包。

本项目按小批持续交付，让用户边玩边做：先修试玩反馈，再按来源主线扩展；每批检查、提交、发布并核实线上。所有参与项目的 AI 遵循 [AGENTS.md 的持续迭代规则](AGENTS.md#持续迭代与边做边玩)。

正式游戏美术使用制作入库的 2D 位图素材，缺项先补绘再接入；Canvas 用于承载图片和运行逻辑，不能用程序几何或拉伸横图代替缺失素材。所有 AI 遵循 [2D 素材规则](AGENTS.md#正式美术必须使用2d素材)；现有缺图回退只是临时故障替代，不代表美术验收完成。

| 版本 | 目录 | 玩法 | 在线试玩 |
| --- | --- | --- | --- |
| V2 原画版：鲸落万物生 | `mvp-v2/` | V5.2 须门五房主线、战斗与冲刺；旧四区另保留入口 | [公网试玩](https://canace22.github.io/BOB/mvp-v2/) |
| 新版：深处的来客 | `mvp-nightmare/` | 2.5D（Three.js），探索 + 解谜 + 潜行逃离，三个短篇关卡 | 保留源码，不再发布 |
| 初版 | `mvp/` | 2D 横版，跳跃探索 + 共鸣开路 + 找回记忆，三关 | 保留源码，不再发布 |

打开 https://canace22.github.io/BOB/ 会直接进入 V2 2D 版本。

## 快速开始

### Godot 工程与制作工作区

Godot 唯一开发工程为 [`godot/WhalebellyRuins/project.godot`](godot/WhalebellyRuins/project.godot)（鲸腹遗城 / Whalebelly Ruins）。
首关七房、最新动作/音频和旧工程资源已合并；不再创建独立版本工程。制作脚本位于 `work/`。
运行及归档见 [统一工程说明](docs/godot-project.md)。
`outputs/`、`builds/` 仍在 BOB 的上一级目录。

大型素材及工具二进制使用 Git LFS。克隆后运行 `git lfs install`、`git lfs pull`。
`work/wan22-production/` 按要求仅保留本地，不提交模型、环境、脚本或归档。
详见 [迁移与提交范围](docs/workspace-migration.md)。

需要 Node.js。

V2 原画版（Node.js 18+，无需安装依赖）：

```sh
cd mvp-v2
npm run publish:preview
npm start
```

浏览器打开 http://127.0.0.1:4175/ 。4175 为稳定快照，4176 为 `npm run dev` 开发预览。当前须门主线：`A / D` 移动、`Space` 跳跃、`Q` 短击、`R` 重鸣、`E` 交互、`Shift` 取得 A1 后冲刺；按键可修改。五间主线房已接入，其余区域按主线逐批开放。[旧四区试玩](https://canace22.github.io/BOB/mvp-v2/legacy.html)保留原操作与存档。运行、测试与发布见 [V2 说明](mvp-v2/README.md)。GitHub Pages 为用户试玩入口，本地服务用于开发验证。

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

打开 http://127.0.0.1:4176/ 查看、筛选和管理已入库素材。标签、备注及验收状态保存到项目台账；数量、覆盖范围与接入状态以[资源台账](assets/catalog.md)和管理页为准。动作动画仍需单独制作与验收。详见[资源管理说明](assets/README.md)。

资源管理页与 V2 开发预览默认都使用 4176，请勿同时启动；稳定试玩 4175 不受影响。

## 发布到 GitHub Pages

```sh
cd mvp
npm run deploy
```

只检查并打包当前 V2 2D 版本、运行清单选中的共享 WebP、封面与回退外观的 WebP 导出，再提交并正常推送到 `gh-pages` 分支，保留发布历史。无需安装 Three.js；旧版源码保留，但不进入本次站点。源码提交与 Pages 发布按[持续迭代规则](AGENTS.md#持续迭代与边做边玩)完成。Pages 部署完成且线上核实后，玩家可刷新进入新版；新主线与旧四区各自保留独立存档。制作期间可继续玩当前公网版本；工作区改动或推送成功不等于已上线。只想看打包结果、不推送：`npm run build:pages`（输出在 `.pages-dist/`）。素材导出命令见[资源管理说明](assets/README.md)。

## 目录

```
BOB/
├── godot/                 # 唯一 Godot 工程 WhalebellyRuins，缓存不入库
├── work/                  # 制作脚本、素材、工具的本地完整目录
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

- V2 当前公开主线：V5.2 须门五房，包含圆润坡面与凹部、短击 / 重鸣、尸蟹与负壳蟹首领、胜后取得 A1、三段冲刺沟、H1 清流窝回访，以及营地、死亡恢复、改键与独立存档。当前批次与来源边界见 [战役说明](mvp-v2/CAMPAIGN.md)，已执行测试和线上结果见 [V2 进度](mvp-v2/progress.md)。
- V2 旧四区：保留鲸口、胃库、肺缘、肋骨的生态探索、攀网 / 升降 / 摆荡和回访，入口为 `legacy.html`，原存档独立保留。旧场景工作台仍用于四区；新主线地图在游戏中按 M 查看。
- V2 运行素材：当前选用 42 张共享 WebP，约 1.87 MiB；封面与回退图另约 436 KiB。原始素材保留，静态原画搭配程序动作反馈，尚非正式动作动画。
- 初版：三关（鲸口门庭、肋骨穹顶、心室潮泵），含存档、地图与手记。
- 新版：三关（失声门庭、听骨廊、最后一次心跳），含检查点存档、藏身潜行、顺序解谜与潮水追逐；美术仍是程序几何体，属于玩法与节奏验证。
- V5.2 全设计的 36 房尚未全部实现；后续区域、A2–A5、其余首领与终局按主线逐批开放，地图元数据不代表可玩区域。

## 更多说明

- 美术资源统一管理：[全局风格规范](assets/art-style.md) · [目录约定](assets/README.md) · [资源台账](assets/catalog.md)
- V2 原画版操作与试玩范围：[mvp-v2/README.md](mvp-v2/README.md)
- 新版操作、完整路线、验收清单：[mvp-nightmare/README.md](mvp-nightmare/README.md)
- 初版操作、完整路线：[mvp/README.md](mvp/README.md)
- 实现记录：[新版](mvp-nightmare/progress.md) · [初版](mvp/progress.md)
- 开发协作与项目 Skill：[AGENTS.md](AGENTS.md)

注意：初版 `mvp` 与 V2 原画版 `mvp-v2` 本地运行时会读取上级目录的原画，不要单独移动目录或改动原画文件名。深处的来客 `mvp-nightmare` 不依赖原画，可独立运行。

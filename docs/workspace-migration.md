# 旧工程迁移与提交范围

## 时间线

1. 2026-10-28 将 `G:/鲸落万物生/godot`、`G:/鲸落万物生/work` 完整迁入 BOB（共 68,424 个文件，逐项核对了存在性和大小），并修正脚本与入口文档中的旧路径，修正清单见 `tools/migration-path-updates.json`。
2. 同日收窄提交范围（提交 `ee37312`）：编辑器缓存、验收截图、第三方工具和日志取消跟踪，只保留在本地。
3. 同日决定以 Godot 重做正式版本：新工程放在 `game/`，旧的 `godot/`、`work/`、`mvp/`、`mvp-v2/`、`mvp-nightmare/` 整体移入 `legacy/`，见 [legacy/README.md](../legacy/README.md) 和[架构说明](architecture.md)。

## 当前入库范围

- `legacy/godot/`：三个旧 Godot 工程的场景、脚本、素材、制作文档和制作历史。
- `legacy/work/`：旧制作脚本与资料。
- `legacy/web/`：三个 Web 原型。
- 以下内容只保留在本地，不入库；需要旧版本时可从 `8a3a20d` 及更早的提交中找回（当时路径没有 `legacy/` 前缀）：
  - `.godot/`：Godot 编辑器导入缓存，打开工程时会自动重建。
  - `legacy/godot/*/evidence/`：验收截图和运行证据，结论已记录在各工程的文档中。
  - `legacy/godot/*/.production/`：制作账本的运行状态。
  - `legacy/work/effekseer/`：Effekseer 编辑器和 Godot 插件，属于第三方工具；需要时从官方渠道安装 1.80.7 版本。
  - `work/wan22-production/`：本地模型与 Python 环境，不提交任何内容或替代归档。
  - 所有 `*.log`、`*.pid`、`__pycache__`、`*.pyc`，以及 `legacy/work/whalefall-share/` 中的 `cloudflared.exe`、`processes.json` 和 `known_hosts`。

大型文件通过 Git LFS 保存：

```sh
git lfs install
git lfs pull
```

## 路径与运行

- 旧 Godot 工程入口：`legacy/godot/first-level/project.godot`、`legacy/godot/first-level-artmatch/project.godot`、`legacy/godot/first-level-v02-graybox/project.godot`。
- Web 原型的服务和发布脚本已改为按新位置解析仓库根目录，运行方式见 [legacy/README.md](../legacy/README.md)。
- `legacy/work/` 中的制作脚本写死了原机器的绝对路径（`G:/鲸落万物生`、`C:/Users/Kingsoft`），`outputs/` 和 `builds/` 也不在本仓库中。这些脚本只作为历史记录，不能直接运行。历史日志、快照和验收记录中的旧路径描述的是当时的环境。

## 验证

- 首次迁移时核对了全部文件的存在性和大小，并对改过路径的 Python、JavaScript 和 PowerShell 脚本做了语法检查。
- 移入 `legacy/` 时，Git 将 1,463 个已跟踪文件全部识别为 100% 相似的重命名，LFS 指针保持不变。
- 移入 `legacy/` 后在新位置执行了 V2 的 `npm run build:pages`，并请求了 V2 与初版本地服务的页面和素材，均返回 200。

# godot / work 迁移与提交范围

2026-10-28 将 `G:/鲸落万物生/godot`、`G:/鲸落万物生/work` 完整迁入 BOB，保持各自的内部结构。迁移前清单共 68,424 个文件，迁移完成时逐项检查文件存在、大小一致，再修正脚本与入口文档中的旧路径。

## 入库范围

- `godot/`：三个 Godot 工程及全部素材、缓存、制作记录和验收资料。
- `work/`：制作脚本、素材和 Effekseer 工具等，排除下述本地专用目录。
- `work/wan22-production/`：按用户最新要求，整个目录仅保留本地，不提交其中的模型、Python 环境、工具、缓存、制作脚本或任何替代归档。
- `work/effekseer/` 在迁入后移出了官方示例、两份安装压缩包，以及 Godot 插件里 Windows 以外的二进制。Windows 版编辑器和 `bin/windows` 保留。`__pycache__` 与 `*.pyc` 不再入库。

迁移后的 `godot/`、`work/` 共 6,759 个文件直接入库；大型文件通过 Git LFS 保存。`.gitignore` 明确忽略 `/work/wan22-production/`。本轮修订尚未推送的本地过渡提交，确保远端分支历史不包含该目录。

```sh
git lfs install
git lfs pull
```

Godot 入口为 `godot/first-level/project.godot`、`godot/first-level-artmatch/project.godot` 和 `godot/first-level-v02-graybox/project.godot`。

## 路径与运行

修正路径的 63 个已入库脚本及入口文档列于 `tools/migration-path-updates.json`。历史日志、快照和验收记录保持原样，其中的旧绝对路径描述当时的环境，不代表当前入口。

`outputs/` 和 `builds/` 未迁移，仍位于 BOB 的上一级；制作脚本继续引用该位置。只克隆本仓库不会自动得到这两个外部目录。部分脚本仍包含本机 Godot、Python 或工具安装路径，此次迁移没有改造这些工具链的安装方式。

迁移前停止了空闲的 ComfyUI、原画预览服务和无窗口 Krita 进程，以释放文件占用。旧 `.pid` 文件按保留要求原样入库，不能用于判断当前进程状态。需要原画预览服务时，确认端口 8765 空闲后，在仓库根目录运行：

```sh
node work/atlas-lan.cjs
```

本地 ComfyUI 可在确认端口 8188 空闲后，通过 `work/wan22-production/启动ComfyUI.ps1` 启动，该目录不随仓库分发。

## 验证

- 迁移完成时核对了全部 68,424 个文件的存在性及大小。
- 已执行路径修正涉及的 Python、JavaScript 和 PowerShell 脚本语法检查。
- 提交前检查 `wan22-production` 不在 Git 索引或新增提交中，且忽略规则生效。
- 提交后核对远端 `main` 与本地提交号一致。
- 此次不修改游戏玩法，没有重新执行游戏实机回归；历史验收记录不代表本次验证。

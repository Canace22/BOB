# 鲸腹遗城 · Whalebelly Ruins

唯一开发入口：[project.godot](../godot/WhalebellyRuins/project.godot)。固定引擎 **Godot 4.7.2.stable.official.ed1daf0bf**，Windows / Compatibility。

用该引擎导入工程，按 F5 运行 `scenes/main.tscn`。房间为 `scenes/r1/R1-01.tscn` 至 `R1-07.tscn`，逻辑在 `scripts/`，关卡数据在 `assets/rooms.json`。目录重命名不改变 `res://` 内部路径。

## 合并规则

- 以 `first-level-artmatch` 最新七房运行代码、角色、场景、素材和测试为准，合入原 `first-level` 的独有资源。
- 同路径冲突取最新 artmatch 版本；first-level 的冲突原件、旧脚本/测试/制作记录保存在 `production-history/pre-unification/first-level/`，由 `.gdignore` 隔离。
- `first-level-v02-graybox` 已移出开发目录并停用，不再保留第三个开发入口。
- 合并前的三个工程已做 ZIP 备份，排除可再生 `.godot` 缓存；已核验文件数、CRC及复制后SHA256。具体备份路径、冲突列表、逐文件来源见 [合并清单](godot-consolidation.json)。备份位于仓库外的 `../backups/`，不会被识别为第二个开发工程。
- 现有 artmatch 存档目录 `WhalefallArtmatchV05` 保留。旧 first-level 的用户存档不删除、不自动转换；两者运行数据格式不同。

永久删除操作被工具自动审批以“blocked by policy”拦截，未返回更具体原因。因此三个旧目录可恢复地移到 `G:/鲸落万物生/backups/godot-retired-20261028/`，其 `project.godot` 改名为 `project.godot.archived`。它们不是活跃工程；开发区仅保留 WhalebellyRuins。

## 后续开发

所有代码、场景与资产修改进入这一工程；使用 Git 历史管理版本，不再复制出 `first-level-vXX`。

`work/r1_v05_capture.py`、`r1_v05_package.py`、`r1_v05_delivery.py`、`r1_v05_finalize.py`、`refine_audio_v05.py` 已指向统一工程。历史初始化/整版重建脚本移到 `work/archive/godot-pre-unification/`，不再作为生产入口。

`outputs/` 和 `builds/` 仍在 BOB 上一级。当前交付册的项目链接已更新。网页原型目录沿用各自说明，本次未合并或发布 Web 版本。

本次验证与未完成事项见 [工程进度](../godot/WhalebellyRuins/progress.md)。历史验收日志保留原始路径与日期，不冒充迁移后的新验证。

## 本轮参考图 · 环境展示场景

在同一工程打开 `scenes/environment/xumen_reference.tscn`，**F6**运行。也可执行工程根目录 `preview-reference-environment.ps1`（可加`-Pan`）。这是仅环境和静态展示角色的1280×720场景，不接入七房关卡控制器；F5入口保持原游戏。[素材、母版、范围和限制](../assets/source/xumen-reference-environment/README.md)。

# 查找旧版本

完整旧工程保存在 [codex/archive-legacy-20261103 分支](https://github.com/Canace22/BOB/tree/codex/archive-legacy-20261103)。该分支保留整理前的完整仓库，包括整个 `legacy/` 的程序、场景、制作脚本、资源与说明，以及 `game/production_sources/` 的历史原件。

当前分支只在 `game/` 开发。素材同步从 `assets/` 读取；当前工程使用的旧素材已迁出归档目录，图片原件随 Framecraft 工程保存。运行 `node tools/godot.mjs sync-art` 不需要切换到归档分支。

查看历史可直接打开[旧版入口说明](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/legacy/README.md)。需要运行旧版时，使用独立检出，避免覆盖当前开发目录：

```sh
git fetch origin codex/archive-legacy-20261103
git worktree add --detach ../BOB-legacy origin/codex/archive-legacy-20261103
git -C ../BOB-legacy lfs pull
```

旧版启动命令在独立检出的 `legacy/README.md`。一次性迁移工具 `tools/recover-whalebelly.mjs`、`tools/migration-path-updates.json`、`game/tools/import_rooms.mjs` 也随归档分支保留。

当前分支还移走了模块化五房版本及其专用测试、重复环境预览、四批旧角色动画及专用预览、未引用的合成帧与 V2 专用 WebP。现版的七房、角色技能参数场、Run 预览和环境动态保留。可复用原画库与未来区域素材继续留在 `assets/`；没有因为暂未接入就将创作素材判为废弃。当前同步清单与历史移出路径见 [Framecraft 批次](../assets/source/framecraft-runtime/README.md)。

归档不会改写 Git 历史，也不会自动缩小完整克隆的历史下载量。已有 Pages 的 V2 等入口继续保留；源码分支整理不删除线上版本。

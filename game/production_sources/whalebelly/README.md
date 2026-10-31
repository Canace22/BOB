# 历史制作源归档

这里保存恢复运行模块时未直接引用的原图、母版、旧音效、制作规则、元素清单、历史文档与辅助脚本。逐文件来源、SHA256和字节数见 `source-index.json`；运行资源的映射在 `../../content/whalebelly/recovery-manifest.json`。

本目录有 `.gdignore` 且在 Web 导出中排除。文件保留历史内容与路径，不代表可以直接运行旧脚本；尤其 `original-launchers/` 仅为原件存档。请通过 `game/project.godot` 或仓库根目录 `node tools/godot.mjs run` 启动。

`docs/全要素覆盖表.md` 与两份中文启动器直接从迁移前 tar 快照恢复，另保留迁移后的乱码文件名副本以便逐项审计。历史验收结论不代替当前工程验收。原全局 Blender/Krita 母版、参考视频和制作脚本继续保留于仓库 `assets/source/` 与冻结的 `legacy/work/local-production/tools/`，不复制成第二套可开发工程。

4份历史校验/导出结果仅本地保留，不入库；source-index.json 的 local_only_files 单独记录其来源。制作源文件本身不因此删除。

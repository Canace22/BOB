# v0.3 接续：七房场景还原

正式工程：G:/鲸落万物生/BOB/godot/first-level/project.godot；固定Godot4.7.2 Compatibility。独立包：G:/鲸落万物生/builds/须门遗港-v0.3-场景还原/Whalefall.exe。交付册：G:/鲸落万物生/outputs/须门遗港_首关场景_v0.3/场景交付册.html。

先运行 tools/ledger.cjs status/next 检查最新账本，读 docs/v03/specification.md、scene-manifest.json、qa-summary.json。旧v0.2账本已归档production-history/v02-ledger；旧脚本/场景完整备份 G:/鲸落万物生/BOB/work/r1-before-scene-v03.zip，旧运行包未改。

新增五类位图：assets/source/v03保存原件，master/v03为未破坏副本，runtime/v03为运行资源；提示在docs/v03/generation-prompts.json，来源/alpha/hash在assets.json。完整场景可直接编辑scenes/r1，脚本绑定碰撞/主体角色；work/r1_scene_build.py可重建，但会覆盖场景人工改动，改前比对。

F6进入只读巡览，数字1～7切房，WASD镜头，Tab全景，F6返回。01～05正常玩法；06/07场景完整但未来能力逻辑未接入。不要把巡览截图标记为七房全流程通关。

最终独立包证据：evidence/v03/play-final、reload-final、normal-final；七房及巡览控制：scenery-pack；支路branch、门闩重载latch-reload、死亡recover。QA存档与正常存档隔离。场景截图都是Godot实际渲染；音效复用旧版，未新增主观试听。

首次导出release缺少模板，已使用官方便携引擎+PCK；重复ShellHinge节点导致资源泄漏已修，QA退出时奖励音频未结束的问题也已修，旧失败日志保留。后续如果需要小体积发行包，再补同版本模板后导出并复验。

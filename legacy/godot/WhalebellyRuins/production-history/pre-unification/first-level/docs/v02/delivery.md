# 须门遗港 v0.2 交付

继续迭代现有首关，正式工程为 [project.godot](../../project.godot)，固定 Godot4.7.2，未替换成实验灰盒工程。

- [Windows运行文件](G:/鲸落万物生/builds/须门遗港-v0.2/Whalefall.exe)
- [便携压缩包](G:/鲸落万物生/builds/须门遗港-v0.2.zip)（约88.4MiB，解压后运行，不要拆开exe/pck）
- [操作说明](G:/鲸落万物生/builds/须门遗港-v0.2/操作说明.txt)
- [完整实测报告](qa.md)
- [样板房实机录像](../../evidence/v02/sample-v2.mp4)
- [最终通关截图](../../evidence/v02/release2-run/complete.png)
- [接续入口](../../RESUME-v02.md)

已完成：独立分层环境、六类透明部件、真实灯光、有限环境动态、事件命中/死亡/重鸣/落地水纹、舌台可往返支路与永久壳闩桥、Boss预告与伤害区域读性修正。用户正常存档兼容保留，旧版运行包与原画未改。

已运行验证：最终独立包五房通关与独立重载；样板10项、支路8项、系统21项、坠落死亡7项、水纹7项及受击恢复。视频是样板阶段运行，最终新增坠落/水纹由独立实机截图和最终包日志补充。不是人工试玩评级。

仍待完善：完整角色步态、左右侧一致性、地形衔接、Boss逐帧动作、门扇独立动画、低配性能和人工音效试听。水纹为环境与落地震动表现，不含游泳。最终包采样P95为16.67ms，存在截图及切换长帧，不承诺恒定60FPS。下一轮优先真人试玩调手感与连续动画，本轮不扩展下一器官。

来源：新增内置image_gen一张图，assets/source/v02/prompt.json保存提示与来源；未调用第三方收费生成，实际内置服务费用未知。原始、母版、运行文件和尺度/锚点均保留。Godot许可证随包附带；只本地交付。

manifest记录包内文件/ZIP/代码/运行资源SHA256；production-history/v02-release2-code.zip为本轮代码快照，v01-ledger与v01-code.zip保留旧验收。流程结果见.production，不以本文取代真实运行证据。

最终包清单为 evidence/v02/build-manifest-release2.json，校验为package-verification-release2.json。普通启动模式已专项复验，修复测试目录在PCK中不可写的问题。

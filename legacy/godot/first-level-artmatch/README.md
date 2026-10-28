# 须门遗港 v0.5：参考图到可玩关卡

固定引擎：Godot 4.7.2.stable.official.ed1daf0bf，Windows x64 / Compatibility。
工程入口：project.godot；主场景 scenes/main.tscn；七房 scenes/r1。
原始图片不修改；source-manifest.json 记录摘要。assets/masks + Shader + 场景是可编辑母版，assets/clean 是本轮补绘，assets/runtime/layers 是 Godot 导出的复用图。

当前：首关正常主路、Boss、两回访支路、下层返坡、四环、软床恢复、保存重载与独立包已实测。当前系统音频输出设备失败，不能签为整体验收完成。见 evidence/audio-devices.log。

运行：使用固定版本打开 project.godot 后 F6/F5，或运行 builds/须门遗港-v0.5-参考图可玩关卡/Whalefall.exe。编辑器F6是运行当前场景，与游戏内F6重载不同。
操作以运行包“操作说明.txt”为准。F9是临时回访练习，不是正式取得A2/A3。

存档：项目使用WhalefallArtmatchV05独立user目录。qa标志下用artmatch_qa_save.json；不覆盖旧v0.4用户数据。
验收：docs/element-manifest.json；真实图形/输入证据 evidence/；失败历史保留，不抹掉返修过程。
正常通关测试并未靠整图背景、文件存在或日志无错冒充玩法。

待返修：部分可玩层平台/锚环拆件仍含原图背景，精细分层边缘验收未通过；详见交付册与coverage-readiness.md。

# 首关可玩交付 · v0.1
本轮：须门遗港五房首通，Godot4.7.2，Windows键盘版。已通过实际输入通关、失败恢复、21项边界夹具、独立启动与另进程存档恢复。不是全游戏。

运行：G:/鲸落万物生/builds/须门遗港-v0.1/Whalefall.exe
便携ZIP：G:/鲸落万物生/builds/须门遗港-v0.1.zip（整包解压，exe和pck不可拆开）
源工程：G:/鲸落万物生/godot/first-level/project.godot
说明：README.md
实机录像：evidence/fixed-run/playthrough.mp4
关卡截图：evidence/standalone-run
制作状态：.production/state.json，恢复入口 RESUME.md

独立包采用已安装的同版本Godot运行时+导出的PCK，未混用4.7导出模板。无需打开编辑器，运行时体积约181MB，PCK约5.5MB；它是便携可运行构建，不是经过平台签名/商店提交的最终发行包。引擎及第三方许可证由当前引擎直接导出随包保留。字体使用Windows系统中文回退。

实际验证：build-manifest.json记录包内hash及源码hash；standalone-run/prototype.json完整通关；p07-run/integration-v1.json的21项通过；p07-run/persistence.json独立进程恢复。1280×720 / i5-14600K / RTX5060，4304帧p95 16.67ms，包含截图读回和换房时的37个长帧。脚本/资源运行无错误，未靠免疫/增伤/传送通关。

表现限制：有限关键姿势及左右镜像、Boss程序变换、地形重复、路线文字地图。音效为原创程序合成，真实混音/削波/时序检查已过，因模型无音频输入，主观听感未测；不冒充人类审美签收。后续能力和区域仍在原设计阶段。
制作历史失败与修复证据全部保留；无未处理的首通阻断。费用：内置image_gen五次调用，费用未知；无外部收费任务。未上传/发布，未改原画册。


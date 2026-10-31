# v0.2 交付与接续

正式可编辑工程：G:/鲸落万物生/BOB/godot/first-level/project.godot。
独立包：G:/鲸落万物生/builds/须门遗港-v0.2/Whalefall.exe；相邻同名PCK必须保留。
固定引擎：Godot 4.7.2.stable.official.ed1daf0bf，Compatibility，Windows x64，1280×720。

恢复先执行：
```
node G:/鲸落万物生/BOB/godot/first-level/tools/ledger.cjs status
node G:/鲸落万物生/BOB/godot/first-level/tools/ledger.cjs next
```
以实际账本为准；全部通过即到达本轮首关边界。不要自动扩展第二章。既有v0.1账本、代码、运行包仍保留；不以实验 first-level-v02-graybox 替换正式工程。

输入与结果：docs/v02/specification.md / art-standard.md 是制作前合同；sample-review.md、qa.md、delivery.md是本轮实际状态。assets/source/v02保留原始生成和提示，master/v02为处理母版，runtime/v02为六类运行部件；asset-delivery.json记录透明边缘、尺度、锚点与hash。旧资源沿用原来源记录，不能补造供应商或任务ID。没有使用第三方付费生成。

证据不可覆盖。后续新测试指定新的绝对 --evidence-dir。QA模式使用save-qa.json；正常玩家档为 %APPDATA%/WhalefallFirstLevel/save-v1.json。本轮不重置用户档，旧档缺latch字段自动默认为false。

常用测试：--qa-render 五房自动输入通关及截图/帧时间；--qa-load 另进程读完成状态；--qa-branch 支路往返；--qa-latch-load另进程读壳闩；--qa-sample动态/事件/暂停；--qa-integration状态边界。完整通关驱动器会选择动作和朝向，行走/跳跃/攻击/冲刺均经Input，不是真人试玩结论。死亡、受击与损坏存档是明确夹具，不能当作完整首通证据。

残余打磨：跑动与左右朝向连续原画、地形衔接、完整门扇动画、Boss逐帧动作、主观音效试听及低配机器测试。水为局部视觉流动及落地震动水纹，无游泳系统。后续优先让真人试玩首关并记录命中距离、预告与跳冲手感，再决定动画扩展；不新增付费或发布操作。

最终证据以evidence/v02/release2-run、normal-smoke2.json及build-manifest-release2.json为准。第一次普通启动报错已修复，日志与旧包归档保留。

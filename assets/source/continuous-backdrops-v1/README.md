# 连续世界远景与旧图分层 V1

2026-11-16，针对用户三张心室观察台截图返修。上一批只解决水色，仍让房间器官远景按房间矩形淡出；连接补绘还带着另一套烘焙远景，因此不能称为整个背景连续。

本批用内置 ImageGen 参考引导新绘六张完整远景：须门、肺心、胃枢、断脊、头海、尾槽，均为2172×724原尺寸PNG。画面同时包含器官和水体，静态结构，远景对比低于道路，不登记动作。`originals/`保留原件，`prompts/`保存实际英文提示词，`registration.json`记录尺寸、SHA256与运行副本；输入引用和生成结果在`generation.json`。个人通用场景Skill仍未安装，沿用项目执行合同与配方。

`terrain/`是14条水平连接的RGBA道路分层，保留完整1536×1024画布，沿旧注册矩形等比放置；背景透过Alpha交给连续远景。它是模型参考引导重绘，不宣称与原画逐像素相同。`terrain-generation.json`和`terrain-registration.json`保存实际来源、提示词及哈希。R1-04→R1-05第一候选实际保留白灰雾底，未采用，保存在`candidates/`；返修清除后再实机检查。四条竖井去台深景停止覆盖背景，精确脚线上的独立台根和碰撞保留。

`chapter/`是须门后六房World/Middle的12张分层候选，只消费Alpha作为原图遮罩，原RGB、画布、坐标、Shader动态与碰撞保持。源图含矩形/多边形水色碎片，仅隐藏Far会把这些碎片暴露出来，必须一起清理。生成重绘的Alpha也可能影响细丝，不宣称像素级保真。原件与哈希见`chapter-registration.json`，提示词见`prompts/chapter-alpha.txt`。

运行副本在`assets/runtime/sprites/continuous-backdrops-v1/`，manifest同步到`game/art/continuous-backdrops-v1/`；不覆盖旧批次。全部背景由单个世界绘制面负责，固定区域锚点，统一0.25视差，镜像取样使用clamp；不随活动房/驻留/卸载重建。区域之间按固定世界距离连续混合，Shader只负责采样入库位图。仍保留中近景生态、玩法结构和门条件。

验收入口见[连续世界说明](../../../docs/streaming-world.md)。单件Alpha验证、原生GPU接入、真实输入和用户整体审美分开记录。初次预览中全透明RGB被误看作光晕，后检查RGBA并实际合成确认不可见；禁止只凭预览底色判断。QA图片/日志只放`game/build/`。最终验收结果见[工程进度](../../../game/progress.md)。未提交、未导出Web、未发布。

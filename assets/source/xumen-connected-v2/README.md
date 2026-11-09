# 须门遗港 · 实际连通 V2

正式入口game/content/whalebelly/main.tscn。Godot4.7.2。承接V1共用远景及动件，将七个原房间放入同一物理空间。四条原主路边E01–E04补实际可走连接段；E33/E35由原须筛上层出口接入喷气孔上层/记忆袋。没有新增章节、能力或剧情。

## 运行原理与边界

- 原房内地形不缩放，主路间隔512像素；连接段顶面直接匹配两端地面。上层通道使用约130像素高差的独立骨质平台，S+空格可逐层下行。
- 七房静态几何同时存在，跨边界保留同一角色、速度、方向和镜头。只对全部场景及镜头等量平移，以当前房间作为局部坐标原点，兼容原战斗和V6存档。自然跨房没有快照渐变或新建角色；预览/死亡/显式加载仍允许重建。
- 未激活的战斗/机关冻结，自主环境动画继续；进入房间激活原玩法。不是新增的跨房追击AI；敌人不在整章范围追逐。整体空间连通不代表新章出口已完成。
- 原浮游/锚环门槛保留，后续能力仍按既有设计回访，F9可临时练习。两条支路验收使用明确的能力配置，不冒充首章自然取得能力。
- 门边外观仍保留一部分旧图切片，软边遮罩控制接缝；未声称全章逐像素重画或用户整体美术签收。新增上行平台为正式透明手绘位图，普通门口仍可继续精修。

## 原件、母版和运行件

原件`originals/tunnel.png`、`shaft.png`、`ledge.png`均由内置imagegen按现有原创概念参考制作，确切来源与提示词见generation.json。没有调用第三方付费生成。已有鱼、气泡、垂须继续使用V1及现有分层场景，不把背景静态挂须登记为新动画。

`master/tunnel.ora`、`shaft.ora`可用Krita打开；保留图层、蒙版和原图。`master/ledge-anchor.json`记录透明边缘清理及脚底锚点。`runtime/`保留导出和中间件；manifest仅选择6张实际引用图片：background/floor/foreground/shaft-background/shaft-walls/ledge。step.png是已弃用的矩形候选，不接入。

地图坐标及原边对应关系在`game/src/campaign/connected/connected_layout.gd`；物理/位图绑定在physical_passages.gd；场景缓存、坐标换原点及上下文在connected_world.gd；旧图边缘蒙版在chunk_edges.gd。修改路面顶面须同步碰撞与脚底锚点，修改房间位置须复验相邻边与镜头。

## 验证与恢复

`node tools/godot.mjs check/test`为原工程回归；连通专项`game/tests/whalebelly/connected_world_qa.gd`覆盖实际行走、同角色往返、六边/支路、正常Boss战、死亡/存档。`-- --reload-connected`顺序运行独立读档，不能与其它QA共写同一文件。`web_connected_world.mjs`以独立Chrome真实键盘通过01/02物理往返、暂停、地图、营地与刷新，不使用数字预览。

证据仅本地`game/build/qa/xumen-connected/`。`visual`的两张主路截图来自从明确起点夹具开始后的实际D行走；上层两张标为布局夹具，不能当攀升录像。性能独立无录制采样。失败及修正、发布与线上版本以`game/progress.md`最终记录为准。

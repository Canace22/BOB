# 五条后续过渡制作

正式入口为 game/content/whalebelly/main.tscn。E01门禁通过后按E02、E03、E04、E33、E35推进。逐边状态见production.json；未制作边保留旧版本，不以本批测试代替新美术验收。

E02已有专用远景、骨膜顶拱和骨路原件，以及须筛右侧支撑的生成式干净提取。originals保留原件，masters为OpenRaster、逐列地面高度、所有权/清理蒙版，runtime位于assets/runtime/scenes/xumen-transitions-v2。build.py复跑导出，register.py更新台账与同步清单，须在项目根运行。Pillow只负责裁片、蒙版、等比导出和既定顶面配准；新美术来自内置imagegen。生成式提取改变了画片，需要配准，不声称像素原样保留。

E02新骨路世界X3310…4910，核心碰撞X3829…4393/Y626.847；原碰撞与26实例不改。章节点AuthoredTransitions由host.clock驱动12鱼、8泡、14秒1%远水亮度起伏；保持E01已验证垂须与其它原房动态。E02本身没有新增柔性物或交互。前景复用原两房并清除替换体积，不用黑层盖接缝。

检查入口：authored_transition_qa.gd（14项）、authored_transition_visual.gd（三机位及关闭前景）、authored_transition_bench.gd（不录制暖机）、web_authored_transitions.mjs（真实键盘跨界及28秒动态）。Web用原预览键2设置房间起点，随后真实D/A/Space往返，明确不冒称从第一房自然通关；完整路线另由connected_world_qa.gd验证。完整路线最后的camp断言只检查内存，独立读档必须等待0.5秒交互动作结束再退出；已保留过早结束的失败日志，并在专项等待65帧后通过，未改游戏机制。

实机证据仅在game/build/qa/xumen-transitions/。check0错误、57/57；E02专项14/14、完整连通38/38、独立读档2/2；Chrome10/10（最后局部清图后需重导/线上复验）。AI查看静帧不等于用户审美签收。性能RTX5060/1280×720 Compatibility暖环境中位16.656ms、p9517.587ms，不是战斗或跨设备保证。

失败修正：新地面若在延伸碰撞边界切换轮廓，会出现3px直台阶；应按原房表面交点连续配准，碰撞保持。远景水、道路、上层结构使用不同所有权蒙版，避免保护分支同时保留旧水色。限定在道路上方且排除生态的局部辅助水色选区已保留母版；没有全局蓝色键。现有更远处旧图仍可能有历史水色边界，不冒称全章已清理。

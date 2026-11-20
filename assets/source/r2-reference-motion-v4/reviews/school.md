# R2背景端足群游组件

2026-11-16。按家族委派，仅新增组件／局部Shader；未改recipe、共享生成器、碰撞、敌人或进度。

## 已看图与选型

实际查看17_R2-03、18_R2-04与assets/runtime/sprites/amphipod-swarm/base.png。原amphipod-swarm虽名swarm，PNG实际是**左向单只端足生物**，不是多只群图；可复用作单体。现图比原画远景生物更卡通、眼睛更大；作为22–40px低对比背景使用，不能称其为原画逐像素精确提取。最终艺术尺度由根侧实机确认。

群游是“个体触须／附肢动作＋路径／编队”，不能只移动整张静图。本批群体生物按项目许可使用原生位图＋局部UV Shader；硬壳和眼部尽量保持稳定，下方附肢按x相位差作小幅摆动，触须和尾部使用独立相位。备选为新制完整八帧，适合近景主角级细看；背景池本批使用有界程序驱动。未新增几何图形、发光线、假气泡或画外物体。

## 交付与接口

- game/src/world/scenery/kit/kit_amphipod_school.gd，class_name KitAmphipodSchool。
- 同目录amphipod_swim.gdshader，两个.uid已由Godot生成。
- `texture:Texture2D`；使用现有res://art/world-kit/amphipod-swarm.png。
- `bounds:Rect2`，父层局部像素；`population:int`固定池，硬上限96；`body_width:float`指可见身体宽度。
- `source_visible_width_ratio=0.888671875`按原PNG alpha bbox(1365/1536)，换新单体时须改实际比例。
- `seed_id:int`、`mode:String`为`"band"`或`"orbit"`；`external_clock=true`默认不自播。
- `update_at(t)`纯时间映射，父时钟控制暂停／零速／重载；`elapsed`与`members`可观察，members每项node／material／phase等。
- `flow_speed`默认26px/s，正向右（原画左向，所以内部flip_h）；`opacity`默认.34；`tint`与`body_motion_strength`可调。
- `snapshot()`给出池数、bounds、模式、时钟与harmful=false，组件没有碰撞、目标、血量、伤害或授能。

band模式预热后全域已有分散个体；边界在至少2.5倍身体宽的区域淡出，循环只在alpha趋零时跨边；每只个体y有小幅水流起伏、速度／相位不同。orbit模式是弱背景环游，不与Boss状态绑定；侧视转向时缩窄并淡化，不冒称完整3D转身。群游方向、身体局部动作与每实例色彩分开控制。

建议根侧在R2-03配置两条高低背景带，层深至少在World之前：例如上带Rect2(300,340,1800,190)，下带Rect2(280,740,1900,140)，单体22–36px、opacity约.25–.34。第二带在跟随镜头较易看到，上带在全景／高镜头出现。这里坐标只是候选，不是已接入。R2-04若使用orbit，应放后层上方弱群，不围住真实Boss形成假预告／假伤害区；优先两条远带也可，不必强用旋群。

## 已执行验证

原生Godot4.7.2、Dummy音频，独立局部夹具在game/build/qa/r2-reference-motion-v4/school_probe.gd：8项通过，覆盖固定28池、路径变化、时间回退确定性、external_clock不重复计时、band／orbit一小时采样中心均在界内、循环跨边只在不可见时发生、实际GPU附肢变化、冻结路径后仍有单体局部动作。school-checks.json、school-probe.log、school-body.png均留该QA目录。已看单体渲染图，触须／附肢形变没有额外底色矩形。导入无SCRIPT ERROR／ERROR，diff --check通过。

此验证只证明独立组件技术工作；真实两房接入、背景唯一来源去重、整体暂停／恢复、实际尺度与审美由根侧继续验证。没有声称自然玩法／难度／整体原画复刻已通过，也没有改真实玩家档。

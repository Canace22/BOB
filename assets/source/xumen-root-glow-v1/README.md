# 骨根琥珀灯蕊珊瑚 · E01低位洞口替换

[当前原画册](../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html#real-scene)。2026-11-06，按用户圈定位置，将角色左侧地面壳洞替换成附着骨根的发光珊瑚，不保留洞口。

旧椭圆门框、空腔和低位红绳全部去除，补成实心多孔骨根。细枝末端透明琥珀色珊瑚虫形成不规则正形轮廓，暖光只落在附近骨质上；位置位于主路后侧。角色、主路、三层台面、斜骨梁和上方圆形开口保留。它是非交互环境装饰，不新增入口、营地或奖励。

内置imagegen一次局部编辑，模型名未公开，无额外付费工具。英文提示词和生成编号见[generation.json](generation.json)，原始输出为[images/E01-glow-coral.png](images/E01-glow-coral.png)，尺寸1374×1145；修改前图与用户圈图在inputs/，哈希见manifest.json。

运行展示复用../xumen-ecology-niches-v1/render_niches.py的随形蒙版，G01-ROOT使用自己的世界视口和素材，只在一个小区域显示；原图和已有补绘不覆盖。图册“生态装饰”开关可对照前后，同组既有[两处珊瑚浅窝](../xumen-ecology-niches-v1/README.md)继续保留。

复验：`node assets/source/xumen-root-glow-v1/verify.cjs`。同一套局部比较脚本以E01视口运行，实际截图确认变化限于指定区域；细节见[acceptance.md](acceptance.md)。重建运行本目录register.py与../xumen-keyart-v2/build_atlas.py。review/是可复跑的本地证据。

仅交付静态概念原画与可编辑蒙版，发光为绘画光色；没有制作运行时发光动画或替换Godot场景。

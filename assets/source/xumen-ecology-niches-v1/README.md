# 须筛接续 · 珊瑚与藤蔓浅窝

[当前图册](../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html#real-scene)。2026-11-06，依据用户红框与“增加珊瑚和藤蔓、减少洞口深度”的要求，修改E02低位主路两处门状装饰。

- N02-L：封闭原空拱的透视洞口，浅骨壁上布置淡紫扇珊瑚、灰黄管珊瑚和贴壁藤蔓，打破完整门框轮廓。
- N02-R：深壳窝改成可见实底的浅凹，小型珊瑚光保留少量琥珀色；藤蔓与珊瑚依附骨壁，主路保持开敞。
- 二者都是静态非交互装饰，不是门、营地、商店、存档或传送点。没有新增路线与玩法。藤蔓本批只交付静态原画，没有声称制作动画。

使用内置imagegen一次完成局部补绘，模型名未公开，未调用其他付费服务。完整英文提示词、生成编号与原路径见 [generation.json](generation.json)，原件为 [images/E02-coral-niches.png](images/E02-coral-niches.png)，保持1374×1145。修改前原图与用户圈图保存在inputs/，哈希与尺寸见manifest.json。

render_niches.py将同一幅补绘通过两块小型随形蒙版放回原坐标；design.json给出ID、功能、位置和轮廓。母版仍是 ../xumen-reference-panorama-v2/原图保真全景.svg，原房图和此前补绘未覆盖。图册可切换“珊瑚浅窝”对照修改前，也保留更早的版本开关。

验证：`node assets/source/xumen-ecology-niches-v1/verify.cjs`实际截图前后对照，确认两处以外像素不变；审核边界见acceptance.md。重建执行register.py与../xumen-keyart-v2/build_atlas.py。review/为本地可复跑截图与检查数据，不作为新美术入库。

本批只更新静态原画册，未修改game/、未构建或发布Godot。

后续[E01发光珊瑚替换](../xumen-root-glow-v1/README.md)复用同一局部显示器，每个元素可指定自己的视口和素材；全组现在3块蒙版、2份新画，图册开关统一名为“生态装饰”。本目录原两处浅窝的源图与位置未变。

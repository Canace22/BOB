# 02_assets

内置imagegen只补绘被遮挡区域和清除需独立移动的烘焙元素；原图主要结构以原生Godot遮罩抽取。生成透明PNG、保留SVG/JSON母版和生成记录。检查透明边缘再接入。

输入：original/reference.png；原件不得覆盖。输出：当前源目录、assets/runtime/xumen-reference-environment 与唯一Godot工程。

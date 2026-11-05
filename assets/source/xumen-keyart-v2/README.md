# 须门遗港原画精修 V2

本批只做原画设计，不改正式Godot工程、碰撞、战斗与发布版本。

入口：[精修图册](../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html)。整体鲸头剖面与七房分别绘制，六条既有连接由design.json约束。原画可用于确认风格、分层和器官衔接，不能直接横向拼贴为运行地图。

## 文件

- `inputs/`：用户七房、既有三过渡和鲸头剖面，以及现有解剖、拓扑、工程布局快照。`input-manifest.json`记录哈希，`sources.json`记录来源角色。
- `images/`：内置imagegen新原画；保留完整生成画幅。
- `prompts.json`、`prompts/`：实际英文提示词、参考角色、生成编号、输出路径。修订保留旧候选。
- `design.json`：七房、六边、器官位置、分层和动态选型，明确设计候选与运行状态。
- `art-manifest.json`：尺寸与哈希。
- `review/`：浏览器验收证据与定向修正记录。
- `acceptance.md`：逐图人工式视觉复核（由AI观察记录）与技术验收边界，用户审美待反馈。
- `build_atlas.py`：由JSON生成可浏览HTML，不生成或修改正式位图原画。

## 继续制作

先确认本批原画方向，再从E01制作双房联合分层母版：对齐现碰撞路面，补齐远景和遮挡面，分离可玩层、前景、须束、鱼、泡和灯。先验证静态构图，再用已有成功机制制作动态单件。后续五边按合同扩展；不把七张概念图拉伸拼接，不据图中暗孔新增通路。

恢复命令（在仓库根目录，Pillow可用的Python环境）：

```powershell
& 'work/wan22-production/helpers/Scripts/python.exe' 'assets/source/xumen-keyart-v2/build_atlas.py'
```

本批没有新动态实测，不将概念选型记成已成功的动画配方；沿用scene-environment-motion的固定端/延迟跟随、生物自身动作与路径分离、粒子有界回收等既有方法。

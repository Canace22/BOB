# 左上与右下近景拆分

根据用户圈选图，把原先混在洞顶/洞壁中的近景分别拆成两个RGBA部件，接回唯一WhalebellyRuins工程。已有底部前景沿用，并增加32像素边缘挤出余量；相接部件同速视差，避免相对运动裂缝。

| ID | 基准位置 | PNG尺寸 | 层级 | 相机位移倍率 |
|---|---|---|---|---|
| FRONT-TOP-LEFT | -32,-32 | 336×336 | 51 | -0.14 |
| FRONT-BOTTOM-RIGHT | 1060,394 | 252×358 | 51 | -0.14 |
| FRONT-01（已有底部） | 0,0，贴图offset -32,-32 | 1344×784 | 50 | -0.14 |
| FOREGROUND-CORNER-BACKING | 0,0 | 1280×720局部透明补片 | -1 | 固定 |

## 制作与母版

- 原画来源：`../xumen-reference-environment/original/reference.png`，构图坐标1280×720。前景直接提取原画像素，未重新生成轮廓或材质。
- 圈选原件：`reference/marked-foreground.png`。
- `master/top-left-mask.svg`、`master/bottom-right-mask.svg`：可编辑曲线轮廓蒙版；原生Godot栅格化、轻度边缘羽化。
- `generated/corner-backing.png`：内置imagegen对既有背景作一次局部补绘，移除左上近景遮挡、延续右下内壁。只使用角落蒙版及其有限余量，全图其他内容不会替换游戏画面。
- `master/*.png`：两片独立前景、底部带余量版本、补绘补片，以及10个去除重复前景像素的静态层副本。
- `source-sprites.json`：拆分前的真实资源绑定快照。再次导出基于此快照，避免重复切割。
- `manifest.json`：实例布局、源到派生映射、清理像素数。

边缘余量来自边界像素挤出，用于有限视差时防止贴图断边；不是新增画外地图。新前景独立保留图层和原图柔焦感，没有让整片洞顶、整面侧壁或路面随前景移动。

## 打开与调整

在Godot 4.7.2中打开 `scenes/environment/xumen_reference.tscn`，选择FRONT-TOP-LEFT或FRONT-BOTTOM-RIGHT。节点为独立子场景，贴图位于 `assets/foreground_edges/`。保持三个相接前景的parallax_amount一致；布局、纹理和参数均可编辑。主关卡R1-01共用此环境。

预览入口 `scenes/environment/motion_preview.tscn`，F6，C切换镜头演示、空格暂停；主游戏F5，Tab切换全景/跟随。没有新增玩法或碰撞。

## 可重复制作流程

1. 修改SVG轮廓或补绘母版。
2. 固定Godot执行 `--headless --script res://tools/motion_elements/prepare_foreground_edges.gd`，导出原生RGBA素材、静态清理副本和有限补片。
3. Python运行 `tools/integrate_foreground_edges.py`，更新场景、全元素清单与布局JSON。
4. Godot导入，运行 `tests/foreground_edges_qa.gd`、环境回归和既有主关卡实际输入测试。
5. 生成同视角截图、隔离图层、隐藏前景画面、实际镜头录像；刷新交付页与便携包。

基础生成器已按顺序调用垂须、柔光和前景修正，防止旧图覆盖新装配。旧原件保留可追溯，不作为活动图层继续显示。

## 检查边界

固定构图、镜头两端、隔离前景和背后补片分别保存截图。全屏视差极限测试与实际游戏镜头测试分开：极限位移±128应使用足够缩放，不能把相机本身移出原图的空白误判为分层接缝。底部全景边缘发现缺少余量后已补齐。

小范围补绘有少量纹理差异；仅在近景移开时可见，不宣称隐藏区域是原图真实内容。旧底部前景轮廓和既有分层质量不冒充本轮重新手工描绘。实际证据见 `godot/WhalebellyRuins/evidence/foreground_edges/`。

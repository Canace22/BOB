# 拱桥下缘与气泡 · 2026-10-29

本轮范围为用户圈选的桥下截断和气泡增补。没有修改关卡碰撞、路线、角色控制或世界范围。

## 截断原因与修正

逐层关闭和局部放大定位到两个问题：前景补底过渡范围较硬，以及旧ROAD多边形蒙版沿斜线裁掉了原图桥下悬挂枝条。首次只改补底时，对照图仍有裁短形状，因此追加道路素材的定向修复。诊断图保留于 `evidence/underbridge/without_FOREGROUND-BACKING.png`，最终效果见after-detail与repair_without_bubbles-detail。

新的 `FOREGROUND-BACKING-SOFT.png` 保留原补片RGB，只修改alpha：在受影响范围软化过渡并保护原图中桥体材质。保护范围受原前景轮廓限制，防止同时显露已移除的前景珊瑚。原图和旧补片均保留，未以模糊整张场景或气泡遮盖问题。

`ROAD-UNDERSIDE-RESTORED.png` 在410…560 × 495…610源图坐标范围提取遗漏的暖色悬挂组织，去掉蓝色水域并保留原画像素。已有VINE-02拥有的447…493 × 534…616区域排除，避免静态副本与独立动态重叠。ROAD节点位置、尺寸、z层和碰撞不改。

源：`../xumen-foreground-edges/master/CLEAN-FOREGROUND-BACKING.png`、`../xumen-reference-environment/original/reference.png`、`../xumen-motion-elements/master/foreground-mask.svg`。母版在本目录master，运行资源在工程assets/underbridge。

## 新增气泡

| 独立场景 | 位置 x,y,w,h | 数量 | 尺寸 | 基础速度 | 不透明度 |
|---|---|---|---|---|---|
| BUBBLE-ZONE-05 | 330,215,65,230 | 7 | 5–9px | 14px/s | 0.48 |
| BUBBLE-ZONE-06 | 560,485,110,170 | 7 | 7–11px | 12px/s | 0.50 |
| BUBBLE-ZONE-07 | 925,175,70,275 | 6 | 4–8px | 15px/s | 0.44 |

分别位于左侧岩缝上方、桥下空腔和右侧开阔水域。每个个体在基础速度上增加0～6px/s，并有小幅横摆、预热分布、边界淡入淡出及回收。三处z=-15，处于道路、角色和近景之后。旧四区保持36个，新增20个，总数56个；环境ID总数106。

复用已入库 `assets/reference_environment/bubble.png` 原画气泡，不调用外部生成或收费服务。可独立编辑每区的bounds、population、size_range、base_speed和bubble_opacity。

## 重建与验收

1. 固定Godot4.7.2运行 `--headless --script res://tools/motion_elements/repair_underbridge.gd`。
2. Python运行 `tools/integrate_underbridge.py`；基础环境生成器最后也调用此步骤，避免旧补片重新覆盖修正。
3. 导入后运行 `tests/underbridge_qa.gd`、`tests/motion_elements_qa.gd`、主关卡 `--qa-reference-level`。
4. 查看同视角前后对照、关闭气泡的修复图、镜头两端和32秒实机录像。打包后独立启动检查。

定向检查包含56个实例、每区动态与层级、180秒加速状态模拟、回收数量；180秒模拟不是180秒人工录像审阅。美术以实际截图与录像抽样对照，少量旧抠图/补绘边缘差异仍属既有局限。

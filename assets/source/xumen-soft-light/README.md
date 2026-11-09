# 水下柔光 · 多边形光束接缝修复

## 原因与修复

旧BEAM-01/02/03不是纯光素材，而是从背景中用四边形蒙版切下的绘画像素，其中包含骨架、洞壁和水体。原导出器同时从ENV-DEPTH扣除了这些区域。镜头跟随时，远景补绘层有视差，缺口中的纹理与固定裁片失配，形成尖角。因此仅隐藏光束仍有接缝，证据见 `evidence/soft_light/old_beams_hidden_1.png`。

修复把被切走的原画像素合回背景层，得到 `ENV-DEPTH-RESTORED.png`。三个旧裁片退出活动场景，原文件保留历史；相同ID现在绑定全新的独立光效场景，元素总数仍为100。没有删除正常的骨架或改动关卡路线。

## 独立光效

- 原件：`generated/underwater-light-original.png`，内置imagegen生成，1024×1536 RGBA；不含场景几何。
- 编辑母版：`master/UNDERWATER-SOFT-LIGHT.png`，512×768 RGBA，保留生成透明度并羽化四边。
- 背景母版：`master/ENV-DEPTH-RESTORED.png`，1232×715，原画补回，不是重新生成背景。
- Godot独立元素：`scenes/environment/elements/soft_underwater_light.tscn`。
- 同名GD与Shader：12秒周期，少量纹理内部流动与亮度呼吸，渐隐边缘，加法合成；不读取屏幕/背景，不改变光效几何位置。
- 三个实例：z=-54，在水面之后、中景/垂须之前。强度0.12/0.08/0.055，方向固定，错开相位。Inspector可改周期、相位、强度；布局在xumen_reference.tscn。

光源材质仍保留原画静态高光；此次替换的是存在棱角的动态叠加层。没有新增碰撞、玩法或声音。

## 实际工具与重建

Godot 4.7.2；内置imagegen调用一次生成柔光原件（透明背景），无第三方付费调用。源参考为用户圈选图，只用于定位错误，不作为新灯光纹理内容。

1. Godot `--headless --script res://tools/motion_elements/restore_light_background.gd`：从旧DEPTH和BEAM PNG恢复背景。必须保留旧PNG作为可再现输入。
2. Godot `--headless --script res://tools/motion_elements/prepare_soft_light.gd`：保留RGBA、统一尺寸、羽化并输出中央运行资源与工程副本。
3. Python `tools/integrate_soft_light.py`：更新活动场景与清单。基础环境生成器已追加此修复，避免再次导入旧裁片。
4. 实际运行 `tests/soft_light_qa.gd`，检查独立纹理、透明边界、12秒循环、镜头±128像素截图。运行环境、水面及既有角色行走回归。

用户原图、提示词、来源和执行记录均在本目录。截图/录像/JSON证据在工程 `evidence/soft_light/`，本次构建仍为官方Godot固定引擎+PCK。

## 验收边界

定向渲染、镜头左右两端和隔离光效有实际截图；已对照圈出的尖角位置，不将所有美术细节宣称为逐像素复刻。平滑感由抽样画面、渲染循环和录像提供证据，最终审美由实际播放判断。

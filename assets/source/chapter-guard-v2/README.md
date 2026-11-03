# 负壳守卫 · 章节重制

2026-11-03：用户确认章节应接原母蟹训练场战斗。本批姿势保留为制作历史，章节运行场景已不再实例化该守卫；以下是 11 月 2 日的制作和接入记录，不代表当前章节 Boss。

针对旧章节 Boss 风格和动作不足的反馈重新绘制。参考同仓库拾潮者与骨壳环境的材质、轮廓和光照，设计象牙重壳、青灰四足与双扣带；不是母蟹训练场动作换名。用户尚未确认本批美术。

## 制作与交付

- [完整提示词链](prompts.md)：本次内置 ImageGen 的实际调用；包含未采用的试验记录。制作源为 concept、sweep、walk、slam、breath-hit、retire PNG；neutral 是横扫首帧的确定性裁片。素材为用户授权的 BOB 创作，未引入外购或第三方下载动作，不另行声称独立许可。
- [extract.py](extract.py) 输出到 [运行目录](../../runtime/sprites/chapter-guard-v2/)。每动作统一比例与偏移，512×512 画布，公共 pivot `[256,440]`。具体裁切、偏移与透明轮廓见 [registration.json](registration.json)，没有逐帧 bbox 归一化。
- 共 40 个绘制姿势：待机 4、受击 4，行走、横扫、压壳、非致死退让各 8。各帧时长、循环和 88 世界像素步幅由 [animations.json](../../runtime/sprites/chapter-guard-v2/animations.json) 定义。
- 角色源图面向左；当前右向用运行镜像，尚未绘制独立右向扣带。有限姿势与持帧不是高帧率补间，不能把 50 FPS 工作台时间轴说成每秒 50 个新姿势。

## Framecraft 工程

使用用户的 [sprite-workbench](https://github.com/Canace22/sprite-workbench) 工作台。六个实际保存、重新打开的项目位于 `projects/`，记录见 [framecraft-projects.json](framecraft-projects.json)。[framecraft.py](framecraft.py) 通过本地 API 保存并复核帧序；需要先启动平台服务，已透明的图片不重复抠图。

非等时长按 20 ms 展开持帧。实际界面导出的 [横扫原始包](exports/sweep-framecraft.zip) 含 91 个时间片、8 个独立姿势、总长 1820 ms。逐片 alpha 与原图一致，RGB 最大差 1/255，黑白背景合成逐像素一致；见 [导出核验](export-verification.json)。平台默认导出 `loop:true` 和底边 pivot，与游戏不一致；保留原始包，游戏按上述运行清单使用 `loop:false` 和 `[256,440]`，不直接照搬导出默认值。

## 画面复核与限制

使用同画布、同倍率并排核对全部 40 姿势，实机证据保存在本地 `game/build/qa/chapters-v2-local/` 与后续发布记录。两个稳定部位的人工近似量测（256 像素预览，无逐帧适配）：横扫首帧壳宽约 129、壳尖至右下扣环约 98；行走首帧约 130 / 92；压壳首帧约 130 / 94。壳宽接近，壳尖至扣环距离仍有约 6% 的跨动作差异；这是粗测，不作为精密尺寸保证。压壳倾转、退让蹲伏不按整体包围盒强行等大。

行走可见四足轮流抬起，末帧接首帧保持壳体位置；横扫经过收钳、伸钳、接触和回收；压壳以屈足、前倾和压低壳体表现重量。录屏抽帧显示脚底与地面相接，横扫/压壳接触从第 4 帧开始、收招从第 6 帧开始；自动测试另核对这些时间边界。受击前两帧壳体抬起，回到待机仍偏硬；壳纹、脚尖有细小形变，步态脚滑未做逐像素量化。不是用户已认可的最终动画，也不宣称所有衔接已达到流畅成片品质。

重新提取：`python assets/source/chapter-guard-v2/extract.py`（Pillow）。修改后重建工作台项目，按游戏 manifest 同步并复核实机；缺图直接暴露加载失败，没有新增程序绘图回退。

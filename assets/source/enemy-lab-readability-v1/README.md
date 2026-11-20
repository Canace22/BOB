# 敌人试验场辨识度样板 v1

用途仅为Godot独立敌人试验场。参考现有corpse_crab/attack.png的线条和材质，重新绘制三种轮廓，不是对旧动画换色或非等比拉伸。使用内置image_gen生成；原始生成图按原字节保存，runtime与game副本同哈希。未经用户美术认可，不标记正式验收。

## 制作约定与提示词记录

三张1536×1024 RGBA图，每张4×4、16帧。每行一个动作，四帧为准备、蓄势、有效姿态、收招；首行四步走路。侧视、朝左；单位参考脚底落点，运行按首帧可见高度统一等比缩放，不逐帧缩放。轮廓/动作要求：

| 稳定ID | 轮廓 | 第2/3/4行 |
| --- | --- | --- |
| forager | 扁三角锈红小甲、长横钳、细长腿、琥珀眼 | 低位横扫；收钳贴地冲撞；两钳交替前刺 |
| mudback | 橄榄灰圆丘厚背、垂污絮、短粗腿、小钳 | 压腿蓄势冲出；顶甲慢推；抬甲露腹翻压 |
| shell_guard | 高象牙螺旋壳、深蓝小体、长针钳 | 回收直刺；缩进壳内侧顶；拖壳回正 |

共同最终提示要求：hand-painted dark underwater fairytale, consistent anatomical identity, LEFT side-view, exact 4 columns x 4 rows, equal384×256 cells, full creature, clear padding, feet around cell y230, transparent background, no floor/shadow/labels/borders, articulated poses rather than translated stills, no repeated overhead claw slam.食腐甲与大甲分别生成；守卫初稿有白色半透明底，留作background-rejected，不用于运行。守卫最终通过image_gen编辑提示“Remove ALL white/gray background, ambient haze, drop shadows; keep all16 poses, location, size, colors; genuine alpha-zero empty space”修复，生成式清底可能重绘细节，不能声称像素保真。

## 区域与接地

生成图的少量长钳越过名义格边，直接按4×4硬切会截钳并串入邻帧。atlas.json依据Alpha≥32连通主轮廓分析得到16个独立对象的包围盒，各加4像素取样余量；只生成区域元数据，不改原Alpha或素材像素。按区域质心映射名义格索引，保留名义根X和逐帧最下支点作为pivot。运行使用region_rect裁片；原全图与元数据可复核，不把自动切片成功当作动作质量通过。

3套各3招、每招4关键帧已接入真实起手/有效/收招；二连分两次出手取不同帧。其余受击、撤退和结束仍复用本套姿态，不代表专门制作了死亡/撤退动画。四步行走为低帧率验证样板，正式流畅动画仍需后续补帧与用户验收。

实机证据：game/build/qa/enemy-lab/readability-*（仅本地）；正式状态与限制见game/progress.md。检查透明边缘、接地、三种轮廓、九招阶段以及格挡反馈，不使用生成式合成图替代实机。

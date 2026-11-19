# 原画风结构资产 · 最终定向交付

2026-11-15。使用内置imagegen，对原画风竖壁/厚低顶两个家族分别作3次定向修形，最终一次选定**v4**。不再追逐固定长宽比，不再重试。既有复杂碰撞和摆放由主任务负责，素材只允许合理等比缩放/多件拼接，不改变碰撞以迁就图片。

完整来源与提示词：[prompts.json](prompts.json)、[production-assets.json](production-assets.json)。后者保留每次edit目标/参考、全prompt、生成ID、旧素材prompt全文、源/runtime/game三份哈希。新图不是从原画精确抠出，而是参考引导重绘；candidate不代表用户美术签收。

## 最终结构核心

坐标是原PNG左上角，bbox右/下不含。`alpha32 bbox`是可见轮廓诊断，不是实心覆盖范围。`core`矩形内所有原始像素alpha≥250，**没有透明孔**；250是实测阈值，不声称全为255，也不裁掉原图低alpha。

| 运行文件 | 画布 | alpha32 bbox | 连续core bbox / 尺寸 | 占可见轮廓宽×高 |
| --- | --- | --- | --- | --- |
| porous-wall.png | 1088×1445 | (364,83,723,1389) | (383,148,710,1324) / 327×1176 | 91.1%×90.0% |
| cavity-roof.png | 1774×887 | (334,184,1436,683) | (444,202,1326,662) / 882×460 | 80.0%×92.2% |

墙的可见比例约1:3.64，顶约2.21:1；地图各实墙比例不同，不把这些比例当成必须修改地图的要求。图中暗孔是绘制的凹坑，仍在不透明结构内。墙已去掉外张巨肩、深根破口；顶已去掉深凹拱/多层亮唇。

原始候选wall虽总bbox宽822，长主干核心曾只有174–241宽；原roof虽总高544，中央核心仅223高。那些候选不能按总bbox拟合成实墙。旧两图、v2/v3仍保存到`images/`，不会覆盖原件；只有v4进入正式porous-wall/cavity-roof运行dest。

## 八件定向副本

共同runtime目录：`assets/runtime/scenes/xumen-original-style-v1/`；共同Godot目录：`game/art/xumen-original-style-v1/`；manifest dest为`xumen-original-style-v1/<文件名>`，无max缩图，原字节/尺寸保持。

| 文件名 | 原来源 | 用途和限制 |
| --- | --- | --- |
| porous-wall.png | images/porous-wall-revised-v4.png | 新连续实体竖壁；按core与冻结墙体核心配准，实际覆盖/通路由主任务检查。 |
| cavity-roof.png | images/cavity-roof-revised-v4.png | 新单块厚顶；不允许拉伸成多层粉饼。 |
| original-ledge.png | assets/runtime/sprites/r1-tongue-ledge/base.png | 原生舌台/组织骨台，2162×727，bbox32=(59,132,2102,665)。 |
| original-membrane.png | assets/runtime/sprites/r1-weight-membrane/base.png | 原膜默认态，2162×727，bbox32=(54,169,2110,576)。 |
| original-membrane-pressed.png | assets/runtime/sprites/r1-weight-membrane-pressed/base.png | 原膜压下态，同2162×727，bbox32=(54,165,2092,593)。两态共享画布/固定端，不能各自裁框对齐抵消下陷。 |
| original-bone-ledge.png | assets/runtime/sprites/r1-nasal-wall/base.png | 原生横向鼻腔灰骨，2060×763，bbox32=(61,72,1998,716)；不是竖墙，不能旋转/纵拉伪装。 |
| original-soft-ledge.png | assets/runtime/sprites/r2-membrane-platform/base.png | 原软膜台，2162×727，bbox32=(60,193,2102,592)；保持软材质识别，不由借用图新增能力。 |
| anatomy-fracture.png | images/porous-wall.png（首个分叉候选） | **仅低对比非碰撞背景骨架/洞顶/平台端附着**。1159×1358，bbox32=(125,17,947,1340)。大叉肩与自然破口是背景优点，不可当实心墙、不可增加碰撞。 |

八件均已登记catalog.json/catalog.md与game/art/manifest.json；没有执行全局sync，没有改生成器、recipe、碰撞或其它图。旧大肩wall仅因新增背景用途复制为anatomy-fracture，不替换正式v4实体墙。初始roof和v2/v3仍只在source。

## 实际检查与限制

- 新结构每次输出已实际看图；最终v4另做[浅底/深蓝底透明合成](review/final-alpha-composites.png)，查看时未见整块底色、宽光晕或内部透空。合成是review图，不是编辑后的运行资产。
- 实测四级alpha边界、连续core、源/runtime/game三份SHA256一致；完整数值见production-assets.json与revised-structure-metrics.json。不按raw非零alpha触边判断轮廓裁坏，不清除可能有用的细边。
- `npm --prefix assets/manager run check`通过。`npm --prefix assets/manager test`为4通过/1失败：原测试在Windows创建文件symlink时返回EPERM，未到资源读取断言；这是测试环境权限限制。本轮未修改管理页或规避该测试。
- 本专项仅证明位图/来源/定向复制/实心区域。最终贴地、墙覆盖、镜头缩放、生态附着、遮挡、膜运动及完整来回路线，仍由主任务当前入口验收。catalog中的candidate与not-integrated不冒充该验收完成；主任务确认后可按实际证据更新。

已验证的方法是用原始alpha逐像素测连续矩形core，能识别“宽肩/深拱总bbox看似足够、实际实墙覆盖不足”；后续新结构先测core，再作场景样板。比例提示无法保证生成的精确像素长宽，不能无限重试或拉伸修正；本次按core与外观选定后停止，由原生等比拼接适配不同实例。该技术经验记录在本批，不把尚未验证的场景拼接效果升为通用已验配方。

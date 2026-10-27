# R1 悬台骨纤根簇

2026-10-27，按用户要求补制缺失的正式 2D 位图，用于 R1 选定悬空平台下方的装饰支撑。稳定 ID：`r1-hanging-root`。

## 来源与制作

使用内置 `image_gen.imagegen`，`transparent_background: true`，纯文本生成；没有传入 `referenced_image_paths` 或 `num_last_images_to_include`，不能声称参考图作为附件参与生成。调用输出 ID 为 `exec-4a769e25-f12e-4da7-9d6a-4a510bf832fb`。

[prompt.txt](prompt.txt)保留制作简报，[prompt-used.txt](prompt-used.txt)保留实际调用提示词。风格目标沿用仓库的深海骨骼、暗红组织和手绘材质，不是现有横向平台贴图拉伸，也没有用代码绘制正式原画。

生成 PNG 原样保存在唯一[原件](../../runtime/sprites/r1-hanging-root/base.png)，源目录通过此链接引用，不重复保存一份。用户要求用于 BOB；未附独立第三方授权文件，也不新增对外授权承诺。

## 像素与尺度

| 字段 | 原件值 |
| --- | --- |
| 画布 / 格式 | 1448 × 1086，RGBA PNG |
| 文件大小 | 991,312 bytes |
| alpha 范围 | 0–255 |
| alpha ≥ 1 bbox | `[0, 17, 1434, 1086]` |
| alpha ≥ 8 bbox | `[211, 72, 1231, 1021]` |
| alpha ≥ 16 bbox | `[211, 72, 1231, 1020]` |
| pivot | `[721, 72]`，alpha ≥ 8 bbox 顶部中心 |
| 世界尺度 | 可见高度 2.2 U，可见宽度 2.3646 U |
| SHA-256 | `cf3cc22de9119d4e0a167ab51a9829e5092ca24a741401e40e9078af6db09baa` |

极低透明像素延伸至画布边缘；沿用库中 alpha ≥ 8 的包围盒约定确定可见尺度，未裁剪或改写原始 PNG。三支骨纤根的非矩形下缘保留，不能纵向拉伸为通屏柱。

运行文件由现有[导出脚本](../../../mvp-v2/tools/export-runtime-art.py)按 384 像素边界、WebP quality 82 等比生成：[r1-hanging-root.webp](../../runtime/sprites/whalefall-v2-optimized/r1-hanging-root.webp)，384 × 288，21,232 bytes。导出倍率 X/Y 均为 `0.26519337016574585`；清单中的 bbox / pivot 已转换为运行像素，不可重复缩放。运行选择增至 42 项，共 1,959,728 bytes；原件哈希导出前后不变。

## 接入范围与验收

仅用于 `mvp-v2` R1 选定悬台；从顶部中心挂到既有平台下方，等比显示，不自动增加站立面、碰撞或新玩法。单张静态精灵，不是动画。未重新打包历史 174 件静态图集。

已执行：原件目检；尺寸/alpha/bbox/哈希核对；WebP 导出与透明度检查；真实按键五房路线、育窝悬台挂点/等比/遮挡/可达性检查。最终只绘制在 R1-05 两个独立中间台下，不加在连续丘面或高井叠台；现已登记接入。证据与发布结果见 [V2进度](../../../mvp-v2/progress.md)。用户美术确认仍独立记录。

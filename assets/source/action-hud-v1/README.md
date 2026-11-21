# 紧凑动作 HUD · V1

依据用户认可的 `approved-layout.png` 接入正式 Godot HUD。使用内置 image_gen 参考重绘透明静态图集，提示链见 `prompts.json`；原概念画面与生成素材并非逐像素相同，实际结果需以游戏截图检查。

- `icons.png`：6×4 静态图标，包括动作、生命面具、资源、架势与笔触。初稿含背景雾，`icons-first-candidate.png` 只留作来源；运行版本使用后续透明清理结果。
- `counter.png`：6×2 静态数字/COMBO/下划线，按实际连击数字组合，不引入私有系统字体。
- 两份 JSON：按规则网格和 Alpha 主体边界生成的像素裁片。只裁取区域，不重画或阈值修改生成像素；尺寸、原图 SHA256 和 Alpha 范围见 `extraction.json`。
- 运行副本在 `assets/runtime/sprites/action-hud-v1/`，通过 `game/art/manifest.json` 同步到 `game/art/action-hud-v1/`。导出清单包含两份非资源 JSON。

图标实际显示约 20～38 逻辑像素。状态、输入页、门条件和进度由现有系统提供；明暗/数字缩放均为程序驱动 UI 表现，不是角色动作动画。背景渐变、条框、拓扑格与边缘箭头属于常规 UI 绘制。

工程与原生视觉验收记录在 `game/progress.md`；技术验收不代替用户实际窗口下的可读性认可。

## 原画细节修正

目标标记由`objective-reference.png`通过内置image_gen参考重绘为`objective-generated.png`，保存`objective-prompt.txt`。仅做带透明留白的裁切与等比缩小到124×128；运行22px高，保留厚暗边、暖红斜面、中央亮点。不是逐像素抠取原图；边界、尺寸与哈希见`objective-extraction.json`。

四处UI底色改为常规UI九宫格绘制：中心为均匀深蓝压暗区，外侧固定48逻辑像素渐隐，代替椭圆径向渐变。生命/技能较深，目标/Combo轻薄；不会作为场景或正式特效美术登记。多出口目的地改为更亮金色和18px文字，方向标签14px，箭头适度放大，并使用轻薄柔底保持亮背景可读性。

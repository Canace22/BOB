# 鲸腹全图 · 鲸头向右续画（首稿）

用户指出此稿的躯干偏薄、腹腔过浅。当前实机采用[原画腹腔与局部补尾版](../world-map-tail-v2/README.md)。下列内容记录首稿。

[全图母版](whale-overview.png)为 2172 × 724 的不透明静态位图。鲸头取自用户选定的[须门遗港七房原画](../world-continuity-v1/images/02-r1-continuous.png)。右方胸腔的肋拱、灰紫肺叶、赭色胃褶、逐节收细的背脊和双叶尾鳍由内置 ImageGen 一次续绘。房名、路线、到访状态和推荐箭头由地图界面叠加。

## 原画保留与接缝

1. 在 2400 × 800 的透明定位画布上，将鲸头等比缩到 1056 × 352，放在左上坐标 (16, 236)。以此画布和全分辨率鲸头为编辑输入。[续画原始输出](outpaint.png)保留完整海水、海床和鲸体。
2. 生成器调整了鲸头的位置。用原画的鲸须、蟹台和上颌空腔在输出上重新配准，再以 Lanczos 将原画等比缩至 1002 × 334，落在成图的 (11, 179)。内区直接使用原画像素，顶部和底部各 36 像素、左端 12 像素、右端 40 像素用于接边。矩形外完整保留续画。尺寸和混合规则见[合成脚本](compose.gd)。
3. 在仓库根目录使用 Godot 4.7.2 执行 `Godot --headless --path game --script ../assets/source/world-map-outpaint/compose.gd`，生成母版。再运行 `Godot --headless --path game --script res://tools/sync_art.gd -- --only=world-map/whale-anatomy-overview.png` 和工程导入。清单按原分辨率直拷贝。
4. 全图及共用全鲸底图的四个区域按[地图配方](../../../game/content/whalebelly/world/recipes/_world.json)的 `map.world` 放置 19 房。须门区域单独使用鲸头原画及其局部坐标。轮廓、水体、器官、菌灯均为静态地图插画，房间位置和状态属于 UI。

用 `test_campaign_world.gd` 检查范围和标签间距，用 `tests/whalebelly/minimap_qa.gd` 在桌面按 D 跨门、C 开图、Enter 切区、Esc 返回。验收记录见[工程进度](../../../game/progress.md)。

导入后的纹理内区为 (23, 215) 起的 950 × 262 像素，已同等比缩小的须门原画逐像素比较。最终母版 SHA-256 为 `fa464993d0004d47e3926d356f868f12692b4d77f8402303251c3b4ad3384f13`。本机采用项目保留的[场景制作合同](../../../.agents/skills/scene-environment-motion/references/production-contract.md)，个人通用场景 Skill 未安装。

## 内置 ImageGen 提示词

Outpaint a hand-painted 2D game world map. Reference image 1 is the actual 3:1 layout canvas: its painted rectangle is fixed in place (left .007, top .295, width .44, height .44). Paint all blank/transparent space to deliver a single fully opaque seamless side-on illustration in the exact same ultra-wide 3:1 aspect. Image 2 is the full-resolution original of the locked rectangle for brushwork and identity. Preserve the existing head panel in place, including the open blue mouth, scalloped ledges, dangling baleen, little figures, amber crab and flipper root. Match its slate/indigo skin, porous ivory bone, warm ochre rim strokes, wine-red and lilac soft tissue, sparse amber fungus lights and dark cobalt water; keep the same painted edge softness, miniature scale, texture frequency, and lateral light as the mouth. The subject is ONE monumental fallen whale with a continuous open side and a complete, graceful whale tail at the far RIGHT. Extend the head's cut edge directly into a chest with a few weathered ribs and softly folded plum-colored lungs, an ochre folded stomach chamber beneath, and an upper segmented ivory vertebral passage dwindling to a long tail peduncle and clearly readable pair of broad horizontal cetacean flukes in 3/4 side perspective. Give the tail breathing room at the right edge. Near-front flipper continues naturally out of the existing flipper root into the lower area. Continue the same tiny bone shelves, warm refuges and distant blue depths inside; open negative spaces between organs. Fill above the silhouette with deep still ink-blue sea and faint underwater scatter; below, continue the quiet dark seafloor in the supplied panel. No rectangular boundary should survive. No border, text, labels, UI, typography, map pins, diagram arrows, medical graphics, glossy 3D, dramatic rays, added whales or second head. Keep original head composition and watercolor/digital gouache treatment. Opaque final painting, landscape 3:1.

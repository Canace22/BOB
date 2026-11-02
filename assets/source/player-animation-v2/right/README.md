# 拾潮者 RIGHT 动作 V2

本批是独立绘制的右向动作，骨鸣器保留在远侧右手、橙灯在近侧左髋，没有把左向镜像成右向。运行 PNG 统一为 384×384，pivot `[192,342]`，游戏缩放 `.275`，站高约 240 源像素。

接入入口是 [delivery/manifest.json](delivery/manifest.json)。来源与失败候选见 [source-provenance.json](review/source-provenance.json)，技术核对见 [delivery-checks.json](review/delivery-checks.json)。这些检查证明文件、时序和平台导出一致，连续动画美术与游戏脚滑由主任务继续验收。

跑步按实际近远腿遮挡重排生成图格，并补入两张[中后承重姿势](stance-fix/README.md)，最终为 10 个独立姿势。近远腿各有接触、承重、中后承重、后蹬与腾空，完整支撑距离推算的步幅约为 86 个游戏像素，见[测量记录](review/stride.json)。落地按同一近脚踝和脚底注册，保留膝盖压缩，不按每帧包围盒缩放。

轻击是横向击出，第二击是单独新绘的斜向上挑，重击是抬举后下砸。命中段按帧边界设为 `[120,200]`、`[160,240]`、`[300,420]` ms。

制作与复跑：

- [assemble.py](assemble.py)：明确裁框、来源组共用比例、解剖锚点注册基础姿势。
- [matte_heavy.py](matte_heavy.py)：调用已有 Framecraft `/api/matte` 去除重击源图误带的背景；BiRefNet lite 的 1024 是推理尺寸，不是源像素尺寸。
- [assemble_combat.py](assemble_combat.py)：注册三组独绘攻击，前段采用张开站姿，恢复回到待机站姿。
- [merge_run_stances.py](merge_run_stances.py)：合并两张独绘承重姿势、重排跑步时序并写入完整支撑测量。
- [package_platform.py](package_platform.py)：调用现有[平台工作流](../../crab-animation-platform-v1/process.mjs)，50 FPS / 20 ms 时间格，真实保存、重开和导出。重复时间格只表示持帧，不是新增画稿。
- [merge_extra.py](merge_extra.py)：合并主任务完成的[受击、冲刺和治疗](extra/delivery/clips.json)。
- [verify_delivery.py](verify_delivery.py)：核对全部 PNG、ZIP 字节、画布、alpha、时长与攻击边界。

平台采用 scale=1、soft/Lanczos、alphaThreshold=8、sharpen=0，保真 PNG。平台没有补绘或生成补间。源图保留在 `raw/`，提示词在 `prompts/`，每组请求与工程在自身目录。

| Clip | Poses | Duration (ms) | Loop | Final Framecraft project |
| --- | ---: | ---: | --- | --- |
| idle | 4 | 800 | True | [project](idle/platform/projects/9f3ae7e4e1ec40c3b35a3f44f8d857d5.framecraft) |
| run | 10 | 640 | True | [project](run/platform/projects/73dd355e12894ff68fe92a7a915ffe1c.framecraft) |
| jump_rise | 2 | 180 | False | [project](jump_rise/platform/projects/43f0609426884ae992ac523113a5c835.framecraft) |
| jump_fall | 2 | 180 | False | [project](jump_fall/platform/projects/ef317f1131cf4f0c96abef455c20b923.framecraft) |
| land | 3 | 140 | False | [project](land/platform/projects/276e097e02324370a244d054d569cdb8.framecraft) |
| attack | 4 | 400 | False | [project](attack/platform/projects/d37faf4d52d2471686c75209cabb73d4.framecraft) |
| attack2 | 4 | 500 | False | [project](attack2/platform/projects/44799562f9ac416696886add3b47146d.framecraft) |
| heavy | 4 | 820 | False | [project](heavy/platform/projects/cf8b983a0ac94354a5cb4d00a9ecf5b6.framecraft) |
| hurt | 3 | 180 | False | [project](extra/hurt/platform/projects/9ddbf23c9fa34074a03a9b8fafb7765a.framecraft) |
| dash | 3 | 220 | False | [project](extra/dash/platform/projects/f57f2b53027f42e5ae0139b8b93dd0a6.framecraft) |
| heal | 3 | 1100 | False | [project](extra/heal/platform/projects/f456fb5b4bee4b60bb1531cbf379c767.framecraft) |

局限：头盔与灯的局部纹理会随生成姿势变化；[两标记尺寸复核](review/rigid-landmarks.json)中，重击灯的比例仍略大。两方向步幅仍需实机核对。攻击图的摆臂范围不代表游戏判定范围。额外三组的注册参数见 [extra/register.py](extra/register.py) 与 [extra/registration.json](extra/registration.json)。

本地接触图与 WebP 位于 `review/`，属于过程证据；若未进入 Git，可运行注册脚本重建。未采用图稿仅留作本地失败证据，名称与原因已登记，不混入运行动作。

# 主角普攻 V3：前突与横劈

2026-11-23。用户要求重做缺乏力量感的普通攻击，参考剑魂的用力方式，并明确采用「前突＋横劈」，使动作与前方命中范围一致。先前下斜劈／上斩提案保留在 `masters/*-unused.png`，不作为最终动作。

## 创作与运行边界

- 保留拾潮者头罩、青披风、灯具和短骨鸣器；不复制 DNF 人物造型。
- 第一段蹬地、送肩、向前突刺；第二段收叉转胯、水平挥劈。每段 16 张绘制帧。参考是动作方向，无视频逐帧复刻声明。
- 身体前探属于绘制姿态；不增加角色根位移，保留地面普攻站定、原命中时刻、判定范围、续击及防御取消。
- 内置 image_gen 原件、提示词与引用见 `requests.json`、`masters/` 和 `references/`。所有帧保持同一像素尺度，不逐帧按包围盒缩放；只做固定网格裁片和地面配准。
- `build.py` 输出三张 1536×1536 图集及 `animations.json`，实际源尺寸、裁片边界、根点、SHA 和独立帧数见 `production.json`。
- 弧光复用已入库的 `tide-picker-action36/strike1-fx.png`，仅显示朝向和等比尺寸变化，不承担伤害。

## 接入

`TideVisualPhaseMap` 在旧动作清单之后覆盖两段身体与帧配置，主线、试验场和共享清单的幻影回放读取同一来源。新增清单纳入素材同步与 JSON 导出白名单。运行目录为 `assets/runtime/sprites/player-basic-slash-v3/`；正式工程导出为 `game/art/player-basic-slash-v3/`。

## 复跑与验收

1. `python assets/source/player-basic-slash-v3/build.py` 重建，核对透明边界和固定根点。
2. 设置本机 `GODOT` 后运行 `node tools/godot.mjs check`、`node tools/godot.mjs test`。
3. 用 `game/tests/whalebelly/basic_attack_qa.gd` 原生 60Hz 真实 J 键输入，左右各跑一次；`-- --left` 指定左向。
4. 核对蓄势、释放、收势，身体大小、脚底和弧光与判定的关系；连续输入及取消验证和用户美术验收分别记录。

本批美术状态为候选，用户最终动作观感尚待试玩确认。实际执行结果见 `game/progress.md` 本批记录，不将源帧预览代替实机验收。

## 2026-11-23 顿挫与架叉格挡修订

用户反馈原普攻过于匀速、格挡依赖特效。保留前突与横劈原绘制帧，改用prepare_marks/release_marks控制停留：蓄势末帧占起手最后38%，出手迅速到接触第7帧并停留约70ms，随后收势，动作总时长与命中/取消时刻不变。实际命中双方停顿第一段4个60Hz物理帧、第二段5帧；多目标仍取最大值，不叠加，连续技内层轻击不改。

新增parry.png，16张绘制帧：0–2抬叉，3–6双手撑架，7–11受力压缩和撑回，12–15收架。有效防御仍按原20ms起手与原架势规则，不为播完动画延迟生效；60Hz下起手会跳过部分源帧。guard_success只启动0.18秒呈现反应，受命中停顿冻结，不写防御、伤害或反击时钟。持守光圈已压淡，格挡素材没有烘焙光圈。

原生guard-body-only-native.gif刻意移除辅助光圈和文字，以真实I键持守、显式正面伤害夹具启动成功事件（不是自然敌人AI攻击验收），检查身体帧3–6→7–11→持守→12–15。basic-weight-native.gif是当前J连按的实际60Hz节奏。技术检查与用户美术验收分别记录。

## 2026-11-23 格挡形象对齐

上一版格挡被用户指出与原角色不符，已弃用并保留为masters/parry-identity-rejected.png。新版只以原待机frame0作为主形象参考（references/canonical-idle.png），原攻击旧图作辅助，恢复细长四肢、小手、开口U形骨鸣器和三角披风。生成与去除头顶多余色块的两次完整请求见guard-identity-prompt.txt、guard-cleanup-prompt.txt；中间原件也保留，清理不是无损像素修改声明。

新版源仍1254×1254，固定根[156,逐行地面]、固定像素尺度导出到[192,340]图集根。新版中立高度250源像素，reference_height同步为250，避免沿用上一版210造成角色整体膨大。没有逐帧按Alpha边界缩放。技术近身对照guard-canonical-size-review.png将原待机、格挡中立、持守与受力帧统一以94px参考高度绘出，逐段动作与原生I键实机分别复验；用户审美验收仍待确认。

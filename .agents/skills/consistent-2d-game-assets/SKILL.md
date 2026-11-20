---
name: consistent-2d-game-assets
description: Generate, extract, validate, and deliver consistent 2D game assets from gameplay screenshots or approved art references. Use for characters, props, environments, sprites, complete static coverage, atlas exports, and project asset libraries that must preserve an established game style.
---

# Consistent 2D Game Assets

AI视频参考与游戏动作验收分开：实际解码时长／帧数／音轨，保留平台原件；若只需无声副本，可copy视频流去音轨并比较压缩视频流哈希，不必重编码画面。逐时刻检查身份、镜头、接触点与局部反馈，成功返回URL不代表服从设计。原图带人物而模型未遵守排除提示、受击片后段追镜等偏差必须如实保留，不能据此声称已能接入。两片原件／提示词／同节点换模型记录与验证脚本见[血巢视频V1](../../../assets/source/bloodnest-combat-video-v1/README.md)。

群体小生物须先以真实游戏尺寸核对头胸／腹节／触须比例，再设计群体。高分辨率长触须图直接线性缩小会出现细线和采样闪烁；优先修形体色块、缩短画布占比，再用等比导出与mipmap，不能用堆数量补救。参考补绘原件、两个生成提示词、512运行副本和实机证据见[血巢V5](../../../assets/source/bloodnest-animation-v5/README.md)；程序群体与逐帧动作分别登记。

背景复刻先对器官大形／色块／光向，再清理烘焙动态对象并独立接回。长触须生物的整体Alpha宽不等于躯干宽，要在真实镜头复核；背景群游的身体局部动作与整体路径分别测。原17／18重建、四件源及最终GPU证据见[肺心V4](../../../assets/source/r2-reference-motion-v4/README.md)。

原画引导透明分件不能只检查Alpha通道存在：在目标深色背景上看白雾／残底，并按实际空洞采样；静态装饰误生锚环会暗示玩法，应去掉。洞框若在全景露出外裁线，先核对实际视域长宽比并等比覆盖，不拉伸源图。六件新图、失败候选及266项实机证据见[建筑V3](../../../assets/source/reference-architecture-v3/README.md)。

后续区域恢复原画时，同源完整depth与透明far应二选一渲染；全景按整房覆盖，另查跟随四边。等比缩小的工作位导出不能记录为与原件字节相同；保留原件SHA、声明max尺寸，并检查实际导出。居民截图将玩家放在交互半径内的侧方，避免两者站在同一点遮住身份。BOB已验证实例见[后续十二房](../../../assets/source/remaining-19-v2/README.md)。

Produce reusable 2D game assets that still look native after deterministic placement in the target game scene.

## BOB project routing

Read [the collaboration rules](../../../AGENTS.md) and [the global art style](../../../assets/art-style.md) before production. Use this skill for generation, extraction, variants, animation, atlases, and asset-library delivery; use [BOB art integration](../bob-art-integration/SKILL.md) for repository paths, catalog fields, runtime loading, coordinate conversion, and in-game acceptance. Keep `mvp/` and `mvp-nightmare/` implementation evidence separate.

## Core decisions

For connected-map concept art based on an existing game, use [world continuity concepts](references/world-continuity-concepts.md). Preserve source topology, distinguish concept from implemented rooms, and pair continuous environment art with an exact connection contract; new seam methods remain candidates until engine-tested.

- Prefer an approved gameplay screenshot as the primary style reference. It carries perspective, scale, palette, line weight, lighting, texture density, and neighboring-object context at once.
- Generate a new asset inside the target scene before isolating it when visual consistency matters more than exact reproduction.
- Treat model-based “extraction” as reference-guided redrawing. It may alter structure, proportions, colors, and small details even when the prompt says “exactly.”
- When the scene-generated object must be preserved exactly, use a mask, segmentation, manual path, or deterministic crop instead of asking a generative model to extract it.
- Validate reusable assets with ordinary image compositing or the game engine. A generative reintegration is only a preview because the model may repair both the asset and the background.
- Keep source screenshots and approved assets unchanged. Save every candidate and accepted result as a new file.

## Route the task

For scene construction, reference-scene reconstruction or environmental motion (including a single fish school, hanging fringe or particle emitter), apply [scene-environment-motion](../scene-environment-motion/SKILL.md) as the production workflow. This skill continues to supply image/style/asset consistency checks; do not create a second competing pipeline.

1. If the user provides a gameplay screenshot, use it as the edit target and main visual reference.
2. If the user provides approved isolated assets but no screenshot, build a small reference board or temporary scene containing representative assets at their real relative scale.
3. If no approved art exists, create one baseline scene first. Treat it as provisional until accepted; do not manufacture a large asset batch from an unapproved baseline.
4. If the request covers multiple assets or production delivery, read [references/production-workflow.md](references/production-workflow.md).
5. When composing or repairing prompts, read [references/prompt-templates.md](references/prompt-templates.md).
6. Before declaring assets ready for use, read and apply [references/qa.md](references/qa.md).
7. For sprite animation, read [references/sprite-animation.md](references/sprite-animation.md) before generating or packing frames. Idle, walk, and attack are different action states; they do not constitute three frames of a walk cycle.
8. When deriving assets from design documents or several kinds of reference, read [references/design-to-assets.md](references/design-to-assets.md) to resolve source roles, preserve gameplay cues, and set a measurable runtime scale.
9. When delivering a searchable asset library or editable resource manager, read [references/asset-library.md](references/asset-library.md) for provenance, review states, derived exports, and persistence checks.

## Minimum asset brief

Gather or infer only what is needed to proceed. Ask the user only when a missing choice would materially change the result.

- Intended use and asset family
- Gameplay view and facing direction
- Real in-game footprint or comparison object
- Required states and variants
- Moving, interactive, and detachable parts
- Shadow policy and light direction
- Required output format, transparency, padding, and anchor

For a complex object, decide the layer split before generation. Building, door, fence, ground decal, shadow, vegetation, and animated creatures should normally remain separate when they move, interact, recolor, or sort independently.

## Default workflow

1. Inspect only relevant screenshots and approved assets. Identify stable visual rules rather than relying on a style label alone.
2. Reserve a clear patch in the target scene or choose an existing empty area.
3. Generate the complete asset in that scene. Specify actual gameplay use, footprint, approach direction, required parts, and the exact area allowed to change.
4. Review the in-scene result before extraction. Reject incorrect perspective, scale, silhouette, or interaction layout early.
5. Isolate the asset using a deterministic mask when fidelity matters. Use transparent generative extraction only when small redesigns are acceptable.
6. Split independently controlled parts and remove baked-in scenery that will not travel with the asset.
7. Place the PNG directly into the target scene without generative editing. Check it on the actual ground, at actual scale, and near existing objects.
8. Make one targeted correction per retry. Preserve accepted properties explicitly. Stop after three failed retries on the same defect and report the persistent failure instead of silently generating indefinitely.
9. Deliver the final assets with prompt records and practical metadata.

## Variant production

- Start variants from an accepted master asset and the same approved scene reference.
- Change one dimension at a time when possible, such as season, damage state, material, or growth stage.
- Keep silhouette, viewpoint, footprint, anchor, line weight, and lighting invariant unless the variant requires a change.
- Generate complete lifecycle sets together when visual relationships matter, but save each state as a separate reusable file.
- For animation, define the phases of one action and whether it loops or plays once. Keep one scale and root convention across its frames, and judge it in motion using the [sprite animation workflow](references/sprite-animation.md). A contact sheet alone does not establish animation quality.

## Delivery contract

For each accepted asset, provide or record:

- Transparent source image and, when useful, an in-scene preview
- Pixel dimensions and intended in-game footprint
- Anchor or pivot location
- Facing direction and light direction
- Layer or attachment relationships
- State or variant name
- Final prompt and reference images used
- Known limitations or required manual cleanup

Do not claim “production-ready” until the asset passes deterministic scene placement and transparent-edge checks.

## Godot reference-layer lessons

For deterministic SubViewport extraction, export straight alpha (`blend_disabled`) to avoid dark seams from double premultiplication. Provide a few pixels of hidden-paint overlap below cutout edges and validate at the intended camera offsets. A stationary reconstruction can hide baked duplicates: inspect isolated layers and moving frames separately. Keyed hanging foliage may include rigid attachment pixels; explicitly zero motion on those pixels and do not label such a crop as a universally reusable clean object. See the scoped example in `assets/source/xumen-reference-environment/README.md`.

For reference-video refinements, keep static placement invariant and change local motion within the existing cutout overlap. Initialize waves relative to their time-zero phase to retain the authored resting pose. Advance one scene clock only when animation is enabled; stopping animation must hold the current pose instead of resetting shader time. Test scene-tree pause, inspector toggles, zero speed, deterministic reload and bounded particle recycling separately. Near bubbles need their own draw depth as well as size/speed; a larger bubble behind the road does not establish foreground depth. Use actual renderer captures and existing level integration checks before repackaging; see `godot/WhalebellyRuins/tests/reference_environment_motion.gd`.

## Scene and environment production routing

Compare each object with its reference, rather than selecting materials from a room name: a grey nasal wall can surround red tissue ledges; a soft-organ room can contain thick living terraces. When replacing a doorway with a source crop, record visible alpha bounds and its own threshold region. Reuse a nearby camp/door visual when both occupy the same source alcove, retaining their original logic; do not duplicate two unrelated lit props. Scoped BOB evidence: `assets/source/xumen-source-style-v2/`.

When preserving an original design on a redesigned level, compare visual mass as well as source texture names. A native wide ledge shrunk onto a narrow landing may become a thin shelf. A larger uniformly scaled native plate cropped below the frozen walking top can restore organ volume, provided its bright duplicate top edge is hidden and real routes remain clear. Verify actual framebuffer contribution and body/landing occlusion; record source rules versus explicit user overrides. See the scoped BOB evidence in `assets/source/xumen-outputs-preservation-v1/`.

For original-style restoration on a redesigned map, preserve the user's chosen live rules and assign references explicit roles. An older art document may carry a different ability chain. Prefer source-native organ pieces over tinting one generic platform across every room; verify opaque structural cores independently of total alpha bounds. A broad decorative shoulder or translucent fringe cannot fill a solid collider just because the bitmap bbox fits. Use transparent, clean pieces for new framing rather than crops containing baked water; retain originals and rejected candidates. The BOB `xumen-original-style-v1` batch records source-byte checks, exact geometry preservation, composite painted-core checks and actual renderer views. These establish technical integration, not user art approval.

For scene construction, reference-scene reconstruction or an environmental motion element, apply [scene-environment-motion](../scene-environment-motion/SKILL.md) for proactive identification, method selection, production and evidence-backed learning. Retain this skill's asset/style consistency checks without starting a competing pipeline.


### 柱体重设计的实心范围与接缝验证

装饰帽不能代替实体障碍的自然轮廓；冻结碰撞后，应为主体制作足够实心的位图，按可见core等比配准。像素覆盖检查要逆完整父链变换，并计入旋转、offset和region，不能只减位置除scale。高位结构反复叠片会形成横线，能用一张完整位图延续到洞顶时优先整体；必要的连接留在后层并验证透明接边。静帧、真实输入路线和用户审美分别记录。BOB柱体重设计批次已有134项单测、GPU镜头与牵引／低顶路线证据；新轮廓尚待用户审阅，详见assets/source/xumen-structure-redesign-v1/。

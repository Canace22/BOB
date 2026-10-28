# 拾潮者 V2.4 → Godot主场景3C/技能

输入原件保留于 `G:/鲸落万物生/outputs/拾潮者_V2.4_透明边缘去紫/`，不覆盖。新增运行资源按用户指定位置存放于 `godot/WhalebellyRuins/assets/animations/player/`，540角色帧、540合成帧、180技能效果帧。全量RGBA与源裁剪像素一致，统一711×489画布、(305,413)脚部根锚点、旧试验场0.22缩放；主场景按原角色高度80–110px求统一等比缩放。

[运行与参数说明](../../../godot/WhalebellyRuins/docs/tide-3c.md) · [逐帧来源](../../../godot/WhalebellyRuins/assets/animations/player/manifest.json) · [45项回归](../../../godot/WhalebellyRuins/evidence/tide-3c/tests.json) · [像素校验](../../../godot/WhalebellyRuins/evidence/tide-3c/assets.json)

状态：技术接入可用，动作美术candidate。七房主场景已接入；移动攻击以独立腿部帧轨道/上身遮罩组合，非骨骼动画。源姿势衔接美术仍待精修；详见运行说明中的限制。未调用收费模型，未生成新角色形态。Reviewer: agent；用户手感及审美尚待确认。

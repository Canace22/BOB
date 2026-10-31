# game/ 工程规则

正式 Godot 工程。架构、模块和约定的主说明是 [docs/architecture.md](../docs/architecture.md)；协作、提交、发布流程遵循[根目录 AGENTS.md](../AGENTS.md)。

## 动手前

1. 读 `docs/architecture.md`，确定改动属于哪个模块目录。
2. 只读相关目录；房间问题直接读 `content/rooms/<区域>/<房间ID>.tscn`。
3. `legacy/` 下的旧工程只作参考，不在里面开发。

## 写代码

- 带类型的 GDScript，每个可复用脚本声明 `class_name`；脚本尽量不超过 250 行。
- 逻辑按稳定 ID（房间、入口、能力、标记）判断，不用房间序号或显示名。
- 新房间、新门、新拾取物优先用场景节点和 `@export` 配置完成，不加特判代码。
- 跨模块通信走 `EventBus` 和 `GameState`；不要 `get_node("/root/Main/...")`。
- 正式画面只用 `art/` 中同步来的位图；新素材先进入 `assets/` 并登记台账，再加到 `art/manifest.json` 并运行 `sync-art`。
- 不提交 `.godot/`、`build/` 和第三方插件二进制；`.import` 和 `.uid` 要提交。

## 验证

```sh
node tools/godot.mjs check
node tools/godot.mjs test
```

改动玩法时补充或更新 `tests/test_*.gd`，并按按键实际走一遍受影响的路线。阶段状态与验收证据写入 `game/progress.md`。


## 场景和环境动态

涉及场景布景、参考图还原、环境动态或独立鱼群/柔性物/气泡时，默认应用[场景与环境动态制作](../.agents/skills/scene-environment-motion/SKILL.md)。主动扫描并选择合适动画方式，先样板再接入，批末回写成功配方；不新增本次未要求的玩法或碰撞。

# 登记、独立验收记录与过期图集清理

入口为 `register.py`，实现位于 `tools/registration.py`。导入模块没有读写副作用。工具夹具测试与正式登记分别记录。最终接入批次已实际登记、同步；清理仅移除了本批已无引用的旧地环图集及其导入记录，保留源文件和失败记录。

## 验收记录

在本目录另存 `validation.json`。不修改构建器持续输出的 `animations.json` 来登记验收。每项记录绑定当前**实际PNG内容**的SHA256，`body`和`fx`必须同时给出；无效果层明确写`null`。例子是待填写模板，不是跑步已通过的声明：

```json
{
  "version": 1,
  "actions": {
    "run": {
      "hashes": {"body": "填写当前本体PNG的64位SHA256", "fx": null},
      "technical": {"status": "pending", "reviewer": "", "reviewed_at": "", "evidence": []},
      "runtime": {"status": "pending", "reviewer": "", "reviewed_at": "", "evidence": []},
      "art": {"status": "pending", "reviewer": "", "reviewed_at": "", "evidence": [], "reviewer_kind": "agent", "user_approved": false}
    }
  }
}
```

三阶段分别是技术检查、正式角色实机接入、美术复核。`status`只接受`pending`、`passed`、`failed`。记录结果必须填真实复核者、复核时间和非空证据引用列表；证据可以是仓库文档、当地实际日志/录屏路径、用户明确验收消息的引用。脚本保存显式记录，不替人检查证据内容；不能把存在某个文件或生成成功推断为验收通过。

- 登记先核对实际PNG与`animations.json`中的SHA。文件缺失或SHA不一致直接中止，两个主台账文件都不写入。
- 未提供记录、body/fx任一SHA不匹配、缺省fx字段或阶段记录不完整：对应阶段不算通过，整体保持`candidate`。
- 一项的body和fx作为同一次组合绑定；新增或更换效果层会使原本体/效果组合的记录失效。
- 技术和实机均通过时可记录`main-level-integrated`，但美术未通过时仍是`candidate`。
- 三阶段全部通过才登记`accepted`。这不是用户确认；只有art记录明确来自真实用户（`reviewer_kind: user`且`user_approved: true`）时才设置`userArtApproval`。
- 记录绑定的是图集字节，不代表后续输入、事件时序、Shader、尺度或场景代码改动自动经过复验。改动这些内容后应重新复核并更新runtime/art记录。
- 独立弹体/红索小图使用`actions["extra:projectile.png"]`、`extra:shadow_projectile.png`、`extra:tether.png`的独立记录，`hashes.body`绑定自身图片、`hashes.fx`为null；不会借用某项动作的验收结果。

精灵表补制按`source_kind`/`source_grid`登记`AI补制`、`精灵表`和`sourceKind: sprite-sheet-ai`；视频提取记录`视频提取`/`video-extraction`。没有足够来源字段时标为`来源待核验`。脚本保留具体源文件与源SHA，不把关键姿势表称作视频提取动画。

## 正式登记

请等构建、精灵表合并和元数据写入全部结束再执行。无参数保持原登记行为，会更新本批台账与同步条目；其它资源条目保留。

```powershell
python assets/source/tide-picker-action36/register.py --dry-run
python assets/source/tide-picker-action36/register.py
# 可选：读取指定独立验收记录
python assets/source/tide-picker-action36/register.py --validation path/to/validation.json --dry-run
node tools/godot.mjs sync-art
```

缺失validation文件不会自动创建通过记录。摘要会输出每项的`hashMatched`、`status`和`integrationStatus`，便于复查。

## 过期图集清理

`--prune`为独立模式，**只列清单，不登记、不同步、不删除**。必须显式再加`--apply`才删除。

```powershell
python assets/source/tide-picker-action36/register.py --prune
python assets/source/tide-picker-action36/register.py --prune --apply
```

建议先登记和同步，再预览清理。保护集合包含源runtime的animations、已同步game的animations，以及`game/art/manifest.json`仍引用的文件；这样未同步完的旧版本不会被提前删除。

清理范围严格限定本任务的两个直接目录：

- `assets/runtime/sprites/tide-picker-action36/`内不再被引用的`*-body.png`、`*-fx.png`。
- `game/art/tide-picker-action36/`内同类PNG及其对应`.png.import`，包括已没有PNG的孤立导入记录。

不递归，不删源视频、脚本、JSON、弹体/红索位图、其它命名文件、runtime侧的.import、其它资源目录或`.godot`缓存。执行前检查整个候选清单的解析路径；目录重定向、符号链接、Windows junction、越界资源URI会拒绝处理。源记录仍引用的图集无论状态是否candidate均保留。

临时夹具回归（只操作系统临时目录）：

```powershell
python assets/source/tide-picker-action36/tools/test_registration.py
```

测试覆盖哈希失效、新增FX使旧记录失效、阶段独立、用户确认独立、精灵表来源、无副作用预览、失败前不改台账、窄范围清理、旧同步引用保护及越界/重定向拒绝。

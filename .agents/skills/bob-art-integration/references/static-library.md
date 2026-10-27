# BOB 静态库操作与验证

用于完整静态交付、派生图集更新或管理页修改。以下命令从 BOB 仓库根目录运行，只执行本任务需要的操作。当前批次入口为 [V5.2 验收记录](../../../../assets/source/whalefall-v5-2-complete/acceptance.md)，使用说明仍以 [assets/README.md](../../../../assets/README.md) 为准。

## 需求与文件关联

- 从该批次 `inventory/`、原画与文档快照盘点，再维护 [coverage.json](../../../../assets/source/whalefall-v5-2-complete/coverage.json)。`requirements[].outputIds` 指向 `assets/catalog.json` 的稳定资源 `id`；`rooms[].requirementIds` 指向需求 `id`，资源的 `rooms` 指向房间 `id`。显示名、文件总数和图集 frame 数均不能替代这些关联。
- [state-rules.json](../../../../assets/source/whalefall-v5-2-complete/state-rules.json)用 `requirementId` 关联需求；有 `staticComponents` 时核对每个资源 ID。组合覆盖要说明哪些状态靠换图、位置、旋转、透明度或文字实现，并保留尚待动画、时序和交互实现的边界。`outputPlanComplete` 不能单独证明文件齐全。
- 逐件核对 PNG 的哈希、尺寸、来源、提示词/可编辑源与缩略图；原始 PNG 保留不动。列表读缩略图、详情读原图；缩略图与图集不计作新的独立需求产物。
- `status: accepted` 表示已记录的静态检查通过。用户美术确认另记；实际修改加载器并完成接入验证之前，保留 `integrationStatus: not-integrated`。

## 从最终台账复跑

组合预览、图集与完整性报告读取最终 `assets/catalog.json` 和实际文件，避免沿用制作工作区的临时路径。以下脚本已经在项目内，勿另复制一份实现。

| 操作 | 输入与产物 |
| --- | --- |
| `python3 assets/source/whalefall-v5-2-complete/tools/make-thumbnails.py` | 从台账原图与 `bbox` 生成该批次 `thumbnails/`；会写回 `thumbnail` 并增加台账 `revision`，不改原图 |
| `node tools/compose-components.cjs <输出目录>` | 读取台账、实际 PNG 与 `review/components/components-recipe.json`；输出组合板和 `composition-render.json`。省略目录会写入已有 `review/components/` |
| `python3 assets/source/whalefall-v5-2-complete/tools/pack-atlases.py` | 按台账生成 `assets/runtime/sprites/whalefall-complete-atlas/` 下的分页 PNG、JSON、索引与 ZIP；不改台账和逐件 PNG |
| `python3 assets/source/whalefall-v5-2-complete/tools/verify-atlases.py` | 独立核对台账、源 PNG、索引、分页和 ZIP，写图集目录的 `verification-report.json` |
| `python3 assets/source/whalefall-v5-2-complete/tools/verify-delivery.py` | 核对文件、来源、需求/房间关联、旧批次原图和图集，写该批次 `review/delivery-integrity.json`；不改素材 |

Python 图像脚本需要 Pillow。组合脚本需要可解析的 Playwright；`PLAYWRIGHT_MODULE` 可指定模块目录。复核已有组合时指定新的输出目录，再与验收板比较，避免先覆盖基线。配方、挂点与复跑细节见[组件组合说明](../../../../assets/source/whalefall-v5-2-complete/review/components/README.md)。

`verify-delivery.py` 的默认数量及原图基线绑定当前 V5.2 交付。扩充批次时，先从需求盘点确定预期，再核对其 `--assets`、`--requirements`、`--rooms`、`--backgrounds`、`--atlas-frames` 参数及原图基线逻辑；不要用实际产出数量反填预期来消除失败，也不要把旧默认值推广为其他批次门槛。

## 组合与图集检查

1. 配方中的基底与子件 ID 均在最终台账中且文件可读。挂点采用原始基底画布像素；同组状态共用比例、取景和注册点，子件围绕明确铰点旋转。复跑后检查图像与变换记录，目检门闩正反侧、奖励拾取前后和生态组合；通道透明度采样仅证明静态图像没有遮挡。
2. 当前打包器选择 `accepted` 静态精灵，排除背景和 L0/L1。世界精灵遵循现有 128 px/U，UI 保留原生画布与 `nineSlice`，同体状态保留 `staticFamilyRegistration`；超出图集页尺寸时先处理规格，不为塞进一页单独缩小。
3. 运行独立图集验证：输入签名与当前台账一致；frame 集合无缺项/多项、无重叠；逐件裁片与源图缩放结果逐像素一致；`sourceRect`、原始及裁片 pivot、挂点正确；外扩像素、透明间隔和 ZIP 字节一致。当前静态索引的 `animations` 应为空。

图集是导出时的快照。管理页保存不自动重打包；打包输入或静态验收状态变化后，按需重新导出再验证。输入签名或裁片检查失败时先查台账和实际源文件，不通过修改报告把失败改为通过。重新生成的派生导出不能证明用户已认可美术或游戏已能加载。

## 管理页持久化与恢复

启动方式见资源管理说明；必须经管理服务访问，静态游戏服务器没有保存 API。页面仅编辑名称、标签、备注和静态验收状态。台账保存采用 `revision` 冲突检查及临时文件替换；写入失败和版本冲突会保留当前页面草稿。

```sh
npm --prefix assets/manager run check
npm --prefix assets/manager test
npm --prefix assets/manager run test:ui
```

`test:ui` 需要 Playwright 和 Chromium；模块不在默认解析位置时，设置 `PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs`。服务测试使用临时测试台账，UI 测试自行复制 `assets/` 到临时目录、启动独立服务并核对真实台账未变；复测保存/归档时沿用这两个入口，不对正式台账写入测试内容。

按修改范围选择以下 case，并区分本轮执行结果和[历史页面验证](../../../../assets/manager/progress.md)：

1. **显示与映射**：列表缩略图实际载入，选择后原图可见，搜索/类别筛选与需求页 ID 映射正确；空白 canvas 或只返回 HTTP 200 不算图片实载。
2. **持久化**：保存后检查临时 JSON、刷新页面和重启服务；名称、标签去重、备注、状态保留，路径与原有证据未被编辑覆盖。
3. **草稿与错误**：切换资源可继续编辑或放弃；过期 `revision` 返回冲突，网络失败保留草稿。冲突后先复制草稿，再重新载入、核对最新值并重做所需编辑；当前页面保留不等于草稿已持久化。
4. **归档恢复**：归档仅修改状态，默认列表移除；在归档筛选中找到同一 ID，恢复原状态并保存，图片仍存在。不要把恢复统一写成 `accepted`，以免跳过尚未完成的静态验收。
5. **验证边界**：服务测试检查非法字段/请求不会破坏台账；UI 测试另检查页面异常与窄屏布局。它们不覆盖美术接受、动作连贯性、游戏碰撞或路线可达性；接入任务继续使用主 skill 的实机流程。
